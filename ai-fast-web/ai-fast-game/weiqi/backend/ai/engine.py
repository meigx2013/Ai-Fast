"""系统对弈引擎统一入口：级位档案 → 级位决策管道 → 规则双保险 → 响应。

流程（v2，本地级位引擎为唯一应手路径，无任何模型调用）：
1. 读取级位档案（levels.get_level_profile）；
2. 调用级位决策管道（decision.decide：模块融合 + 习惯 + 噪声 + 主动 Pass）；
3. 引擎候选返回前必须再次通过服务端规则校验（双保险）；
4. 决策管道异常时回退首个合法点；仍无合法点时返回 "pass"。

引擎函数黑白参数化（player 参数）为任务 5/8 自对弈测试铺路；
`generate_move` 端点入口固定系统执白。

安全兜底原则：
- 引擎内部任何异常都不向外抛 500，先回退 first_legal_or_pass；
- 无密钥、无网络调用，本地引擎是唯一应手路径。
"""

import logging
import random
import time

from .. import go_rules
from ..models import MovePoint, SystemMoveRequest, SystemMoveResponse
from . import decision, levels

logger = logging.getLogger("weiqi.backend.ai")

ENGINE_NAME = "kyu-engine"


def _extract_last_move(request: SystemMoveRequest) -> tuple[int, int] | None:
    last_move = request.lastMove
    if isinstance(last_move, MovePoint):
        return last_move.row, last_move.col
    return None  # None 或 "pass"


def first_legal_or_pass(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> tuple[int, int, str] | None:
    """兜底策略：按行列顺序返回第一个合法点；无合法点返回 None。

    仅在决策管道出现意外异常时由引擎调用，保证接口永不因引擎缺陷而 500。
    """
    for row in range(size):
        for col in range(size):
            if board[row][col] != go_rules.EMPTY:
                continue
            if go_rules.simulate_move(board, size, row, col, player, previous_board).ok:
                return row, col, "稳健应手"
    return None


def generate_engine_move(
    board: list[list[int]],
    size: int,
    player: int,
    level: int,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    move_number: int = 0,
    rng: random.Random | None = None,
) -> tuple[tuple[int, int] | None, str]:
    """生成 player 方下一手（黑白参数化，自对弈测试直接调用）。

    返回 (落点, reason)；落点为 None 表示虚手。三层兜底：
    决策管道 → 首个合法点 → "pass"。reason 统一带 [N级] 前缀。
    """
    profile = levels.get_level_profile(level)
    if rng is None:
        rng = random.Random()

    result = None
    try:
        result = decision.decide(
            board, size, player, profile,
            previous_board=previous_board, last_move=last_move,
            rng=rng, move_number=move_number,
        )
    except Exception:
        logger.exception("级位决策管道异常，回退至首个合法点")
        result = None

    # 双保险：引擎候选必须再次通过服务端规则校验。
    if result is not None and result.move is not None:
        row, col = result.move
        check = go_rules.simulate_move(board, size, row, col, player, previous_board)
        if not check.ok:
            logger.warning(
                "引擎候选 (%s,%s) 未通过规则校验(%s)，回退首个合法点", row, col, check.reason
            )
            result = None
        else:
            return (row, col), f"[{profile.label}]{result.reason}"

    # 决策正常给出的虚手（无合法点或级位化主动 Pass）直接采纳。
    if result is not None and result.move is None:
        return None, f"[{profile.label}]{result.reason}"

    # 兜底：首个合法点；仍无合法点时虚手。
    try:
        choice = first_legal_or_pass(board, size, player, previous_board)
    except Exception:
        logger.exception("兜底策略异常，虚手")
        choice = None

    if choice is None:
        return None, "无合法落点，虚手"
    row, col, reason = choice
    return (row, col), f"[{profile.label}]{reason}"


async def generate_move(request: SystemMoveRequest) -> SystemMoveResponse:
    """生成白方（系统）下一手；请求体已由 Pydantic 完成结构校验。"""
    start = time.perf_counter()
    last_move = _extract_last_move(request)
    move, reason = generate_engine_move(
        request.board,
        request.size,
        go_rules.WHITE,
        request.level,
        previous_board=request.previousBoard,
        last_move=last_move,
        move_number=request.moveNumber,
    )
    elapsed_ms = int((time.perf_counter() - start) * 1000)

    if move is None:
        return SystemMoveResponse(
            move="pass",
            reason=reason,
            elapsedMs=elapsed_ms,
            engine=ENGINE_NAME,
        )
    row, col = move
    return SystemMoveResponse(
        move=MovePoint(row=row, col=col),
        reason=reason,
        elapsedMs=elapsed_ms,
        engine=ENGINE_NAME,
    )
