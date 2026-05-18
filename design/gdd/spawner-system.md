# 物体生成系统 (Spawner System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 心流至上, 宇宙奇观

## Overview

物体生成系统控制"宇宙中有什么"——它决定何时、何地、生成什么类型和大小的天体从屏幕边缘漂入。这是游戏节奏和难度的核心控制器：生成物的大小分布直接决定了"可吃的多还是要躲的多"，而生成密度决定了"画面热闹还是空旷"。系统根据玩家当前进化阶段动态调整生成参数，确保每个阶段都有适当比例的食物和威胁，维持"心流"状态下的最佳紧张度。

## Player Fantasy

玩家不会意识到物体是"被生成"的——他们感受到的是"宇宙中有各种天体在漂流，而我是其中的捕食者/躲避者"。系统的隐形目标是让宇宙感觉像是"活的"：天体不是为了玩家而出现，而是"本来就在那里"，玩家只是碰巧经过。生成方向的随机性和漂流速度的变化营造出一种"宇宙自有节奏"的氛围——服务"宇宙奇观"支柱。

## Detailed Design

### Core Rules

1. **生成位置**：所有天体从屏幕边缘外 50-80px 处生成。生成点分布在屏幕四周的矩形边界上。

2. **生成方向**：天体进入屏幕的方向有轻微随机偏转（±15°），创造自然漂流感而非正对玩家射来。

3. **方向分布偏置**：
   - 食物天体：60% 偏向玩家前方（手指移动方向），40% 随机方向。让玩家"向前移动就有食物"。
   - 威胁天体：70% 从侧面/后方出现，30% 从前方。给玩家反应时间。
   - 稀有天体：100% 随机方向。

4. **大小分布（基于进化阶段）**：每个阶段有固定的食物/威胁比例：
   - 食物占比（mass_value < player_absolute_mass）：70%-80%
   - 威胁占比（mass_value ≥ player_absolute_mass）：20%-30%

5. **食物大小分层**：食物天体的质量在 `[player_mass * 0.01, player_mass * 0.8]` 之间分布。小食物多（容易但贡献小），大食物少（贡献大但视觉上接近威胁尺寸，需要判断力）。

6. **漂移速度**：天体以 `drift_speed` 匀速直线漂移穿越屏幕。漂移速度在 `[min_drift, max_drift]` 之间随机。

7. **生成节奏**：以波次（wave）形式生成。每波间隔 `wave_interval` 秒，每波生成 `wave_size` 个天体。波次间有密度脉动（Art Bible 6.3 的"视觉呼吸"）。

8. **画面密度管理**：同屏活跃天体数量被 `max_active_objects` 限制。达到上限时暂停生成，有天体离开/被吞噬后恢复。

9. **离屏回收**：天体完全离开屏幕外 100px 后，归还对象池。不无限存在。

10. **通过对象池获取**：所有天体节点通过 `object_pool.checkout(type)` 获取。如果池返回 null（扩容限制），跳过本次生成。

### States and Transitions

| 状态 | 条件 | 行为 |
|------|------|------|
| Spawning（正常生成中）| active_count < max_active_objects | 按 wave_interval 节奏生成 |
| Saturated（饱和暂停）| active_count >= max_active_objects | 暂停生成，等待天体离开/被吞噬 |
| Tension Wave（紧张波次）| 随机触发，30-60秒间隔 | 短时间内增加威胁占比至 40-50%，持续 5-8秒 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 对象池 | ← 调用 | `checkout(type) -> Node2D` | 获取天体节点 |
| 对象池 | ← 调用 | `return_to_pool(node)` | 离屏天体归还 |
| 质量/成长 | ← 读取 | `get_absolute_mass()`, `get_current_stage()` | 决定生成物大小分布和难度 |
| 碰撞判定 | → 提供 | 天体的 `mass_value` 属性 | 碰撞时比较质量 |
| 引力吸附 | → 间接 | 生成的小天体会被引力场吸附 | 位置由引力系统修改 |
| 区域系统 | ← 读取(Demo) | 当前区域的天体种类表 | 不同区域生成不同类型 |

## Formulas

### 1. 食物质量分布 (Food Mass Distribution)

`food_mass = player_absolute_mass * random_range(mass_ratio_min, mass_ratio_max)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| player_absolute_mass | M_p | float | 0-12100+ | 玩家当前质量 |
| mass_ratio_min | R_min | float | 0.01-0.05 | 最小食物的质量比（微小碎片） |
| mass_ratio_max | R_max | float | 0.5-0.8 | 最大食物的质量比（接近玩家大小） |

**Distribution:** 偏向小值的指数分布——小食物频繁，大食物稀少
**Example:** M_p=500, R_min=0.02, R_max=0.7 → food_mass ∈ [10, 350]，多数在 10-80 之间

### 2. 威胁质量分布 (Threat Mass Distribution)

`threat_mass = player_absolute_mass * random_range(threat_ratio_min, threat_ratio_max)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| threat_ratio_min | T_min | float | 1.2-1.5 | 最小威胁比（刚好比玩家大） |
| threat_ratio_max | T_max | float | 3.0-8.0 | 最大威胁比（远大于玩家） |

**Output Range:** 总是 > player_absolute_mass
**Example:** M_p=500, T_min=1.2, T_max=5.0 → threat_mass ∈ [600, 2500]

### 3. 波次生成节奏 (Wave Timing)

`next_wave_time = wave_interval + random_range(-wave_jitter, wave_jitter)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| wave_interval | W_i | float | 1.0-3.0 s | 波次基础间隔 |
| wave_jitter | W_j | float | 0.2-0.5 s | 随机抖动（避免机械节奏） |
| wave_size | W_s | int | 3-8 | 每波生成天体数 |

**Example:** W_i=2.0, W_j=0.3 → next_wave 在 1.7-2.3s 之间随机

### 4. 漂移速度 (Drift Speed)

`drift_speed = random_range(min_drift, max_drift) * stage_speed_multiplier[current_stage]`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| min_drift | V_min | float | 30-60 px/s | 最慢漂移 |
| max_drift | V_max | float | 100-200 px/s | 最快漂移 |
| stage_speed_multiplier | S_m[] | float[] | [1.0, 1.0, 1.1, 1.2, 1.3, 1.5] | 后期天体更快 |

**Output Range:** 30-300 px/s
**Example:** 阶段4, min=50, max=150, S_m=1.2 → drift ∈ [60, 180] px/s

## Edge Cases

- **If 对象池返回 null（池耗尽）**: 跳过本次生成，下一波重试。不崩溃，不创建裸节点。画面可能短暂变空旷但会自然恢复。

- **If 玩家不动且不吃任何东西（AFK）**: 天体继续生成和漂流，离屏后回收。画面保持"宇宙活着"的状态。密度不会无限累积（max_active_objects 限制）。

- **If 进化刚完成，玩家质量跳变**: 下一波生成立即使用新质量计算大小分布。之前已在屏幕上的天体保持原有 mass_value 不变——曾经的威胁可能瞬间变成食物（这是进化的爽感来源之一）。

- **If 紧张波次期间触发进化**: 紧张波次立即结束，进化后恢复正常生成比例。进化是奖励时刻，不应叠加威胁。

- **If 同屏大量天体被引力吸入并快速消失**: active_count 下降 → 系统快速恢复生成 → 画面自动填充。但不会同一帧大量生成（每帧最多 wave_size 个）。

- **If 玩家在屏幕边缘附近**: 减少该方向的生成（避免天体从玩家"身后"紧贴出现，给予反应时间）。具体：玩家距屏幕某边 < 100px 时，该边不生成威胁体。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 对象池 | `checkout()`, `return_to_pool()` | 硬 | 节点的唯一获取/归还途径 |
| 质量/成长 | `get_absolute_mass()`, `get_current_stage()` | 硬 | 大小分布的计算基础 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 碰撞判定 | 天体的 mass_value 属性 | 硬 | 碰撞时读取 |
| 引力吸附 | 天体位置 | 软 | 引力修改天体位置 |
| 区域系统 | 天体种类配置 | 软（MVP无区域） | Demo 后需要区域特有天体 |

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `max_active_objects` | 25 | 12-50 | 画面过于密集→信息过载→焦虑 | 画面空旷→无事可做→无聊 | 画面密度/视觉呼吸感 |
| `food_ratio` | 0.75 | 0.6-0.85 | 食物太多→无挑战 | 食物太少→威胁太多→焦虑 | 安全感 vs 紧张感 |
| `wave_interval` | 2.0 s | 1.0-3.0 | 太慢→节奏拖沓 | 太快→信息过载 | 游戏节奏快慢 |
| `wave_size` | 5 | 3-8 | 每波太多→瞬间拥挤 | 每波太少→成长缓慢 | 每波的"丰收感" |
| `mass_ratio_max` | 0.7 | 0.5-0.8 | 大食物太多→大口吃感太频繁 | 大食物太少→都是碎屑无满足感 | 吞噬时的"大餐"感 |
| `threat_ratio_max` | 5.0 | 3.0-8.0 | 威胁太巨大→恐怖感过强 | 威胁不明显→缺乏紧张 | 威胁的压迫感 |
| `stage_speed_multiplier` | [1,1,1.1,1.2,1.3,1.5] | 各×0.8-1.5 | 后期太快→焦虑 | 后期太慢→无挑战提升 | 难度递进感 |

**交互关系：**
- `max_active_objects` × `wave_interval` × `wave_size` 共同决定"屏幕上总有多少东西"
- `food_ratio` × `mass_ratio_max` 共同决定"吃东西的频率和满足感"
- `stage_speed_multiplier` 与玩家移动系统的 `max_speed` 形成对抗——天体速度不应超过玩家最大速度

## Acceptance Criteria

1. **GIVEN** 游戏开始，**WHEN** 第一波计时器到期，**THEN** wave_size 个天体从屏幕边缘外出现并开始漂入。

2. **GIVEN** 玩家 absolute_mass=500，**WHEN** 生成食物，**THEN** 食物 mass_value < 500（严格小于玩家）。

3. **GIVEN** 玩家 absolute_mass=500，**WHEN** 生成威胁，**THEN** 威胁 mass_value ≥ 600（至少 1.2 倍于玩家）。

4. **GIVEN** active_count = max_active_objects，**WHEN** 波次计时器到期，**THEN** 不生成新天体，等待空间释放。

5. **GIVEN** 天体漂出屏幕外 100px，**WHEN** 下一帧检查，**THEN** 天体被归还对象池，active_count 减少。

6. **GIVEN** 进化发生使 mass 从 500 跳到 600，**WHEN** 屏幕上有 mass_value=550 的天体，**THEN** 该天体现在视觉上作为"食物"（碰撞判定会判为吞噬），但其 mass_value 不变。

7. **GIVEN** 食物方向偏置生效，**WHEN** 统计 100 个食物生成方向，**THEN** 约 60% 来自玩家移动方向的前方半球。

8. **GIVEN** 玩家位于屏幕右边缘 < 100px，**WHEN** 威胁体生成，**THEN** 不从右侧边缘生成威胁体。

9. **GIVEN** 紧张波次激活，**WHEN** 同时触发进化，**THEN** 紧张波次立即终止，恢复正常比例。

10. **性能**: 单帧生成逻辑（含 wave_size 个 checkout 调用）< 1.0ms。
