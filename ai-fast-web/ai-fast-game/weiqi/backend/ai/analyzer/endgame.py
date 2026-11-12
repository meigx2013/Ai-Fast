"""官子思维分析器（骨架，任务 5 填充）。

规划能力：边界空点官子枚举、先手判定、大小估算与收官顺序策略
（先手官子全部收完 → 按大小收后手官子，2 级以上启用）。
"""

from .base import Candidate, GameContext


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """官子维度评分（空实现：任务 5 提供先手判定与大小排序）。"""
    return []
