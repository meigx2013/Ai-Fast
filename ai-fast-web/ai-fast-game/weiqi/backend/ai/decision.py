"""级位决策器（任务 3 低级位视野过滤与误判注入；任务 4 中级位模块融合）。

决策管道：
1. 生成全盘合法候选（analyzer.generate_candidates，规则模拟复用）；
2. 视野过滤（apply_vision）：10 级仅上一手 ±2 区域 + 己方被叫吃块的逃吃
   方向（以 ignore_atari 概率对告警"视而不见"）；9 级 ±3；8 级半盘
   （上一手曼哈顿距离 <= size//2 的菱形区域）；7 级及以上全盘。视野外的
   候选不参与评分（真实体现"看不见"）；
3. 按 LevelProfile.modules 开关调用各分析器，融合评分（模块贡献求和，
   对杀气数按 accuracy.liberty 概率性"数错"——随机源走 ctx.rng）。
   任务 4 起 6~4 级解锁布局成形（角部价值矩阵/挂角/守角/拆边）、死活
   棋形库（点杀/做活）、手筋（双打吃/关门吃/扑/接不归）、征子（读步数
   受 accuracy.ladder_steps 限制）与基础定式库（5~4 级）——中级位视野为
   全盘 + 局部深算（对杀/死活/征子候选允许 3~5 步推演，深算在各分析器
   内部完成，误判率降至 10%/7%/5%）；
4. 落子习惯注入（habits.attachment_score 贴身度 + opening_target_bonus
   开局目标点）；
5. 误判注入：送吃（blunder_rate——在视野内选择"落子后自身仅 1 气且无
   提子"的合法点，仅非关键局面触发）；
6. 级位噪声 + 非关键局面"随性一手"（与 v1 行为等价，可重复种子）；
7. 主动 Pass：全模块融合后的最高候选分低于 pass_threshold 即"收官完毕"
   （当前所有级位为保守不可达值，任务 5 校准）。

关键不变量：
- 关键手段（提子/叫吃/救棋/逃吃）任何可见级位都不放弃
  （CRITICAL_MOVE_SCORE 守护送吃与随性，且各关键维度权重 >= 1.0）；
- 所有输出均为合法候选（引擎侧另有规则双保险）。
"""

import random
from dataclasses import dataclass

from .. import go_rules
from . import habits
from .analyzer import MODULE_REGISTRY
from .analyzer.base import GameContext, generate_candidates
from .analyzer.capture import escape_targets
from .levels import (
    Accuracy,
    HabitWeights,
    LevelProfile,
    MistakeRates,
    ScoreWeights,
    Vision,
)

# 关键局面阈值：干净评分（无噪声）达到该值意味着提子/叫吃/救棋级别的要点，
# 任何级位都不应因"随性一手"或"送吃误判"而放弃，保证最弱级位也遵守
# 吃子与死活的基本功。
CRITICAL_MOVE_SCORE = 45.0

# 贴身度达到该值（距离上一手足够近）时在 reason 中追加"贴身应战"标签。
ATTACHMENT_TAG_THRESHOLD = 5.0


@dataclass(frozen=True)
class Decision:
    """决策结果：move 为 None 表示虚手（active_pass 区分主动/无合法点）。"""

    move: tuple[int, int] | None
    reason: str
    active_pass: bool = False


# 无级位档案时的基线参数（等价 v1 启发式任务 3 行为：全 1.0 权重、噪声 3.0）。
_BASELINE_PROFILE = LevelProfile(
    level=0, label="基线", strategy="",
    vision=Vision(mode="global"),
    modules=frozenset({"capture", "opening"}),
    accuracy=Accuracy(liberty=1.0, ladder_steps=0, territory=0.0),
    mistake_rates=MistakeRates(ignore_atari=0.0, blunder_rate=0.0),
    habit_weights=HabitWeights(attachment=1.0),
    pass_threshold=-1e9,
    noise_amplitude=3.0,
    weak_choice_rate=0.0,
    weights=ScoreWeights(),
)


def _resolve_profile(profile: LevelProfile | None) -> LevelProfile:
    return _BASELINE_PROFILE if profile is None else profile


def apply_vision(
    ctx: GameContext, profile: LevelProfile, rng: random.Random | None = None
) -> list[tuple[int, int, go_rules.MoveResult]]:
    """级位化视野过滤：视野外的候选不参与评分（真实体现"看不见"）。

    - local：上一手切比雪夫 ±radius 的区域；
    - half：上一手曼哈顿距离 <= size//2 的"半盘"菱形区域；
    - global：全盘；
    - last_move 为 None（开局/虚手后）时全盘（无参照点）。

    己方被叫吃块的逃吃方向构成"告警视野"（local/half 模式下额外并入），
    但以 mistake_rates.ignore_atari 概率对告警"视而不见"——被忽略时
    逃吃点不进入视野（global 级位看见了也当没看见）。rng 为 None 时代表
    清醒评估（不注入忽略），供干净评分与测试复现使用。

    兜底：过滤后为空则回退全盘候选（看得见的地方没得下时仍会随手落子，
    不会因视野狭窄而无故虚手）。
    """
    last = ctx.last_move
    if last is None:
        visible = list(ctx.candidates)
    else:
        mode = profile.vision.mode
        if mode == "local":
            radius = profile.vision.radius
            visible = [
                cand for cand in ctx.candidates
                if abs(cand[0] - last[0]) <= radius and abs(cand[1] - last[1]) <= radius
            ]
        elif mode == "half":
            limit = ctx.size // 2
            visible = [
                cand for cand in ctx.candidates
                if abs(cand[0] - last[0]) + abs(cand[1] - last[1]) <= limit
            ]
        else:  # global：全盘粗略
            visible = list(ctx.candidates)

    escapes = escape_targets(ctx)
    if escapes:
        escape_set = set(escapes)
        if rng is not None and rng.random() < profile.mistake_rates.ignore_atari:
            # 对叫吃告警"视而不见"：逃吃点不进入（或移出）视野。
            visible = [cand for cand in visible if (cand[0], cand[1]) not in escape_set]
        else:
            visible_keys = {(cand[0], cand[1]) for cand in visible}
            visible = visible + [
                cand for cand in ctx.candidates
                if (cand[0], cand[1]) in escape_set and (cand[0], cand[1]) not in visible_keys
            ]

    if not visible and ctx.candidates:
        visible = list(ctx.candidates)
    return visible


def _blunder_pool(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None,
    visible_keys: set[tuple[int, int]],
) -> list[tuple[int, int]]:
    """视野内"落子后自身仅 1 气且无提子"的合法点（送吃候选）。

    仅决策器注入 rng 命中 blunder_rate 时才会计算；基线/干净路径不调用。
    """
    pool: list[tuple[int, int]] = []
    for row, col, move_result in generate_candidates(board, size, player, previous_board):
        if (row, col) not in visible_keys or move_result.captured > 0:
            continue
        _, liberties = go_rules.get_group(move_result.board, size, row, col)
        if len(liberties) == 1:
            pool.append((row, col))
    return pool


def _tactical_bonus(
    ctx: GameContext, row: int, col: int, move_result: go_rules.MoveResult
) -> tuple[float, int]:
    """1 级基础死活/联络加强读（v1 平移）：更看重提子余味、气数充足与连成一体。

    返回 (加分, 邻点己方子数)。
    """
    bonus = 0.0
    if move_result.captured > 0:
        bonus += 10.0
    _, own_liberties = go_rules.get_group(move_result.board, ctx.size, row, col)
    if len(own_liberties) >= 3:
        bonus += 8.0
    same_count = 0
    for n_row, n_col in go_rules.neighbors(row, col, ctx.size):
        if ctx.board[n_row][n_col] == ctx.player:
            same_count += 1
    if same_count >= 2:
        bonus += 8.0
    return bonus, same_count


def _primary_tag(
    contributions: list[tuple[str, float, str]], habit_score: float
) -> str:
    """选取主导模块的类型标签：贡献最大的正向模块；全部为零时取"占据要点"。"""
    best_module, best_score, best_tag = "", 0.0, "占据要点"
    for module_name, score, tag in contributions:
        if score > best_score:
            best_module, best_score, best_tag = module_name, score, tag
    if habit_score > best_score:
        best_tag = "贴身应战"
    return best_tag or "占据要点"


def rank_candidates(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    *,
    profile: LevelProfile | None = None,
    candidates: list[tuple[int, int, go_rules.MoveResult]] | None = None,
    move_number: int = 0,
    rng: random.Random | None = None,
) -> list[tuple[float, int, int, str]]:
    """按评分降序排列候选，返回 [(score, row, col, tag)]。

    融合 = 各启用模块贡献之和 + 开局目标点习惯 + 贴身习惯 + （1 级）加强读
    加成；同分按 (row, col) 稳定排序。profile 为 None 时使用基线权重。

    rng 携带时（决策管道路径）注入两类低级位"看走眼"：
    - 视野过滤按 ignore_atari 概率忽略己方被叫吃告警；
    - 对杀气数按 accuracy.liberty 概率数错 ±1 气。
    rng 缺省时为干净精确评分（测试与强度基准路径）。
    """
    profile = _resolve_profile(profile)
    if candidates is None:
        candidates = generate_candidates(board, size, player, previous_board)
    ctx = GameContext(
        board=board, size=size, player=player,
        previous_board=previous_board, last_move=last_move,
        move_number=move_number, candidates=candidates, rng=rng,
    )

    visible = apply_vision(ctx, profile, rng)

    # 模块贡献与标签（每点一份 [(module, score, tag), ...]）。
    contributions: dict[tuple[int, int], list[tuple[str, float, str]]] = {}
    for module_name in sorted(profile.modules):
        analyzer = MODULE_REGISTRY.get(module_name)
        if analyzer is None:
            continue
        for cand in analyzer.analyze(ctx, profile):
            key = (cand.row, cand.col)
            contributions.setdefault(key, []).append((module_name, cand.score, cand.tag))

    attachment = profile.habit_weights.attachment
    tactical = bool(profile.tactical_bonus)
    visible_keys = {(row, col) for row, col, _ in visible}

    scored: list[tuple[float, int, int, str]] = []
    for row, col, move_result in candidates:
        key = (row, col)
        if key not in visible_keys:
            continue
        module_list = contributions.get(key, [])
        opening_bonus, opening_tag = habits.opening_target_bonus(
            ctx, row, col, profile.habit_weights.opening_targets
        )
        if opening_bonus > 0.0:
            module_list = module_list + [("opening-target", opening_bonus, opening_tag)]
        total = sum(score for _module, score, _tag in module_list)
        habit_score = habits.attachment_score(ctx, row, col, attachment)
        total += habit_score
        if tactical:
            bonus, _same_count = _tactical_bonus(ctx, row, col, move_result)
            total += bonus
        tag = _primary_tag(module_list, habit_score)
        scored.append((total, row, col, tag))

    scored.sort(key=lambda item: (-item[0], item[1], item[2]))
    return scored


def choose_move(
    board: list[list[int]],
    size: int,
    player: int,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    rng: random.Random | None = None,
    *,
    profile: LevelProfile | None = None,
    candidates: list[tuple[int, int, go_rules.MoveResult]] | None = None,
    ranked: list[tuple[float, int, int, str]] | None = None,
    move_number: int = 0,
) -> tuple[int, int, str] | None:
    """选择一手棋，返回 (row, col, reason)；无合法点时返回 None。

    级位行为：
    - 视野外候选不参与评分（低级位"看不见"）；
    - 误判注入（送吃）：非关键局面按 blunder_rate 概率在视野内选择
      "落子后自身仅 1 气且无提子"的合法点（真实低级位典型错误）；
    - 噪声幅度随级位变化（级位数字越大噪声越大，选择越不稳定）；
    - 非关键局面（干净最优分 < CRITICAL_MOVE_SCORE）时按 weak_choice_rate
      概率放弃最优解，从其余合法候选中随机取一手"随性一手"；
    - 关键手段（提子/叫吃/救棋/逃吃）任何级位都不放弃；
    - 测试可注入固定种子的 rng 以获得可重复结果。
    """
    profile = _resolve_profile(profile)
    if rng is None:
        rng = random.Random()
    if ranked is None:
        ranked = rank_candidates(
            board, size, player, previous_board, last_move,
            profile=profile, candidates=candidates, move_number=move_number,
            rng=rng,
        )
    if not ranked:
        return None

    # 误判注入——送吃：仅非关键局面（关键提子/救棋手段绝不让位于送吃）。
    if ranked[0][0] < CRITICAL_MOVE_SCORE and rng.random() < profile.mistake_rates.blunder_rate:
        visible_keys = {(row, col) for _score, row, col, _tag in ranked}
        pool = _blunder_pool(board, size, player, previous_board, visible_keys)
        if pool:
            index = min(int(rng.random() * len(pool)), len(pool) - 1)
            row, col = pool[index]
            entry = next(
                (item for item in ranked if (item[1], item[2]) == (row, col)), None
            )
            tag = entry[3] if entry is not None else "随手"
            reason = _assemble_reason(
                profile, tag, ranked, (row, col)
            )
            return row, col, f"{reason}（{profile.label}随手送吃）"

    noise = profile.noise_amplitude
    noisy = [
        (score + rng.random() * noise, row, col, tag)
        for score, row, col, tag in ranked
    ]
    noisy.sort(key=lambda item: (-item[0], item[1], item[2]))
    best_score, best_row, best_col, best_tag = noisy[0]

    reason = _assemble_reason(profile, best_tag, ranked, (best_row, best_col))

    # 弱级位"随性一手"：仅非关键局面触发，选点仍然合法。
    if (
        len(noisy) > 1
        and ranked[0][0] < CRITICAL_MOVE_SCORE
        and rng.random() < profile.weak_choice_rate
    ):
        pool = noisy[1:]
        index = min(int(rng.random() * len(pool)), len(pool) - 1)
        _, row, col, tag = pool[index]
        reason = _assemble_reason(profile, tag, ranked, (row, col))
        return row, col, f"{reason}（{profile.label}随性一手）"

    return best_row, best_col, reason


def _assemble_reason(
    profile: LevelProfile,
    tag: str,
    ranked: list[tuple[float, int, int, str]],
    point: tuple[int, int],
) -> str:
    """组装 reason：主导模块标签 + 显著贴身时追加"贴身应战"。

    贴身判定基于该点干净评分相对最高分的贴近程度（噪声选择可能与最高分
    接近，视为就近应手），复用 rank 中的分数避免重复计算。
    """
    reason = tag
    if tag != "贴身应战" and ranked:
        best_score = ranked[0][0]
        own_score = next(
            (score for score, row, col, _t in ranked if (row, col) == point), 0.0
        )
        # 就近应手：所选点与最高分差距很小（近似贴身选择了当前战斗区域）。
        if best_score - own_score <= 3.0:
            reason = f"{tag} · 贴身应战"
    return reason


def decide(
    board: list[list[int]],
    size: int,
    player: int,
    profile: LevelProfile,
    previous_board: list[list[int]] | None = None,
    last_move: tuple[int, int] | None = None,
    rng: random.Random | None = None,
    move_number: int = 0,
) -> Decision:
    """级位决策入口：返回 Decision（move=None 表示虚手）。

    主动 Pass 语义：全模块融合后的最高候选分低于 profile.pass_threshold
    （"收官完毕，再无有价值落点"）时系统主动虚手。当前所有级位阈值为
    保守不可达值，任务 5 校准（低级位几乎不主动 Pass）。
    """
    if rng is None:
        rng = random.Random()
    ranked = rank_candidates(
        board, size, player, previous_board, last_move,
        profile=profile, move_number=move_number, rng=rng,
    )
    if not ranked:
        return Decision(move=None, reason="无合法落点，虚手", active_pass=False)
    if ranked[0][0] < profile.pass_threshold:
        return Decision(move=None, reason="收官完毕，主动虚手", active_pass=True)
    choice = choose_move(
        board, size, player, previous_board, last_move, rng,
        profile=profile, ranked=ranked, move_number=move_number,
    )
    if choice is None:
        return Decision(move=None, reason="无合法落点，虚手", active_pass=False)
    row, col, reason = choice
    return Decision(move=(row, col), reason=reason, active_pass=False)
