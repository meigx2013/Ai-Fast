"""落子习惯模型（任务 3 已落地：贴身度 + 开局目标点偏好）。

真实级位棋手的"手癖"：低级位贴身缠绕近战（10 级贴身度 1.5），
高级位更看全局（贴身度渐降）。本模块的输出并入决策器融合评分。

- attachment_score：与上一手距离的偏好评分（由 v1 proximity 维度平移）；
- opening_target_bonus：开局阶段（前 12 手）对目标类别的加分，
  目标类别由 LevelProfile.habit_weights.opening_targets 给出：
  * "star-area"   星位（含天元）±1 区域——10 级"随机星位附近"；
  * "third-line"  三线——10 级"任意三线点" / 9 级"开始走三线"；
  * "fourth-line" 四线——9 级三线四线偏好；
  * "corner"      空角星位/三三 ±1 区域——8 级"优先空角星位/三三"、
                  7 级"空角→边顺序"的占角目标（角区无子才加分）；
  * "side"        三线四线的边要点（角区外）——7 级"空角→挂角→拆边"
                  顺序中的拆边目标。
"""

from ..go_rules import EMPTY
from .analyzer.base import GameContext

# 开局阶段判定：前 12 手内目标点偏好生效（此后进入中盘思维）。
OPENING_MOVE_LIMIT = 12


def attachment_score(ctx: GameContext, row: int, col: int, attachment: float) -> float:
    """贴身度评分：与上一手越近分越高（距离超过 5 格后为 0）。

    attachment 为级位习惯权重（habit_weights.attachment），数值越大越"贴身"。
    last_move 为 None（开局/虚手后）时无贴身倾向。
    """
    if ctx.last_move is None:
        return 0.0
    last_row, last_col = ctx.last_move
    distance = abs(row - last_row) + abs(col - last_col)
    return max(0.0, 10.0 - distance * 1.8) * attachment


def _line_of(row: int, col: int, size: int) -> int:
    """到最近边的"线数"：0=一线，1=二线，2=三线，以此类推。"""
    return min(row, col, size - 1 - row, size - 1 - col)


def _star_offset(size: int) -> int:
    """星位到边的线数（0 基）：13/19 路为三线（0 基 3），9 路为二线（0 基 2）。"""
    return 3 if size >= 13 else 2


def star_points(size: int) -> list[tuple[int, int]]:
    """全部星位（含天元，奇数路盘）。"""
    offset = _star_offset(size)
    points = [
        (offset, offset),
        (offset, size - 1 - offset),
        (size - 1 - offset, offset),
        (size - 1 - offset, size - 1 - offset),
    ]
    if size % 2 == 1:
        points.append((size // 2, size // 2))
    return points


def corner_zones(size: int) -> list[set[tuple[int, int]]]:
    """四个角的"星位/三三 ±1"目标区域（空角占角习惯的目标点集合）。"""
    offset = _star_offset(size)
    zones: list[set[tuple[int, int]]] = []
    for top in (True, False):
        for left in (True, False):
            star = (offset if top else size - 1 - offset,
                    offset if left else size - 1 - offset)
            san_san = (2 if top else size - 3,
                       2 if left else size - 3)
            zone: set[tuple[int, int]] = set()
            for base_row, base_col in (star, san_san):
                for d_row in (-1, 0, 1):
                    for d_col in (-1, 0, 1):
                        row, col = base_row + d_row, base_col + d_col
                        if 0 <= row < size and 0 <= col < size:
                            zone.add((row, col))
            zones.append(zone)
    return zones


def _zone_is_empty(ctx: GameContext, zone: set[tuple[int, int]]) -> bool:
    """角区内无任何棋子才算"空角"（占角目标才加分）。"""
    return all(ctx.board[row][col] == EMPTY for row, col in zone)


def opening_target_bonus(
    ctx: GameContext, row: int, col: int, targets: tuple[str, ...]
) -> tuple[float, str]:
    """开局阶段目标点加分，返回 (加分, 标签)；非开局或无匹配时为 (0.0, "")。

    targets 按优先顺序排列（前者先命中）；所有随机性不在此引入，
    偏好仅是确定性的加分项。
    """
    if not targets or ctx.move_number > OPENING_MOVE_LIMIT:
        return 0.0, ""
    size = ctx.size
    line = _line_of(row, col, size)
    zones = corner_zones(size)
    for target in targets:
        if target == "corner":
            for zone in zones:
                if (row, col) in zone and _zone_is_empty(ctx, zone):
                    return 25.0, "开局占角"
        elif target == "side":
            in_corner = any((row, col) in zone for zone in zones)
            if line in (2, 3) and not in_corner:
                return 8.0, "拆边要点"
        elif target == "star-area":
            for star_row, star_col in star_points(size):
                if abs(row - star_row) <= 1 and abs(col - star_col) <= 1:
                    return 6.0, "占星位附近"
        elif target == "third-line":
            if line == 2:
                return 6.0, "走三线"
        elif target == "fourth-line":
            if line == 3:
                return 5.0, "走四线"
    return 0.0, ""
