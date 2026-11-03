"""服务端围棋规则内核：与前端 index.html 的规则语义严格一致（二维数组版本）。

判定顺序与前端 `play()` 完全一致：
越界/非法 → 占用 → 落子到副本 → 先提相邻无气对方块 → 己方无气(自杀) → 简单劫。

约定：
- 棋盘为 size × size 二维整数数组，0=空、1=黑、2=白。
- 坐标 row、col 均从 0 开始，row 0 在棋盘顶部（与前端 index = row*size + col 一致）。
- 所有函数均不修改调用方传入的棋盘。
- 简单劫语义：拟落子（含提子）后的完整盘面与 `previous_board` 逐点相等即判劫；
  `previous_board` 为 None 表示无劫限制（开局或虚手之后）。
"""

from dataclasses import dataclass

EMPTY, BLACK, WHITE = 0, 1, 2


@dataclass(frozen=True)
class MoveResult:
    """一次落子模拟的结果。ok 为 True 时 board 为落子后的新棋盘（独立副本）。"""

    ok: bool
    reason: str | None = None  # outside / occupied / suicide / ko
    board: list[list[int]] | None = None
    captured: int = 0


def neighbors(row: int, col: int, size: int) -> list[tuple[int, int]]:
    """返回 (row, col) 的上下左右合法邻点。"""
    result: list[tuple[int, int]] = []
    if row > 0:
        result.append((row - 1, col))
    if row < size - 1:
        result.append((row + 1, col))
    if col > 0:
        result.append((row, col - 1))
    if col < size - 1:
        result.append((row, col + 1))
    return result


def get_group(
    board: list[list[int]], size: int, row: int, col: int
) -> tuple[set[tuple[int, int]], set[tuple[int, int]]]:
    """flood-fill 获取 (row, col) 处棋子的同色连通块及该块的全部气。

    返回 (棋子坐标集合, 气坐标集合)。等价于前端 getGroup()。
    """
    color = board[row][col]
    stones = {(row, col)}
    liberties: set[tuple[int, int]] = set()
    stack = [(row, col)]
    while stack:
        current_row, current_col = stack.pop()
        for n_row, n_col in neighbors(current_row, current_col, size):
            value = board[n_row][n_col]
            if value == EMPTY:
                liberties.add((n_row, n_col))
            elif value == color and (n_row, n_col) not in stones:
                stones.add((n_row, n_col))
                stack.append((n_row, n_col))
    return stones, liberties


def count_liberties(board: list[list[int]], size: int, row: int, col: int) -> int:
    return len(get_group(board, size, row, col)[1])


def copy_board(board: list[list[int]]) -> list[list[int]]:
    return [row[:] for row in board]


def simulate_move(
    board: list[list[int]],
    size: int,
    row: int,
    col: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> MoveResult:
    """模拟一次落子，绝不修改 board；返回结构化 MoveResult。

    `previous_board` 为"对方上一手落子前"的完整棋盘，用于简单劫校验。
    """
    # 防御非整数坐标（如模型返回字符串或浮点）；bool 是 int 子类，一并排除。
    if isinstance(row, bool) or isinstance(col, bool) or not isinstance(row, int) or not isinstance(col, int):
        return MoveResult(False, "outside")
    if not (0 <= row < size and 0 <= col < size):
        return MoveResult(False, "outside")
    if board[row][col] != EMPTY:
        return MoveResult(False, "occupied")

    opponent = WHITE if player == BLACK else BLACK
    new_board = copy_board(board)
    new_board[row][col] = player

    # 先检查相邻对方棋块：所有无气棋块均可被这一手提取（与前端顺序一致）。
    captured = 0
    checked: set[tuple[int, int]] = set()
    for n_row, n_col in neighbors(row, col, size):
        if new_board[n_row][n_col] != opponent or (n_row, n_col) in checked:
            continue
        stones, liberties = get_group(new_board, size, n_row, n_col)
        checked.update(stones)
        if not liberties:
            for s_row, s_col in stones:
                new_board[s_row][s_col] = EMPTY
            captured += len(stones)

    # 自杀：提子之后己方棋块（含落子点）仍无气。
    _, own_liberties = get_group(new_board, size, row, col)
    if not own_liberties:
        return MoveResult(False, "suicide")

    # 简单劫：落子并提子后的盘面与上一手之前的盘面完全一致。
    if previous_board is not None and new_board == previous_board:
        return MoveResult(False, "ko")

    return MoveResult(True, None, new_board, captured)


def legal_moves(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> list[tuple[int, int]]:
    """遍历全部空点做完整规则模拟，返回所有合法落点，不遗漏合法点。"""
    moves: list[tuple[int, int]] = []
    for row in range(size):
        for col in range(size):
            if board[row][col] != EMPTY:
                continue
            if simulate_move(board, size, row, col, player, previous_board).ok:
                moves.append((row, col))
    return moves


def has_legal_move(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
) -> bool:
    for row in range(size):
        for col in range(size):
            if board[row][col] != EMPTY:
                continue
            if simulate_move(board, size, row, col, player, previous_board).ok:
                return True
    return False
