"""手筋思维分析器（任务 4：双打吃 / 关门吃 / 扑 / 接不归）。

四类基础手筋的识别与评分（按级位开关，6~4 级模块 tesuji 解锁）：
- 双打吃（6 级起）：落子后同时叫吃对方两个不同棋块——对方只能逃一块，
  另一块必失（得分与"必得"等价）；
- 关门吃（6 级起）：对方 2 气块，己方落子收其中一气后，剩余唯一气点的
  四邻被己方与棋盘壁封死——对方逃无可逃（"关门"）；
- 扑（5 级起）：故意送吃——落子后自身仅 1 气且无提子，但对方提子后，
  己方在原落点回提可净得多子（倒扑）；
- 接不归（5 级起）：对方 2 气块被收气后，对方"接"上最后一气（逃跑）
  时合并块仍只剩 1 气——回家的连接点接不回（逃了也是死）。

级位能力边界：6 级仅双打吃/关门吃；5 级加扑/接不归；4 级全开（5 级已
全量，4 级的差距体现在死活加强读与征子步数，见 levels.py）。

全部判断基于 ctx.candidates 自带的落子模拟结果（MoveResult），无额外
盘面修改；标签体现手筋类型（reason 可解释性）。
"""

from ... import go_rules
from ...go_rules import BLACK, WHITE
from .base import Candidate, GameContext

# 各手筋分数：双打吃必得一块（次重量级），关门吃净吃，接不归是对方
# 无理的证明；扑（倒扑）净得 >= 2 子——按 capture 度量对齐 2×120，且
# 需压过"直接提吃 1 子"的诱惑（120），否则引擎宁提单子不做倒扑。
# 均低于提多子的直取（120×N）与点杀急所（62）之上的关系需与 capture
# 模块叠加：叫吃基础分 45 + 手筋加分。
DOUBLE_ATARI_SCORE = 55.0
GETA_SCORE = 50.0
SNAPBACK_SCORE = 260.0
CONNECT_DIE_SCORE = 42.0


def _adjacent_opponent_groups(
    board: list[list[int]], size: int, row: int, col: int, opponent: int
) -> list[set[tuple[int, int]]]:
    """落子后 (row, col) 邻接的对方棋块清单（每块只取一次）。"""
    groups: list[set[tuple[int, int]]] = []
    seen: set[tuple[int, int]] = set()
    for n_row, n_col in go_rules.neighbors(row, col, size):
        if board[n_row][n_col] != opponent or (n_row, n_col) in seen:
            continue
        stones, _liberties = go_rules.get_group(board, size, n_row, n_col)
        seen.update(stones)
        groups.append(stones)
    return groups


def _is_walled(
    board: list[list[int]], size: int, point: tuple[int, int], player: int,
    allowed: set[tuple[int, int]] | None = None,
) -> bool:
    """关门判定：point 的四邻（在盘内者）均为 player 色，或属于被围棋块
    自身（allowed，棋盘壁视为墙）。

    对方块若只剩这一口气，逃到此点也逃不出（关门吃）。
    """
    row, col = point
    for n_row, n_col in go_rules.neighbors(row, col, size):
        if board[n_row][n_col] == player:
            continue
        if allowed is not None and (n_row, n_col) in allowed:
            continue
        return False
    return True


def double_atari_points(ctx: GameContext) -> list[tuple[int, int, int]]:
    """双打吃点枚举，返回 [(row, col, 被叫吃块数)]。

    条件：落子后（不含提子）邻接的对方棋块中恰有 >= 2 块只剩 1 气。
    """
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    results: list[tuple[int, int, int]] = []
    for row, col, move_result in ctx.candidates:
        if move_result.captured > 0:
            continue  # 直接提子由 capture 模块覆盖
        new_board = move_result.board
        atari_count = 0
        for stones in _adjacent_opponent_groups(new_board, ctx.size, row, col, opponent):
            _, liberties = go_rules.get_group(new_board, ctx.size, *next(iter(stones)))
            if len(liberties) == 1:
                atari_count += 1
                if atari_count >= 2:
                    break
        if atari_count >= 2:
            results.append((row, col, atari_count))
    return results


def geta_points(ctx: GameContext) -> list[tuple[int, int]]:
    """关门吃点枚举：收掉对方 2 气块一气后，剩余气点被己方封闭。"""
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    board = ctx.board
    size = ctx.size
    results: list[tuple[int, int]] = []
    # 枚举对方 2 气块（低气块少，直接全盘扫一遍即可）。
    two_lib_groups: list[set[tuple[int, int]]] = []
    seen: set[tuple[int, int]] = set()
    for row in range(size):
        for col in range(size):
            if board[row][col] != opponent or (row, col) in seen:
                continue
            stones, liberties = go_rules.get_group(board, size, row, col)
            seen.update(stones)
            if len(liberties) == 2:
                two_lib_groups.append(stones)

    for stones in two_lib_groups:
        liberties = go_rules.get_group(board, size, *next(iter(stones)))[1]
        for target in liberties:
            # 己方在 target 收一气：检查合法性（在候选中）与关门性。
            move_result = next(
                (result for row, col, result in ctx.candidates if (row, col) == target),
                None,
            )
            if move_result is None or not move_result.ok:
                continue
            if move_result.captured > 0:
                continue  # 直接提子不是关门吃
            remaining = (liberties - {target})
            remaining_point = next(iter(remaining))
            if _is_walled(
                move_result.board, size, remaining_point, player, allowed=stones
            ):
                results.append(target)
    return results


def snapback_points(ctx: GameContext) -> list[tuple[int, int]]:
    """扑点枚举：送吃换取倒扑的落点。

    条件：落子后自身棋块仅剩 1 气（无提子）；对方若提吃（下在己方唯一
    气点），己方在原落点回提可净得 >= 2 子（倒扑成立）。
    """
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    size = ctx.size
    results: list[tuple[int, int]] = []
    for row, col, move_result in ctx.candidates:
        if move_result.captured > 0:
            continue  # 扑是送吃，不是提子
        new_board = move_result.board
        _, own_liberties = go_rules.get_group(new_board, size, row, col)
        if len(own_liberties) != 1:
            continue
        sacrifice_liberty = next(iter(own_liberties))
        # 对方提吃：在其气点落子提掉我方扑子。
        capture_result = go_rules.simulate_move(
            new_board, size, sacrifice_liberty[0], sacrifice_liberty[1], opponent
        )
        if not capture_result.ok or capture_result.captured == 0:
            continue
        # 我方回提：在原落点重新落子。
        recapture = go_rules.simulate_move(
            capture_result.board, size, row, col, player
        )
        if recapture.ok and recapture.captured >= 2:
            results.append((row, col))
    return results


def connect_die_points(ctx: GameContext) -> list[tuple[int, int]]:
    """接不归点枚举：对方 2 气块的连接点，接上后仍剩 1 气（逃了也死）。

    返回己方收气落点（抢先收掉"接不归方向"的一气，使对方无论接与不接
    都无生路）。
    """
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    board = ctx.board
    size = ctx.size
    results: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for row in range(size):
        for col in range(size):
            if board[row][col] != opponent or (row, col) in seen:
                continue
            stones, liberties = go_rules.get_group(board, size, row, col)
            seen.update(stones)
            if len(liberties) != 2:
                continue
            # 对每个收气点：己方收掉后对方只剩 1 气 L；
            # 对方逃（下在 L）后合并块仍 <= 1 气 → 接不归。
            for target in liberties:
                move_result = next(
                    (result for r, c, result in ctx.candidates if (r, c) == target),
                    None,
                )
                if move_result is None or not move_result.ok or move_result.captured > 0:
                    continue
                remaining = liberties - {target}
                escape_point = next(iter(remaining))
                escape_result = go_rules.simulate_move(
                    move_result.board, size, escape_point[0], escape_point[1], opponent
                )
                if not escape_result.ok:
                    results.append(target)  # 逃点自杀：等同接不归
                    continue
                _, merged_liberties = go_rules.get_group(
                    escape_result.board, size, escape_point[0], escape_point[1]
                )
                if len(merged_liberties) <= 1:
                    results.append(target)
    return results


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """手筋维度评分：按级位开关输出四类手筋候选。"""
    level = profile.level
    results: list[Candidate] = []

    for row, col, _count in double_atari_points(ctx):
        results.append(Candidate(
            row=row, col=col, score=DOUBLE_ATARI_SCORE, tag="双打吃",
        ))

    for row, col in geta_points(ctx):
        results.append(Candidate(
            row=row, col=col, score=GETA_SCORE, tag="关门吃",
        ))

    # 扑/接不归：5 级起掌握（6 级不识这两类手筋）。
    if level <= 5:
        for row, col in snapback_points(ctx):
            results.append(Candidate(
                row=row, col=col, score=SNAPBACK_SCORE, tag="扑倒扑",
            ))
        for row, col in connect_die_points(ctx):
            results.append(Candidate(
                row=row, col=col, score=CONNECT_DIE_SCORE, tag="接不归",
            ))

    return results
