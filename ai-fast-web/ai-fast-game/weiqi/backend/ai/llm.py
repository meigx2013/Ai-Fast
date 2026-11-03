"""DeepSeek 模型调用模块：Chat Completions 风格异步客户端。

职责边界：
- 仅负责模型 HTTP 调用、提示词拼装、防御性 JSON 解析、重试与规则预校验；
- 任何失败（网络/超时/HTTP 错误/解析失败/非法坐标/无候选却虚手）统一抛
  `LlmError`，由 engine 捕获后回退启发式，绝不把未校验结果交给前端；
- 密钥只从 Settings 注入请求头，禁止打印 Authorization 或完整密钥。

安全与降级原则（总纲第 7 节）：
- 单次调用超时由 settings.timeout_seconds 控制（默认 12 秒）；
- 失败后最多重试 settings.max_retries 次（默认 1 次），退避间隔可配置；
- 模型输出必须是严格 JSON，Markdown 包裹、非 JSON、缺字段、错误类型、
  越界/占用/自杀/劫坐标一律视为本次调用失败。
"""

import asyncio
import json
import logging
import re

import httpx

from .. import go_rules
from . import heuristic

logger = logging.getLogger("weiqi.backend.ai.llm")

# 模型理由回传给前端前的最大长度，避免异常超长输出。
MAX_REASON_LENGTH = 60

# 匹配 ```json ... ``` 或 ``` ... ``` 的 Markdown 代码块包裹。
_FENCE_RE = re.compile(r"```(?:json)?\s*(.*?)\s*```", re.DOTALL)


class LlmError(Exception):
    """模型调用/解析/校验失败。异常消息不含密钥与请求头。"""


def _build_client() -> httpx.AsyncClient:
    """创建异步 HTTP 客户端；独立函数便于测试注入 Fake 客户端。"""
    return httpx.AsyncClient()


def _clean_reason(reason) -> str:
    """规整模型给出的理由：非字符串或为空时给默认值，并截断过长文本。"""
    if not isinstance(reason, str) or not reason.strip():
        return "模型建议"
    text = reason.strip().replace("\n", " ")
    return text[:MAX_REASON_LENGTH]


def _extract_content(payload) -> str:
    """从 Chat Completions 响应中提取首条消息内容，结构异常时抛 LlmError。"""
    if not isinstance(payload, dict):
        raise LlmError("模型响应不是 JSON 对象")
    choices = payload.get("choices")
    if not isinstance(choices, list) or not choices:
        raise LlmError("模型响应缺少 choices")
    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    if not isinstance(message, dict):
        raise LlmError("模型响应缺少 message")
    content = message.get("content")
    if not isinstance(content, str):
        raise LlmError("模型响应 content 非字符串")
    return content


def parse_llm_reply(text: str, size: int) -> tuple[str | tuple[int, int], str]:
    """防御性解析模型回复，返回 ("pass" | (row, col), reason)。

    处理：空响应、Markdown 包裹、非 JSON、非对象、move 缺失/类型错误、
    非整数坐标（含 bool）、越界坐标。任何问题均抛 LlmError。
    """
    if not isinstance(text, str) or not text.strip():
        raise LlmError("模型返回空内容")
    content = text.strip()
    fenced = _FENCE_RE.search(content)
    if fenced:
        content = fenced.group(1).strip()
    # 容错：截取首个 "{" 到最后一个 "}" 之间的内容再解析。
    start, end = content.find("{"), content.rfind("}")
    if start == -1 or end <= start:
        raise LlmError("模型返回中未找到 JSON 对象")
    try:
        data = json.loads(content[start : end + 1])
    except json.JSONDecodeError as exc:
        raise LlmError("模型返回非合法 JSON") from exc
    if not isinstance(data, dict):
        raise LlmError("模型返回 JSON 不是对象")

    move = data.get("move")
    if move == "pass":
        return "pass", _clean_reason(data.get("reason"))
    if not isinstance(move, dict) or "row" not in move or "col" not in move:
        raise LlmError("模型 move 字段缺失或类型错误")
    row, col = move["row"], move["col"]
    # bool 是 int 子类，需一并排除。
    if (
        isinstance(row, bool) or isinstance(col, bool)
        or not isinstance(row, int) or not isinstance(col, int)
    ):
        raise LlmError("模型坐标不是整数")
    if not (0 <= row < size and 0 <= col < size):
        raise LlmError(f"模型坐标越界：({row},{col})")
    return (row, col), _clean_reason(data.get("reason"))


def build_messages(request, profile, ranked_candidates) -> list[dict]:
    """拼装模型消息：尺寸、0 基坐标、棋盘值、白方回合、候选点与级位策略。"""
    size = request.size
    board_lines = "\n".join(
        f"{row_index} {''.join(str(value) for value in row)}"
        for row_index, row in enumerate(request.board)
    )
    candidate_lines = "\n".join(
        f"({row},{col}) {tag} 评分{score:.0f}"
        for score, row, col, tag in ranked_candidates
    )
    system = (
        "你是一个围棋 AI，执白（棋子值 2），对手黑方为 1，空点为 0。"
        "坐标系为 0 基：row 从上到下、col 从左到右，均从 0 开始。"
        "你必须从给定的合法候选点中选择一个落点。"
        "只输出严格 JSON，禁止 Markdown 代码块和任何额外文字。"
        '输出格式：{"move":{"row":3,"col":15},"reason":"简短理由"} '
        '或 {"move":"pass","reason":"理由"}'
    )
    user = (
        f"棋盘尺寸：{size}×{size}\n"
        f"当前手数：{request.moveNumber}\n"
        f"盘面（每行开头数字为 row，其后依次为 col=0 到 {size - 1} 的值）：\n"
        f"{board_lines}\n"
        "当前轮到白方（你）落子。\n"
        f"你的级位：{profile.label}，策略要求：{profile.strategy}\n"
        "按启发式评分从高到低排序的合法候选点：\n"
        f"{candidate_lines}\n"
        "请只输出 JSON。"
    )
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
    ]


async def request_llm_move(request, profile, settings, candidates, last_move):
    """请求模型下一手，返回 ((row, col), reason)。

    前置条件：candidates 非空（由 engine 保证）。本函数内部完成：
    Top-K 候选约束 → 提示词拼装 → HTTP 调用（超时/重试/退避）→
    防御性解析 → 服务端规则预校验。任何失败在重试耗尽后抛 LlmError。
    模型在仍有合法候选时返回 pass 视为失败（虚手只能由无合法点触发）。
    """
    size = request.size
    board = request.board
    previous_board = request.previousBoard

    ranked = heuristic.rank_candidates(
        board, size, go_rules.WHITE, previous_board, last_move,
        profile=profile, candidates=candidates,
    )
    # 候选数上限：级位 top_k，且不超过全局配置预算。
    k = max(1, min(profile.top_k, settings.candidate_top_k, len(ranked)))
    payload = {
        "model": settings.model,
        "messages": build_messages(request, profile, ranked[:k]),
        "temperature": profile.temperature,
        "max_tokens": settings.max_tokens,
    }
    headers = {
        "Authorization": f"Bearer {settings.api_key}",
        "Content-Type": "application/json",
    }
    url = f"{settings.base_url}/chat/completions"
    attempts = 1 + max(0, settings.max_retries)
    last_error: LlmError | None = None

    for attempt in range(1, attempts + 1):
        try:
            async with _build_client() as client:
                response = await client.post(
                    url, json=payload, headers=headers, timeout=settings.timeout_seconds
                )
            if response.status_code != 200:
                # 不回显响应体，避免把模型侧敏感信息写进日志或异常。
                if response.status_code == 400:
                    # 400 通常是模型名不被服务端支持（而非瞬时故障），给出可操作提示。
                    raise LlmError(
                        "模型 HTTP 状态码 400（请检查 DEEPSEEK_MODEL 是否为"
                        "服务端支持的模型名，如 deepseek-flash）"
                    )
                raise LlmError(f"模型 HTTP 状态码 {response.status_code}")
            content = _extract_content(response.json())
            move, reason = parse_llm_reply(content, size)
            if move == "pass":
                raise LlmError("模型在仍有合法候选时返回 pass")
            row, col = move
            check = go_rules.simulate_move(board, size, row, col, go_rules.WHITE, previous_board)
            if not check.ok:
                raise LlmError(f"模型坐标违反规则：{check.reason}")
            return (row, col), reason
        except LlmError as exc:
            last_error = exc
        except (httpx.TimeoutException, httpx.HTTPError) as exc:
            # 只记录异常类型，不携带 URL/请求头等可能含密钥的细节。
            last_error = LlmError(f"模型网络错误：{type(exc).__name__}")
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            last_error = LlmError(f"模型响应结构异常：{type(exc).__name__}")

        if attempt < attempts:
            await asyncio.sleep(settings.retry_backoff_seconds)

    raise LlmError(f"模型调用失败（已重试 {attempts - 1} 次）：{last_error}")
