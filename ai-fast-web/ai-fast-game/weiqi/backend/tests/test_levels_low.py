"""低级位（10~7 级）思维建模行为测试（任务 3）。

全部断言基于固定种子（可重复），统计数据来自实测校准：
- 提子不放弃：10 级 60/60（3 盘面 × 20 种子）；
- 忽略叫吃：10 级不逃比例 ≈ 0.44（期望 0.40 ±0.10），7 级 ≈ 0.17（期望 0.15 ±0.10）；
- 贴身程度：与上一手平均距离 10 级 1.77 < 9 级 2.25 < 7 级 2.66（单调）；
- 视野：远离上一手的提子机会 10 级 0/10 看不见、7 级 10/10 看见；
- 占角：空盘开局 8 级 16/20 落角部区域（星位/三三 ±1），10 级 13/20 不保证；
- 主动 Pass：低级位在仅剩低价值点时仍不 Pass（阈值保守不可达）；
- 强度趋势：120 种子平均候选干净排名 8 级 3.69 严格优于 10 级 6.77；
- 合法性：10~7 级 × 9/13/19 路各 50 手抽样对弈全部通过 simulate_move 校验。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, habits, levels
from backend.ai.analyzer import life_death
from backend.ai.analyzer.base import GameContext, generate_candidates
from backend.ai.analyzer.capture import escape_targets, semeai_verdict
from backend.ai.engine import generate_engine_move


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


def fresh(board):
    return [row[:] for row in board]


class ScriptedRandom(random.Random):
    """固定返回同一随机值的可控随机源（测试专用）。"""

    def __init__(self, value: float):
        super().__init__(0)
        self._value = value

    def random(self) -> float:
        return self._value


# ---------------------------------------------------------------------------
# 盘面构造：任务 3 校准用固定局面
# ---------------------------------------------------------------------------

def capture_board_1():
    """黑 (4,4) 仅剩 (4,3) 一气（上一手为黑 (4,4)，在 10 级 ±2 视野内）。"""
    board = empty_board()
    place(board, [(4, 4)], gr.BLACK)
    place(board, [(3, 4), (5, 4), (4, 5)], gr.WHITE)
    return board, (4, 4), (4, 3)


def capture_board_2():
    """黑 (2,2) 仅剩 (2,1) 一气。"""
    board = empty_board()
    place(board, [(2, 2)], gr.BLACK)
    place(board, [(1, 2), (3, 2), (2, 3)], gr.WHITE)
    return board, (2, 2), (2, 1)


def capture_board_3():
    """黑 (6,6)/(6,7) 两子仅剩 (6,5) 一气（可提 2 子）。"""
    board = empty_board()
    place(board, [(6, 6), (6, 7)], gr.BLACK)
    place(board, [(5, 6), (5, 7), (7, 6), (7, 7), (6, 8)], gr.WHITE)
    return board, (6, 6), (6, 5)


def atari_escape_board():
    """白 (6,6)/(6,7) 仅剩 (6,5) 一气，唯一有效逃吃点 (6,5)；上一手黑 (0,0) 远离。"""
    board = empty_board()
    place(board, [(6, 6), (6, 7)], gr.WHITE)
    place(board, [(5, 6), (5, 7), (7, 6), (7, 7), (6, 8), (0, 0)], gr.BLACK)
    return board


def far_capture_vision_board():
    """提子点 (7,3) 距上一手 (4,4) 切比雪夫 3（10 级 ±2 视野外、7 级全盘可见）。"""
    board = empty_board()
    place(board, [(7, 4), (4, 4)], gr.BLACK)
    place(board, [(6, 4), (8, 4), (7, 5)], gr.WHITE)
    return board


def blunder_board():
    """白 (4,4) 一气；逃点 (4,3) 落子后仍仅 1 气（无效逃 = 送吃点）。

    黑 (3,3)/(5,3) 封住 (4,3) 的左侧出路，白 (4,4)+(4,3) 合并后仅剩 (4,2) 一气。
    """
    board = empty_board()
    place(board, [(4, 4)], gr.WHITE)
    place(board, [(3, 4), (5, 4), (4, 5), (3, 3), (5, 3)], gr.BLACK)
    return board


def low_value_endgame_board():
    """仅剩 3 个低价值空点（黑白混围的中立区域），仍不应主动 Pass。"""
    board = empty_board(9)
    for row in range(9):
        for col in range(9):
            if (row, col) in [(4, 3), (4, 4), (4, 5)]:
                continue
            board[row][col] = gr.BLACK if (row + col) % 2 == 0 else gr.WHITE
    return board


def strength_boards():
    """强度趋势基准盘面（含视野差异、安静中盘与局部黑厚势三种局面）。"""
    boards = []

    def build(black, white, last_move):
        board = empty_board()
        place(board, black, gr.BLACK)
        place(board, white, gr.WHITE)
        boards.append((board, last_move))

    # 远端提子：提子点 (7,3) 距 (4,4) 切比雪夫 3，10 级看不见。
    build([(7, 4), (4, 4)], [(6, 4), (8, 4), (7, 5)], (4, 4))
    # 安静中盘。
    build([(2, 6), (6, 2), (4, 4)], [(2, 2), (6, 6)], (4, 4))
    # 局部黑厚势。
    build([(4, 4), (4, 5), (5, 4)], [(6, 6)], (5, 4))
    return boards


# ---------------------------------------------------------------------------
# 参数档案测试
# ---------------------------------------------------------------------------

class LowLevelParameterTests(unittest.TestCase):
    def test_opening_targets_defined(self):
        profiles = levels.all_level_profiles()
        self.assertEqual(profiles[10].habit_weights.opening_targets, ("star-area", "third-line"))
        self.assertEqual(profiles[9].habit_weights.opening_targets, ("third-line", "fourth-line"))
        self.assertEqual(profiles[8].habit_weights.opening_targets, ("corner",))
        self.assertEqual(profiles[7].habit_weights.opening_targets, ("corner", "side"))

    def test_mistake_rates_monotonic_downward(self):
        # 误判率随棋力增强严格下降：10 → 7 级。
        profiles = levels.all_level_profiles()
        for weaker, stronger in ((10, 9), (9, 8), (8, 7)):
            self.assertGreater(
                profiles[weaker].mistake_rates.ignore_atari,
                profiles[stronger].mistake_rates.ignore_atari,
            )
            self.assertGreater(
                profiles[weaker].mistake_rates.blunder_rate,
                profiles[stronger].mistake_rates.blunder_rate,
            )
        self.assertAlmostEqual(profiles[10].mistake_rates.ignore_atari, 0.40, places=2)
        self.assertAlmostEqual(profiles[10].mistake_rates.blunder_rate, 0.30, places=2)
        self.assertAlmostEqual(profiles[7].mistake_rates.ignore_atari, 0.15, places=2)
        self.assertAlmostEqual(profiles[7].mistake_rates.blunder_rate, 0.10, places=2)

    def test_accuracy_liberty_monotonic_upward(self):
        # 气数计算正确率随棋力增强严格上升：10 → 7 级。
        profiles = levels.all_level_profiles()
        values = [profiles[level].accuracy.liberty for level in (10, 9, 8, 7)]
        self.assertEqual(values, sorted(values))
        self.assertEqual(len(set(values)), 4)
        self.assertAlmostEqual(values[0], 0.6, places=2)
        self.assertAlmostEqual(values[-1], 0.85, places=2)

    def test_low_level_pass_threshold_unreachable(self):
        # 低级位几乎不主动 Pass：阈值为保守不可达值（任务 5 校准）。
        for level in range(7, 11):
            self.assertLess(levels.get_level_profile(level).pass_threshold, -1e8)


# ---------------------------------------------------------------------------
# 行为测试（固定种子统计）
# ---------------------------------------------------------------------------

class LowLevelBehaviorTests(unittest.TestCase):
    def test_level10_never_misses_visible_capture(self):
        # 提子不放弃：三个可直接提子盘面（提子点均在 ±2 视野内）× 20 个种子，
        # 10 级必须 100% 提取——吃子是所有级位的基本功。
        profile = levels.get_level_profile(10)
        for board, last_move, capture_point in (
            capture_board_1(), capture_board_2(), capture_board_3()
        ):
            for seed in range(20):
                choice = decision.choose_move(
                    fresh(board), 9, gr.WHITE, last_move=last_move,
                    rng=random.Random(seed), profile=profile,
                )
                self.assertEqual(
                    (choice[0], choice[1]), capture_point,
                    f"种子{seed}未提取（上一手{last_move}）",
                )

    def test_critical_capture_beats_blunder_and_weakness(self):
        # 关键提子局面下送吃/随性误注入都被 CRITICAL 守护拦截：
        # 0.29 < 送吃率 0.30 且 < 随性率 0.40，仍必须提子。
        board, last_move, capture_point = capture_board_1()
        profile = levels.get_level_profile(10)
        choice = decision.choose_move(
            fresh(board), 9, gr.WHITE, last_move=last_move,
            rng=ScriptedRandom(0.29), profile=profile,
        )
        self.assertEqual((choice[0], choice[1]), capture_point)

    def test_ignore_atari_probability(self):
        # 忽略叫吃：己方 1 气块远离上一手时，10 级以约 40%（±10%）
        # 的种子比例不逃，7 级降至约 15%（±10%）。
        board = atari_escape_board()
        for level, expected in ((10, 0.40), (7, 0.15)):
            profile = levels.get_level_profile(level)
            no_escape = 0
            for seed in range(100):
                result = decision.decide(
                    fresh(board), 9, gr.WHITE, profile,
                    last_move=(0, 0), rng=random.Random(seed),
                )
                if result.move is None or (result.move[0], result.move[1]) != (6, 5):
                    no_escape += 1
            self.assertGreaterEqual(no_escape / 100, expected - 0.10, f"{level}级不逃比例过低")
            self.assertLessEqual(no_escape / 100, expected + 0.10, f"{level}级不逃比例过高")

    def test_attachment_distance_monotonic(self):
        # 贴身程度：100 个固定种子的开局应手与上一手平均距离 10 级 < 9 级 < 7 级。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        averages = {}
        for level in (10, 9, 7):
            profile = levels.get_level_profile(level)
            distances = []
            for seed in range(100):
                choice = decision.choose_move(
                    fresh(board), 9, gr.WHITE, last_move=(4, 4),
                    rng=random.Random(seed), profile=profile,
                )
                distances.append(abs(choice[0] - 4) + abs(choice[1] - 4))
            averages[level] = sum(distances) / len(distances)
        # 校准值：10级 1.77 / 9级 2.25 / 7级 2.66。
        self.assertLess(averages[10], averages[9], "贴身度：10 级应比 9 级更贴身")
        self.assertLess(averages[9], averages[7], "贴身度：9 级应比 7 级更贴身")

    def test_vision_blind_to_far_capture(self):
        # 视野验证：远离上一手的提子机会，10 级（±2 视野外）看不见，
        # 7 级（全盘）看得见且必然提取。
        board = far_capture_vision_board()
        profile10 = levels.get_level_profile(10)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, last_move=(4, 4),
                rng=random.Random(seed), profile=profile10,
            )
            self.assertNotEqual(
                (choice[0], choice[1]), (7, 3), "10 级不应看见视野外的提子机会"
            )
            self.assertTrue(gr.simulate_move(board, 9, choice[0], choice[1], gr.WHITE).ok)
        profile7 = levels.get_level_profile(7)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, last_move=(4, 4),
                rng=random.Random(seed), profile=profile7,
            )
            self.assertEqual((choice[0], choice[1]), (7, 3), "7 级应看见并提取")

    def test_level8_corner_opening(self):
        # 占角习惯：空盘开局，8 级固定种子第一手大多落在角部区域
        # （星位/三三 ±1）；10 级不保证（存在落角部之外的种子）。
        zones = habits.corner_zones(9)

        def in_corner(row, col):
            return any((row, col) in zone for zone in zones)

        hits = {}
        for level in (10, 8):
            profile = levels.get_level_profile(level)
            count = 0
            for seed in range(20):
                choice = decision.choose_move(
                    empty_board(), 9, gr.WHITE,
                    rng=random.Random(seed), profile=profile,
                )
                count += in_corner(choice[0], choice[1])
            hits[level] = count
        # 校准值：8 级 16/20、10 级 13/20。
        self.assertGreaterEqual(hits[8], 12, "8 级开局应有明显占角倾向")
        self.assertLess(hits[10], 20, "10 级开局不应保证落角部区域")

    def test_low_levels_never_active_pass_on_low_value_board(self):
        # 主动 Pass 阈值：低级位在仅剩低价值点时仍不 Pass。
        board = low_value_endgame_board()
        for level in (10, 9, 8, 7):
            profile = levels.get_level_profile(level)
            result = decision.decide(
                fresh(board), 9, gr.WHITE, profile,
                last_move=(4, 4), rng=random.Random(1),
            )
            self.assertFalse(result.active_pass, f"{level}级不应主动 Pass")
            self.assertIsNotNone(result.move, f"{level}级应仍有落子")
            check = gr.simulate_move(board, 9, result.move[0], result.move[1], gr.WHITE)
            self.assertTrue(check.ok)

    def test_blunder_injection_picks_self_atari(self):
        # 送吃误注入：0.29 < 10 级送吃率 0.30，选择视野内落子后自身仅 1 气
        # 且无提子的合法点 (4,3)，reason 留痕"随手送吃"。
        board = blunder_board()
        profile = levels.get_level_profile(10)
        choice = decision.choose_move(
            fresh(board), 9, gr.WHITE, last_move=(5, 3),
            rng=ScriptedRandom(0.29), profile=profile,
        )
        self.assertEqual((choice[0], choice[1]), (4, 3))
        self.assertIn("随手送吃", choice[2])
        result = gr.simulate_move(board, 9, 4, 3, gr.WHITE)
        _, liberties = gr.get_group(result.board, 9, 4, 3)
        self.assertEqual(len(liberties), 1, "送吃点应落子后仅 1 气")

    def test_blunder_not_triggered_when_roll_high(self):
        # 0.31 > 送吃率 0.30：不触发送吃，绝不选择自撞 1 气点。
        board = blunder_board()
        profile = levels.get_level_profile(10)
        choice = decision.choose_move(
            fresh(board), 9, gr.WHITE, last_move=(5, 3),
            rng=ScriptedRandom(0.31), profile=profile,
        )
        self.assertNotEqual((choice[0], choice[1]), (4, 3))
        self.assertTrue(gr.simulate_move(board, 9, choice[0], choice[1], gr.WHITE).ok)

    def test_selfplay_moves_always_legal(self):
        # 合法性：10~7 级 × 9/13/19 路抽样对弈各 50 手（固定种子），
        # 所有落子通过 simulate_move 校验，无非法坐标、无自杀、无劫违例。
        for level in (10, 9, 8, 7):
            for size in (9, 13, 19):
                board = empty_board(size)
                previous = None
                last = None
                rng = random.Random(99)
                moves_played = 0
                for move_number in range(50):
                    player = gr.BLACK if move_number % 2 == 0 else gr.WHITE
                    move, _reason = generate_engine_move(
                        board, size, player, level,
                        previous_board=previous, last_move=last,
                        move_number=move_number, rng=rng,
                    )
                    if move is None:
                        break
                    row, col = move
                    result = gr.simulate_move(board, size, row, col, player, previous)
                    self.assertTrue(
                        result.ok,
                        f"{level}级 {size}路 第{move_number}手非法：{(row, col)}",
                    )
                    previous = board
                    board = result.board
                    last = (row, col)
                    moves_played += 1
                self.assertEqual(moves_played, 50, f"{level}级 {size}路应下满 50 手")

    def test_strength_rank_level8_beats_level10(self):
        # 强度趋势：固定 120 个种子，8 级平均候选干净排名严格优于 10 级。
        # 排名基准 = 基线档案（全盘视野、精确气数、全 1.0 权重）的干净评分序。
        boards = strength_boards()
        averages = {}
        for level in (8, 10):
            profile = levels.get_level_profile(level)
            per_board = []
            for board, last_move in boards:
                reference = decision.rank_candidates(fresh(board), 9, gr.WHITE, last_move=last_move)
                rank_of = {(row, col): index for index, (_s, row, col, _t) in enumerate(reference)}
                total = 0
                for seed in range(120):
                    choice = decision.choose_move(
                        fresh(board), 9, gr.WHITE, last_move=last_move,
                        rng=random.Random(seed), profile=profile,
                    )
                    total += rank_of.get((choice[0], choice[1]), len(reference))
                per_board.append(total / 120)
            averages[level] = sum(per_board) / len(per_board)
        # 校准值：8 级总平均 3.69 / 10 级 6.77。
        self.assertLess(averages[8], averages[10], "8 级平均候选干净排名应严格优于 10 级")

    def test_engine_reason_has_level_prefix(self):
        board, last_move, _capture = capture_board_1()
        move, reason = generate_engine_move(
            fresh(board), 9, gr.WHITE, 10, last_move=last_move, rng=random.Random(3)
        )
        self.assertTrue(reason.startswith("[10级]"), f"reason 缺少级位前缀：{reason!r}")
        self.assertIn("提", reason)
        self.assertTrue(gr.simulate_move(board, 9, move[0], move[1], gr.WHITE).ok)


# ---------------------------------------------------------------------------
# 视野过滤单元测试
# ---------------------------------------------------------------------------

class VisionFilterTests(unittest.TestCase):
    def _ctx(self, board, last_move, player=gr.WHITE):
        candidates = generate_candidates(board, 9, player)
        return GameContext(
            board=board, size=9, player=player,
            last_move=last_move, candidates=candidates,
        )

    def test_local_vision_radius_2(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ctx = self._ctx(board, (4, 4))
        visible = decision.apply_vision(ctx, levels.get_level_profile(10))
        for row, col, _result in visible:
            self.assertLessEqual(abs(row - 4), 2)
            self.assertLessEqual(abs(col - 4), 2)
        self.assertGreater(len(visible), 0)

    def test_local_vision_includes_atari_escape_when_alert(self):
        # 己方被叫吃块的逃吃点进入告警视野（rng=None 清醒评估）。
        board = atari_escape_board()
        ctx = self._ctx(board, (0, 0))
        visible = decision.apply_vision(ctx, levels.get_level_profile(10), rng=None)
        points = {(row, col) for row, col, _ in visible}
        self.assertIn((6, 5), points)

    def test_local_vision_excludes_atari_escape_when_ignored(self):
        # 0.39 < 10 级 ignore_atari 0.40：对告警"视而不见"。
        board = atari_escape_board()
        ctx = self._ctx(board, (0, 0))
        visible = decision.apply_vision(
            ctx, levels.get_level_profile(10), rng=ScriptedRandom(0.39)
        )
        points = {(row, col) for row, col, _ in visible}
        self.assertNotIn((6, 5), points)

    def test_global_vision_sees_everything(self):
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ctx = self._ctx(board, (4, 4))
        visible = decision.apply_vision(ctx, levels.get_level_profile(7))
        self.assertEqual(len(visible), len(ctx.candidates))

    def test_half_vision_diamond(self):
        # 8 级半盘：上一手曼哈顿距离 <= size//2（9 路 = 4）的菱形区域。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ctx = self._ctx(board, (4, 4))
        visible = decision.apply_vision(ctx, levels.get_level_profile(8))
        for row, col, _result in visible:
            self.assertLessEqual(abs(row - 4) + abs(col - 4), 4)
        points = {(row, col) for row, col, _ in visible}
        self.assertIn((4, 8), points)     # 距离 4：可见
        self.assertNotIn((0, 0), points)  # 距离 8：视野外

    def test_vision_empty_falls_back_to_all(self):
        # 兜底：视野内无点可下时回退全盘（不会因视野狭窄而无故虚手）。
        board = empty_board()
        place(board, [(r, c) for r in range(3) for c in range(3)], gr.BLACK)
        place(board, [(8, 8)], gr.WHITE)
        ctx = self._ctx(board, (0, 0))
        visible = decision.apply_vision(ctx, levels.get_level_profile(10))
        self.assertEqual(len(visible), len(ctx.candidates))

    def test_no_last_move_means_global_vision(self):
        # 开局/虚手后无参照点：视野为全盘。
        board = empty_board()
        place(board, [(4, 4)], gr.BLACK)
        ctx = self._ctx(board, None)
        for level in (10, 9, 8, 7):
            visible = decision.apply_vision(ctx, levels.get_level_profile(level))
            self.assertEqual(len(visible), len(ctx.candidates))


# ---------------------------------------------------------------------------
# 吃子/死活基础能力单元测试
# ---------------------------------------------------------------------------

class CaptureCapabilityTests(unittest.TestCase):
    def test_escape_targets_enumerates_valid_escape(self):
        # 白 (4,4) 一气：逃点 (4,3) 落子后整体 3 气，是有效逃吃方向。
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        ctx = GameContext(
            board=board, size=9, player=gr.WHITE,
            candidates=generate_candidates(board, 9, gr.WHITE),
        )
        self.assertEqual(escape_targets(ctx), [(4, 3)])

    def test_escape_targets_excludes_invalid_escape(self):
        # 无效逃：落子后整体仍 1 气（送吃点），不算逃吃方向。
        board = blunder_board()
        ctx = GameContext(
            board=board, size=9, player=gr.WHITE,
            candidates=generate_candidates(board, 9, gr.WHITE),
        )
        self.assertNotIn((4, 3), escape_targets(ctx))

    def test_escape_tagged_in_ranking(self):
        # 逃吃点的 reason 标签：任何级位看见被叫吃块时都应优先逃。
        board = atari_escape_board()
        ranked = decision.rank_candidates(
            fresh(board), 9, gr.WHITE, last_move=(0, 0),
            profile=levels.get_level_profile(7),
        )
        escape_entry = next(item for item in ranked if (item[1], item[2]) == (6, 5))
        self.assertGreaterEqual(escape_entry[0], decision.CRITICAL_MOVE_SCORE)
        self.assertEqual(escape_entry[3], "逃出叫吃")

    def test_semeai_verdict_exact(self):
        self.assertEqual(semeai_verdict(4, 3)[0], "杀得过")
        self.assertEqual(semeai_verdict(2, 3)[0], "杀不过")
        self.assertEqual(semeai_verdict(3, 3)[0], "对气")
        # rng 缺省 = 精确计算，重复调用结论稳定。
        self.assertEqual(semeai_verdict(4, 3)[1], 3)

    def test_semeai_verdict_miscounts_with_low_accuracy(self):
        # accuracy 0.6：约 40% 的种子数错对方气数（±1）。
        miscounted = 0
        for seed in range(1000):
            _verdict, counted = semeai_verdict(3, 3, rng=random.Random(seed), accuracy=0.6)
            if counted != 3:
                miscounted += 1
        self.assertAlmostEqual(miscounted / 1000, 0.40, delta=0.05)

    def test_semeai_verdict_exact_with_full_accuracy(self):
        for seed in range(50):
            _verdict, counted = semeai_verdict(3, 3, rng=random.Random(seed), accuracy=1.0)
            self.assertEqual(counted, 3)


class LifeDeathSkeletonTests(unittest.TestCase):
    def test_atari_groups_both_colors(self):
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        white_atari = life_death.atari_groups(board, 9, gr.WHITE)
        black_atari = life_death.atari_groups(board, 9, gr.BLACK)
        self.assertEqual(len(white_atari), 1)
        self.assertEqual(white_atari[0][0], {(4, 4)})
        self.assertEqual(white_atari[0][1], (4, 3))
        self.assertEqual(black_atari, [])  # 黑三子均多气

    def test_dead_stones_are_one_liberty_groups(self):
        # 骨架能力："气 <= 1 必死" = 1 气块（对方先手即可提净）。
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        place(board, [(8, 8)], gr.WHITE)  # 多气块，不死
        dead = life_death.dead_stones(board, 9)
        self.assertEqual(len(dead), 1)
        stones, liberty, color = dead[0]
        self.assertEqual((stones, liberty, color), ({(4, 4)}, (4, 3), gr.WHITE))
        self.assertEqual(life_death.dead_stones(board, 9, gr.BLACK), [])

    def test_analyze_returns_empty_for_low_levels(self):
        # 10~7 级模块开关不含 life_death（低级位无死活思维，任务 4 解锁）。
        board = empty_board()
        place(board, [(4, 4)], gr.WHITE)
        place(board, [(3, 4), (5, 4), (4, 5)], gr.BLACK)
        ctx = GameContext(
            board=board, size=9, player=gr.WHITE,
            candidates=generate_candidates(board, 9, gr.WHITE),
        )
        self.assertEqual(life_death.analyze(ctx, levels.get_level_profile(10)), [])


# ---------------------------------------------------------------------------
# 落子习惯单元测试
# ---------------------------------------------------------------------------

class OpeningHabitTests(unittest.TestCase):
    def _ctx(self, board, move_number=0):
        return GameContext(
            board=board, size=9, player=gr.WHITE,
            move_number=move_number,
            candidates=generate_candidates(board, 9, gr.WHITE),
        )

    def test_corner_zones_cover_star_and_san_san(self):
        zones = habits.corner_zones(9)
        flat = set().union(*zones)
        # 星位与三三（0 基 (2,2) 等）均在角区；天元 (4,4) 不在。
        for point in [(2, 2), (2, 6), (6, 2), (6, 6)]:
            self.assertIn(point, flat)
        self.assertNotIn((4, 4), flat)
        for size in (13, 19):
            zones_big = habits.corner_zones(size)
            flat_big = set().union(*zones_big)
            offset = 3 if size >= 13 else 2
            self.assertIn((offset, offset), flat_big)
            self.assertIn((2, 2), flat_big)

    def test_corner_bonus_only_for_empty_corner(self):
        board = empty_board()
        ctx = self._ctx(board)
        bonus, tag = habits.opening_target_bonus(ctx, 2, 2, ("corner",))
        self.assertEqual(bonus, 25.0)
        self.assertEqual(tag, "开局占角")
        # 角区已有棋子（黑占角后）：不再给空角加分。
        place(board, [(2, 2)], gr.BLACK)
        bonus, _tag = habits.opening_target_bonus(ctx, 2, 3, ("corner",))
        self.assertEqual(bonus, 0.0)

    def test_side_bonus_outside_corner_zones(self):
        board = empty_board()
        ctx = self._ctx(board)
        # (4,2) 为三线且不在角区：拆边要点。
        bonus, tag = habits.opening_target_bonus(ctx, 4, 2, ("corner", "side"))
        self.assertEqual(bonus, 8.0)
        self.assertEqual(tag, "拆边要点")
        # 角区优先：空角未占时占角优先于拆边。
        bonus, tag = habits.opening_target_bonus(ctx, 2, 2, ("corner", "side"))
        self.assertEqual((bonus, tag), (25.0, "开局占角"))

    def test_line_and_star_area_bonuses(self):
        board = empty_board()
        ctx = self._ctx(board)
        self.assertEqual(habits.opening_target_bonus(ctx, 2, 4, ("third-line",)), (6.0, "走三线"))
        self.assertEqual(habits.opening_target_bonus(ctx, 3, 4, ("fourth-line",)), (5.0, "走四线"))
        # (3,3) 在星位 (2,2)±1 内。
        self.assertEqual(habits.opening_target_bonus(ctx, 3, 3, ("star-area",)), (6.0, "占星位附近"))

    def test_opening_bonus_inactive_after_move_12(self):
        board = empty_board()
        ctx = self._ctx(board, move_number=13)
        self.assertEqual(habits.opening_target_bonus(ctx, 2, 2, ("corner",)), (0.0, ""))


if __name__ == "__main__":
    unittest.main()
