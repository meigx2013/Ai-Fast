"""布局思维分析器（任务 4 完整能力：任务 2 雏形扩展）。

布局成形能力（6 级起解锁，10~7 级仅有雏形维度）：
1. 角部价值矩阵：星 / 小目 / 三三 / 目外 / 高目五类开局点按棋盘进度
   （开局窗口内）给价值——空角越早价值越高；
2. 挂角响应：对方占角后的合理挂角点（小飞挂/低挂，与角上对方子保持
   适当距离、不贴身）；
3. 守角：己方占角后的守角点（小飞守角/一间跳守角）；
4. 拆边价值：沿三线/四线向中腹方向展开的间距选择（本手拆二/拆三，
   与己方棋子成合适间隔且无对方棋子阻隔）；
5. 大场排序：空角（最高）> 挂角/守角 > 拆边 > 中腹（基础位置分承载）。

能力门控（布局成形与死活思维同期解锁，6 级起）：
`"life_death" in profile.modules` 作为"布局成形"开关——10~7 级的布局
行为仍由 habits 开局目标点承载（任务 3 校准的行为不受影响）；基线档案
（profile=None）不含该开关，保持 v1 行为。

任务 2 平移的基础维度（所有级位保留）：
- 位置价值：一线亏损、三线四线好、中腹略有价值（围空意识雏形）；
- 联络（邻点己方子）与接触战（邻点对方子）。
"""

from ... import go_rules
from ...go_rules import BLACK, EMPTY, WHITE
from .base import Candidate, GameContext


def _line_of(row: int, col: int, size: int) -> int:
    """到最近边的"线数"：0=一线，1=二线，2=三线，以此类推。"""
    return min(row, col, size - 1 - row, size - 1 - col)


def _star_offset(size: int) -> int:
    """星位到边的线数（0 基）：13/19 路为 3，9 路为 2。"""
    return 3 if size >= 13 else 2


_LINE_SCORES = {0: -20.0, 1: -8.0, 2: 15.0, 3: 12.0}

# 布局成形窗口：占角/挂角/守角/拆边加分仅在开局窗口内生效
# （此后进入中盘思维，官子与打入由后续模块承载）。
_OPENING_WINDOW = 16


def _corner_key_points(s: int) -> list[tuple[int, int, float, str]]:
    """角部五类开局点价值矩阵：[(d_row, d_col, 价值, 标签)]。

    - 小目 (s-1, s)/(s, s-1)：实地与发展的平衡，价值最高；
    - 星 (s, s)：速度最快；
    - 三三 (s-1, s-1)：一手占角实地；
    - 目外 (s, s+1)：取外势；
    - 高目 (s-1, s+1)：高位取势。
    """
    return [
        (s - 1, s, 32.0, "占小目"),
        (s, s - 1, 32.0, "占小目"),
        (s, s, 30.0, "占星位"),
        (s - 1, s - 1, 28.0, "占三三"),
        (s, s + 1, 24.0, "占目外"),
        (s + 1, s, 24.0, "占目外"),
        (s - 1, s + 1, 23.0, "占高目"),
        (s + 1, s - 1, 23.0, "占高目"),
    ]


def _corner_box(size: int, corner_r: int, corner_c: int, r_dir: int, c_dir: int, span: int):
    """角盒子的绝对坐标集合与角锚点方向工具。"""
    points: set[tuple[int, int]] = set()
    for d_r in range(span):
        for d_c in range(span):
            row = corner_r + r_dir * d_r
            col = corner_c + c_dir * d_c
            if 0 <= row < size and 0 <= col < size:
                points.add((row, col))
    return points


def _corners(size: int) -> list[tuple[int, int, int, int]]:
    """四个角：(corner_r, corner_c, r_dir, c_dir)。"""
    return [
        (0, 0, 1, 1),
        (0, size - 1, 1, -1),
        (size - 1, 0, -1, 1),
        (size - 1, size - 1, -1, -1),
    ]


def _corner_stone_in_zone(board, size, zone: set[tuple[int, int]], color: int):
    """角区内是否存在 color 的棋子。"""
    return any(board[r][c] == color for r, c in zone)


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """对全部合法候选做位置价值/联络 + 布局成形评分，返回带标签的候选。"""
    weights = profile.weights
    player = ctx.player
    opponent = WHITE if player == BLACK else BLACK
    board = ctx.board
    size = ctx.size
    results: list[Candidate] = []
    # 布局成形能力开关：6 级起（与死活思维同期解锁）；基线/低级位不启用。
    formed = "life_death" in profile.modules
    in_opening_window = ctx.move_number <= _OPENING_WINDOW

    # ---- 布局成形的角部静态分析（每次 analyze 一遍）----
    # key_point_bonus: 绝对坐标 -> (价值, 标签)。
    key_point_bonus: dict[tuple[int, int], tuple[float, str]] = {}
    if formed and in_opening_window:
        s = _star_offset(size)
        span = 2 * s + 2
        for corner_r, corner_c, r_dir, c_dir in _corners(size):
            zone = _corner_box(size, corner_r, corner_c, r_dir, c_dir, span)
            own_in_zone = _corner_stone_in_zone(board, size, zone, player)
            opp_in_zone = _corner_stone_in_zone(board, size, zone, opponent)
            if not own_in_zone and not opp_in_zone:
                # 空角：五类开局点按价值矩阵加分（大场之最）。
                for d_r, d_c, value, label in _corner_key_points(s):
                    row = corner_r + r_dir * d_r
                    col = corner_c + c_dir * d_c
                    if 0 <= row < size and 0 <= col < size:
                        key_point_bonus.setdefault((row, col), (value, label))
            elif opp_in_zone and not own_in_zone:
                # 对方占角：挂角点（小飞挂，与对方角子成小飞间距）。
                for d_r, d_c, value, label in (
                    (s + 2, s - 1, 26.0, "挂角"),
                    (s - 1, s + 2, 26.0, "挂角"),
                    (s + 1, s - 2, 24.0, "低挂"),
                ):
                    row = corner_r + r_dir * d_r
                    col = corner_c + c_dir * d_c
                    if 0 <= row < size and 0 <= col < size:
                        key_point_bonus.setdefault((row, col), (value, label))
            elif own_in_zone and not opp_in_zone:
                # 己方占角：守角点（小飞守/一间跳守）。
                for d_r, d_c, value, label in (
                    (s + 2, s + 1, 27.0, "守角"),
                    (s + 1, s + 2, 27.0, "守角"),
                    (s + 2, s - 1, 25.0, "小飞守角"),
                    (s - 1, s + 2, 25.0, "小飞守角"),
                ):
                    row = corner_r + r_dir * d_r
                    col = corner_c + c_dir * d_c
                    if 0 <= row < size and 0 <= col < size:
                        key_point_bonus.setdefault((row, col), (value, label))

    # ---- 拆边分析：己方三线/四线棋子沿边方向的目标展开点 ----
    extension_bonus: dict[tuple[int, int], tuple[float, str]] = {}
    if formed and in_opening_window:
        for row, col, _move_result in ctx.candidates:
            line = _line_of(row, col, size)
            if line not in (2, 3):
                continue
            # 四个正交方向找最近的己方棋子（同线或邻线，距离 2~3 为拆）。
            for delta_r, delta_c in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                for dist in (2, 3):
                    base_r, base_c = row - delta_r * dist, col - delta_c * dist
                    if not (0 <= base_r < size and 0 <= base_c < size):
                        continue
                    if board[base_r][base_c] != player:
                        continue
                    base_line = _line_of(base_r, base_c, size)
                    if base_line not in (2, 3):
                        continue
                    # 中间不得有对方棋子（阻隔则非"拆"而是侵入接触）。
                    blocked = False
                    for step in range(1, dist):
                        mid_r = base_r + delta_r * step
                        mid_c = base_c + delta_c * step
                        if board[mid_r][mid_c] == opponent:
                            blocked = True
                            break
                    if blocked:
                        continue
                    # 与己方棋子距离 2（拆二）/ 3（拆三），与最近对方子保持
                    # 一格以上安全距离。
                    value = 22.0 if dist == 2 else 18.0
                    label = "拆二" if dist == 2 else "拆三"
                    current = extension_bonus.get((row, col))
                    if current is None or current[0] < value:
                        extension_bonus[(row, col)] = (value, label)
                    break  # 同一方向找到最近己方子即止

    for row, col, _move_result in ctx.candidates:
        score = 0.0
        tag = "占据要点"

        # 位置价值：一线亏损、三线四线好、中腹略有价值（所有级位）。
        line = _line_of(row, col, size)
        score += _LINE_SCORES.get(line, 5.0) * weights.position

        # 联络（邻点己方子）与接触战（邻点对方子）（所有级位）。
        same_count = 0
        contact_count = 0
        for n_row, n_col in go_rules.neighbors(row, col, size):
            value = board[n_row][n_col]
            if value == player:
                same_count += 1
            elif value == opponent:
                contact_count += 1
        score += (same_count * 7.0 + contact_count * 4.0) * weights.connection

        # 布局成形（6 级起）：角部价值矩阵 / 挂角 / 守角 / 拆边。
        if formed and in_opening_window:
            bonus, label = key_point_bonus.get((row, col), (0.0, ""))
            if bonus > 0.0:
                score += bonus * weights.position
                tag = label
            ext_bonus, ext_label = extension_bonus.get((row, col), (0.0, ""))
            if ext_bonus > 0.0:
                score += ext_bonus * weights.position
                if bonus <= 0.0:
                    tag = ext_label

        results.append(Candidate(row=row, col=col, score=score, tag=tag))

    return results
