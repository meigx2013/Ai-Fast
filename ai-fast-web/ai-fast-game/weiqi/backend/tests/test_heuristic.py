"""启发式引擎测试：候选完整性、提子优先、合法性与可重复性。"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import heuristic


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


class CandidateGenerationTests(unittest.TestCase):
    def test_candidates_cover_all_legal_points(self):
        board = empty_board(9)
        candidates = heuristic.generate_candidates(board, 9, gr.WHITE)
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
        candidates = heuristic.generate_candidates(after, 9, gr.WHITE, previous_board=before)
        points = {(row, col) for row, col, _ in candidates}
        self.assertNotIn((2, 2), points)
        # 除劫点外的合法点仍然全部保留。
        self.assertGreater(len(points), 70)

    def test_full_board_no_candidates(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertEqual(heuristic.generate_candidates(board, 9, gr.WHITE), [])


class ChooseMoveTests(unittest.TestCase):
    def test_capture_move_preferred(self):
        # 黑 (4,4) 只剩 (4,3) 一口气，白应选择 (4,3) 提子。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        choice = heuristic.choose_move(board, 9, gr.WHITE, rng=random.Random(7))
        self.assertIsNotNone(choice)
        row, col, reason = choice
        self.assertEqual((row, col), (4, 3))
        self.assertIn("提", reason)

    def test_rescue_own_group(self):
        # 白 (4,4) 只剩 (4,3) 一口气，白应选择逃出/提子的方向而不是远离。
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        choice = heuristic.choose_move(board, 9, gr.WHITE, rng=random.Random(7))
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
            choice = heuristic.choose_move(board, 9, gr.WHITE, last_move=(4, 4))
            row, col, _ = choice
            self.assertTrue(gr.simulate_move(board, 9, row, col, gr.WHITE).ok)

    def test_fixed_seed_reproducible(self):
        board = empty_board(9)
        place(board, [(4, 4), (3, 3), (5, 5)], gr.BLACK)
        first = heuristic.choose_move(board, 9, gr.WHITE, rng=random.Random(42))
        second = heuristic.choose_move(board, 9, gr.WHITE, rng=random.Random(42))
        self.assertEqual(first, second)

    def test_no_legal_move_returns_none(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertIsNone(heuristic.choose_move(board, 9, gr.WHITE))

    def test_input_board_not_mutated(self):
        board = empty_board(9)
        place(board, [(4, 4)], gr.BLACK)
        snapshot = [row[:] for row in board]
        heuristic.choose_move(board, 9, gr.WHITE, rng=random.Random(1))
        self.assertEqual(board, snapshot)

    def test_first_legal_or_pass(self):
        board = empty_board(9)
        place(board, [(0, 0)], gr.BLACK)
        fallback = heuristic.first_legal_or_pass(board, 9, gr.WHITE)
        self.assertEqual((fallback[0], fallback[1]), (0, 1))
        full = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertIsNone(heuristic.first_legal_or_pass(full, 9, gr.WHITE))

    def test_sizes_13_and_19_return_legal_moves(self):
        for size in (13, 19):
            board = empty_board(size)
            place(board, [(size // 2, size // 2)], gr.BLACK)
            choice = heuristic.choose_move(
                board, size, gr.WHITE, last_move=(size // 2, size // 2), rng=random.Random(3)
            )
            row, col, _ = choice
            self.assertTrue(gr.simulate_move(board, size, row, col, gr.WHITE).ok)


if __name__ == "__main__":
    unittest.main()
