"""级位能力档案 v2 测试：参数映射、视野/模块/误判率与固定随机源下的行为差异。

不依赖随机运气：通过 ScriptedRandom 注入固定的 rng.random() 返回值，
使"随性一手"分支的触发与否完全可控、可重复。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, levels


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


class ScriptedRandom(random.Random):
    """固定返回同一随机值的可控随机源（测试专用）。"""

    def __init__(self, value: float):
        super().__init__(0)
        self._value = value

    def random(self) -> float:
        return self._value


class LevelProfileTests(unittest.TestCase):
    def test_all_ten_levels_defined(self):
        profiles = levels.all_level_profiles()
        self.assertEqual(sorted(profiles.keys()), list(range(1, 11)))
        for level, profile in profiles.items():
            self.assertEqual(profile.level, level)
            self.assertTrue(profile.label.endswith("级"))
            self.assertTrue(profile.strategy, "策略描述不应为空")

    def test_invalid_level_raises(self):
        for level in (0, 11, -1, 99):
            with self.assertRaises(ValueError):
                levels.get_level_profile(level)

    def test_v2_fields_present(self):
        for profile in levels.all_level_profiles().values():
            self.assertIn(profile.vision.mode, ("local", "half", "global"))
            self.assertIsInstance(profile.modules, frozenset)
            self.assertIn("capture", profile.modules, "任何级位都启用吃子模块")
            for rate in (profile.mistake_rates.ignore_atari, profile.mistake_rates.blunder_rate):
                self.assertGreaterEqual(rate, 0.0)
                self.assertLessEqual(rate, 1.0)
            self.assertGreater(profile.habit_weights.attachment, 0.0)
            self.assertIsInstance(profile.pass_threshold, float)

    def test_randomness_monotonic_with_strength(self):
        # 级位数字越大越弱：噪声与随性概率应随级位数字增大而严格增大。
        profiles = levels.all_level_profiles()
        for weaker in range(2, 11):
            stronger = weaker - 1
            self.assertGreater(
                profiles[weaker].noise_amplitude, profiles[stronger].noise_amplitude,
                f"噪声：{weaker}级应高于{stronger}级",
            )
            self.assertGreater(
                profiles[weaker].weak_choice_rate, profiles[stronger].weak_choice_rate,
                f"随性概率：{weaker}级应高于{stronger}级",
            )

    def test_vision_expands_with_strength(self):
        # 视野随级位扩大：10 级 ±2、9 级 ±3、8 级半盘、7 级以上全盘。
        profiles = levels.all_level_profiles()
        self.assertEqual(profiles[10].vision.mode, "local")
        self.assertEqual(profiles[10].vision.radius, 2)
        self.assertEqual(profiles[9].vision.mode, "local")
        self.assertEqual(profiles[9].vision.radius, 3)
        self.assertEqual(profiles[8].vision.mode, "half")
        self.assertEqual(profiles[7].vision.mode, "global")
        self.assertEqual(profiles[1].vision.mode, "global")

    def test_low_level_module_gates(self):
        # 10~7 级仅启用吃子与布局雏形（无死活/手筋/定式/中盘/官子/形势思维）。
        for level in range(7, 11):
            profile = levels.get_level_profile(level)
            self.assertLessEqual(
                set(profile.modules), {"capture", "opening"},
                f"{level}级模块开关越界",
            )

    def test_mistake_rates_shrink_with_strength(self):
        profiles = levels.all_level_profiles()
        self.assertAlmostEqual(profiles[10].mistake_rates.ignore_atari, 0.40, places=2)
        for weaker in range(2, 11):
            stronger = weaker - 1
            self.assertGreaterEqual(
                profiles[weaker].mistake_rates.ignore_atari,
                profiles[stronger].mistake_rates.ignore_atari,
                f"忽略叫吃率：{weaker}级应不低于{stronger}级",
            )

    def test_attachment_shrinks_with_strength(self):
        # 弱级位贴身缠斗（贴身度高），强级位更看全局。
        profiles = levels.all_level_profiles()
        self.assertGreater(
            profiles[10].habit_weights.attachment, profiles[1].habit_weights.attachment
        )

    def test_pass_threshold_conservative_in_task2(self):
        # 任务 2 阈值取保守不可达值（不触发主动 Pass），任务 5 校准。
        for profile in levels.all_level_profiles().values():
            self.assertLess(profile.pass_threshold, -1e8, "任务 2 阈值必须保守不可达")

    def test_level10_weak_rate_about_40_percent(self):
        self.assertAlmostEqual(levels.get_level_profile(10).weak_choice_rate, 0.40, places=2)

    def test_level1_has_lowest_randomness(self):
        profile = levels.get_level_profile(1)
        self.assertEqual(profile.weak_choice_rate, 0.0)
        self.assertLessEqual(profile.noise_amplitude, 1.0)

    def test_critical_weights_never_below_one(self):
        # 关键手段（提子/叫吃/救棋）不被任何级位削弱，保证最弱级位的基本功。
        for profile in levels.all_level_profiles().values():
            self.assertGreaterEqual(profile.weights.capture, 1.0)
            self.assertGreaterEqual(profile.weights.atari, 1.0)
            self.assertGreaterEqual(profile.weights.rescue, 1.0)

    def test_position_weight_grows_with_strength(self):
        # 10 级无围空概念（位置权重极低），1 级有全局意识（位置权重高）。
        profiles = levels.all_level_profiles()
        self.assertLess(profiles[10].weights.position, 0.2)
        self.assertGreater(profiles[1].weights.position, 1.0)

    def test_proximity_weight_shrinks_with_strength(self):
        # 弱级位集中于局部缠斗（贴近上一手权重高），强级位更看全局。
        profiles = levels.all_level_profiles()
        self.assertGreater(profiles[10].weights.proximity, profiles[1].weights.proximity)

    def test_tactical_bonus_only_for_level1(self):
        profiles = levels.all_level_profiles()
        self.assertTrue(profiles[1].tactical_bonus)
        for level in range(2, 11):
            self.assertFalse(profiles[level].tactical_bonus)

    def test_level_parameters_are_distinct(self):
        profiles = levels.all_level_profiles()
        tuples = {
            (p.noise_amplitude, p.weak_choice_rate, p.habit_weights.attachment)
            for p in profiles.values()
        }
        self.assertEqual(len(tuples), 10, "10 个级位的核心参数不得共用同一组值")


class LevelBehaviorTests(unittest.TestCase):
    def _quiet_board(self):
        """无提子/叫吃/救棋要点的安静局面：随性一手唯一可触发的场景。"""
        board = empty_board()
        place(board, [(4, 4), (3, 3), (5, 5)], gr.BLACK)
        return board

    def test_level10_picks_weaker_move_when_triggered(self):
        # rng.random()=0.39 < 0.40：10 级触发随性一手，应放弃最优解；
        # 1 级 weak_rate=0 永远选最优。两者选择应不同且均合法。
        board = self._quiet_board()
        weak = decision.choose_move(
            board, 9, gr.WHITE, rng=ScriptedRandom(0.39), profile=levels.get_level_profile(10)
        )
        strong = decision.choose_move(
            board, 9, gr.WHITE, rng=ScriptedRandom(0.39), profile=levels.get_level_profile(1)
        )
        self.assertIsNotNone(weak)
        self.assertIsNotNone(strong)
        self.assertNotEqual((weak[0], weak[1]), (strong[0], strong[1]))
        for row, col, _ in (weak, strong):
            self.assertTrue(gr.simulate_move(board, 9, row, col, gr.WHITE).ok)
        self.assertIn("随性一手", weak[2], "随性一手的 reason 应有留痕")

    def test_level10_keeps_best_when_roll_high(self):
        # rng.random()=0.95 > 0.40：10 级不触发随性一手，应选中其自身权重下的
        # 干净最优解（级位权重不同，各档"最优"本就可能不同——这正是级位差异）。
        board = self._quiet_board()
        profile10 = levels.get_level_profile(10)
        choice = decision.choose_move(
            board, 9, gr.WHITE, rng=ScriptedRandom(0.95), profile=profile10
        )
        best = decision.rank_candidates(board, 9, gr.WHITE, profile=profile10)[0]
        self.assertEqual((choice[0], choice[1]), (best[1], best[2]))
        self.assertNotIn("随性一手", choice[2])

    def test_critical_capture_never_sacrificed(self):
        # 关键局面：黑 (4,4) 只剩 (4,3) 一口气。即使 10 级且随性触发
        # （0.39 < 0.40），也必须提子——吃子是所有级位的基本功。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
        for level in (10, 5, 1):
            choice = decision.choose_move(
                board, 9, gr.WHITE, rng=ScriptedRandom(0.39),
                profile=levels.get_level_profile(level),
            )
            self.assertEqual((choice[0], choice[1]), (4, 3), f"{level}级必须提子")

    def test_fixed_seed_reproducible_per_level(self):
        board = self._quiet_board()
        for level in (10, 5, 1):
            first = decision.choose_move(
                board, 9, gr.WHITE, rng=random.Random(42), profile=levels.get_level_profile(level)
            )
            second = decision.choose_move(
                board, 9, gr.WHITE, rng=random.Random(42), profile=levels.get_level_profile(level)
            )
            self.assertEqual(first, second, f"{level}级固定种子应可重复")

    def test_all_levels_choose_legal_moves(self):
        board = self._quiet_board()
        for level in range(1, 11):
            choice = decision.choose_move(
                board, 9, gr.WHITE, rng=random.Random(2024),
                profile=levels.get_level_profile(level),
            )
            self.assertIsNotNone(choice)
            row, col, _ = choice
            self.assertTrue(
                gr.simulate_move(board, 9, row, col, gr.WHITE).ok,
                f"{level}级返回了非法落点",
            )

    def test_decide_active_pass_not_triggered_in_task2(self):
        # 任务 2 阈值保守：安静盘面与低价值盘面都不应触发主动 Pass。
        board = self._quiet_board()
        for level in (1, 5, 10):
            result = decision.decide(
                board, 9, gr.WHITE, levels.get_level_profile(level),
                last_move=(4, 4), rng=random.Random(7),
            )
            self.assertIsNotNone(result.move, f"{level}级不应主动 Pass")

    def test_rank_candidates_sorted_without_noise(self):
        board = self._quiet_board()
        ranked = decision.rank_candidates(
            board, 9, gr.WHITE, profile=levels.get_level_profile(1)
        )
        self.assertEqual(len(ranked), 78)
        scores = [item[0] for item in ranked]
        self.assertEqual(scores, sorted(scores, reverse=True))
        # 两次调用结果完全一致（无随机成分）。
        again = decision.rank_candidates(board, 9, gr.WHITE, profile=levels.get_level_profile(1))
        self.assertEqual(ranked, again)


if __name__ == "__main__":
    unittest.main()
