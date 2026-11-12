"""分析器共享契约：统一输入上下文与带类型标签的候选评分输出。

每个思维方式模块（analyzer）都遵守同一签名：
    analyze(ctx, profile) -> list[Candidate]
- 输入为 `GameContext`（棋局上下文，含共享合法候选，避免重复规则模拟）；
- 输出为 `Candidate` 列表（落点 + 分数 + 类型标签），标签体现该模块的
  "思维方式"可解释性（如"提取2子""紧气叫吃""占据要点"）。

级位差异由 `profile.modules`（模块开关）与各级位参数承载（见 ai/levels.py v2）。
"""


import random
from dataclasses import dataclass, field

from ... import go_rules


@dataclass(frozen=True)
class Candidate:
    """单个候选点的模块评分：分数 + 类型标签（可解释性来源）。"""

    row: int
    col: int
    score: float
    tag: str


@dataclass
class GameContext:
    """棋局上下文：分析器的统一输入。

    candidates 为全盘合法候选 (row, col, MoveResult)，由决策器统一生成后
    注入，供各模块复用落子模拟结果，避免重复计算。

    rng 为注入随机源（任务 3）：携带时分析器可按级位精度做概率性"数错"
    （对杀气数 ±1），视野过滤按误判率对叫吃告警"视而不见"；缺省（None）
    表示清醒/精确评估——干净评分与测试复现均走该路径。
    """

    board: list[list[int]]
    size: int
    player: int
    previous_board: list[list[int]] | None = None
    last_move: tuple[int, int] | None = None
    move_number: int = 0
    candidates: list[tuple[int, int, go_rules.MoveResult]] = field(default_factory=list)
    rng: random.Random | None = None


def generate_candidates(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> list[tuple[int, int, go_rules.MoveResult]]:
    """遍历全部空点做完整规则模拟，返回所有合法候选 (row, col, MoveResult)。

    候选生成基于 legal_moves 语义（全盘扫描），不会遗漏合法点；
    每个候选自带落子后的新棋盘与提子数，供各分析器复用。
    """
    candidates: list[tuple[int, int, go_rules.MoveResult]] = []
    for row in range(size):
        for col in range(size):
            if board[row][col] != go_rules.EMPTY:
                continue
            result = go_rules.simulate_move(board, size, row, col, player, previous_board)
            if result.ok:
                candidates.append((row, col, result))
    return candidates
