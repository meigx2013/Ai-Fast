"""征子与手筋测试（任务 4）：征子双向判断、级位读步数、四类手筋。

- 可征：逃跑线上无接应子 → 5 级判断成立并实际执行征子序列（多轮追杀
  直至提净）；
- 不可征：中途有对方接应子 → 4 级不发动征子（梯子断，读清不追）；
- 长征子（5 步）：5 级读得清（成立），6 级（读 3 步）读不清（不成立）；
- 双打吃：6 级固定种子必选双打吃点；
- 扑（倒扑）：5 级命中扑点（送吃一子换提多子）；
- 关门吃 / 接不归：单元能力验证。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, levels
from backend.ai.analyzer import ladder, tesuji
from backend.ai.analyzer.base import GameContext, generate_candidates
from backend.ai.engine import generate_engine_move


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


def fresh(board):
    return [row[:] for row in board]


def make_ctx(board, player, move_number=0):
    return GameContext(
        board=board, size=9, player=player,
        move_number=move_number,
        candidates=generate_candidates(board, 9, player),
    )


# ---------------------------------------------------------------------------
# 征子盘面构造
# ---------------------------------------------------------------------------

def working_ladder_board():
    """可征（左上角向角部追杀，3 轮推演提净）。

    黑 (1,1)(1,2) 为上壁，(2,3) 为右侧壁；白 (2,2) 两口气 (2,1)(3,2)。
    黑叫吃候选 (3,2)：白逃 (2,1) 后仅 2 气，黑沿梯子侧逐手叫吃，
    至 (1,0) 逃点仅 1 气，黑 (0,0) 提净 4 子。
    """
    board = empty_board()
    place(board, [(1, 1), (1, 2), (2, 3)], gr.BLACK)
    place(board, [(2, 2)], gr.WHITE)
    return board


def broken_ladder_board():
    """不可征：白接应子 (3,1) 站在逃跑线上（撞气逃出）。"""
    board = working_ladder_board()
    place(board, [(3, 1)], gr.WHITE)
    return board


def long_ladder_board():
    """长征子（5 轮推演）：黑沿第 4 行预置上壁，白 (5,5) 向左逃。

    黑 (4,5) 上、(5,6) 右、(4,4)~(4,0) 上壁；叫吃候选 (6,5)。
    白逐手向左逃 (5,4)(5,3)(5,2)(5,1)(5,0)，黑沿第 6 行追杀，
    至左边缘提净。5 级（读 5 步）成立；6 级（读 3 步）读不清。
    """
    board = empty_board()
    place(board, [(4, 5), (5, 6), (4, 4), (4, 3), (4, 2), (4, 1), (4, 0)], gr.BLACK)
    place(board, [(5, 5)], gr.WHITE)
    return board


def atari_candidate_board(board):
    """返回叫吃候选 (3,2)/(6,5) 落子后的盘面（read_ladder 的起点）。"""
    result = gr.simulate_move(board, 9, 3, 2, gr.BLACK)
    return result.board


# ---------------------------------------------------------------------------
# 征子判断单元测试
# ---------------------------------------------------------------------------

class LadderReadingTests(unittest.TestCase):
    def test_working_ladder_succeeds(self):
        board = atari_candidate_board(working_ladder_board())
        works, chase = ladder.read_ladder(board, 9, (2, 2), gr.BLACK, 5)
        self.assertTrue(works, "无接应子的征子应成立")
        self.assertGreaterEqual(len(chase), 2, "追杀序列应至少含两轮叫吃/提净")
        # 按序列回放（对方始终最佳逃跑），最终白块被提净。
        current, root, captured = board, (2, 2), False
        for chase_move in chase:
            stones, libs = gr.get_group(current, 9, *root)
            if stones and len(libs) == 1:
                escape_point = next(iter(libs))
                escape = gr.simulate_move(current, 9, *escape_point, gr.WHITE)
                if escape.ok:
                    current = escape.board
                    root = escape_point
            result = gr.simulate_move(current, 9, *chase_move, gr.BLACK)
            if result.ok:
                if result.captured > 0:
                    captured = True
                current = result.board
        self.assertTrue(captured, "按追杀序列回放应最终提净白块")

    def test_broken_ladder_fails(self):
        board = atari_candidate_board(broken_ladder_board())
        works, _chase = ladder.read_ladder(board, 9, (2, 2), gr.BLACK, 6)
        self.assertFalse(works, "逃跑线上有接应子时征子不成立")

    def test_long_ladder_needs_five_steps(self):
        board = fresh(long_ladder_board())
        result = gr.simulate_move(board, 9, 6, 5, gr.BLACK)
        self.assertTrue(result.ok)
        works5, _chase5 = ladder.read_ladder(result.board, 9, (5, 5), gr.BLACK, 5)
        works3, _chase3 = ladder.read_ladder(result.board, 9, (5, 5), gr.BLACK, 3)
        self.assertTrue(works5, "5 步读得清：长征子成立")
        self.assertFalse(works3, "3 步读不清：长征子视为不成立")

    def test_ladder_analyze_level_gating(self):
        # 5 级（读 5 步）对长征子给出"征子成立"候选；6 级（读 3 步）不给。
        board = long_ladder_board()
        ctx = make_ctx(board, gr.BLACK)
        candidates5 = ladder.analyze(ctx, levels.get_level_profile(5))
        candidates6 = ladder.analyze(ctx, levels.get_level_profile(6))
        self.assertTrue(any(cand.tag == "征子成立" for cand in candidates5))
        self.assertFalse(any(cand.tag == "征子成立" for cand in candidates6))

    def test_low_levels_have_no_ladder_module(self):
        for level in (7, 8, 9, 10):
            self.assertNotIn("ladder", levels.get_level_profile(level).modules)
        for level in (4, 5, 6):
            self.assertIn("ladder", levels.get_level_profile(level).modules)


class LadderEngineTests(unittest.TestCase):
    def test_level5_executes_ladder_sequence(self):
        # 5 级（黑方为引擎）实际执行征子：逐轮"引擎追杀 → 白最佳逃跑"，
        # 引擎每手都紧气（叫吃或提净），若干轮内白块被全部提净。
        board = empty_board()
        place(board, [(1, 1), (1, 2), (2, 3)], gr.BLACK)
        place(board, [(2, 2)], gr.WHITE)
        victim_root = (2, 2)
        previous = None
        rng = random.Random(7)

        for round_index in range(8):
            move, reason = generate_engine_move(
                fresh(board), 9, gr.BLACK, 5,
                previous_board=previous, last_move=None,
                move_number=round_index, rng=rng,
            )
            self.assertIsNotNone(move, f"第{round_index}轮引擎不应虚手（{reason}）")
            row, col = move
            result = gr.simulate_move(board, 9, row, col, gr.BLACK, previous)
            self.assertTrue(result.ok, f"第{round_index}轮落子非法 {move}")
            if result.captured > 0:
                # 提净出现：征子执行完毕（白块被吃光）。
                white_stones = sum(r.count(gr.WHITE) for r in result.board)
                self.assertEqual(
                    white_stones, 0, "征子提净后棋盘上不应再有多余白子残留判断",
                )
                return
            # 引擎必须持续紧气：落子后白块处于叫吃（仅 1 气）。
            stones, libs = gr.get_group(result.board, 9, *victim_root)
            self.assertTrue(
                stones and len(libs) == 1,
                f"第{round_index}轮引擎未紧气（白块 {len(libs)} 气）",
            )
            board = result.board
            previous = fresh(board)
            # 白方最佳逃跑：下在唯一气点（若自杀则无路可逃，下轮必被提）。
            escape_point = next(iter(libs))
            escape = gr.simulate_move(board, 9, *escape_point, gr.WHITE, None)
            if escape.ok:
                board = escape.board
                victim_root = escape_point
                previous = None
        self.fail("8 轮内征子未执行完毕（引擎未追杀到提净）")

    def test_level4_does_not_start_broken_ladder(self):
        # 不可征局面：4 级读得清（梯子断）——不给"征子成立"候选，
        # 决策 reason 不出现"征子"（不会一头扎进注定失败的追杀）。
        board = broken_ladder_board()
        ctx = make_ctx(board, gr.BLACK)
        candidates = ladder.analyze(ctx, levels.get_level_profile(4))
        self.assertFalse(any(cand.tag == "征子成立" for cand in candidates))
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.BLACK, rng=random.Random(seed),
                profile=levels.get_level_profile(4),
            )
            self.assertNotIn("征子", choice[2])
            self.assertTrue(gr.simulate_move(board, 9, choice[0], choice[1], gr.BLACK).ok)


# ---------------------------------------------------------------------------
# 手筋测试
# ---------------------------------------------------------------------------

def double_atari_board():
    """双打吃：白 (4,5) 一子双叫吃黑 (4,4) 与 (4,6)。"""
    board = empty_board()
    place(board, [(4, 4), (4, 6)], gr.BLACK)
    place(board, [(3, 4), (4, 3), (3, 6), (4, 7)], gr.WHITE)
    return board


def snapback_board():
    """扑（倒扑）：白 (4,4) 送吃，黑提后白回提 6 子。

    黑内环：{(3,4),(3,5)}、{(4,3)}、{(4,6)}、{(5,4),(5,5)}；
    眼位 P=(4,4)、L=(4,5)；白外壁 (2,4)(2,5)(3,3)(3,6)(5,3)(5,6)(6,4)(6,5)(4,7)。
    白扑 P（自撞 1 气）→ 黑 L 提 P → 黑合并大块仅剩 P 一气 → 白 P 回提 6 子。
    """
    board = empty_board()
    place(board, [
        (3, 4), (3, 5), (4, 3), (4, 6), (5, 4), (5, 5),
    ], gr.BLACK)
    place(board, [
        (2, 4), (2, 5), (3, 3), (3, 6),
        (5, 3), (5, 6), (6, 4), (6, 5), (4, 7),
    ], gr.WHITE)
    return board


def geta_board():
    """关门吃：黑 (4,4) 两气 (4,3)(4,5)；白收 (4,5) 后剩气 (4,3) 被封死。"""
    board = empty_board()
    place(board, [(4, 4)], gr.BLACK)
    place(board, [(3, 4), (5, 4), (3, 3), (5, 3), (4, 2)], gr.WHITE)
    return board


def connect_die_board():
    """接不归：黑 (4,4)(5,4) 两气 (4,5)(5,5)；白收 (4,5) 后黑逃 (5,5) 仍 1 气。"""
    board = empty_board()
    place(board, [(4, 4), (5, 4)], gr.BLACK)
    place(board, [(3, 4), (4, 3), (5, 3), (6, 4), (6, 5)], gr.WHITE)
    return board


class TesujiUnitTests(unittest.TestCase):
    def test_double_atari_point_detected(self):
        board = double_atari_board()
        ctx = make_ctx(board, gr.WHITE)
        points = tesuji.double_atari_points(ctx)
        self.assertIn((4, 5, 2), points)

    def test_geta_point_detected(self):
        board = geta_board()
        ctx = make_ctx(board, gr.WHITE)
        self.assertIn((4, 5), tesuji.geta_points(ctx))
        self.assertNotIn((4, 3), tesuji.geta_points(ctx))

    def test_snapback_point_detected(self):
        board = snapback_board()
        ctx = make_ctx(board, gr.WHITE)
        self.assertIn((4, 4), tesuji.snapback_points(ctx))

    def test_snapback_mechanic_nets_multiple_stones(self):
        # 完整推演：白扑 → 黑提 → 白回提 6 子（倒扑净得验证）。
        board = snapback_board()
        snap = gr.simulate_move(board, 9, 4, 4, gr.WHITE)
        self.assertTrue(snap.ok)
        self.assertEqual(snap.captured, 0, "扑本身不提子（送吃）")
        _, own_libs = gr.get_group(snap.board, 9, 4, 4)
        self.assertEqual(len(own_libs), 1, "扑后自身仅 1 气")
        black_reply = gr.simulate_move(snap.board, 9, 4, 5, gr.BLACK)
        self.assertTrue(black_reply.ok)
        self.assertEqual(black_reply.captured, 1, "黑提掉白扑子")
        recapture = gr.simulate_move(black_reply.board, 9, 4, 4, gr.WHITE)
        self.assertTrue(recapture.ok)
        self.assertGreaterEqual(recapture.captured, 2, "回提应净得多子")

    def test_connect_die_point_detected(self):
        board = connect_die_board()
        ctx = make_ctx(board, gr.WHITE)
        points = tesuji.connect_die_points(ctx)
        self.assertIn((4, 5), points)
        self.assertNotIn((5, 5), points, "黑逃 (5,5) 后有 2 气，非接不归方向")

    def tesuji_level_gating(self):
        # 6 级仅双打吃/关门吃；5 级起扑/接不归（此断言由行为测试覆盖）。
        profile6 = levels.get_level_profile(6)
        self.assertIn("tesuji", profile6.modules)


class TesujiEngineTests(unittest.TestCase):
    def test_level6_always_takes_double_atari(self):
        # 双打吃必得：6 级固定种子 100% 选双打吃点 (4,5)。
        board = double_atari_board()
        profile = levels.get_level_profile(6)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, rng=random.Random(seed),
                profile=profile,
            )
            self.assertEqual((choice[0], choice[1]), (4, 5), f"种子{seed}应选双打吃点")
            result = gr.simulate_move(board, 9, 4, 5, gr.WHITE)
            self.assertTrue(result.ok)

    def test_level5_hits_snapback_point(self):
        # 5 级命中扑点 (4,4)：送吃换倒扑（分数须压过直接提吃单子的 (4,5)）。
        board = snapback_board()
        profile = levels.get_level_profile(5)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, rng=random.Random(seed),
                profile=profile,
            )
            self.assertEqual((choice[0], choice[1]), (4, 4), f"种子{seed}应命中扑点")

    def tesuji_not_available_for_low_levels(self):
        for level in (7, 8, 9, 10):
            self.assertNotIn("tesuji", levels.get_level_profile(level).modules)


if __name__ == "__main__":
    unittest.main()
