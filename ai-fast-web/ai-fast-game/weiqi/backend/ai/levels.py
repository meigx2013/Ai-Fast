"""级位参数与策略映射（总纲第 4 节，1～10 级）。

数字越小 AI 越强：1 级最强（随机性最低），10 级最弱。
级位映射只存在于后端，前端仅传 1～10 的整数。

所有级位共用同一套合法候选生成与规则校验，强度差异只体现在：
- temperature       传给模型的采样温度（级位越弱越高）
- noise_amplitude   本地评分噪声幅度（级位越弱越大）
- weak_choice_rate  非关键局面放弃最优解的概率（10 级约 40%，1 级为 0）
- top_k             提供给模型的候选数量上限（4~5 级受限，2~3 级扩大，1 级最大）
- weights           本地评分各维度乘数（体现各档位棋风，如 10 级无围空概念）
- tactical_bonus    1 级附加的基础死活/联络加强读

关键手段（提子/叫吃/救棋）的权重在任何级位都 >= 1.0，
配合 heuristic.CRITICAL_MOVE_SCORE 保证最弱级位也不放弃吃子与死活基本功。
"""

from dataclasses import dataclass

from .heuristic import ScoreWeights


@dataclass(frozen=True)
class LevelProfile:
    """单个级位的完整参数档案。"""

    level: int
    label: str          # 展示名，如 "10级"
    strategy: str       # 级位策略描述（同时用于模型提示词）
    temperature: float  # 模型采样温度
    noise_amplitude: float  # 本地评分噪声
    weak_choice_rate: float  # 非关键局面随性一手概率
    top_k: int          # 模型候选数量上限
    weights: ScoreWeights  # 评分维度权重
    tactical_bonus: bool = False  # 1 级：基础死活/联络加强读


_LEVEL_TABLE: dict[int, LevelProfile] = {
    10: LevelProfile(
        level=10, label="10级",
        strategy="以吃子与基础死活为核心：优先能提对方子、救援己方危险棋块、贴近上一手"
                 "接触战的选点；尚无围空概念，选点集中在局部缠斗，忽略全局大场。",
        temperature=1.3, noise_amplitude=12.0, weak_choice_rate=0.40, top_k=20,
        weights=ScoreWeights(capture=1.3, liberty=1.0, atari=1.1, rescue=1.2,
                             proximity=1.5, position=0.15, connection=0.6),
    ),
    9: LevelProfile(
        level=9, label="9级",
        strategy="吃子熟练并开始有围空意识：能稳定完成基础吃子与对杀，"
                 "偶尔尝试占据角部和边线，但围空效率低。",
        temperature=1.2, noise_amplitude=10.0, weak_choice_rate=0.32, top_k=22,
        weights=ScoreWeights(capture=1.25, liberty=1.0, atari=1.1, rescue=1.15,
                             proximity=1.3, position=0.35, connection=0.7),
    ),
    8: LevelProfile(
        level=8, label="8级",
        strategy="吃子与对杀稳定，会尝试占据角部和边线，"
                 "但常因局部战斗而放弃已占区域。",
        temperature=1.1, noise_amplitude=8.0, weak_choice_rate=0.25, top_k=24,
        weights=ScoreWeights(capture=1.2, liberty=1.0, atari=1.05, rescue=1.1,
                             proximity=1.2, position=0.5, connection=0.8),
    ),
    7: LevelProfile(
        level=7, label="7级",
        strategy="基础布局与分断连接概念：能选择星位/小目等常见开局点，"
                 "理解连接己方与分断对方的价值，兼顾简单对杀的气数计算。",
        temperature=1.0, noise_amplitude=6.5, weak_choice_rate=0.18, top_k=26,
        weights=ScoreWeights(capture=1.15, liberty=1.0, atari=1.05, rescue=1.05,
                             proximity=1.1, position=0.7, connection=0.9),
    ),
    6: LevelProfile(
        level=6, label="6级",
        strategy="基础布局成形：星位/小目等开局点选择合理，"
                 "重视连接与分断，局部对杀气数计算较可靠。",
        temperature=0.9, noise_amplitude=5.0, weak_choice_rate=0.13, top_k=28,
        weights=ScoreWeights(capture=1.1, liberty=1.0, atari=1.05, rescue=1.05,
                             proximity=1.0, position=0.85, connection=1.0),
    ),
    5: LevelProfile(
        level=5, label="5级",
        strategy="死活棋形与基础手筋：能识别板六、盘角曲四等常见死活棋形，"
                 "掌握滚打包收、接不归等简单手筋，开始尝试基础定式；候选选择相对集中。",
        temperature=0.8, noise_amplitude=4.0, weak_choice_rate=0.09, top_k=24,
        weights=ScoreWeights(capture=1.1, liberty=1.05, atari=1.1, rescue=1.1,
                             proximity=0.95, position=0.95, connection=1.0),
    ),
    4: LevelProfile(
        level=4, label="4级",
        strategy="死活棋形与基础手筋熟练，能记忆并使用基础定式，"
                 "但定式后的行棋方向仍模糊；候选选择相对集中。",
        temperature=0.7, noise_amplitude=3.0, weak_choice_rate=0.06, top_k=26,
        weights=ScoreWeights(capture=1.1, liberty=1.1, atari=1.1, rescue=1.1,
                             proximity=0.9, position=1.0, connection=1.0),
    ),
    3: LevelProfile(
        level=3, label="3级",
        strategy="布局选点与中盘战术入门：能根据星/小目布局选择合理大场，"
                 "开始理解打入与侵消时机，注意角部常见死活型，官子有收束意识。",
        temperature=0.6, noise_amplitude=2.0, weak_choice_rate=0.04, top_k=34,
        weights=ScoreWeights(capture=1.05, liberty=1.05, atari=1.05, rescue=1.05,
                             proximity=0.9, position=1.1, connection=1.05),
    ),
    2: LevelProfile(
        level=2, label="2级",
        strategy="布局与中盘战术：大场与急所判断初具雏形，"
                 "打入侵消时机把握尚可，收官有序。",
        temperature=0.5, noise_amplitude=1.5, weak_choice_rate=0.02, top_k=36,
        weights=ScoreWeights(capture=1.05, liberty=1.05, atari=1.05, rescue=1.05,
                             proximity=0.85, position=1.15, connection=1.05),
    ),
    1: LevelProfile(
        level=1, label="1级",
        strategy="综合实战与全局平衡：具备完整的布局—中盘—收官框架，"
                 "综合运用死活、手筋、定式知识处理局部，"
                 "能判断大场与急所的优先级（判断精度有限）。",
        temperature=0.2, noise_amplitude=0.5, weak_choice_rate=0.0, top_k=40,
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
