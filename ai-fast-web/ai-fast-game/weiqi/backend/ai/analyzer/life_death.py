"""死活思维分析器（任务 4 完整棋形库 + 任务 3 骨架能力）。

能力分层：
- 骨架（任务 3，任何级位复用）：
  * atari_groups(board, size, color)：一方 1 气连通块清单（"告警"来源）；
  * dead_stones(board, size, color)：气 <= 1 必死（结算死子建议的最底层）。
- 棋形库（任务 4，6~4 级模块开关 life_death 解锁）：
  * 真眼判定：眼位点的四邻（在盘内者）均为本块同色 → 真眼；
  * 眼位区域提取：flood-fill 空区，边界棋子全为同色 → 该色的"围空眼位"；
  * 常见死活棋形结论表（对眼位区域做形状匹配后查表）：
      直三 / 曲三 / 丁四 / 刀把五 → "先手死"（对方先手点杀则死，己方先手做活）
      曲四 / 直四 / 板六 / 更大眼位 → "活"
      眼位 <= 2 点（一眼/直二）→ "死"（先手也做不活）
  * 级位识别精度：6 级仅识别基础型（直三/板六），其余棋形"不识"；
    5 级全表；4 级全表 + 局部加强读（识别"死"型 → 弃死子，不给救援加分）。
- analyze()：对 6~4 级输出两类候选——
  * 点杀：对方"先手死"眼位的要点（急所）；
  * 做活：己方"先手死"眼位的要点（先手做活）。

工程近似边界（04_prompt 范围声明）：不做打劫死活、不精确判定畸形盘面；
中间态（气 >= 3 无两眼且无围空眼位）交由用户在结算前修正（任务 6）。
"""

from ... import go_rules
from ...go_rules import BLACK, EMPTY, WHITE
from .base import Candidate, GameContext

# 棋形结论表：形状名 -> (结论, 说明)
# 结论取值："活" / "先手死"（对方先手点杀则死）/ "死"（先手也做不活）。
VERDICT_ALIVE = "活"
VERDICT_FIRST_KILL = "先手死"
VERDICT_DEAD = "死"

# 6 级识别的基础棋形（其余形状 6 级"不识"——真实 6 级棋力边界）。
BASIC_SHAPES = frozenset({"直三", "板六"})

# 棋形要点（做活/点杀急所）与结论的统一分数：死活急所价值与叫吃同量级，
# 低于提子（120），高于普通联络——任何解锁死活思维的级位都不该漏。
VITAL_POINT_SCORE = 62.0
# 4 级加强读：己方"死"型（先手也做不活）的邻点救援负分（弃死子思维）。
DEAD_GROUP_RESCUE_PENALTY = -55.0


def atari_groups(
    board: list[list[int]], size: int, color: int
) -> list[tuple[set[tuple[int, int]], tuple[int, int]]]:
    """返回 color 方所有只剩 1 口气的连通块：[(棋子坐标集合, 唯一气点)]。"""
    result: list[tuple[set[tuple[int, int]], tuple[int, int]]] = []
    seen: set[tuple[int, int]] = set()
    for row in range(size):
        for col in range(size):
            if board[row][col] != color or (row, col) in seen:
                continue
            stones, liberties = go_rules.get_group(board, size, row, col)
            seen.update(stones)
            if len(liberties) == 1:
                result.append((stones, next(iter(liberties))))
    return result


def dead_stones(
    board: list[list[int]], size: int, color: int | None = None
) -> list[tuple[set[tuple[int, int]], tuple[int, int], int]]:
    """气数 <= 1 的棋块（必死若不逃/不被救）：[(棋子集合, 唯一气点, 颜色)]。"""
    colors = (BLACK, WHITE) if color is None else (color,)
    result: list[tuple[set[tuple[int, int]], tuple[int, int], int]] = []
    for stone_color in colors:
        for stones, liberty in atari_groups(board, size, stone_color):
            result.append((stones, liberty, stone_color))
    return result


# ---------------------------------------------------------------------------
# 真眼判定与眼位区域提取
# ---------------------------------------------------------------------------

def is_true_eye(
    board: list[list[int]], size: int, point: tuple[int, int], color: int
) -> bool:
    """真眼判定：point 为空点，其四邻（在盘内者）均为 color 同色棋子。

    棋盘边缘方向视为"壁"（天然封闭）；假眼（对角被断等）不做精细区分，
    属工程近似（04_prompt 范围声明）。
    """
    row, col = point
    if board[row][col] != EMPTY:
        return False
    for n_row, n_col in go_rules.neighbors(row, col, size):
        if board[n_row][n_col] != color:
            return False
    return True


def enclosed_eye_regions(
    board: list[list[int]], size: int
) -> list[tuple[int, set[tuple[int, int]]]]:
    """提取"围空眼位"区域：边界棋子全为同一色的空区。

    返回 [(该色, 空点集合)]。数子结算（任务 6）与棋形库共用本能力：
    一个区域属于某一色，意味着该区域只能为该色棋块提供眼位。
    """
    visited: set[tuple[int, int]] = set()
    regions: list[tuple[int, set[tuple[int, int]]]] = []
    for row in range(size):
        for col in range(size):
            if board[row][col] != EMPTY or (row, col) in visited:
                continue
            # flood-fill 一个完整空区，同时收集边界棋子颜色。
            region: set[tuple[int, int]] = set()
            border_colors: set[int] = set()
            stack = [(row, col)]
            while stack:
                cur_row, cur_col = stack.pop()
                if (cur_row, cur_col) in region:
                    continue
                region.add((cur_row, cur_col))
                for n_row, n_col in go_rules.neighbors(cur_row, cur_col, size):
                    value = board[n_row][n_col]
                    if value == EMPTY:
                        if (n_row, n_col) not in region:
                            stack.append((n_row, n_col))
                    else:
                        border_colors.add(value)
            visited.update(region)
            if len(border_colors) == 1:
                regions.append((next(iter(border_colors)), region))
    return regions


def true_eye_points(
    board: list[list[int]], size: int, color: int, region: set[tuple[int, int]]
) -> list[tuple[int, int]]:
    """区域内属于 color 的真眼点清单（眼位点四邻均为 color）。"""
    return [p for p in region if is_true_eye(board, size, p, color)]


# ---------------------------------------------------------------------------
# 棋形库：形状匹配 + 结论表
# ---------------------------------------------------------------------------

def _region_adjacency(region: set[tuple[int, int]]) -> dict[tuple[int, int], int]:
    """区域内每点的区域内正交邻接数（用于丁四/曲三/直三等结构判别）。"""
    adjacency: dict[tuple[int, int], int] = {}
    for row, col in region:
        adjacency[(row, col)] = sum(
            1
            for delta_row, delta_col in ((-1, 0), (1, 0), (0, -1), (0, 1))
            if (row + delta_row, col + delta_col) in region
        )
    return adjacency


def classify_region(
    region: set[tuple[int, int]],
) -> tuple[str, str, tuple[int, int] | None]:
    """对眼位区域做形状匹配，返回 (形状名, 结论, 要点)。

    结论表（常见死活棋形库）：
    - 眼位 1~2 点（一眼/直二）→ "死"（先手也做不活），要点为任一空点；
    - 直三 / 曲三（3 点）→ "先手死"，要点为眼位中的结构点（直三中点/曲三拐点）；
    - 丁四（4 点 T 形，存在 3 邻接点）→ "先手死"，要点为丁字交叉点；
    - 曲四 / 直四（其余 4 点）→ "活"，无要点；
    - 刀把五（5 点，包围盒 3×2 缺一角的"刀把"形）→ "先手死"，
      要点为包围盒中缺失的那一点；
    - 直五（1×5 一线）→ "活"；
    - 板六（2×3 矩形满六点）→ "活"；
    - 其余 >= 5 点的大眼位 → "活"（工程近似：大眼位通常能做出两眼）。
    """
    count = len(region)
    if count == 0:
        return "无眼位", VERDICT_DEAD, None
    if count <= 2:
        return "直二" if count == 2 else "一眼", VERDICT_DEAD, next(iter(region))

    adjacency = _region_adjacency(region)
    rows = [r for r, _c in region]
    cols = [c for _r, c in region]
    row_span = max(rows) - min(rows) + 1
    col_span = max(cols) - min(cols) + 1

    if count == 3:
        if row_span == 1 or col_span == 1:
            # 直三：一线三点，要点为中点（邻接数 2）。
            vital = next(p for p, degree in adjacency.items() if degree == 2)
            return "直三", VERDICT_FIRST_KILL, vital
        # 曲三：拐形三点，要点为拐点（邻接数 2）。
        vital = next(p for p, degree in adjacency.items() if degree == 2)
        return "曲三", VERDICT_FIRST_KILL, vital

    if count == 4:
        if 3 in adjacency.values():
            # 丁四：存在三邻接的交叉点。
            vital = next(p for p, degree in adjacency.items() if degree == 3)
            return "丁四", VERDICT_FIRST_KILL, vital
        # 直四（一线）与曲四（弯形）均为活形。
        name = "直四" if row_span == 1 or col_span == 1 else "曲四"
        return name, VERDICT_ALIVE, None

    if count == 5:
        if row_span == 1 or col_span == 1:
            return "直五", VERDICT_ALIVE, None
        # 结构判别：存在三邻接以上的"中腹"点 → 刀把五/梅花五类
        # （点杀后拆成直三/曲三 + 单点，先手死）；要点即该中腹点。
        max_point, max_degree = max(adjacency.items(), key=lambda kv: kv[1])
        if max_degree >= 3:
            return "刀把五", VERDICT_FIRST_KILL, max_point
        # 弯五（之字五连）：拆不断成死形，视为活（工程近似）。
        return "弯五", VERDICT_ALIVE, None

    if count == 6:
        rows_sorted = sorted({r for r, _c in region})
        cols_sorted = sorted({c for _r, c in region})
        if row_span == 2 and col_span == 3 and len(rows_sorted) == 2 and len(cols_sorted) == 3:
            return "板六", VERDICT_ALIVE, None
        if row_span == 3 and col_span == 2 and len(rows_sorted) == 3 and len(cols_sorted) == 2:
            return "板六", VERDICT_ALIVE, None

    return "大眼位", VERDICT_ALIVE, None


def region_verdicts(
    board: list[list[int]], size: int
) -> list[dict]:
    """全盘眼位区域的棋形结论清单（棋形库入口，供 analyze 与测试复用）。

    每项：{color, region, shape, verdict, vital, eyes}（eyes=真眼点数）。
    判活优先级：
    1. 区域内 >= 2 只分离真眼 → 活（"两真眼"）；
    2. 同色跨区域真眼点合计 >= 2（两只分离的单点真眼分属不同空区）→ 该色
       各含真眼的小区域判活（真实棋形：两眼活棋，眼位分居两个空区）；
    3. 其余按形状匹配查棋形结论表。
    """
    raw: list[tuple[int, set, list]] = []
    for color, region in enclosed_eye_regions(board, size):
        eyes = true_eye_points(board, size, color, region)
        raw.append((color, region, eyes))
    eye_totals: dict[int, int] = {}
    for color, _region, eyes in raw:
        eye_totals[color] = eye_totals.get(color, 0) + len(eyes)

    results: list[dict] = []
    for color, region, eyes in raw:
        if len(eyes) >= 2 or (eyes and eye_totals.get(color, 0) >= 2):
            shape, verdict, vital = "两真眼", VERDICT_ALIVE, None
        else:
            shape, verdict, vital = classify_region(region)
        results.append({
            "color": color,
            "region": region,
            "shape": shape,
            "verdict": verdict,
            "vital": vital,
            "eyes": eyes,
        })
    return results


def _shape_recognized(shape: str, level: int) -> bool:
    """级位识别精度：6 级仅基础型（直三/板六），5 级起全表。"""
    if level >= 6:
        return shape in BASIC_SHAPES
    return True


# ---------------------------------------------------------------------------
# analyze：点杀 / 做活 / 弃死子 候选
# ---------------------------------------------------------------------------

def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """死活维度评分：眼位区域形状匹配后，按级位识别精度输出急所候选。

    - 对方"先手死"眼位 → 点杀要点（VITAL_POINT_SCORE）；
    - 己方"先手死"眼位 → 做活要点（VITAL_POINT_SCORE，"先手做活"）；
    - 4 级加强读：己方"死"型（一眼/直二）邻点给负分（弃死子，救援无意义）；
    - 6 级不识别非基础棋形（BASIC_SHAPES 之外的形状不产生候选）。
    """
    level = profile.level
    if level > 6:
        return []  # 10~7 级无死活棋形思维（模块开关也不含 life_death）

    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    candidate_keys = {(row, col) for row, col, _result in ctx.candidates}
    results: list[Candidate] = []

    for info in region_verdicts(ctx.board, ctx.size):
        verdict = info["verdict"]
        shape = info["shape"]
        vital = info["vital"]
        if not _shape_recognized(shape, level):
            continue  # 6 级不识定式之外的棋形（真实棋力边界）

        if verdict == VERDICT_FIRST_KILL and vital is not None:
            if vital in candidate_keys:
                if info["color"] == opponent:
                    results.append(Candidate(
                        row=vital[0], col=vital[1],
                        score=VITAL_POINT_SCORE, tag=f"点杀{shape}",
                    ))
                else:
                    results.append(Candidate(
                        row=vital[0], col=vital[1],
                        score=VITAL_POINT_SCORE, tag=f"做活{shape}",
                    ))

        # 4 级局部加强读：己方"死"型（先手也做不活）→ 弃死子。
        # 惩罚覆盖"死型眼位区域内及其相邻"的候选（在眼位内填子/贴眼位
        # 救援均为无效自救）。
        if level <= 4 and verdict == VERDICT_DEAD and info["color"] == player:
            dead_area = info["region"]
            for row, col, _move_result in ctx.candidates:
                if (row, col) in dead_area or any(
                    (n_row, n_col) in dead_area
                    for n_row, n_col in go_rules.neighbors(row, col, ctx.size)
                ):
                    results.append(Candidate(
                        row=row, col=col,
                        score=DEAD_GROUP_RESCUE_PENALTY, tag="弃死子",
                    ))

    return results
