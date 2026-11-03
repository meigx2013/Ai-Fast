"""/api/ai-move 接口测试：契约结构、规则守护、重复请求无状态污染与输入校验。"""

import copy
import unittest

from backend import go_rules as gr
from backend.tests.test_health import build_client


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


def make_request(board, size=9, level=10, move_number=1, last_move=None, previous_board=None, passes=0):
    return {
        "board": board,
        "size": size,
        "level": level,
        "moveNumber": move_number,
        "lastMove": last_move,
        "previousBoard": previous_board,
        "consecutivePasses": passes,
    }


class ApiContractTests(unittest.TestCase):
    def setUp(self):
        self.client = build_client(self)

    def test_normal_move_response_contract(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        response = self.client.post("/api/ai-move", json=make_request(board, last_move={"row": 4, "col": 4}))
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(set(data.keys()), {"move", "reason", "elapsedMs", "engine"})
        self.assertEqual(data["engine"], "heuristic")
        self.assertIsInstance(data["reason"], str)
        self.assertTrue(data["reason"], "reason 不应为空")
        self.assertIsInstance(data["elapsedMs"], int)
        self.assertGreaterEqual(data["elapsedMs"], 0)
        # 开局附近必有大量合法点，AI 应返回 dict 落点而不是 pass。
        self.assertIsInstance(data["move"], dict)
        self.assertEqual(set(data["move"].keys()), {"row", "col"})
        # 返回点必须通过服务端规则校验。
        move = data["move"]
        self.assertTrue(gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok)

    def test_repeated_request_no_state_pollution(self):
        # 同一提子局面重复请求：结果必须合法且每次都选择提子点；请求体不因服务端而变化。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        payload = make_request(board, move_number=7, last_move={"row": 4, "col": 5})
        snapshot = copy.deepcopy(payload)
        for _ in range(3):
            response = self.client.post("/api/ai-move", json=payload)
            self.assertEqual(response.status_code, 200)
            move = response.json()["move"]
            self.assertEqual((move["row"], move["col"]), (4, 3))
        self.assertEqual(payload, snapshot, "服务端不得修改请求体内容")

    def test_last_move_all_three_forms_accepted(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        for last_move in ({"row": 4, "col": 4}, "pass", None):
            payload = make_request(board, last_move=last_move)
            response = self.client.post("/api/ai-move", json=payload)
            self.assertEqual(response.status_code, 200, f"lastMove={last_move!r} 应被接受")

    def test_all_levels_return_legal_moves(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        for level in range(1, 11):
            payload = make_request(board, level=level, last_move={"row": 4, "col": 4})
            response = self.client.post("/api/ai-move", json=payload)
            self.assertEqual(response.status_code, 200)
            move = response.json()["move"]
            if isinstance(move, dict):
                self.assertTrue(
                    gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok,
                    f"level={level} 返回了非法落点",
                )

    def test_all_board_sizes_return_legal_moves(self):
        for size in (9, 13, 19):
            board = empty_board(size)
            place(board, [(size // 2, size // 2)], gr.BLACK)
            payload = make_request(
                board, size=size, last_move={"row": size // 2, "col": size // 2}
            )
            response = self.client.post("/api/ai-move", json=payload)
            self.assertEqual(response.status_code, 200, f"size={size}")
            move = response.json()["move"]
            self.assertIsInstance(move, dict, f"size={size} 空盘附近必有点可选")
            self.assertTrue(gr.simulate_move(board, size, move["row"], move["col"], gr.WHITE).ok)

    def test_pass_context_still_plays(self):
        # 玩家刚虚手（lastMove="pass", consecutivePasses=1）时 AI 正常应手。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(5, 5)], gr.WHITE)
        payload = make_request(board, move_number=2, last_move="pass", passes=1)
        response = self.client.post("/api/ai-move", json=payload)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["engine"], "heuristic")


class RulesGuardThroughApiTests(unittest.TestCase):
    """AI 结果必须遵守规则：提子、避劫、无合法点虚手。"""

    def setUp(self):
        self.client = build_client(self)

    def test_ai_takes_capture(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        response = self.client.post(
            "/api/ai-move",
            json=make_request(board, move_number=7, last_move={"row": 4, "col": 5}),
        )
        move = response.json()["move"]
        self.assertEqual((move["row"], move["col"]), (4, 3))

    def test_ai_avoids_simple_ko(self):
        before = empty_board()
        place(before, [(2, 1), (1, 2), (3, 2)], gr.BLACK)
        place(before, [(2, 2), (1, 3), (3, 3), (2, 4)], gr.WHITE)
        after = empty_board()
        place(after, [(2, 1), (1, 2), (3, 2), (2, 3)], gr.BLACK)
        place(after, [(1, 3), (3, 3), (2, 4)], gr.WHITE)
        response = self.client.post(
            "/api/ai-move",
            json=make_request(
                after, move_number=9, last_move={"row": 2, "col": 3}, previous_board=before
            ),
        )
        move = response.json()["move"]
        if isinstance(move, dict):
            self.assertNotEqual((move["row"], move["col"]), (2, 2), "AI 不得立即回提劫")

    def test_full_board_returns_pass(self):
        board = [[gr.BLACK] * 9 for _ in range(9)]
        response = self.client.post(
            "/api/ai-move",
            json=make_request(board, move_number=81, last_move={"row": 8, "col": 8}),
        )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["move"], "pass")
        self.assertEqual(data["engine"], "heuristic")


class RequestValidationTests(unittest.TestCase):
    """非法请求体必须返回 422，错误信息友好且不含堆栈。"""

    def setUp(self):
        self.client = build_client(self)

    def _assert_422(self, payload):
        response = self.client.post("/api/ai-move", json=payload)
        self.assertEqual(response.status_code, 422)
        self.assertNotIn("Traceback", response.text)

    def test_invalid_size(self):
        board = empty_board(8)
        self._assert_422(make_request(board, size=8))

    def test_level_out_of_range(self):
        board = empty_board()
        for level in (0, 11, -1):
            self._assert_422(make_request(board, level=level))

    def test_board_dimension_mismatch(self):
        board = [[0] * 9 for _ in range(8)]  # 行数不是 9
        self._assert_422(make_request(board))
        board = [[0] * 8 for _ in range(9)]  # 列长不是 9
        self._assert_422(make_request(board))

    def test_board_invalid_value(self):
        board = empty_board()
        board[0][0] = 3
        self._assert_422(make_request(board))
        board[0][0] = "1"  # 字符串棋子值
        self._assert_422(make_request(board))

    def test_previous_board_dimension_mismatch(self):
        board = empty_board()
        previous = [[0] * 9 for _ in range(8)]
        self._assert_422(make_request(board, previous_board=previous))

    def test_last_move_out_of_bounds(self):
        board = empty_board()
        self._assert_422(make_request(board, last_move={"row": 9, "col": 0}))
        self._assert_422(make_request(board, last_move={"row": 0, "col": -1}))

    def test_last_move_invalid_type(self):
        board = empty_board()
        self._assert_422(make_request(board, last_move="xyz"))
        self._assert_422(make_request(board, last_move=[1, 2]))

    def test_negative_counters(self):
        board = empty_board()
        self._assert_422(make_request(board, move_number=-1))
        self._assert_422(make_request(board, passes=-1))
        self._assert_422(make_request(board, passes=3))

    def test_missing_required_fields(self):
        self._assert_422({"size": 9, "level": 10})  # 缺 board
        self._assert_422({"board": empty_board(), "level": 10})  # 缺 size


if __name__ == "__main__":
    unittest.main()
