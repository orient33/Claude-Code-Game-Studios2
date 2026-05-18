# 引力吸附系统 (Gravity Attraction System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 心流至上, 尺度震撼

## Overview

引力吸附系统为玩家天体赋予一个随质量增长的被动引力场——场内比玩家小的物体会自动向玩家滑动，减少玩家"追逐食物"的操作负担，让吞噬行为更流畅轻松。引力不是一个玩家主动使用的技能，而是一个"越强越明显"的被动能力——质量越大，引力场半径越大，吸附速度越快。这创造了正反馈循环：吃得越多→引力越强→吃得越轻松→吃得更多。引力只影响比玩家小的天体，比玩家大的天体不受引力影响（不会被拉近玩家造成不可避免的死亡）。

## Player Fantasy

"万物向我坠落。"玩家的幻想是成为一个不可抗拒的引力源——不需要追逐，猎物自己飘来。这个系统直接服务于"心流至上"：玩家不需要精确瞄准每一个小天体，只需漂浮在食物密集区域，引力场会替你完成最后的"收割"。同时服务于"尺度震撼"：引力场范围的可见增长是"我正在变强"的持续视觉证明。

## Detailed Design

### Core Rules

1. **引力场**：玩家天体拥有一个圆形引力场，半径为 `gravity_radius`。场内所有 `mass_value < player_absolute_mass` 的天体被施加一个指向玩家中心的加速力。

2. **吸附力方向**：始终指向玩家天体中心位置（每帧更新方向）。

3. **吸附力大小**：距离越近，吸附力越大（类反比关系）。公式详见 Formulas 节。

4. **仅吸小不吸大**：引力场只对质量小于玩家的天体生效。质量大于或等于玩家的天体完全无视引力场——它们按原有轨迹移动，不受任何偏转。

5. **不影响玩家自身**：引力场不对玩家天体自身产生任何力——玩家移动完全由手指控制（玩家移动系统的职责）。

6. **引力场随质量增长**：`gravity_radius` 基于玩家 `absolute_mass` 计算，质量越大半径越大。

7. **被吸附天体的速度叠加**：天体自身的漂移速度 + 引力吸附加速度 = 实际速度。引力是附加力，不替代天体原有运动。

8. **无上限堆叠**：多个天体可同时在引力场内被吸附，没有"同时吸附数量上限"。

### States and Transitions

引力吸附系统无内部状态机——它是持续运行的场效应系统。每帧对场内所有合法天体施加力。

每个被影响天体的隐含状态：
| 状态 | 条件 | 行为 |
|------|------|------|
| Outside（场外）| 距离 > gravity_radius | 不受引力影响 |
| Attracted（被吸引中）| 距离 ≤ gravity_radius 且 mass < player mass | 每帧受指向玩家的力 |
| Immune（免疫）| mass ≥ player mass | 无论距离远近均不受引力 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 玩家移动 | ← 读取 | `get_position() -> Vector2` | 引力中心 = 玩家位置 |
| 质量/成长 | ← 读取 | `get_absolute_mass() -> float` | 计算引力场半径和力强度 |
| 质量/成长 | ← 读取 | `get_visual_radius() -> float` | 引力场起始半径（不小于视觉半径） |
| 物体生成 | ← 读取 | 各天体的 `mass_value` | 判断是否小于玩家（合法吸附目标） |
| 碰撞判定 | → 间接 | 加速物体接近玩家 → 更快触发碰撞 | 引力不跳过碰撞，只加速接近 |
| 粒子/VFX | → 信号 | 引力场范围数据 | 用于绘制引力场视觉指示（微光圈） |

## Formulas

### 1. 引力场半径 (Gravity Radius)

`gravity_radius = visual_radius * gravity_range_multiplier`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| visual_radius | R_v | float | 16-224 px | 来自质量/成长系统 |
| gravity_range_multiplier | G_r | float | 2.0-5.0 | 引力场是视觉半径的倍数 |

**Output Range:** 32px（尘埃阶段）→ 1120px（黑洞阶段，G_r=5时）
**Example:** R_v=60px（阶段3中期）, G_r=3.0 → gravity_radius = 180px

### 2. 引力吸附力 (Gravity Force)

`gravity_force = gravity_strength / max(distance_to_player - visual_radius, min_distance)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| gravity_strength | G_s | float | 50-300 px/s² | 基础引力强度 |
| distance_to_player | d | float | 0-gravity_radius px | 目标天体到玩家中心的距离 |
| visual_radius | R_v | float | 16-224 px | 减去视觉半径，使力从天体表面开始计算 |
| min_distance | d_min | float | 8-16 px | 最小距离（防止除零，限制最大力） |

**Output Range:** gravity_strength/gravity_radius（场边缘最弱）→ gravity_strength/min_distance（最近处最强）
**Example:** G_s=150, d=100, R_v=60, d_min=10 → 150/max(100-60, 10) = 150/40 = 3.75 px/s²

### 3. 引力场可见性缩放 (Visual Indicator Scale)

`glow_ring_radius = gravity_radius`
`glow_ring_opacity = base_opacity * (1.0 + stage_progress * 0.3)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_opacity | O | float | 0.05-0.15 | 引力场微光圈的基础不透明度 |

**Output:** 一个随质量缓慢变亮的极淡光圈，服务"寂生辉"原则。

## Edge Cases

- **If 天体恰好在引力场边缘（distance ≈ gravity_radius）**: 施加极弱的力。不做突变——天体平滑地从"不受力"过渡到"微弱受力"。

- **If 玩家质量突然增加（吞噬导致引力场扩大）**: 场内新增的天体从下一帧开始受力。不追溯补偿——效果是自然的"引力场膨胀"。

- **If 被吸附的天体被引力加速到极高速度（接近玩家时）**: 天体速度被 `max_attracted_speed` 限制（防止穿透碰撞体）。上限应低于碰撞检测的每帧最大位移。

- **If 两个可吸附天体同时在场内且彼此很近**: 各自独立受力，不互相影响（天体之间不存在引力——只有玩家是引力源）。

- **If 进化发生，gravity_radius 突然跳变**: 引力场在进化动画期间平滑扩大（配合镜头拉远的 1.5秒过渡），不瞬间跳变。

- **If 玩家位于屏幕边缘，引力场延伸出屏幕外**: 正常工作——屏幕外的天体也受引力影响（它们已由物体生成系统创建在屏幕外50-80px处）。这使得天体在进入可见区域时已经有向玩家偏转的趋势。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 玩家移动 | `get_position()` | 硬 | 引力中心 |
| 质量/成长 | `get_absolute_mass()`, `get_visual_radius()` | 硬 | 场半径和力强度的计算基础 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 碰撞判定 | 间接——加速天体接近玩家 | 软 | 引力加速碰撞触发但不跳过碰撞 |
| 粒子/VFX | gravity_radius 数据 | 软 | 引力场视觉指示 |

**接口契约：**
- 引力系统不修改任何天体的 mass_value——只修改其位置/速度
- 引力系统不触发碰撞——只加速接近，实际碰撞由碰撞判定系统处理
- 引力场半径变化是平滑的（无突变）

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `gravity_range_multiplier` | 3.0 | 2.0-5.0 | 太远→食物自动飘来太多，游戏无操控需求 | 太近→引力几乎无感，需要精确追逐每个天体 | "被动收割"的轻松感 vs 主动操控需求 |
| `gravity_strength` | 150 px/s² | 50-300 | 太强→天体飞速被吸入，缺乏观赏时间 | 太弱→天体几乎不偏移，引力无感 | 吸附的"可见性"和"速度感" |
| `max_attracted_speed` | 600 px/s | 300-1000 | 太快→可能穿透碰撞体 | 太慢→近距离天体接近速度受限 | 近距离吸附的"暴力感" |
| `min_distance` | 10 px | 8-16 | 太大→近距离力被过度限制 | 太小→力在极近距离趋向无穷大 | 极近距离的吸附加速感 |

**交互关系：**
- `gravity_range_multiplier` × 质量/成长的 `radius_scale[]` 共同决定场的实际像素大小
- `max_attracted_speed` 必须小于碰撞判定系统每帧最大检测位移（确保不穿模）
- `gravity_strength` 影响物体生成系统的存活时间——力太强则天体很快被吸走，屏幕上存在时间短

## Acceptance Criteria

1. **GIVEN** 玩家 absolute_mass=500，一个 mass_value=100 的天体在引力场内，**WHEN** 每帧更新，**THEN** 该天体向玩家方向移动，速度随接近递增。

2. **GIVEN** 一个 mass_value=800 的天体（大于玩家）在引力场内，**WHEN** 每帧更新，**THEN** 该天体不受任何力影响，按原轨迹移动。

3. **GIVEN** 玩家质量增加（吞噬了天体），**WHEN** 下一帧，**THEN** gravity_radius 增大，之前场外的天体现在可能进入场内开始被吸附。

4. **GIVEN** 天体在引力场边缘刚好进入，**WHEN** 计算吸附力，**THEN** 力极小（接近零），无突变跳跃。

5. **GIVEN** 天体被引力加速到接近 max_attracted_speed，**WHEN** 继续受力，**THEN** 速度被 clamp 在上限，不超过。

6. **GIVEN** 进化动画触发，**WHEN** gravity_radius 需要扩大，**THEN** 扩大过程平滑（≥1.0秒过渡），不瞬间跳变。

7. **GIVEN** 引力场延伸到屏幕外，**WHEN** 屏幕外的天体在场内，**THEN** 该天体正常受力，进入屏幕时已有向玩家偏转。

8. **性能**: 单帧对所有场内天体（≤50个）的引力计算总耗时 < 0.5ms。
