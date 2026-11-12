"""定式与布局测试（任务 4）：定式库命中、布局成形顺序、强度趋势、合法性。

- 定式命中：星位小飞挂前缀 → 4 级固定种子按库应手（下一手坐标）；
  镜像角同样命中；角盒被污染（多余棋子）不误匹配；开局 10 手后不命中；
- 6 级不识定式（modules 不含 joseki）：同局面 reason 无"定式应手"；
- 布局顺序：6 级空盘开局前 4 手均为角部/三线四线合理点（无一线二线
  随手、无中腹漂移）；
- 强度趋势：固定 120 种子，4 级平均候选干净排名严格优于 6 级，
  6 级优于 7 级（衔接任务 3 断言；基准 = 完整能力参考档案）；
- 合法性：6~4 级 × 9/13/19 路抽样对弈各 50 手全部合法。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, levels
from backend.ai.analyzer import joseki
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


# 完整能力参考档案：全模块 + 精确计算 + 全 1.0 权重 + 零噪声（强度基准）。
def reference_profile() -> levels.LevelProfile:
    return levels.LevelProfile(
        level=0, label="参考", strategy="",
        vision=levels.Vision(mode="global"),
        modules=frozenset(
            {"capture", "opening", "life_death", "tesuji", "ladder", "joseki"}
        ),
        accuracy=levels.Accuracy(liberty=1.0, ladder_steps=8, territory=0.0),
        mistake_rates=levels.MistakeRates(ignore_atari=0.0, blunder_rate=0.0),
        habit_weights=levels.HabitWeights(attachment=1.0),
        pass_threshold=-1e9,
        noise_amplitude=0.0,
        weak_choice_rate=0.0,
        weights=levels.ScoreWeights(),
    )


# ---------------------------------------------------------------------------
# 定式库测试
# ---------------------------------------------------------------------------

def star_approach_prefix_board():
    """星位小飞挂前缀（角 (0,0)）：黑星 (2,2)、白小飞挂 (4,1)、黑小飞应 (4,3)。

    序列下一手 = 白拆边 (6,1)。
    """
    board = empty_board()
    place(board, [(2, 2), (4, 3)], gr.BLACK)
    place(board, [(4, 1)], gr.WHITE)
    return board


def star_approach_prefix_mirror_board():
    """同形镜像到角 (8,8)：黑 (6,6)(4,5)、白 (4,7)；下一手 = 白 (2,7)。"""
    board = empty_board()
    place(board, [(6, 6), (4, 5)], gr.BLACK)
    place(board, [(4, 7)], gr.WHITE)
    return board


def komoku_tuotui_prefix_board():
    """小目托退前缀（角 (0,0)）：黑小目 (1,2)、白低挂 (3,0)、黑外挡 (3,3)。

    序列下一手 = 白退 (4,0)。
    """
    board = empty_board()
    place(board, [(1, 2), (3, 3)], gr.BLACK)
    place(board, [(3, 0)], gr.WHITE)
    return board


class JosekiMatchTests(unittest.TestCase):
    def test_star_approach_next_move(self):
        board = star_approach_prefix_board()
        hits = joseki.match_joseki(board, 9, 3, gr.WHITE)
        self.assertIn(("星位小飞挂", (6, 1)), hits)

    def test_star_approach_mirror(self):
        board = star_approach_prefix_mirror_board()
        hits = joseki.match_joseki(board, 9, 3, gr.WHITE)
        self.assertIn(("星位小飞挂", (2, 7)), hits)

    def test_komoku_tuotui_next_move(self):
        board = komoku_tuotui_prefix_board()
        hits = joseki.match_joseki(board, 9, 3, gr.WHITE)
        self.assertIn(("小目托退", (4, 0)), hits)

    def test_polluted_corner_no_match(self):
        # 角盒内出现序列之外的棋子（形状不纯净）→ 不误匹配。
        board = star_approach_prefix_board()
        place(board, [(0, 4)], gr.WHITE)
        hits = joseki.match_joseki(board, 9, 3, gr.WHITE)
        self.assertEqual(hits, [])

    def test_no_match_after_move_ten(self):
        board = star_approach_prefix_board()
        hits = joseki.match_joseki(board, 9, 11, gr.WHITE)
        self.assertEqual(hits, [])

    def test_short_prefix_no_match(self):
        # 仅一手占角（前缀 < 2）不足以触发定式应手。
        board = empty_board()
        place(board, [(2, 2)], gr.BLACK)
        hits = joseki.match_joseki(board, 9, 1, gr.WHITE)
        self.assertEqual(hits, [])


class JosekiEngineTests(unittest.TestCase):
    def test_level4_follows_joseki(self):
        # 4 级固定种子：应手落在定式库该序列的下一手坐标 (6,1)，
        # reason 带"定式应手"标签（思维方式可解释性）。
        board = star_approach_prefix_board()
        profile = levels.get_level_profile(4)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, rng=random.Random(seed),
                profile=profile, move_number=3,
            )
            self.assertEqual(
                (choice[0], choice[1]), (6, 1),
                f"种子{seed}：4 级应按定式应手 (6,1)",
            )
            self.assertIn("定式应手", choice[2])

    def test_level6_does_not_know_joseki(self):
        # 6 级不识定式：模块开关不含 joseki，reason 不出现"定式应手"，
        # 且不会稳定选择定式下一手 (6,1)。
        profile6 = levels.get_level_profile(6)
        self.assertNotIn("joseki", profile6.modules)
        self.assertIn("joseki", levels.get_level_profile(4).modules)
        self.assertIn("joseki", levels.get_level_profile(5).modules)
        board = star_approach_prefix_board()
        joseki_moves = 0
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, rng=random.Random(seed),
                profile=profile6, move_number=3,
            )
            self.assertNotIn("定式", choice[2])
            if (choice[0], choice[1]) == (6, 1):
                joseki_moves += 1
        self.assertLess(joseki_moves, 10, "6 级不应稳定按定式应手（不识定式）")

    def test_level5_joseki_enabled(self):
        # 5 级定式入门：同局面也按库应手。
        board = star_approach_prefix_board()
        choice = decision.choose_move(
            fresh(board), 9, gr.WHITE, rng=random.Random(0),
            profile=levels.get_level_profile(5), move_number=3,
        )
        self.assertEqual((choice[0], choice[1]), (6, 1))


# ---------------------------------------------------------------------------
# 布局成形测试
# ---------------------------------------------------------------------------

class OpeningOrderTests(unittest.TestCase):
    def test_level6_opening_four_moves_reasonable(self):
        # 6 级空盘开局前 4 手（黑白均由 6 级引擎走）：均为三线/四线或
        # 角部区域合理点——无一线二线随手、无中腹漂移（线数 > 3 即漂移）。
        def line_of(row, col):
            return min(row, col, 8 - row, 8 - col)

        board = empty_board()
        previous = None
        last = None
        rng = random.Random(21)
        for move_number in range(4):
            player = gr.BLACK if move_number % 2 == 0 else gr.WHITE
            move, reason = generate_engine_move(
                board, 9, player, 6,
                previous_board=previous, last_move=last,
                move_number=move_number, rng=rng,
            )
            self.assertIsNotNone(move, f"第{move_number}手不应虚手（{reason}）")
            row, col = move
            line = line_of(row, col)
            self.assertGreaterEqual(
                line, 2,
                f"第{move_number}手 {(row, col)} 为一线/二线随手（{reason}）",
            )
            self.assertLessEqual(
                line, 3,
                f"第{move_number}手 {(row, col)} 中腹漂移（{reason}）",
            )
            result = gr.simulate_move(board, 9, row, col, player, previous)
            self.assertTrue(result.ok)
            previous = board
            board = result.board
            last = (row, col)

    def test_opening_module_gives_kakari_bonus(self):
        # 布局成形：对方占角后，挂角点获得 opening 模块加分（6 级解锁，
        # 7 级无布局成形能力——低级位由开局习惯承载，加分结构不同）。
        board = empty_board()
        place(board, [(2, 2)], gr.BLACK)
        ctx = make_ctx(board, gr.WHITE)
        profile6 = levels.get_level_profile(6)
        candidates = decision.rank_candidates(
            fresh(board), 9, gr.WHITE, profile=profile6, move_number=0,
        )
        kakari_points = {(4, 1), (1, 4)}
        top20 = {(row, col) for _s, row, col, _t in candidates[:20]}
        self.assertTrue(
            kakari_points & top20,
            "挂角点应进入 6 级开局高分候选区",
        )

    def test_extension_bonus_for_own_side_stone(self):
        # 拆边：己方三线棋子沿边方向的拆二点获得加分（布局成形能力）。
        board = empty_board()
        place(board, [(2, 2), (4, 4)], gr.BLACK)
        place(board, [(2, 6)], gr.WHITE)  # 白占角 (0,8) 星位
        ctx = make_ctx(board, gr.WHITE)
        profile6 = levels.get_level_profile(6)
        ranked = decision.rank_candidates(
            fresh(board), 9, gr.WHITE, profile=profile6, move_number=4,
        )
        # (2,4) 与白星位 (2,6) 同线（三线）相距 2：拆二要点。
        entry = next(item for item in ranked if (item[1], item[2]) == (2, 4))
        self.assertGreater(entry[0], 0.0)


# ---------------------------------------------------------------------------
# 强度趋势与合法性
# ---------------------------------------------------------------------------

def strength_boards():
    """强度基准盘面（安静中盘 / 丁四死活 / 征子 / 定式前缀 四类）。"""
    from backend.tests.test_life_death import pyramid_four_board
    from backend.tests.test_ladder_tesuji import working_ladder_board

    boards = []

    quiet = empty_board()
    place(quiet, [(4, 4), (2, 6), (6, 2)], gr.BLACK)
    place(quiet, [(2, 2), (6, 6)], gr.WHITE)
    boards.append((quiet, (6, 2), 12))

    boards.append((pyramid_four_board(), None, 20))   # 丁四点杀要点
    boards.append((working_ladder_board(), None, 6))  # 征子叫吃点
    boards.append((star_approach_prefix_board(), None, 3))  # 定式应手
    return boards


class StrengthTrendTests(unittest.TestCase):
    def _average_clean_rank(self, level: int, seeds: int = 120) -> float:
        per_board = []
        for board, last_move, move_number in strength_boards():
            reference = decision.rank_candidates(
                fresh(board), 9, gr.WHITE, last_move=last_move,
                profile=reference_profile(), move_number=move_number,
            )
            rank_of = {
                (row, col): index
                for index, (_s, row, col, _t) in enumerate(reference)
            }
            profile = levels.get_level_profile(level)
            total = 0
            for seed in range(seeds):
                rng = random.Random(seed)
                choice = decision.choose_move(
                    fresh(board), 9, gr.WHITE, last_move=last_move,
                    rng=rng, profile=profile, move_number=move_number,
                )
                row, col, _reason = choice
                self.assertTrue(
                    gr.simulate_move(board, 9, row, col, gr.WHITE).ok
                )
                total += rank_of.get((row, col), len(rank_of))
            per_board.append(total / seeds)
        return sum(per_board) / len(per_board)

    def test_level4_beats_level6_beats_level7(self):
        # 固定 120 种子：4 级平均候选干净排名严格优于 6 级，6 级优于 7 级。
        avg4 = self._average_clean_rank(4)
        avg6 = self._average_clean_rank(6)
        avg7 = self._average_clean_rank(7)
        self.assertLess(avg4, avg6, "4 级应严格优于 6 级")
        self.assertLess(avg6, avg7, "6 级应严格优于 7 级")


class MidLevelLegalityTests(unittest.TestCase):
    def test_selfplay_moves_always_legal(self):
        # 6~4 级 × 9/13/19 路抽样对弈各 50 手（固定种子）：所有落子通过
        # simulate_move 校验，无非法坐标、无自杀、无劫违例。
        for level in (6, 5, 4):
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
                    result = gr.simulate_move(
                        board, size, row, col, player, previous
                    )
                    self.assertTrue(
                        result.ok,
                        f"{level}级 {size}路 第{move_number}手非法：{(row, col)}",
                    )
                    previous = board
                    board = result.board
                    last = (row, col)
                    moves_played += 1
                self.assertEqual(
                    moves_played, 50, f"{level}级 {size}路应下满 50 手"
                )


# ---------------------------------------------------------------------------
# 中级位参数档案
# ---------------------------------------------------------------------------

class MidLevelParameterTests(unittest.TestCase):
    def test_modules_monotonic(self):
        # 级位越高解锁越多：7 级 ⊂ 6 级 ⊂（5 级=4 级，精度差异承载）。
        profiles = levels.all_level_profiles()
        modules7 = set(profiles[7].modules)
        modules6 = set(profiles[6].modules)
        modules5 = set(profiles[5].modules)
        modules4 = set(profiles[4].modules)
        self.assertTrue(modules7 < modules6)
        self.assertTrue(modules6 < modules5)
        self.assertEqual(modules5, modules4)

    def test_mistake_rates_mid_levels(self):
        profiles = levels.all_level_profiles()
        self.assertAlmostEqual(
            profiles[6].mistake_rates.ignore_atari, 0.10, places=2
        )
        self.assertAlmostEqual(
            profiles[5].mistake_rates.ignore_atari, 0.07, places=2
        )
        self.assertAlmostEqual(
            profiles[4].mistake_rates.ignore_atari, 0.05, places=2
        )

    def test_ladder_steps_mid_levels(self):
        profiles = levels.all_level_profiles()
        self.assertEqual(profiles[6].accuracy.ladder_steps, 3)
        self.assertEqual(profiles[5].accuracy.ladder_steps, 5)
        self.assertEqual(profiles[4].accuracy.ladder_steps, 6)

    def test_mid_level_pass_threshold_conservative(self):
        # Pass 阈值任务 5 校准（当前保守不可达，不触发主动 Pass）。
        for level in (4, 5, 6):
            self.assertLess(
                levels.get_level_profile(level).pass_threshold, -1e8
            )


if __name__ == "__main__":
    unittest.main()
