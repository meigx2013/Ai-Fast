"""本地启发式 AI：合法候选生成 + 多维评分。

评分维度（与总纲 10～1 级的通用要求对齐）：
1. 提子（最高优先）
2. 避免自杀 / 明显自损（己方落子后棋块的气数）
3. 压制对方棋块（落子后对方邻块只剩 1 气 = 叫吃）
4. 救援己方危险棋块（相邻己方块气 <= 2 时为其增长气）
5. 靠近上一手（接触战倾向）
6. 占角 / 边的位置价值（一线差、三线四线好）
7. 联络（邻点己方子）与接触战（邻点对方子）

级位差异（任务 4）：
- `ScoreWeights` 对各维度做乘数缩放，由 `ai/levels.py` 的级位档案提供；
- `profile`（LevelProfile）注入后，choose_move 使用级位噪声幅度与非关键局面的
  "随性一手"概率（10 级约 40%），关键手段（提子/叫吃/救棋）不会被级位放弃；
- 不传 profile 时行为与任务 3 完全一致，作为可重复的基线。
"""

import random
from dataclasses import dataclass

from .. import go_rules
from ..go_rules import BLACK, EMPTY, WHITE

# 关键局面阈值：干净评分（无噪声）达到该值意味着提子/叫吃/救棋级别的要点，
# 任何级位都不应因"随性一手"而放弃，保证最弱级位也遵守吃子与死活的基本功。
CRITICAL_MOVE_SCORE = 45.0


@dataclass(frozen=True)
class ScoreWeights:
    """启发式各评分维度的乘数权重；全 1.0 时等价于任务 3 的基础评分。"""

    capture: float = 1.0      # 提子
    liberty: float = 1.0      # 己方气数 / 避免自损
    atari: float = 1.0        # 叫吃对方
    rescue: float = 1.0       # 救援己方危险棋块
    proximity: float = 1.0    # 靠近上一手（接触战）
    position: float = 1.0     # 占角/边/线的位置价值（围空意识）
    connection: float = 1.0   # 联络与接触


def generate_candidates(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> list[tuple[int, int, go_rules.MoveResult]]:
    """遍历全部空点做完整规则模拟，返回所有合法候选 (row, col, MoveResult)。

    候选生成基于 legal_moves 语义（全盘扫描），不会遗漏合法点；
    每个候选自带落子后的新棋盘与提子数，供评分复用，避免重复模拟。
    """
    candidates: list[tuple[int, int, go_rules.MoveResult]] = []
    for row in range(size):
        for col in range(size):
            if board[row][col] != EMPTY:
                continue
            result = go_rules.simulate_move(board, size, row, col, player, previous_board)
            if result.ok:
                candidates.append((row, col, result))
    return candidates


def _line_of(row: int, col: int, size: int) -> int:
    """到最近边的"线数"：0=一线，1=二线，2=三线，以此类推。"""
    return min(row, col, size - 1 - row, size - 1 - col)


_LINE_SCORES = {0: -20.0, 1: -8.0, 2: 15.0, 3: 12.0}


def _evaluate(
    board: list[list[int]],
    result: go_rules.MoveResult,
    size: int,
    row: int,
    col: int,
    player: int,
    last_move: tuple[int, int] | None,
    weights: ScoreWeights | None = None,
    tactical: bool = False,
) -> tuple[float, str]:
    """对单个合法候选打分，返回 (分数, 简要理由标签)。

    weights 为 None 时退化为任务 3 的基础评分（全 1.0）；
    tactical 为 True 时（1 级）附加基础死活/联络加强读奖励。
    """
    if weights is None:
        weights = ScoreWeights()
    opponent = WHITE if player == BLACK else BLACK
    new_board = result.board
    score = 0.0
    tag = "占据要点"

    # 1. 提子：压倒性优先。
    if result.captured > 0:
        score += 120.0 * result.captured * weights.capture
        tag = f"提取{result.captured}子"

    # 2. 己方落子块的气数：1 气 = 自陷/送吃风险，2 气 = 略亏，气多则厚。
    own_stones, own_liberties = go_rules.get_group(new_board, size, row, col)
    own_liberty_count = len(own_liberties)
    if own_liberty_count == 1:
        score -= 90.0 * weights.liberty
        if tag == "占据要点":
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
        if len(liberties) == 1 and result.captured == 0:
            score += 45.0 * weights.atari
            if tag == "占据要点":
                tag = "紧气叫吃"

    # 4. 救援己方危险棋块：相邻己方块气 <= 2，落子后整体气数增长。
    for n_row, n_col in go_rules.neighbors(row, col, size):
        if board[n_row][n_col] != player:
            continue
        _, old_liberties = go_rules.get_group(board, size, n_row, n_col)
        if len(old_liberties) <= 2 and own_liberty_count > len(old_liberties):
            score += 50.0 * weights.rescue
            if tag == "占据要点":
                tag = "救援己方"
            break

    # 5. 靠近上一手：接触战与就近应手。
    if last_move is not None:
        distance = abs(row - last_move[0]) + abs(col - last_move[1])
        score += max(0.0, 10.0 - distance * 1.8) * weights.proximity

    # 6. 位置价值：一线亏损、三线四线好、中腹略有价值。
    line = _line_of(row, col, size)
    score += _LINE_SCORES.get(line, 5.0) * weights.position

    # 7. 联络（邻点己方子）与接触战（邻点对方子）。
    same_count = 0
    contact_count = 0
    for n_row, n_col in go_rules.neighbors(row, col, size):
        value = board[n_row][n_col]
        if value == player:
            same_count += 1
        elif value == opponent:
            contact_count += 1
    score += (same_count * 7.0 + contact_count * 4.0) * weights.connection

    # 8. 基础死活/联络加强读（1 级专用）：更看重提子后的余味、
    #    落子后气数充足以及把多个己方棋块连成一体。
    if tactical:
        if result.captured > 0:
            score += 10.0
        if own_liberty_count >= 3:
            score += 8.0
        if same_count >= 2:
            score += 8.0

    return score, tag


def rank_candidates(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    *,
    profile=None,
    candidates: list[tuple[int, int, go_rules.MoveResult]] | None = None,
) -> list[tuple[float, int, int, str]]:
    """按干净评分（无随机噪声）降序排列候选，返回 [(score, row, col, tag)]。

    供模型提示词的 Top-K 候选列表与级位测试使用；同分按 (row, col) 稳定排序。
    profile 为 None 时使用基础权重（任务 3 行为）。
    """
    if candidates is None:
        candidates = generate_candidates(board, size, player, previous_board)
    weights = profile.weights if profile is not None else None
    tactical = bool(getattr(profile, "tactical_bonus", False))
    scored: list[tuple[float, int, int, str]] = []
    for row, col, result in candidates:
        score, tag = _evaluate(board, result, size, row, col, player, last_move, weights, tactical)
        scored.append((score, row, col, tag))
    scored.sort(key=lambda item: (-item[0], item[1], item[2]))
    return scored


def choose_move(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    rng: random.Random | None = None,
    *,
    profile=None,
    candidates: list[tuple[int, int, go_rules.MoveResult]] | None = None,
) -> tuple[int, int, str] | None:
    """选择一手棋，返回 (row, col, reason)；无合法点时返回 None。

    不传 profile 时与任务 3 完全一致：噪声 3 分仅用于打破平局。
    传入级位档案（LevelProfile）后：
    - 噪声幅度随级位变化（级位数字越大噪声越大，选择越不稳定）；
    - 非关键局面（干净最优分 < CRITICAL_MOVE_SCORE，即无提子/叫吃/救棋要点）
      时按 weak_choice_rate 概率放弃最优解，从其余合法候选中随机取一手
      "随性一手"（10 级约 40%）；关键手段任何级位都不放弃；
    - 测试可注入固定种子的 rng 以获得可重复结果。
    """
    if rng is None:
        rng = random.Random()
    ranked = rank_candidates(
        board, size, player, previous_board, last_move,
        profile=profile, candidates=candidates,
    )
    if not ranked:
        return None

    noise = 3.0 if profile is None else profile.noise_amplitude
    noisy = [
        (score + rng.random() * noise, row, col, tag)
        for score, row, col, tag in ranked
    ]
    noisy.sort(key=lambda item: (-item[0], item[1], item[2]))
    best_score, best_row, best_col, best_tag = noisy[0]

    # 弱级位"随性一手"：仅非关键局面触发，选点仍然合法。
    if (
        profile is not None
        and len(noisy) > 1
        and ranked[0][0] < CRITICAL_MOVE_SCORE
        and rng.random() < profile.weak_choice_rate
    ):
        pool = noisy[1:]
        index = min(int(rng.random() * len(pool)), len(pool) - 1)
        _, row, col, tag = pool[index]
        return row, col, f"{tag}（{profile.label}随性一手）"

    return best_row, best_col, best_tag


def first_legal_or_pass(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> tuple[int, int, str] | None:
    """兜底策略：按行列顺序返回第一个合法点；无合法点返回 None。

    仅在启发式主路径出现意外异常时由引擎调用，保证接口永不因引擎缺陷而 500。
    """
    for row in range(size):
        for col in range(size):
            if board[row][col] != EMPTY:
                continue
            if go_rules.simulate_move(board, size, row, col, player, previous_board).ok:
                return row, col, "稳健应手"
    return None
