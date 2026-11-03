"""Pydantic 请求/响应模型。

字段名与总纲 6.2/6.3 的接口契约保持一致（camelCase 直接作为字段名）。
结构校验由 Pydantic 完成，棋局语义校验（维度、值域、坐标界内）在 model_validator 中统一执行。
"""

from typing import Literal, Union

from pydantic import BaseModel, Field, StrictInt, model_validator

from .config import load_settings


class HealthResponse(BaseModel):
    """GET /api/health 响应，字段与总纲 6.3 严格一致。"""

    status: str = Field(default="ok", description="服务状态，正常为 ok")
    llm: bool = Field(description="模型是否启用（是否配置了有效密钥）")
    model: str = Field(description="模型标识，如 deepseek-v4.1-flash")
    version: str = Field(description="后端版本号")


class MovePoint(BaseModel):
    """棋盘坐标，0 基；StrictInt 拒绝字符串与浮点形式的坐标。"""

    row: StrictInt
    col: StrictInt


def _validate_board_values(board: list[list[int]], size: int, field_name: str) -> None:
    """校验棋盘维度与取值（0=空、1=黑、2=白），错误信息对用户友好。"""
    if len(board) != size:
        raise ValueError(f"{field_name} 必须是 {size}×{size} 的二维数组")
    for index, row in enumerate(board):
        if len(row) != size:
            raise ValueError(f"{field_name} 第 {index} 行长度必须为 {size}")
        for col, value in enumerate(row):
            if value not in (0, 1, 2):
                raise ValueError(f"{field_name}[{index}][{col}] 的值 {value!r} 非法，仅允许 0/1/2")


class AiMoveRequest(BaseModel):
    """POST /api/ai-move 请求体。AI 固定执白（2）。"""

    board: list[list[StrictInt]] = Field(description="当前棋盘，size×size 二维整数数组")
    size: StrictInt = Field(description="棋盘尺寸，仅允许配置中的尺寸（默认 9/13/19）")
    level: StrictInt = Field(ge=1, le=10, description="AI 级位，1 最强、10 最弱")
    moveNumber: StrictInt = Field(default=0, ge=0, description="当前手数")
    lastMove: Union[MovePoint, Literal["pass"], None] = Field(
        default=None, description="上一手：null / \"pass\" / {row,col}"
    )
    previousBoard: Union[list[list[StrictInt]], None] = Field(
        default=None, description="上一手落子前的棋盘，用于服务端简单劫校验；null 表示无劫限制"
    )
    consecutivePasses: StrictInt = Field(default=0, ge=0, le=2, description="连续虚手数")

    @model_validator(mode="after")
    def _validate_game_state(self) -> "AiMoveRequest":
        allowed = load_settings().allowed_sizes
        if self.size not in allowed:
            raise ValueError(f"size 仅支持 {list(allowed)}")
        _validate_board_values(self.board, self.size, "board")
        if self.previousBoard is not None:
            _validate_board_values(self.previousBoard, self.size, "previousBoard")
        if isinstance(self.lastMove, MovePoint) and not (
            0 <= self.lastMove.row < self.size and 0 <= self.lastMove.col < self.size
        ):
            raise ValueError("lastMove 坐标越界")
        return self


class AiMoveResponse(BaseModel):
    """POST /api/ai-move 成功响应。"""

    move: Union[MovePoint, Literal["pass"]] = Field(description='落点 {row,col} 或字符串 "pass"')
    reason: str = Field(description="简要理由")
    elapsedMs: int = Field(ge=0, description="服务端耗时（毫秒）")
    engine: Literal["llm", "heuristic"] = Field(description="实际使用的引擎")
