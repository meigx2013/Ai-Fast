"""死活棋形库测试（任务 4）：六种标准局部 + 真眼判定 + 级位识别精度。

标准棋形结论表（04_prompt）：
- 直三 / 曲三 / 丁四 / 刀把五 → "先手死"（对方先手点杀则死）；
- 曲四 / 板六 → "活"；
- 白先手点杀直三后，黑眼位围合区被破坏（碎成边界混合的散空，无法做活）；
- 6 级仅识别基础型（直三/板六），其余形状不识别属预期；
- 5 级全表；4 级全表 + 局部加强读（弃死子）。

盘面构造：黑棋环围出目标眼位即可（眼位各点四邻均为黑 → 围合黑方
眼位区域）；外围大空区同样只邻黑，判"大眼位·活"，不产生候选（无害）。
黑环气数充足，棋形判定与气数判定分离（先手死由眼位形状决定）。
"""

import random
import unittest

from backend import go_rules as gr
from backend.ai import decision, levels
from backend.ai.analyzer import life_death
from backend.ai.analyzer.base import GameContext, generate_candidates


def empty_board(size: int = 9) -> list[list[int]]:
    return [[gr.EMPTY] * size for _ in range(size)]


def place(board, points, color):
    for row, col in points:
        board[row][col] = color


def fresh(board):
    return [row[:] for row in board]


def build_shape_board(black_stones, eyespace):
    """黑环围眼位的标准局部盘面（外围留空，黑环气数充足）。"""
    board = empty_board()
    place(board, black_stones, gr.BLACK)
    for row, col in eyespace:
        assert board[row][col] == gr.EMPTY, f"眼位 {row},{col} 与黑子重叠"
    return board


def make_ctx(board, player=gr.WHITE, move_number=0):
    return GameContext(
        board=board, size=9, player=player,
        move_number=move_number,
        candidates=generate_candidates(board, 9, player),
    )


def find_verdict(board, region_subset, color=gr.BLACK):
    """在 region_verdicts 中查找包含指定点集的某色眼位结论。"""
    for info in life_death.region_verdicts(board, 9):
        if info["color"] == color and region_subset <= info["region"]:
            return info
    return None


# ---------------------------------------------------------------------------
# 六种标准局部（嵌入 9 路棋盘）
# ---------------------------------------------------------------------------

def straight_three_board():
    """直三：眼位 (4,3)(4,4)(4,5)，黑环围。"""
    black = [(3, 3), (3, 4), (3, 5), (5, 3), (5, 4), (5, 5), (4, 2), (4, 6)]
    return build_shape_board(black, [(4, 3), (4, 4), (4, 5)])


def bent_three_board():
    """曲三：眼位 (4,4)(4,5)(5,4)，黑环围。"""
    black = [(3, 4), (3, 5), (4, 3), (4, 6), (5, 3), (5, 5), (6, 4)]
    return build_shape_board(black, [(4, 4), (4, 5), (5, 4)])


def pyramid_four_board():
    """丁四：眼位 (4,4)(4,5)(4,6)(5,5)（T 形），黑环围。"""
    black = [(3, 4), (4, 3), (3, 5), (3, 6), (4, 7), (5, 4), (6, 5), (5, 6)]
    return build_shape_board(black, [(4, 4), (4, 5), (4, 6), (5, 5)])


def knife_five_board():
    """刀把五：眼位 (4,3)(4,4)(4,5)(5,3)(5,4)（(4,4) 为刀把中腹要点）。"""
    black = [
        (3, 3), (3, 4), (3, 5), (4, 2), (4, 6),
        (5, 2), (6, 3), (6, 4), (6, 5), (5, 5),
    ]
    # (5,5) 为刀把五包围盒内的黑子（刀把拐角），眼位为其余 5 点。
    return build_shape_board(black, [(4, 3), (4, 4), (4, 5), (5, 3), (5, 4)])


def bent_four_board():
    """曲四：眼位 (4,4)(5,4)(6,4)(6,5)（弯四连），黑环围。"""
    black = [
        (3, 4), (4, 3), (4, 5), (5, 3), (5, 5),
        (7, 4), (6, 3), (7, 5), (6, 6),
    ]
    return build_shape_board(black, [(4, 4), (5, 4), (6, 4), (6, 5)])


def rectangular_six_board():
    """板六：眼位 2×3 六点 (4,3)~(5,5)，黑环围。"""
    black = [
        (3, 3), (3, 4), (3, 5), (4, 2), (4, 6),
        (5, 2), (5, 6), (6, 3), (6, 4), (6, 5),
    ]
    return build_shape_board(black, [(4, 3), (4, 4), (4, 5), (5, 3), (5, 4), (5, 5)])


def straight_two_board():
    """直二死型：眼位 (4,3)(4,4) 两点，黑环围（先手也做不活）。"""
    black = [(3, 3), (3, 4), (5, 3), (5, 4), (4, 2), (4, 5)]
    return build_shape_board(black, [(4, 3), (4, 4)])


def two_real_eyes_board():
    """两真眼活棋：黑块分立两只单点真眼 (3,3) 与 (3,5)。"""
    black = [
        (2, 3), (2, 4), (2, 5),
        (3, 2), (3, 4), (3, 6),
        (4, 3), (4, 4), (4, 5),
    ]
    return build_shape_board(black, [(3, 3), (3, 5)])


# ---------------------------------------------------------------------------
# 棋形库单元测试
# ---------------------------------------------------------------------------

class ShapeLibraryTests(unittest.TestCase):
    def test_straight_three_first_kill(self):
        board = straight_three_board()
        info = find_verdict(board, {(4, 3), (4, 4), (4, 5)})
        self.assertIsNotNone(info, "直三眼位区域应被提取")
        self.assertEqual(info["shape"], "直三")
        self.assertEqual(info["verdict"], life_death.VERDICT_FIRST_KILL)
        self.assertEqual(info["vital"], (4, 4))  # 要点：直三中点

    def test_bent_three_first_kill(self):
        board = bent_three_board()
        info = find_verdict(board, {(4, 4), (4, 5), (5, 4)})
        self.assertIsNotNone(info)
        self.assertEqual(info["shape"], "曲三")
        self.assertEqual(info["verdict"], life_death.VERDICT_FIRST_KILL)
        self.assertEqual(info["vital"], (4, 4))  # 要点：曲三拐点

    def test_pyramid_four_first_kill(self):
        board = pyramid_four_board()
        info = find_verdict(board, {(4, 4), (4, 5), (4, 6), (5, 5)})
        self.assertIsNotNone(info)
        self.assertEqual(info["shape"], "丁四")
        self.assertEqual(info["verdict"], life_death.VERDICT_FIRST_KILL)
        self.assertEqual(info["vital"], (4, 5))  # 要点：丁字交叉点

    def test_knife_five_first_kill(self):
        board = knife_five_board()
        info = find_verdict(board, {(4, 3), (4, 4), (4, 5), (5, 3), (5, 4)})
        self.assertIsNotNone(info)
        self.assertEqual(info["shape"], "刀把五")
        self.assertEqual(info["verdict"], life_death.VERDICT_FIRST_KILL)
        self.assertEqual(info["vital"], (4, 4))  # 要点：刀把中腹

    def test_bent_four_alive(self):
        board = bent_four_board()
        info = find_verdict(board, {(4, 4), (5, 4), (6, 4), (6, 5)})
        self.assertIsNotNone(info)
        self.assertEqual(info["shape"], "曲四")
        self.assertEqual(info["verdict"], life_death.VERDICT_ALIVE)
        self.assertIsNone(info["vital"])

    def test_rectangular_six_alive(self):
        board = rectangular_six_board()
        info = find_verdict(board, {(4, 3), (4, 4), (5, 4)})
        self.assertIsNotNone(info)
        self.assertEqual(info["shape"], "板六")
        self.assertEqual(info["verdict"], life_death.VERDICT_ALIVE)
        self.assertIsNone(info["vital"])

    def test_kill_after_vital_point_played(self):
        # 白先手点杀直三要点后，黑眼位围合区被破坏（(4,3)/(4,5) 边界
        # 混入白子，不再构成黑方围合眼位）——黑无法再做活，直三先手死。
        board = straight_three_board()
        board[4][4] = gr.WHITE
        for point in ((4, 3), (4, 5)):
            info = find_verdict(board, {point}, color=gr.BLACK)
            self.assertIsNone(
                info,
                f"点杀后 {point} 不应再是黑方围合眼位",
            )
        # 黑方全盘不再有任何"先手死/死"眼位区域（外围大空区判大眼位·活，
        # 不构成眼位，无候选——点杀后黑无法再做活）。
        black_regions = [
            info for info in life_death.region_verdicts(board, 9)
            if info["color"] == gr.BLACK
        ]
        self.assertTrue(
            all(info["verdict"] == life_death.VERDICT_ALIVE for info in black_regions),
            "点杀后黑方不应存在可做活/待杀的围合眼位",
        )

    def test_two_real_eyes_alive(self):
        # 黑块两只分离单点真眼（跨区域合计 >= 2）→ 判活，不被点杀。
        board = two_real_eyes_board()
        for point in ((3, 3), (3, 5)):
            self.assertTrue(
                life_death.is_true_eye(board, 9, point, gr.BLACK),
                f"{point} 应为黑真眼",
            )
        for info in life_death.region_verdicts(board, 9):
            if info["color"] == gr.BLACK:
                self.assertEqual(info["verdict"], life_death.VERDICT_ALIVE)
                self.assertIsNone(info["vital"])

    def test_true_eye_requires_all_neighbors_same_color(self):
        board = straight_three_board()
        # 眼位内部点四邻含空点（直三的邻接眼位）→ 非真眼。
        self.assertFalse(life_death.is_true_eye(board, 9, (4, 4), gr.BLACK))


# ---------------------------------------------------------------------------
# 级位识别精度与引擎行为
# ---------------------------------------------------------------------------

class LifeDeathLevelTests(unittest.TestCase):
    def test_level6_recognizes_basic_shapes_only(self):
        # 6 级识别直三/板六（基础型）→ 有点杀候选；曲三不识别 → 无候选。
        ctx = make_ctx(straight_three_board())
        candidates6 = life_death.analyze(ctx, levels.get_level_profile(6))
        self.assertTrue(
            any(cand.tag == "点杀直三" for cand in candidates6),
            "6 级应识别直三",
        )

        ctx_bent = make_ctx(bent_three_board())
        candidates6b = life_death.analyze(ctx_bent, levels.get_level_profile(6))
        self.assertEqual(
            candidates6b, [], "6 级不识别曲三（基础型之外不识别属预期）"
        )

    def test_level5_full_table(self):
        for board, shape in (
            (straight_three_board(), "直三"),
            (bent_three_board(), "曲三"),
            (pyramid_four_board(), "丁四"),
            (knife_five_board(), "刀把五"),
        ):
            ctx = make_ctx(board)
            candidates5 = life_death.analyze(ctx, levels.get_level_profile(5))
            self.assertTrue(
                any(cand.tag == f"点杀{shape}" for cand in candidates5),
                f"5 级应识别{shape}",
            )

    def test_alive_shapes_produce_no_kill_candidates(self):
        for board in (bent_four_board(), rectangular_six_board(), two_real_eyes_board()):
            ctx = make_ctx(board)
            candidates = life_death.analyze(ctx, levels.get_level_profile(5))
            self.assertEqual(
                candidates, [], "活形不应产生点杀/做活候选",
            )

    def test_level5_kills_straight_three(self):
        # 5 级引擎（白）在直三局面下落要点 (4,4)（多固定种子稳定）。
        board = straight_three_board()
        profile = levels.get_level_profile(5)
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, last_move=None,
                rng=random.Random(seed), profile=profile,
            )
            self.assertEqual(
                (choice[0], choice[1]), (4, 4),
                f"种子{seed}：5 级应点杀直三要点",
            )
            self.assertTrue(gr.simulate_move(board, 9, 4, 4, gr.WHITE).ok)

    def test_level6_kills_bent_three_not_recognized(self):
        # 6 级对曲三不识别：不选要点 (4,4)（点杀属 5 级能力）。
        board = bent_three_board()
        profile = levels.get_level_profile(6)
        picked_vital = 0
        for seed in range(10):
            choice = decision.choose_move(
                fresh(board), 9, gr.WHITE, last_move=None,
                rng=random.Random(seed), profile=profile,
            )
            if (choice[0], choice[1]) == (4, 4):
                picked_vital += 1
        # 不识别不保证绝对不碰巧落要点，但稳定点杀要点则说明识别了棋形。
        self.assertLess(picked_vital, 10, "6 级不应稳定点杀曲三（不识别）")

    def test_defensive_vital_point_for_own_group(self):
        # 黑方自己的直三眼位 → 做活要点（先手做活）。
        board = straight_three_board()
        ctx = make_ctx(board, player=gr.BLACK)
        candidates = life_death.analyze(ctx, levels.get_level_profile(5))
        self.assertTrue(
            any(cand.tag == "做活直三" and (cand.row, cand.col) == (4, 4)
                for cand in candidates),
            "5 级（黑）应识别己方直三做活要点",
        )

    def test_level4_abandons_dead_own_group(self):
        # 4 级加强读：己方"直二死型"（先手也做不活）眼位内的落子给负分
        # （填眼自救无效，弃死子）；6 级无此加强读。
        board = straight_two_board()
        ctx = make_ctx(board, player=gr.BLACK)
        candidates = life_death.analyze(ctx, levels.get_level_profile(4))
        tagged = [cand for cand in candidates if cand.tag == "弃死子"]
        self.assertTrue(tagged, "4 级应识别己方死型并弃死子")
        for cand in tagged:
            self.assertIn((cand.row, cand.col), ((4, 3), (4, 4)))
            self.assertLess(cand.score, 0.0)
        # 6 级无"弃死子"加强读（由 4 级局部深算承载）。
        candidates6 = life_death.analyze(ctx, levels.get_level_profile(6))
        self.assertFalse(any(cand.tag == "弃死子" for cand in candidates6))

    def test_low_levels_have_no_life_death_module(self):
        # 10~7 级模块开关不含 life_death（低级位无死活棋形思维）。
        for level in (7, 8, 9, 10):
            profile = levels.get_level_profile(level)
            self.assertNotIn("life_death", profile.modules)
        for level in (4, 5, 6):
            self.assertIn("life_death", levels.get_level_profile(level).modules)


if __name__ == "__main__":
    unittest.main()
