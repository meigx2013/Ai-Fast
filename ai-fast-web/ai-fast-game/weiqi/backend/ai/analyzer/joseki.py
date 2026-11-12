"""定式思维分析器（任务 4：基础角部定式库，4~5 级启用）。

定式库设计：
- 每个定式 = 角部锚定的相对坐标序列（黑白交替），按棋盘星位偏移
  s = star_offset(size) 参数化（13/19 路 s=3、9 路 s=2）；
- 匹配：对四个角 × 水平/垂直镜像变换，把序列映射为绝对坐标；
  角部盒子（边长 2s+3）内的实际棋子须与序列前缀逐手一致（颜色与
  位置），且盒子内无前缀之外的棋子（形状纯净，防误匹配）；
- 命中条件：前缀长度 >= 2（至少完成"占角 + 挂角"），且下一手属于
  己方（与 ctx.player 一致）时，按序列应手（下一手坐标）；
- 生效窗口：开局前 10 手（move_number <= 10，04_prompt 约定）；
- 6 级不识定式（modules 不含 joseki，决策器根本不调用本模块）。

收录 6 个基础定式（简化序列，以形状合理为先）：
1. 星位小飞挂定式：星 → 小飞挂 → 小飞应 → 拆边；
2. 星位一间跳定式：星 → 小飞挂 → 一间跳应 → 拆边；
3. 小目挂角托退定式：小目 → 低挂 → 挡 → 退 → 虎；
4. 三三挂角简明定式：三三 → 一间高挂 → 顶 → 退；
5. 星位三三渗透定式：星 → 挂 → 三三打入 → 挡 → 爬；
6. 小目高挂定式：小目 → 高挂 → 飞应 → 拆。
"""

from ...go_rules import EMPTY
from .base import Candidate, GameContext

# 定式应手的基础分：与点杀急所同量级——中级位"按型走"的可靠度。
JOSEKI_SCORE = 50.0
# 生效窗口：开局前 10 手。
JOSEKI_MOVE_LIMIT = 10


def star_offset(size: int) -> int:
    """星位到边的线数（0 基）：13/19 路为 3，9 路为 2。"""
    return 3 if size >= 13 else 2


# 序列用 (d_row, d_col, 颜色) 相对角锚点（角为 (0,0) 方向）表示，
# d 均为非负，镜像变换负责翻到其它三个角。颜色 1=黑 2=白。
def _sequences(s: int) -> list[tuple[str, list[tuple[int, int, int]]]]:
    return [
        ("星位小飞挂", [
            (s, s, 1),          # 黑占星位
            (s + 2, s - 1, 2),  # 白小飞挂
            (s + 2, s + 1, 1),  # 黑小飞应
            (s + 4, s - 1, 2),  # 白拆边
        ]),
        ("星位一间跳", [
            (s, s, 1),
            (s + 2, s - 1, 2),
            (s - 1, s + 2, 1),  # 黑一间跳应（朝中腹方向）
            (s + 4, s - 1, 2),
        ]),
        ("小目托退", [
            (s - 1, s, 1),          # 黑占小目
            (s + 1, s - 2, 2),      # 白低挂（托向小目）
            (s + 1, s + 1, 1),      # 黑外挡
            (s + 2, s - 2, 2),      # 白退
            (s + 3, s - 2, 1),      # 黑虎
        ]),
        ("三三简明", [
            (s - 1, s - 1, 1),  # 黑占三三
            (s - 3, s, 2),      # 白一间高挂
            (s - 2, s + 1, 1),  # 黑顶
            (s - 3, s + 2, 2),  # 白退
        ]),
        ("星三三渗透", [
            (s, s, 1),          # 黑占星位
            (s + 2, s - 1, 2),  # 白挂角
            (s - 1, s - 1, 1),  # 黑三三渗透
            (s - 2, s, 2),      # 白挡角
            (s - 1, s + 1, 1),  # 黑爬出
        ]),
        ("小目高挂", [
            (s - 1, s, 1),      # 黑占小目
            (s - 2, s + 1, 2),  # 白高挂
            (s + 1, s - 1, 1),  # 黑飞应
            (s + 3, s - 1, 2),  # 白拆边
        ]),
    ]


def _corner_boxes(size: int) -> list[tuple[int, int, int, int, int, int]]:
    """四个角盒子的参数：[(corner_r, corner_c, r_dir, c_dir, rows, cols)]。

    盒子以角为原点，边长 2s+3；r_dir/c_dir 为相对角的方向（+1 或 -1）。
    """
    s = star_offset(size)
    span = 2 * s + 3
    boxes = []
    for corner_r, r_dir in ((0, 1), (size - 1, -1)):
        for corner_c, c_dir in ((0, 1), (size - 1, -1)):
            boxes.append((corner_r, corner_c, r_dir, c_dir, span, span))
    return boxes


def _abs(corner_r: int, corner_c: int, r_dir: int, c_dir: int, d_r: int, d_c: int):
    return corner_r + r_dir * d_r, corner_c + c_dir * d_c


def match_joseki(
    board: list[list[int]], size: int, move_number: int, player: int
) -> list[tuple[str, tuple[int, int]]]:
    """全盘角部定式匹配，返回 [(定式名, 己方下一手绝对坐标)]。

    逐角 × 逐序列：序列前缀须与角盒内实际棋子完全一致（颜色+位置），
    角盒内不得有多余棋子；下一手颜色须为 player。开局 10 手后不再命中。
    """
    if move_number > JOSEKI_MOVE_LIMIT:
        return []
    hits: list[tuple[str, tuple[int, int]]] = []
    s = star_offset(size)
    sequences = _sequences(s)

    for corner_r, corner_c, r_dir, c_dir, span_r, span_c in _corner_boxes(size):
        # 角盒内的全部棋子。
        box_stones: dict[tuple[int, int], int] = {}
        for d_r in range(span_r):
            for d_c in range(span_c):
                row, col = _abs(corner_r, corner_c, r_dir, c_dir, d_r, d_c)
                if 0 <= row < size and 0 <= col < size and board[row][col] != EMPTY:
                    box_stones[(row, col)] = board[row][col]
        if not box_stones:
            continue

        for name, seq in sequences:
            prefix = {
                _abs(corner_r, corner_c, r_dir, c_dir, d_r, d_c): color
                for d_r, d_c, color in seq
            }
            placed = list(prefix.items())
            # 已落子的序列长度。
            matched = 0
            for point, color in placed:
                if box_stones.get(point) == color:
                    matched += 1
                else:
                    break
            if matched < 2:
                continue  # 至少"占角 + 挂角"完成
            if set(box_stones) != {p for p, _c in placed[:matched]}:
                continue  # 角盒内有前缀之外的棋子：形状不纯净
            if matched >= len(seq):
                continue  # 序列已完成
            next_d = seq[matched]
            if next_d[2] != player:
                continue  # 下一手轮到对方
            row, col = _abs(corner_r, corner_c, r_dir, c_dir, next_d[0], next_d[1])
            if 0 <= row < size and 0 <= col < size and board[row][col] == EMPTY:
                hits.append((name, (row, col)))
    return hits


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """定式维度评分：命中的定式下一手加分并打"定式应手"标签。"""
    results: list[Candidate] = []
    candidate_keys = {(row, col) for row, col, _result in ctx.candidates}
    for _name, point in match_joseki(ctx.board, ctx.size, ctx.move_number, ctx.player):
        if point in candidate_keys:
            results.append(Candidate(
                row=point[0], col=point[1], score=JOSEKI_SCORE, tag="定式应手",
            ))
    return results
