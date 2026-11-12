"""任务 7 边界加固测试（v2 平移）：总纲契约样例、输入加固、引擎异常兜底与级位强度趋势。

全部使用受控环境与 Mock，不访问网络（本地级位引擎无外部调用）。
"""

import random
import unittest
from unittest import mock

from backend import go_rules as gr
from backend.ai import decision, levels
from backend.tests.test_health import build_client
from backend.tests.test_system_move_api import empty_board, place


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


class SpecContractTests(unittest.TestCase):
    """04_prompt.md 接口契约样例必须原样可被接口接受（前后端契约回归基线）。"""

    def setUp(self):
        self.client = build_client(self)

    def test_spec_example_request_accepted(self):
        payload = {
            "board": [[0] * 9 for _ in range(9)],
            "size": 9,
            "level": 10,
            "moveNumber": 1,
            "lastMove": {"row": 2, "col": 2},
            "previousBoard": [[0] * 9 for _ in range(9)],
            "consecutivePasses": 0,
        }
        payload["board"][2][2] = 1
        response = self.client.post("/api/system-move", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(set(data.keys()), {"move", "reason", "elapsedMs", "engine"})
        self.assertEqual(data["engine"], "kyu-engine")
        if isinstance(data["move"], dict):
            self.assertTrue(
                gr.simulate_move(payload["board"], 9, data["move"]["row"], data["move"]["col"], gr.WHITE).ok
            )
        else:
            self.assertEqual(data["move"], "pass")


class InputHardeningTests(unittest.TestCase):
    """类型与取值加固：任何非法输入必须 422，且响应不泄露堆栈细节。"""

    def setUp(self):
        self.client = build_client(self)

    def _assert_422(self, payload, label):
        response = self.client.post("/api/system-move", json=payload)
        self.assertEqual(response.status_code, 422, f"{label} 应返回 422")
        detail = response.json().get("detail")
        self.assertTrue(detail, f"{label} 错误响应应带用户可读 detail")

    def test_board_string_value_rejected(self):
        board = empty_board()
        board[4][4] = "1"
        self._assert_422(make_request(board), "board 含字符串值")

    def test_board_float_value_rejected(self):
        board = empty_board()
        board[4][4] = 1.0
        self._assert_422(make_request(board), "board 含浮点值")

    def test_board_bool_value_rejected(self):
        board = empty_board()
        board[4][4] = True
        self._assert_422(make_request(board), "board 含布尔值")

    def test_board_ragged_row_rejected(self):
        board = empty_board()
        board[3] = board[3][:-1]  # 行长度不足
        self._assert_422(make_request(board), "board 行长度不一致")

    def test_level_string_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, level="5"), "level 为字符串")

    def test_level_float_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, level=5.5), "level 为浮点")

    def test_move_number_string_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, move_number="3"), "moveNumber 为字符串")

    def test_consecutive_passes_above_two_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, passes=3), "consecutivePasses 超过 2")

    def test_last_move_negative_coordinates_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(
            make_request(board, last_move={"row": -1, "col": 0}), "lastMove 负坐标"
        )

    def test_last_move_float_coordinates_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(
            make_request(board, last_move={"row": 1.5, "col": 2}), "lastMove 浮点坐标"
        )

    def test_previous_board_invalid_value_rejected(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        previous = empty_board()
        previous[4][4] = 7
        self._assert_422(
            make_request(board, previous_board=previous), "previousBoard 值域非法"
        )

    def test_size_not_in_allowed_list_rejected(self):
        board = empty_board(8)
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, size=8), "size=8 不在允许列表")

    def test_board_dimension_mismatch_with_size_rejected(self):
        board = empty_board(9)
        place(board, [(4, 4)], gr.BLACK)
        self._assert_422(make_request(board, size=13), "board 与 size 维度不一致")


class SizeLevelMatrixTests(unittest.TestCase):
    """系统验证 9/13/19 路 × 1～10 级全组合：全部返回合法结果。"""

    def test_all_size_level_combinations_legal(self):
        client = build_client(self)
        for size in (9, 13, 19):
            board = empty_board(size)
            place(board, [(size // 2, size // 2)], gr.BLACK)
            for level in range(1, 11):
                payload = make_request(
                    board, size=size, level=level,
                    last_move={"row": size // 2, "col": size // 2},
                )
                response = client.post("/api/system-move", json=payload)
                self.assertEqual(
                    response.status_code, 200, f"size={size} level={level}"
                )
                move = response.json()["move"]
                if isinstance(move, dict):
                    self.assertTrue(
                        gr.simulate_move(
                            board, size, move["row"], move["col"], gr.WHITE
                        ).ok,
                        f"size={size} level={level} 返回非法落点 {move}",
                    )
                else:
                    self.assertEqual(move, "pass")


class CornerEdgeScenarioTests(unittest.TestCase):
    """边角对杀局面：系统应手必须合法且不违反劫。"""

    def setUp(self):
        self.client = build_client(self)

    def test_corner_capture_taken(self):
        # 角部黑子被白叫吃仅剩一口气：白方收紧 (1,0) 即提子，任何级位都不应放过。
        board = empty_board()
        place(board, [(0, 0)], gr.BLACK)
        place(board, [(0, 1)], gr.WHITE)
        for level in (1, 5, 10):
            payload = make_request(board, level=level, move_number=2, last_move={"row": 0, "col": 1})
            response = self.client.post("/api/system-move", json=payload)
            self.assertEqual(response.status_code, 200)
            move = response.json()["move"]
            self.assertIsInstance(move, dict)
            result = gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE)
            self.assertTrue(result.ok, f"level={level} 边角应手非法")
            self.assertGreaterEqual(result.captured, 1, "角部提子必须被执行")

    def test_edge_atari_escape_legal(self):
        # 边线白子被叫吃：系统应手合法（逃、提或弃均可，但不能非法）。
        board = empty_board()
        place(board, [(4, 0), (5, 0)], gr.BLACK)
        place(board, [(3, 0)], gr.WHITE)
        payload = make_request(board, level=3, move_number=3, last_move={"row": 5, "col": 0})
        response = self.client.post("/api/system-move", json=payload)
        self.assertEqual(response.status_code, 200)
        move = response.json()["move"]
        if isinstance(move, dict):
            self.assertTrue(
                gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok
            )


class EngineFallbackHardeningTests(unittest.TestCase):
    """引擎内部异常兜底：任何缺陷都不得外泄 500，必须得到合法结果或 pass。"""

    def setUp(self):
        self.client = build_client(self)

    def test_decision_crash_falls_back_to_first_legal(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        with mock.patch(
            "backend.ai.decision.decide", side_effect=RuntimeError("引擎内部错误")
        ):
            response = self.client.post(
                "/api/system-move", json=make_request(board, last_move={"row": 4, "col": 4})
            )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["engine"], "kyu-engine")
        move = data["move"]
        self.assertIsInstance(move, dict)
        self.assertTrue(gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok)
        # 兜底路径 reason 仍带 [N级] 前缀。
        self.assertTrue(data["reason"].startswith("["))

    def test_decision_returns_illegal_point_falls_back(self):
        # 决策管道返回占用点：双保险规则校验拦截后回退首个合法点。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        bad = decision.Decision(move=(4, 4), reason="坏点")
        with mock.patch("backend.ai.decision.decide", return_value=bad):
            response = self.client.post(
                "/api/system-move", json=make_request(board, last_move={"row": 4, "col": 4})
            )
        self.assertEqual(response.status_code, 200)
        move = response.json()["move"]
        self.assertIsInstance(move, dict)
        self.assertNotEqual((move["row"], move["col"]), (4, 4))
        self.assertTrue(gr.simulate_move(board, 9, move["row"], move["col"], gr.WHITE).ok)

    def test_all_engines_crash_returns_pass(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        with mock.patch(
            "backend.ai.decision.decide", side_effect=RuntimeError("崩溃A")
        ), mock.patch(
            "backend.ai.engine.first_legal_or_pass", side_effect=RuntimeError("崩溃B")
        ):
            response = self.client.post(
                "/api/system-move", json=make_request(board, last_move={"row": 4, "col": 4})
            )
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["move"], "pass")
        self.assertEqual(data["engine"], "kyu-engine")


class LevelStrengthTrendTests(unittest.TestCase):
    """固定随机种子下的级位强度趋势：1 级所选点干净排名优于 5 级，5 级优于 10 级。

    任务 4 起 6~4 级解锁布局成形/死活/手筋/征子/定式模块，中级位的合理
    选点（挂角/点杀等）会偏离 v1 基线偏好，因此强度参考基准升级为
    "完整能力参考档案"（全模块 + 精确计算 + 全 1.0 权重 + 零噪声），
    各级位仍按同一基准单调比较（断言不变，不是放宽）。
    """

    def _reference_profile(self) -> levels.LevelProfile:
        return levels.LevelProfile(
            level=0, label="参考", strategy="",
            vision=levels.Vision(mode="global"),
            modules=frozenset(
                {"capture", "opening", "life_death", "tesuji", "ladder"}
            ),
            accuracy=levels.Accuracy(liberty=1.0, ladder_steps=8, territory=0.0),
            mistake_rates=levels.MistakeRates(ignore_atari=0.0, blunder_rate=0.0),
            habit_weights=levels.HabitWeights(attachment=1.0),
            pass_threshold=-1e9,
            noise_amplitude=0.0,
            weak_choice_rate=0.0,
            weights=levels.ScoreWeights(),
        )

    def _average_clean_rank(self, level: int, seeds: int = 120) -> float:
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ranked = decision.rank_candidates(
            board, 9, gr.WHITE, None, (4, 4), profile=self._reference_profile()
        )
        rank_index = {(row, col): index for index, (_s, row, col, _t) in enumerate(ranked)}
        profile = levels.get_level_profile(level)
        total = 0
        for seed in range(seeds):
            rng = random.Random(seed)
            choice = decision.choose_move(
                board, 9, gr.WHITE, None, (4, 4), rng, profile=profile
            )
            self.assertIsNotNone(choice)
            row, col, _reason = choice
            # 所有点都必须合法（强度差异绝不允许以非法落子为代价）。
            self.assertTrue(gr.simulate_move(board, 9, row, col, gr.WHITE).ok)
            total += rank_index[(row, col)]
        return total / seeds

    def test_strength_trend_monotonic(self):
        avg_level1 = self._average_clean_rank(1)
        avg_level5 = self._average_clean_rank(5)
        avg_level10 = self._average_clean_rank(10)
        self.assertLessEqual(avg_level1, avg_level5, "1 级平均排名应不劣于 5 级")
        self.assertLessEqual(avg_level5, avg_level10, "5 级平均排名应不劣于 10 级")
        self.assertLess(avg_level1, avg_level10, "1 级与 10 级必须存在可验证强度差异")

    def test_level1_noise_stays_within_amplitude(self):
        # 1 级随机性最低：所选点干净评分与最优解的偏差不得超过其噪声幅度 0.5，
        # 且平均偏差显著小于 10 级（噪声 12.0 + 随性一手）。
        # 干净评分基准与强度趋势测试一致（完整能力参考档案，任务 4 升级）。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ranked = decision.rank_candidates(
            board, 9, gr.WHITE, None, (4, 4), profile=self._reference_profile()
        )
        score_of = {(row, col): score for score, row, col, _t in ranked}
        best_score = ranked[0][0]

        def average_deviation(level: int) -> float:
            profile = levels.get_level_profile(level)
            amplitude = profile.noise_amplitude
            seeds = 120
            total = 0.0
            for seed in range(seeds):
                choice = decision.choose_move(
                    board, 9, gr.WHITE, None, (4, 4), random.Random(seed), profile=profile
                )
                deviation = best_score - score_of[(choice[0], choice[1])]
                if level == 1:
                    self.assertLessEqual(
                        deviation, amplitude + 1e-9,
                        "1 级选择偏离最优解超过噪声幅度，随机性参数失效",
                    )
                total += deviation
            return total / seeds

        avg_level1 = average_deviation(1)
        avg_level10 = average_deviation(10)
        self.assertLessEqual(avg_level1, levels.get_level_profile(1).noise_amplitude)
        self.assertLess(
            avg_level1, avg_level10,
            "1 级平均评分偏差必须小于 10 级（强度趋势的另一可验证面）",
        )


if __name__ == "__main__":
    unittest.main()
