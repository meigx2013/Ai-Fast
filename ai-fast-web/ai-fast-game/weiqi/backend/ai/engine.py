"""AI 引擎统一入口：级位调度 + 模型优先 + 启发式永久兜底。

流程（任务 4）：
1. 读取配置与级位档案（levels.get_level_profile）；
2. 配置了密钥且存在合法候选时，优先调用 DeepSeek（llm.request_llm_move，
   内部含 Top-K 候选约束、12 秒超时、最多 1 次重试与规则预校验）；
3. 模型路径任何失败（LlmError / 意外异常）降级启发式，engine 如实标记；
4. 启发式路径应用级位参数（噪声幅度、随性一手概率、评分权重、战术加成）；
5. 引擎候选返回前必须再次通过服务端规则校验（双保险）；
6. 无合法点时返回 "pass"。

安全兜底原则：
- 引擎内部任何异常都不向外抛 500，先回退 first_legal_or_pass；
- 密钥与请求头绝不进入日志和响应。
"""

import logging
import random
import time

from .. import go_rules
from ..config import get_settings
from ..models import AiMoveRequest, AiMoveResponse, MovePoint
from . import heuristic, levels, llm

logger = logging.getLogger("weiqi.backend.ai")


def _extract_last_move(request: AiMoveRequest) -> tuple[int, int] | None:
    last_move = request.lastMove
    if isinstance(last_move, MovePoint):
        return last_move.row, last_move.col
    return None  # None 或 "pass"


async def generate_move(request: AiMoveRequest) -> AiMoveResponse:
    """生成白方（AI）下一手；请求体已由 Pydantic 完成结构校验。"""
    start = time.perf_counter()
    settings = get_settings()
    profile = levels.get_level_profile(request.level)
    board = request.board
    size = request.size
    previous_board = request.previousBoard
    last_move = _extract_last_move(request)

    # ---- 模型路径：密钥存在且仍有合法候选时优先尝试 ----
    if settings.llm_enabled:
        try:
            candidates = heuristic.generate_candidates(board, size, go_rules.WHITE, previous_board)
            if candidates:
                (row, col), reason = await llm.request_llm_move(
                    request, profile, settings, candidates, last_move
                )
                # 双保险：模型结果返回前再次通过服务端规则校验。
                check = go_rules.simulate_move(board, size, row, col, go_rules.WHITE, previous_board)
                if check.ok:
                    return AiMoveResponse(
                        move=MovePoint(row=row, col=col),
                        reason=reason,
                        elapsedMs=int((time.perf_counter() - start) * 1000),
                        engine="llm",
                    )
                # 理论上不可达（llm 内部已校验）；保留双保险降级日志。
                logger.warning("模型坐标未通过二次规则校验(%s)，降级启发式", check.reason)
            # 无合法候选：直接进入启发式 pass 分支，不浪费模型调用。
        except llm.LlmError as exc:
            logger.warning("模型调用失败，降级启发式：%s", exc)
        except Exception:
            logger.exception("模型路径意外异常，降级启发式")

    # ---- 启发式路径（带级位参数）：始终可用的兜底 ----
    try:
        choice = heuristic.choose_move(
            board, size, go_rules.WHITE, previous_board, last_move,
            random.Random(), profile=profile,
        )
    except Exception:
        logger.exception("启发式引擎异常，回退至首个合法点")
        choice = None

    if choice is not None:
        row, col, reason = choice
        # 双保险：引擎候选必须再次通过服务端规则校验。
        check = go_rules.simulate_move(board, size, row, col, go_rules.WHITE, previous_board)
        if not check.ok:
            logger.warning("引擎候选 (%s,%s) 未通过规则校验(%s)，回退", row, col, check.reason)
            choice = None

    if choice is None:
        try:
            choice = heuristic.first_legal_or_pass(board, size, go_rules.WHITE, previous_board)
        except Exception:
            logger.exception("兜底策略异常，虚手")
            choice = None

    elapsed_ms = int((time.perf_counter() - start) * 1000)

    if choice is None:
        # 无合法点（满盘或所有空点均为自杀/劫）时返回 pass。
        return AiMoveResponse(
            move="pass",
            reason="无合法落点，虚手",
            elapsedMs=elapsed_ms,
            engine="heuristic",
        )

    row, col, reason = choice
    return AiMoveResponse(
        move=MovePoint(row=row, col=col),
        reason=f"[{profile.label}]{reason}",
        elapsedMs=elapsed_ms,
        engine="heuristic",
    )
