"""go_rules 规则内核测试：与前端 index.html 规则语义一一对应。"""

import unittest

from backend import go_rules as gr


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


class NeighborTests(unittest.TestCase):
    def test_corner_has_two_neighbors(self):
        self.assertEqual(gr.neighbors(0, 0, 9), [(1, 0), (0, 1)])

    def test_edge_has_three_neighbors(self):
        self.assertEqual(gr.neighbors(0, 4, 9), [(1, 4), (0, 3), (0, 5)])

    def test_center_has_four_neighbors(self):
        self.assertEqual(gr.neighbors(4, 4, 9), [(3, 4), (5, 4), (4, 3), (4, 5)])


class GroupTests(unittest.TestCase):
    def test_single_stone_liberties(self):
        board = empty_board()
        stones, liberties = gr.get_group(board, 9, 4, 4)
        self.assertEqual(stones, {(4, 4)})
        self.assertEqual(len(liberties), 4)

    def test_connected_group_shared_liberties(self):
        board = empty_board()
        place(board, [(4, 4), (4, 5)], gr.BLACK)
        stones, liberties = gr.get_group(board, 9, 4, 4)
        self.assertEqual(stones, {(4, 4), (4, 5)})
        self.assertEqual(len(liberties), 6)

    def test_count_liberties(self):
        board = empty_board()
        place(board, [(0, 0)], gr.BLACK)
        self.assertEqual(gr.count_liberties(board, 9, 0, 0), 2)


class SimulateMoveTests(unittest.TestCase):
    def test_normal_move_ok_and_original_board_untouched(self):
        board = empty_board()
        result = gr.simulate_move(board, 9, 2, 2, gr.BLACK)
        self.assertTrue(result.ok)
        self.assertEqual(result.board[2][2], gr.BLACK)
        # 输入棋盘不被修改。
        self.assertEqual(board[2][2], gr.EMPTY)
        self.assertTrue(all(cell == gr.EMPTY for row in board for cell in row))

    def test_occupied_rejected(self):
        board = empty_board()
        board[2][2] = gr.BLACK
        result = gr.simulate_move(board, 9, 2, 2, gr.WHITE)
        self.assertFalse(result.ok)
        self.assertEqual(result.reason, "occupied")

    def test_outside_rejected(self):
        board = empty_board()
        for row, col in [(-1, 0), (0, -1), (9, 0), (0, 9)]:
            result = gr.simulate_move(board, 9, row, col, gr.BLACK)
            self.assertFalse(result.ok)
            self.assertEqual(result.reason, "outside")

    def test_non_integer_coordinates_rejected(self):
        board = empty_board()
        for row, col in [("2", 2), (2.5, 2), (None, 2), (True, 2)]:
            result = gr.simulate_move(board, 9, row, col, gr.BLACK)
            self.assertFalse(result.ok, f"{row!r},{col!r} 应被判为非法")
            self.assertEqual(result.reason, "outside")

    def test_capture_single_stone(self):
        # 白 (2,2) 仅剩 (2,3) 一口气，黑下 (2,3) 提子。
        board = empty_board()
        place(board, [(2, 2)], gr.WHITE)
        place(board, [(1, 2), (3, 2), (2, 1)], gr.BLACK)
        result = gr.simulate_move(board, 9, 2, 3, gr.BLACK)
        self.assertTrue(result.ok)
        self.assertEqual(result.captured, 1)
        self.assertEqual(result.board[2][2], gr.EMPTY)
        self.assertEqual(result.board[2][3], gr.BLACK)

    def test_capture_multiple_groups_at_once(self):
        # 黑 (4,4) 同时打吃两块白棋：白 (3,4) 与 (5,4) 各只剩 (4,4) 一口气。
        board = empty_board()
        place(board, [(3, 4)], gr.WHITE)
        place(board, [(3, 3), (2, 4), (3, 5)], gr.BLACK)
        place(board, [(5, 4)], gr.WHITE)
        place(board, [(5, 3), (6, 4), (5, 5)], gr.BLACK)
        result = gr.simulate_move(board, 9, 4, 4, gr.BLACK)
        self.assertTrue(result.ok)
        self.assertEqual(result.captured, 2)
        self.assertEqual(result.board[3][4], gr.EMPTY)
        self.assertEqual(result.board[5][4], gr.EMPTY)

    def test_suicide_rejected(self):
        # 黑下 (0,0) 后自身无气，且白棋仍有气 → 自杀。
        board = empty_board()
        place(board, [(0, 1), (1, 0)], gr.WHITE)
        result = gr.simulate_move(board, 9, 0, 0, gr.BLACK)
        self.assertFalse(result.ok)
        self.assertEqual(result.reason, "suicide")
        self.assertIsNone(result.board)

    def test_suicide_that_captures_is_legal(self):
        # 黑 (0,1) 只剩 (0,0) 一口气；白下 (0,0) 提黑后自身有气 → 合法提子而非自杀。
        board = empty_board()
        place(board, [(0, 1)], gr.BLACK)
        place(board, [(1, 1), (0, 2)], gr.WHITE)
        place(board, [(1, 0)], gr.WHITE)
        result = gr.simulate_move(board, 9, 0, 0, gr.WHITE)
        self.assertTrue(result.ok)
        self.assertEqual(result.captured, 1)


class SimpleKoTests(unittest.TestCase):
    """经典劫争局面：黑提劫后白立即回提被简单劫拦截。"""

    def setUp(self):
        # 黑提劫前：白 (2,2) 只剩 (2,3) 一口气。
        self.before = empty_board()
        place(self.before, [(2, 1), (1, 2), (3, 2)], gr.BLACK)
        place(self.before, [(2, 2), (1, 3), (3, 3), (2, 4)], gr.WHITE)
        # 黑下 (2,3) 提白 (2,2) 后的盘面：黑 (2,3) 只剩 (2,2) 一口气。
        self.after = empty_board()
        place(self.after, [(2, 1), (1, 2), (3, 2), (2, 3)], gr.BLACK)
        place(self.after, [(1, 3), (3, 3), (2, 4)], gr.WHITE)

    def test_immediate_recapture_is_ko(self):
        # 白立即回提 (2,2) → 提黑 (2,3) 后盘面与 previousBoard 完全一致 → 简单劫。
        result = gr.simulate_move(self.after, 9, 2, 2, gr.WHITE, previous_board=self.before)
        self.assertFalse(result.ok)
        self.assertEqual(result.reason, "ko")

    def test_recapture_without_previous_board_is_legal(self):
        # previousBoard 为 None（开局或虚手后）时无劫限制。
        result = gr.simulate_move(self.after, 9, 2, 2, gr.WHITE, previous_board=None)
        self.assertTrue(result.ok)
        self.assertEqual(result.captured, 1)

    def test_other_points_not_affected_by_ko(self):
        result = gr.simulate_move(self.after, 9, 8, 8, gr.WHITE, previous_board=self.before)
        self.assertTrue(result.ok)


class LegalMoveEnumerationTests(unittest.TestCase):
    def test_legal_moves_on_empty_board_covers_all_points(self):
        board = empty_board(9)
        moves = gr.legal_moves(board, 9, gr.WHITE)
        self.assertEqual(len(moves), 81)

    def test_full_board_has_no_legal_move(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        self.assertEqual(gr.legal_moves(board, 9, gr.WHITE), [])
        self.assertFalse(gr.has_legal_move(board, 9, gr.WHITE))

    def test_13_and_19_board_enumeration(self):
        for size in (13, 19):
            board = empty_board(size)
            self.assertEqual(len(gr.legal_moves(board, size, gr.BLACK)), size * size)


if __name__ == "__main__":
    unittest.main()
