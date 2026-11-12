"""征子思维分析器（任务 4：按级位限制读步数的征子判断）。

征子（ladder）判断：从叫吃点出发逐手模拟双方逃跑/挡——
1. 对方 2 气块被己方叫吃（收至 1 气）后，对方唯一生路是下在最后一气上
   逃跑；
2. 逃跑后合并块气数：
   - 仅剩 1 气 → 己方下一手直接提净（征子继续有效）；
   - >= 3 气 → 对方逃出（逃跑线上有接应子/撞厚），征子失败；
   - 恰好 2 气 → 己方继续从"梯子"一侧收气叫吃，循环推进；
3. 读步数受 `accuracy.ladder_steps` 限制（6 级 3 步 / 5 级 5 步 / 4 级
   6 步）：步数内推演到"逃不掉"则征子成立，超出步数视为"读不清"不发动。

接应子（ladder breaker）由模拟天然覆盖：逃跑撞上对方子气数增长 >= 3。

对外能力：
- read_ladder(board, size, victim_root, chaser, max_steps)：
  从"victim 已被叫吃（仅剩 1 气）"的盘面出发推演，返回
  (征子成立与否, 己方追杀落点序列)。victim_root 为对方被叫吃块任一子。
- analyze(ctx, profile)：枚举"叫吃对方 2 气块且征子成立"的候选，
  加分并打"征子成立"标签（低位级读不清步数外不加分，可能误征子由
  合法性双保险与后续对杀纠正）。
"""

from ... import go_rules
from ...go_rules import BLACK, WHITE
from .base import Candidate, GameContext

# 征子成立的基础加分：征子意味着连续叫吃直至提净，价值高于普通叫吃，
# 与手筋同量级（capture 模块的叫吃基础分 45 会叠加）。
LADDER_SCORE = 48.0


def read_ladder(
    board: list[list[int]],
    size: int,
    victim_root: tuple[int, int],
    chaser: int,
    max_steps: int,
) -> tuple[bool, list[tuple[int, int]]]:
    """推演征子：victim 块当前仅剩 1 气（已被叫吃），**轮到对方逃跑**。

    每轮推演 = 对方逃跑一手 + 己方追杀一手（叫吃或提净），带回溯：
    - 对方无法逃（逃点自杀）→ 己方直接提净，征子成立；
    - 逃跑后 >= 3 气 → 逃出（接应子/撞厚），此路征子失败；
    - 逃跑后 1 气 → 己方提净，征子成立；
    - 逃跑后 2 气 → 己方有两个叫吃方向（梯子的两侧），逐一尝试并
      递归推演——某一侧最终追到"逃不掉"则征子成立；两侧都失败则失败。

    返回 (征子成立, 己方追杀落点序列)（不含已落下的初始叫吃）。
    max_steps 为级位读步数上限（己方追杀手数计数）；不修改 board。
    """
    runner = WHITE if chaser == BLACK else BLACK

    def search(
        current: list[list[int]], root: tuple[int, int], steps_left: int
    ) -> tuple[bool, list[tuple[int, int]]]:
        if steps_left <= 0:
            return False, []
        stones, liberties = go_rules.get_group(current, size, *root)
        if not stones:
            return True, []  # 块已被提净（征子完成）
        if len(liberties) >= 3:
            return False, []
        if len(liberties) != 1:
            return False, []  # 非叫吃状态（调用约定被破坏）

        escape_point = next(iter(liberties))
        escape = go_rules.simulate_move(
            current, size, escape_point[0], escape_point[1], runner
        )
        if not escape.ok:
            # 逃点自杀：对方接不上，己方直接提净。
            capture = go_rules.simulate_move(
                current, size, escape_point[0], escape_point[1], chaser
            )
            if capture.ok and capture.captured > 0:
                return True, [escape_point]
            return False, []

        _stones_after, libs_after = go_rules.get_group(
            escape.board, size, *escape_point
        )
        if len(libs_after) == 0:
            return True, []
        if len(libs_after) >= 3:
            return False, []
        if len(libs_after) == 1:
            # 逃跑后仍 1 气：己方下一手提净。
            capture_point = next(iter(libs_after))
            capture = go_rules.simulate_move(
                escape.board, size, capture_point[0], capture_point[1], chaser
            )
            if capture.ok and capture.captured > 0:
                return True, [capture_point]
            return False, []

        # 逃跑后 2 气：两个叫吃方向逐一试（先试成的一路，带回溯）。
        for liberty in libs_after:
            block = go_rules.simulate_move(
                escape.board, size, liberty[0], liberty[1], chaser
            )
            if not block.ok:
                continue
            _stones_blocked, libs_blocked = go_rules.get_group(
                block.board, size, *escape_point
            )
            if len(libs_blocked) != 1:
                continue  # 该方向收不到叫吃
            works, tail = search(block.board, escape_point, steps_left - 1)
            if works:
                return True, [liberty] + tail
        return False, []

    return search(go_rules.copy_board(board), victim_root, max_steps)


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """征子维度评分：叫吃对方 2 气块且步数内征子成立的候选。"""
    if profile.accuracy.ladder_steps <= 0:
        return []  # 级位不读征子（10~8 级）
    max_steps = profile.accuracy.ladder_steps
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    size = ctx.size

    # 枚举对方 2 气块。
    two_lib_roots: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for row in range(size):
        for col in range(size):
            if ctx.board[row][col] != opponent or (row, col) in seen:
                continue
            stones, liberties = go_rules.get_group(ctx.board, size, row, col)
            seen.update(stones)
            if len(liberties) == 2:
                two_lib_roots.append((row, col))

    if not two_lib_roots:
        return []

    two_lib_groups = {
        root: go_rules.get_group(ctx.board, size, *root)[1] for root in two_lib_roots
    }
    results: list[Candidate] = []
    for row, col, move_result in ctx.candidates:
        if move_result.captured > 0:
            continue  # 直接提子由 capture 覆盖
        # 该候选是否把某个对方 2 气块叫吃到 1 气。
        new_board = move_result.board
        hit_root = None
        for root, liberties in two_lib_groups.items():
            if (row, col) not in liberties:
                continue
            stones_after, libs_after = go_rules.get_group(new_board, size, *root)
            if stones_after and len(libs_after) == 1:
                hit_root = (root, stones_after)
                break
        if hit_root is None:
            continue
        root, stones_after = hit_root
        works, _sequence = read_ladder(
            new_board, size, next(iter(stones_after)), player, max_steps
        )
        if works:
            results.append(Candidate(
                row=row, col=col, score=LADDER_SCORE, tag="征子成立",
            ))
    return results
