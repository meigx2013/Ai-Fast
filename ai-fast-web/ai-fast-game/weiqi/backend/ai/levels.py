"""级位能力档案 v2（LevelProfile：能力开关 / 精度 / 误判率 / 视野 / 习惯 / Pass 阈值）。

数字越小系统越强：1 级最强（误判率最低、视野与计算深度最高），10 级最弱。
级位映射只存在于后端，前端仅传 1～10 的整数。

v2 参数维度（每级一组，对应 04_prompt.md"级位思维方式模型"）：
- vision          候选评估的空间过滤范围（local=上一手±radius / half=半盘 / global=全盘）；
- modules         启用的分析模块开关集合（级位越高解锁越多）；
- accuracy        精度：气数计算正确率、征子读步数、形势判断精度；
- mistake_rates   误判率：忽略被叫吃概率、送吃/随手概率；
- habit_weights   落子习惯：贴身度权重、开局目标点偏好（opening_targets）；
- pass_threshold  主动 Pass 阈值：全模块融合后的最高候选分低于该值即"收官完毕"
                  主动 Pass。任务 4 前（10~8 级）取保守不可达值（不触发），
                  任务 5 用"官子收完"盘面逐级校准后固化（10~8 级几乎不
                  主动 Pass，3~1 级正常收官后主动 Pass）。

任务 3 已落地 10～7 级（低级位：吃子死活基本功 + 贴身缠斗习惯）：
- 10 级：视野 ±2、气数正确率 0.6、忽略叫吃 40%/送吃 30%、贴身度 1.5、
         开局"星位附近/任意三线"随手；
- 9 级：视野 ±3、气数正确率 0.7、25%/20%、贴身度 1.3、三线四线偏好；
- 8 级：半盘视野、气数正确率 0.8、20%/15%、贴身度 1.2、优先空角星位/三三；
- 7 级：全盘粗略、气数正确率 0.85、15%/10%、贴身度 1.1、空角→边顺序。

任务 4 已落地 6～4 级（中级位：布局成形 + 死活棋形 + 手筋 + 征子 + 定式）：
- 6 级：全盘、模块 capture/opening/life_death/tesuji/ladder，气数正确率
         0.9、征子读 3 步、死活仅基础型（直三/板六）、手筋仅双打吃/关门
         吃、不识定式、误判 10%/7%；
- 5 级：+joseki（定式库），气数正确率 0.93、征子读 5 步、死活全表、
         手筋加扑/接不归、误判 7%/5%；
- 4 级：定式熟练，气数正确率 0.95、征子读 6 步、死活全表 + 局部加强读
         （弃死子）、误判 5%/4%。
Pass 阈值仍为保守不可达值（任务 5 用"官子收完"盘面逐级校准）。
3～1 级仍为过渡档案（沿用 v1 权重，任务 5 覆盖为完整 v2 参数）。

过渡字段（3~1 级沿用，任务 5 逐级覆盖）：
- noise_amplitude / weak_choice_rate / weights / tactical_bonus，
  其中 weights 为各评分维度乘数（ScoreWeights）。

关键不变量（所有级位必须遵守）：
- 落子永远合法（引擎侧规则双保险校验）；
- 提子机会任何级位都不放过（关键手段权重 >= 1.0 + CRITICAL_MOVE_SCORE 守护）；
- 关键维度（提子/叫吃/救援）权重任何级位 >= 1.0。
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class ScoreWeights:
    """各评分维度的乘数权重（过渡期沿用 v1；全 1.0 为基础评分）。"""

    capture: float = 1.0      # 提子
    liberty: float = 1.0      # 己方气数 / 避免自损
    atari: float = 1.0        # 叫吃对方
    rescue: float = 1.0       # 救援己方危险棋块
    proximity: float = 1.0    # 靠近上一手（贴身习惯；v2 由 habit_weights.attachment 承载）
    position: float = 1.0     # 占角/边/线的位置价值（围空意识）
    connection: float = 1.0   # 联络


@dataclass(frozen=True)
class Vision:
    """视野范围：候选评估的空间过滤。

    mode: "local"（上一手 ±radius 的切比雪夫区域 + 己方被叫吃块）
          "half"（半盘，按到上一手的曼哈顿距离衰减）
          "global"（全盘）
    """

    mode: str
    radius: int = 0


@dataclass(frozen=True)
class Accuracy:
    """级位精度：气数计算正确率 / 征子读步数 / 形势判断精度（0~1）。"""

    liberty: float
    ladder_steps: int
    territory: float


@dataclass(frozen=True)
class MistakeRates:
    """级位误判率：忽略被叫吃概率 / 送吃（落子后自身仅 1 气）概率。"""

    ignore_atari: float
    blunder_rate: float


@dataclass(frozen=True)
class HabitWeights:
    """落子习惯：贴身度权重（对上一手距离的偏好强度）、开局目标点偏好。"""

    attachment: float
    opening_targets: tuple[str, ...] = ()


@dataclass(frozen=True)
class LevelProfile:
    """单个级位的完整能力档案（v2）。"""

    level: int
    label: str            # 展示名，如 "10级"
    strategy: str         # 级位思维方式描述
    vision: Vision
    modules: frozenset[str]
    accuracy: Accuracy
    mistake_rates: MistakeRates
    habit_weights: HabitWeights
    pass_threshold: float
    # ---- 过渡字段（任务 3~5 逐级覆盖为 v2 精细参数）----
    noise_amplitude: float
    weak_choice_rate: float
    weights: ScoreWeights
    tactical_bonus: bool = False  # 1 级：基础死活/联络加强读


# 主动 Pass 阈值（任务 2~4 期间）：保守不可达值，保证不触发；
# 任务 5 用"官子收完"标准盘面逐级校准后固化（10~8 级几乎不 Pass）。
_CONSERVATIVE_PASS_THRESHOLD = -1e9

# 10~7 级模块开关：低级位只有吃子与布局雏形思维（无死活棋形/手筋/定式/中盘/官子）。
_LOW_MODULES = frozenset({"capture", "opening"})

# 6 级模块开关：布局成形 + 基础死活 + 基础手筋 + 征子（不识定式）。
_MID_MODULES = frozenset({"capture", "opening", "life_death", "tesuji", "ladder"})

# 5~4 级模块开关：在 6 级之上解锁定式库（4~5 级"按型走"）。
_MID_PLUS_MODULES = frozenset({"capture", "opening", "life_death", "tesuji", "ladder", "joseki"})


_LEVEL_TABLE: dict[int, LevelProfile] = {
    10: LevelProfile(
        level=10, label="10级",
        strategy="只算眼前一手：看到能提子就提，自己被叫吃时多数时候会逃；"
                 "无布局/围空/死活概念，开局随手，贴身缠绕近战。",
        vision=Vision(mode="local", radius=2),
        modules=_LOW_MODULES,
        accuracy=Accuracy(liberty=0.6, ladder_steps=0, territory=0.0),
        mistake_rates=MistakeRates(ignore_atari=0.40, blunder_rate=0.30),
        habit_weights=HabitWeights(attachment=1.5, opening_targets=("star-area", "third-line")),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=12.0, weak_choice_rate=0.40,
        weights=ScoreWeights(capture=1.3, liberty=1.0, atari=1.1, rescue=1.2,
                             proximity=1.5, position=0.15, connection=0.6),
    ),
    9: LevelProfile(
        level=9, label="9级",
        strategy="吃子熟练；有围空意识但效率低（沿一、二线爬行）；知道逃子方向，"
                 "开始走三线四线。",
        vision=Vision(mode="local", radius=3),
        modules=_LOW_MODULES,
        accuracy=Accuracy(liberty=0.7, ladder_steps=0, territory=0.0),
        mistake_rates=MistakeRates(ignore_atari=0.25, blunder_rate=0.20),
        habit_weights=HabitWeights(attachment=1.3, opening_targets=("third-line", "fourth-line")),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=10.0, weak_choice_rate=0.32,
        weights=ScoreWeights(capture=1.25, liberty=1.0, atari=1.1, rescue=1.15,
                             proximity=1.3, position=0.35, connection=0.7),
    ),
    8: LevelProfile(
        level=8, label="8级",
        strategy="对杀气数计算稳定；开局会占角（星位/三三）；懂得简单逃子与弃子，"
                 "但常因局部战斗而放弃已占区域。",
        vision=Vision(mode="half"),
        modules=_LOW_MODULES,
        accuracy=Accuracy(liberty=0.8, ladder_steps=1, territory=0.0),
        mistake_rates=MistakeRates(ignore_atari=0.20, blunder_rate=0.15),
        habit_weights=HabitWeights(attachment=1.2, opening_targets=("corner",)),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=8.0, weak_choice_rate=0.25,
        weights=ScoreWeights(capture=1.2, liberty=1.0, atari=1.05, rescue=1.1,
                             proximity=1.2, position=0.5, connection=0.8),
    ),
    7: LevelProfile(
        level=7, label="7级",
        strategy="布局概念形成：空角→挂角→拆边顺序；理解连接与分断；简单死活；"
                 "征子只看 1~2 步。",
        vision=Vision(mode="global"),
        modules=_LOW_MODULES,
        accuracy=Accuracy(liberty=0.85, ladder_steps=2, territory=0.1),
        mistake_rates=MistakeRates(ignore_atari=0.15, blunder_rate=0.10),
        habit_weights=HabitWeights(attachment=1.1, opening_targets=("corner", "side")),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=6.5, weak_choice_rate=0.18,
        weights=ScoreWeights(capture=1.15, liberty=1.0, atari=1.05, rescue=1.05,
                             proximity=1.1, position=0.7, connection=0.9),
    ),
    # ---- 6~4 级：中级位（任务 4 落地：布局成形/死活棋形/手筋/征子/定式）----
    6: LevelProfile(
        level=6, label="6级",
        strategy="布局成形（星小目 + 拆边合理）；对杀可靠；基础手筋（双打吃/关门吃）；"
                 "常见死活棋形（直三/板六）；连接分断明确；不识定式。",
        vision=Vision(mode="global"),
        modules=_MID_MODULES,
        accuracy=Accuracy(liberty=0.9, ladder_steps=3, territory=0.2),
        mistake_rates=MistakeRates(ignore_atari=0.10, blunder_rate=0.07),
        habit_weights=HabitWeights(attachment=1.0),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=5.0, weak_choice_rate=0.13,
        weights=ScoreWeights(capture=1.1, liberty=1.0, atari=1.05, rescue=1.05,
                             proximity=1.0, position=0.85, connection=1.0),
    ),
    5: LevelProfile(
        level=5, label="5级",
        strategy="死活棋形熟练（直三/曲三/丁四/刀把五/板六）；手筋掌握扑/接不归；"
                 "征子可读约 5 步；基础定式入门；候选选择集中。",
        vision=Vision(mode="global"),
        modules=_MID_PLUS_MODULES,
        accuracy=Accuracy(liberty=0.93, ladder_steps=5, territory=0.3),
        mistake_rates=MistakeRates(ignore_atari=0.07, blunder_rate=0.05),
        habit_weights=HabitWeights(attachment=0.95),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=4.0, weak_choice_rate=0.09,
        weights=ScoreWeights(capture=1.1, liberty=1.05, atari=1.1, rescue=1.1,
                             proximity=0.95, position=0.95, connection=1.0),
    ),
    4: LevelProfile(
        level=4, label="4级",
        strategy="基础定式记忆（常见角部定式按型走）；手筋熟练；局部可计算 3~5 步，"
                 "死活加强读（弃死子）。",
        vision=Vision(mode="global"),
        modules=_MID_PLUS_MODULES,
        accuracy=Accuracy(liberty=0.95, ladder_steps=6, territory=0.4),
        mistake_rates=MistakeRates(ignore_atari=0.05, blunder_rate=0.04),
        habit_weights=HabitWeights(attachment=0.9),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=3.0, weak_choice_rate=0.06,
        weights=ScoreWeights(capture=1.1, liberty=1.1, atari=1.1, rescue=1.1,
                             proximity=0.9, position=1.0, connection=1.0),
    ),
    # ---- 3~1 级：过渡档案（模块集已对齐 4 级保证级间单调；参数沿用 v1
    # 权重，任务 5 覆盖为完整 v2 参数：中盘/官子/形势模块 + 精度上限）----
    3: LevelProfile(
        level=3, label="3级",
        strategy="布局选点合理（大场判断入门）；中盘战术：攻击弱棋/切断联络；"
                 "把握打入与侵消时机；有先手官子概念。",
        vision=Vision(mode="global"),
        modules=_MID_PLUS_MODULES,
        accuracy=Accuracy(liberty=0.96, ladder_steps=7, territory=0.5),
        mistake_rates=MistakeRates(ignore_atari=0.04, blunder_rate=0.03),
        habit_weights=HabitWeights(attachment=0.9),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=2.0, weak_choice_rate=0.04,
        weights=ScoreWeights(capture=1.05, liberty=1.05, atari=1.05, rescue=1.05,
                             proximity=0.9, position=1.1, connection=1.05),
    ),
    2: LevelProfile(
        level=2, label="2级",
        strategy="大场与急所优先级判断可靠；形势判断雏形（目数估算）；收官有序。",
        vision=Vision(mode="global"),
        modules=_MID_PLUS_MODULES,
        accuracy=Accuracy(liberty=0.98, ladder_steps=8, territory=0.7),
        mistake_rates=MistakeRates(ignore_atari=0.02, blunder_rate=0.02),
        habit_weights=HabitWeights(attachment=0.85),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=1.5, weak_choice_rate=0.02,
        weights=ScoreWeights(capture=1.05, liberty=1.05, atari=1.05, rescue=1.05,
                             proximity=0.85, position=1.15, connection=1.05),
    ),
    1: LevelProfile(
        level=1, label="1级",
        strategy="综合实战与全局平衡：布局—中盘—官子完整框架；形势判断可靠；"
                 "领先时安全运转、落后时拼搏；计算深度最深。",
        vision=Vision(mode="global"),
        modules=_MID_PLUS_MODULES,
        accuracy=Accuracy(liberty=1.0, ladder_steps=10, territory=0.9),
        mistake_rates=MistakeRates(ignore_atari=0.01, blunder_rate=0.01),
        habit_weights=HabitWeights(attachment=0.8),
        pass_threshold=_CONSERVATIVE_PASS_THRESHOLD,
        noise_amplitude=0.5, weak_choice_rate=0.0,
        weights=ScoreWeights(capture=1.1, liberty=1.1, atari=1.1, rescue=1.1,
                             proximity=0.8, position=1.1, connection=1.1),
        tactical_bonus=True,
    ),
}


def get_level_profile(level: int) -> LevelProfile:
    """获取级位档案；越界级位直接抛错（请求层已由 Pydantic 限制 1～10）。"""
    try:
        return _LEVEL_TABLE[level]
    except KeyError as exc:
        raise ValueError(f"非法级位：{level}（仅允许 1～10）") from exc


def all_level_profiles() -> dict[int, LevelProfile]:
    """返回全部级位档案（测试与文档用）。"""
    return dict(_LEVEL_TABLE)
