"""思维方式模块库（analyzer）：承载各级位棋手的"会什么"。

每个模块遵守统一签名（见 base.py）：
    analyze(ctx, profile) -> list[Candidate]

模块清单与启用级位（见 04_prompt.md 级位思维方式模型）：
- capture     提子/叫吃/逃吃/对杀气数（所有级位启用）
- opening     布局：位置价值/占角/挂角/拆边（所有级位启用，能力随级位增强）
- life_death  死活棋形（任务 3 骨架 / 任务 4 棋形库）
- ladder      征子判断（任务 4）
- tesuji      手筋：双打吃/关门吃/扑/接不归（任务 4）
- joseki      基础定式库（任务 4）
- middle      中盘：切断/攻击/打入侵消（任务 5）
- endgame     官子：先手判定/大小排序/收官顺序（任务 5）
- territory   形势估算（任务 5）
"""

from . import (
    capture,
    endgame,
    joseki,
    ladder,
    life_death,
    middle,
    opening,
    territory,
    tesuji,
)
from .base import Candidate, GameContext, generate_candidates

# 模块名 -> 分析函数的注册表（决策器按 LevelProfile.modules 开关调用）。
MODULE_REGISTRY = {
    "capture": capture,
    "opening": opening,
    "life_death": life_death,
    "ladder": ladder,
    "tesuji": tesuji,
    "joseki": joseki,
    "middle": middle,
    "endgame": endgame,
    "territory": territory,
}

__all__ = [
    "Candidate",
    "GameContext",
    "generate_candidates",
    "MODULE_REGISTRY",
    "capture",
    "opening",
    "life_death",
    "ladder",
    "tesuji",
    "joseki",
    "middle",
    "endgame",
    "territory",
]
