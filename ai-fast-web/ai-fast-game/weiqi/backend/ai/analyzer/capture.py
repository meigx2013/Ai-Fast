"""吃子思维分析器（任务 3 完整能力）：提子、气数、叫吃、救援、逃吃、对杀气数。

由 v1 启发式的四个评分维度（提子/气数/叫吃/救援）平移并模块化（任务 2），
任务 3 补齐低级位吃子死活基本功的完整能力：
1. 提子：直接可提子的落点（压倒性优先，任何级位都不放过）；
2. 己方气数：落子后自身棋块的气（1 气 = 送吃风险，气多则厚）；
3. 叫吃：落子后对方邻块只剩 1 气；
4. 救援：相邻己方危险棋块（气 <= 2）落子后气数增长；
5. 逃吃：己方 1 气块的有效逃吃方向——落子后包含原块的整体气数增长
   （> 1 气）才算有效逃，加分显著高于普通联络；
6. 对杀气数：己方低气数棋块与对方低气数棋块相互邻近时的气数对比，
   输出"杀得过/杀不过"结论并加减分；低级位按 accuracy.liberty 概率性
   "数错"对方气数（±1 气，随机源走 ctx.rng，数错时可能做出错误对杀决策）。
"""

from ... import go_rules
from ...go_rules import BLACK, EMPTY, WHITE
from . import life_death
from .base import Candidate, GameContext

# 对杀判定门槛：双方气数均 <= 3 才视为"相互包围"的紧气对杀（开放棋盘上
# 的普通接触不算对杀，避免噪声污染全局评分与随机流）。
SEMEAI_LIBERTY_LIMIT = 3


def semeai_verdict(
    own_liberties: int,
    opponent_liberties: int,
    *,
    rng: object | None = None,
    accuracy: float = 1.0,
) -> tuple[str, int]:
    """对杀气数结论，返回 (结论, 引擎数出的对方气数)。

    结论为 "杀得过" / "杀不过" / "对气"。携带 rng 时按 accuracy 概率性
    数错对方气数（±1 气，各 50%）：accuracy 为级位精度（气数计算正确率），
    rng 缺省时为精确计算（干净评分路径）。
    """
    counted = opponent_liberties
    if rng is not None and rng.random() > accuracy:
        step = 1 if rng.random() < 0.5 else -1
        counted = max(0, opponent_liberties + step)
    if own_liberties > counted:
        return "杀得过", counted
    if own_liberties < counted:
        return "杀不过", counted
    return "对气", counted


def escape_targets(ctx: GameContext) -> list[tuple[int, int]]:
    """己方 1 气块的有效逃吃方向，返回落点清单。

    有效逃 = 落子点与被叫吃块相邻，且落子后包含原块的整体气数增长
    （> 1 气），或直接提掉紧邻攻击者（captured > 0，提子即解围）。
    供决策器视野过滤（"己方被叫吃块"进入告警视野）与测试复用。
    """
    warnings = life_death.atari_groups(ctx.board, ctx.size, ctx.player)
    if not warnings:
        return []
    warning_stones: set[tuple[int, int]] = set()
    for stones, _liberty in warnings:
        warning_stones.update(stones)
    escapes: list[tuple[int, int]] = []
    for row, col, move_result in ctx.candidates:
        if not any(
            (n_row, n_col) in warning_stones
            for n_row, n_col in go_rules.neighbors(row, col, ctx.size)
        ):
            continue
        if move_result.captured > 0:
            escapes.append((row, col))  # 提掉攻击者同样是逃
            continue
        _, liberties_after = go_rules.get_group(move_result.board, ctx.size, row, col)
        if len(liberties_after) > 1:
            escapes.append((row, col))
    return escapes


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """对全部合法候选做吃子维度评分，返回带类型标签的候选列表。"""
    weights = profile.weights
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    board = ctx.board
    size = ctx.size
    results: list[Candidate] = []

    # 己方 1 气块告警（气 <= 1 必死，逃吃方向加分）。
    escape_points = set(escape_targets(ctx))

    for row, col, move_result in ctx.candidates:
        score = 0.0
        tag: str | None = None

        # 1. 提子：压倒性优先。
        if move_result.captured > 0:
            score += 120.0 * move_result.captured * weights.capture
            tag = f"提取{move_result.captured}子"

        # 2. 己方落子块的气数：1 气 = 自陷/送吃风险，2 气 = 略亏，气多则厚。
        new_board = move_result.board
        _, own_liberties = go_rules.get_group(new_board, size, row, col)
        own_liberty_count = len(own_liberties)
        if own_liberty_count == 1:
            score -= 90.0 * weights.liberty
            if tag is None:
                tag = "保守联络"
        elif own_liberty_count == 2:
            score -= 12.0 * weights.liberty
        else:
            score += min(own_liberty_count, 6) * 2.5 * weights.liberty

        # 3. 压制对方邻块：落子后对方棋块只剩 1 气即叫吃。
        checked: set[tuple[int, int]] = set()
        for n_row, n_col in go_rules.neighbors(row, col, size):
            if new_board[n_row][n_col] != opponent or (n_row, n_col) in checked:
                continue
            stones, liberties = go_rules.get_group(new_board, size, n_row, n_col)
            checked.update(stones)
            if len(liberties) == 1 and move_result.captured == 0:
                score += 45.0 * weights.atari
                if tag is None:
                    tag = "紧气叫吃"

        # 4. 救援己方危险棋块：相邻己方块气 <= 2，落子后整体气数增长。
        for n_row, n_col in go_rules.neighbors(row, col, size):
            if board[n_row][n_col] != player:
                continue
            _, old_liberties = go_rules.get_group(board, size, n_row, n_col)
            if len(old_liberties) <= 2 and own_liberty_count > len(old_liberties):
                score += 50.0 * weights.rescue
                if tag is None:
                    tag = "救援己方"
                break

        # 5. 逃吃：己方 1 气块的有效逃方向（提子情形已由维度 1 覆盖）。
        # 标签优先于泛化的"救援己方"（逃吃是更具体的思维动作）。
        if move_result.captured == 0 and (row, col) in escape_points:
            score += 70.0 * weights.rescue
            if tag is None or tag == "救援己方":
                tag = "逃出叫吃"

        # 6. 对杀气数：己方低气块与对方低气块相互邻近时的气数对比。
        if move_result.captured == 0 and own_liberty_count <= SEMEAI_LIBERTY_LIMIT:
            checked_racing: set[tuple[int, int]] = set()
            for n_row, n_col in go_rules.neighbors(row, col, size):
                if new_board[n_row][n_col] != opponent or (n_row, n_col) in checked_racing:
                    continue
                stones, liberties_after = go_rules.get_group(new_board, size, n_row, n_col)
                checked_racing.update(stones)
                if len(liberties_after) > SEMEAI_LIBERTY_LIMIT:
                    continue
                _, liberties_before = go_rules.get_group(board, size, n_row, n_col)
                if len(liberties_before) > SEMEAI_LIBERTY_LIMIT:
                    continue  # 对方原本气足，不算相互包围的对杀
                verdict, counted = semeai_verdict(
                    own_liberty_count, len(liberties_after),
                    rng=ctx.rng, accuracy=profile.accuracy.liberty,
                )
                margin = own_liberty_count - counted
                if verdict == "杀得过":
                    score += min(margin, 3) * 6.0 * weights.liberty
                    if tag is None:
                        tag = "对杀占先"
                elif verdict == "杀不过":
                    score -= min(-margin, 3) * 6.0 * weights.liberty
                break  # 同一候选只按最紧的一组对杀评一次

        results.append(Candidate(row=row, col=col, score=score, tag=tag or ""))

    return results


def capture_targets(ctx: GameContext) -> list[tuple[int, int, int]]:
    """直接可提子的落点枚举，返回 [(row, col, 提子数)]。

    供后续模块（对杀/手筋/死活）与测试复用；任何级位都不放过提子机会。
    """
    targets: list[tuple[int, int, int]] = []
    for row, col, move_result in ctx.candidates:
        if move_result.captured > 0:
            targets.append((row, col, move_result.captured))
    return targets


def atari_targets(ctx: GameContext, player: int | None = None) -> list[tuple[int, int]]:
    """对方 1 气棋块的叫吃点（落子后使其只剩 1 气的己方落点）。

    player 为 None 时默认分析 ctx.player 的对手棋块。
    """
    board = ctx.board
    size = ctx.size
    me = ctx.player if player is None else player
    opponent = WHITE if me == BLACK else BLACK
    points: list[tuple[int, int]] = []
    seen_groups: set[tuple[int, int]] = set()
    for row in range(size):
        for col in range(size):
            if board[row][col] != opponent or (row, col) in seen_groups:
                continue
            stones, liberties = go_rules.get_group(board, size, row, col)
            seen_groups.update(stones)
            if len(liberties) == 1:
                liberty = next(iter(liberties))
                if board[liberty[0]][liberty[1]] == EMPTY:
                    points.append(liberty)
    return points
