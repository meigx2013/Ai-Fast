"""吃子分析器与决策器测试（v2）：候选完整性、提子优先、合法性与可重复性。

断言由 v1 test_heuristic.py 平移：generate_candidates → analyzer.generate_candidates，
choose_move/rank_candidates → decision 同名 API，first_legal_or_pass → engine。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, engine
from backend.ai.analyzer import capture as capture_analyzer
from backend.ai.analyzer.base import GameContext, generate_candidates


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


class CandidateGenerationTests(unittest.TestCase):
    def test_candidates_cover_all_legal_points(self):
        board = empty_board(9)
        candidates = generate_candidates(board, 9, gr.WHITE)
        self.assertEqual(len(candidates), 81)
        for row, col, result in candidates:
            self.assertTrue(result.ok)
            self.assertEqual(result.board[row][col], gr.WHITE)

    def test_candidates_exclude_ko_point(self):
        # 构造劫争：黑刚提劫，白立即回提点 (2,2) 为劫点，不应出现在候选中。
        before = empty_board()
        place(before, [(2, 1), (1, 2), (3, 2)], gr.BLACK)
        place(before, [(2, 2), (1, 3), (3, 3), (2, 4)], gr.WHITE)
        after = empty_board()
        place(after, [(2, 1), (1, 2), (3, 2), (2, 3)], gr.BLACK)
        place(after, [(1, 3), (3, 3), (2, 4)], gr.WHITE)
        candidates = generate_candidates(after, 9, gr.WHITE, previous_board=before)
        points = {(row, col) for row, col, _ in candidates}
        self.assertNotIn((2, 2), points)
        # 除劫点外的合法点仍然全部保留。
        self.assertGreater(len(points), 70)

    def test_full_board_no_candidates(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertEqual(generate_candidates(board, 9, gr.WHITE), [])


class CaptureAnalyzerTests(unittest.TestCase):
    """吃子分析器：提子点枚举、叫吃点计算与带类型标签的评分。"""

    def _ctx(self, board, player=gr.WHITE, last_move=None):
        candidates = generate_candidates(board, 9, player)
        return GameContext(
            board=board, size=9, player=player,
            last_move=last_move, candidates=candidates,
        )

    def test_capture_targets_enumerated(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        targets = capture_analyzer.capture_targets(self._ctx(board))
        self.assertIn((4, 3, 1), targets)

    def test_atari_targets_enumerated(self):
        # 黑 (4,4) 三面被围只剩 (4,3) 一口气：叫吃点即 (4,3)。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        targets = capture_analyzer.atari_targets(self._ctx(board, player=gr.WHITE))
        self.assertIn((4, 3), targets)

    def test_capture_candidate_tagged(self):
        from backend.ai import levels

        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        ctx = self._ctx(board)
        results = capture_analyzer.analyze(ctx, levels.get_level_profile(10))
        by_point = {(c.row, c.col): c for c in results}
        self.assertEqual(by_point[(4, 3)].tag, "提取1子")
        # 提子点分数必须显著高于普通点（关键手段压倒性优先）。
        quiet = next(c for c in results if (c.row, c.col) == (8, 8))
        self.assertGreater(by_point[(4, 3)].score, quiet.score + 100)


class ChooseMoveTests(unittest.TestCase):
    def test_capture_move_preferred(self):
        # 黑 (4,4) 只剩 (4,3) 一口气，白应选择 (4,3) 提子。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        choice = decision.choose_move(board, 9, gr.WHITE, rng=random.Random(7))
        self.assertIsNotNone(choice)
        row, col, reason = choice
        self.assertEqual((row, col), (4, 3))
        self.assertIn("提", reason)

    def test_rescue_own_group(self):
        # 白 (4,4) 只剩 (4,3) 一口气，白应选择逃出/提子的方向而不是远离。
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        choice = decision.choose_move(board, 9, gr.WHITE, rng=random.Random(7))
        self.assertIsNotNone(choice)
        row, col, _ = choice
        result = gr.simulate_move(board, 9, row, col, gr.WHITE)
        self.assertTrue(result.ok)
        # 白 (4,4) 危险块在应手后气数应增加或直接提掉攻击者。
        new_liberties = gr.count_liberties(result.board, 9, 4, 4) if result.board[4][4] == gr.WHITE else 99
        self.assertGreaterEqual(new_liberties, 2)

    def test_result_always_legal(self):
        board = empty_board(9)
        place(board, [(4, 4)], gr.BLACK)
        for _ in range(5):
            choice = decision.choose_move(board, 9, gr.WHITE, last_move=(4, 4))
            row, col, _ = choice
            self.assertTrue(gr.simulate_move(board, 9, row, col, gr.WHITE).ok)

    def test_fixed_seed_reproducible(self):
        board = empty_board(9)
        place(board, [(4, 4), (3, 3), (5, 5)], gr.BLACK)
        first = decision.choose_move(board, 9, gr.WHITE, rng=random.Random(42))
        second = decision.choose_move(board, 9, gr.WHITE, rng=random.Random(42))
        self.assertEqual(first, second)

    def test_no_legal_move_returns_none(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertIsNone(decision.choose_move(board, 9, gr.WHITE))

    def test_input_board_not_mutated(self):
        board = empty_board(9)
        place(board, [(4, 4)], gr.BLACK)
        snapshot = [row[:] for row in board]
        decision.choose_move(board, 9, gr.WHITE, rng=random.Random(1))
        self.assertEqual(board, snapshot)

    def test_first_legal_or_pass(self):
        board = empty_board(9)
        place(board, [(0, 0)], gr.BLACK)
        fallback = engine.first_legal_or_pass(board, 9, gr.WHITE)
        self.assertEqual((fallback[0], fallback[1]), (0, 1))
        full = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertIsNone(engine.first_legal_or_pass(full, 9, gr.WHITE))

    def test_sizes_13_and_19_return_legal_moves(self):
        for size in (13, 19):
            board = empty_board(size)
            place(board, [(size // 2, size // 2)], gr.BLACK)
            choice = decision.choose_move(
                board, size, gr.WHITE, last_move=(size // 2, size // 2), rng=random.Random(3)
            )
            row, col, _ = choice
            self.assertTrue(gr.simulate_move(board, size, row, col, gr.WHITE).ok)

    def test_engine_parameterized_for_black(self):
        # 引擎黑白参数化（自对弈测试前置）：黑方调用同样返回合法落点。
        board = empty_board(9)
        place(board, [(4, 4)], gr.WHITE)
        move, reason = engine.generate_engine_move(
            board, 9, gr.BLACK, level=5, last_move=(4, 4)
        )
        self.assertIsNotNone(move)
        row, col = move
        self.assertTrue(gr.simulate_move(board, 9, row, col, gr.BLACK).ok)
        self.assertTrue(reason.startswith("[5级]"), f"reason 缺少 [N级] 前缀：{reason!r}")


if __name__ == "__main__":
    unittest.main()
