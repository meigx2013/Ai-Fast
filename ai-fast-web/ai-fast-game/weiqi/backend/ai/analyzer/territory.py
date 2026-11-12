"""形势估算分析器（骨架，任务 5 填充）。

规划能力：势力辐射（距离 <= 4 格线性衰减）、空点归属倾向、双方"势力 +
实地"累计估值与形势结论（黑大优/白大优/细棋）。
"""

from .base import Candidate, GameContext


def analyze(ctx: GameContext, profile) -> list[Candidate]:
    """形势维度评分（空实现：任务 5 提供形势判断与全局平衡反馈）。"""
    return []
