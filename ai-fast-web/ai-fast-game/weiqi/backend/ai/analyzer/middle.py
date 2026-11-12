"""中盘思维分析器（骨架，任务 5 填充）。

规划能力：弱棋识别与攻击、切断点与连接点价值、打入点（对方大空的三线
渗透）、侵消点（对方厚势边缘的肩冲/镇类轻消点）。
"""

from .base import Candidate, GameContext


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """中盘维度评分（空实现：任务 5 提供切断/攻击/打入侵消）。"""
    return []
