# 碰撞判定系统 (Collision System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 一目了然, 心流至上

## Overview

碰撞判定系统是星噬核心循环的裁判——它在玩家天体与任何其他天体重叠时，判定结果是"吞噬"还是"死亡"。判定规则极其简单：玩家的绝对质量 > 对方质量 = 吞噬（对方消失，玩家成长）；反之 = 死亡（玩家回退）。这个二元判定是整个游戏紧张感的来源：每个接近的天体都是一个瞬间决策——能吃还是该躲？系统依赖"一目了然"支柱确保玩家在碰撞发生前就能通过视觉尺寸预判结果。

## Player Fantasy

每一次接近都是一场赌注——"我比它大吗？"这个问题的答案在碰撞的瞬间揭晓。当判定为吞噬时，玩家感受到的是捕食者的满足；当判定为死亡时，感受到的是"我不该贪心"的瞬间后悔。碰撞系统的幻想是：宇宙中只有一条法则——大鱼吃小鱼，没有例外，没有运气，只有你对尺寸的判断力。

## Detailed Design

### Core Rules

1. **碰撞检测**：使用 Godot 的 `Area2D` 碰撞。玩家天体和所有 NPC 天体都拥有 `CircleShape2D` 碰撞体，半径等于各自的 `visual_radius`。

2. **碰撞触发**：当两个 Area2D 重叠时（`area_entered` 信号），碰撞判定开始。

3. **质量比较**：
   - 获取玩家的 `absolute_mass`（来自质量/成长系统）
   - 获取对方天体的 `mass_value`（物体生成系统在创建时赋予）
   - 如果 `player_absolute_mass > target_mass_value` → 吞噬
   - 如果 `player_absolute_mass <= target_mass_value` → 死亡

4. **吞噬流程**：
   - 调用质量/成长系统的 `add_mass(target_mass_value)`
   - 广播信号 `body_consumed(target_node, mass_value)`（粒子/VFX系统和音频系统监听）
   - 将目标天体归还对象池

5. **死亡流程**：
   - 广播信号 `player_killed(killer_node)`（死亡/重生系统监听）
   - 不修改质量系统状态（回退由死亡/重生系统通过进化阶段系统处理）

6. **碰撞体半径同步**：玩家天体的 `CircleShape2D` 半径必须与质量/成长系统的 `get_visual_radius()` 保持同步。每次质量变化时更新碰撞体。

### States and Transitions

碰撞判定系统无内部状态——它是纯事件驱动的反应式系统。每次碰撞独立判定，无累积状态。

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 质量/成长 | ← 读取 | `get_absolute_mass() -> float` | 获取玩家当前绝对质量 |
| 质量/成长 | → 调用 | `add_mass(value: float)` | 吞噬成功时增加质量 |
| 质量/成长 | ← 读取 | `get_visual_radius() -> float` | 同步碰撞体半径 |
| 物体生成 | ← 读取 | 目标天体的 `mass_value` 属性 | 获取对方质量 |
| 对象池 | → 调用 | `return_to_pool(node)` | 被吞噬的天体归还池 |
| 死亡/重生 | → 信号 | `player_killed(killer)` | 通知死亡 |
| 粒子/VFX | → 信号 | `body_consumed(node, mass)` | 触发吞噬特效 |
| 音频 | → 信号 | `body_consumed(node, mass)` | 触发吞噬音效 |
| 玩家移动 | ← 读取 | `get_position()` | Area2D 位置由移动系统决定 |

## Formulas

### 1. 碰撞判定公式 (Collision Resolution)

`result = "consume" if player_absolute_mass > target_mass_value else "death"`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| player_absolute_mass | M_p | float | 0-12100+ | 来自质量/成长系统 |
| target_mass_value | M_t | float | 0.5-10000+ | 目标天体的固定质量值 |

**Output:** 二元——"consume" 或 "death"
**Example:** M_p=850, M_t=200 → 850 > 200 → consume

### 2. 碰撞体半径同步 (Collision Shape Sync)

`collision_radius = visual_radius * collision_scale`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| visual_radius | R_v | float | 16-224 px | 来自质量/成长系统 |
| collision_scale | C_s | float | 0.7-1.0 | 碰撞体与视觉体的比例（略小于视觉，宽容判定） |

**Output Range:** 11.2-224 px
**Example:** R_v=60, C_s=0.85 → collision_radius = 51px（碰撞体比视觉小15%，给玩家"擦过"的惊险感）

## Edge Cases

- **If 玩家质量恰好等于对方质量（M_p == M_t）**: 判定为死亡。设计意图：平手时玩家不占优势，鼓励"只吃确定比自己小的"策略。

- **If 同一帧多个天体同时碰撞玩家**: 按 area_entered 信号的触发顺序依次处理。如果第一个是吞噬（增加质量），第二个的判定使用增加后的新质量——可能导致"连吃"。如果第一个导致死亡，后续碰撞不再处理（死亡优先）。

- **If 死亡信号触发后同帧还有吞噬碰撞排队**: 死亡状态下忽略所有后续碰撞。通过设置 `is_dead` 标志位在判定前检查。

- **If 玩家正在进化动画中发生碰撞**: 进化动画期间启用无敌帧（碰撞判定暂停）——进化是奖励时刻，不应被打断。无敌帧时长由进化阶段系统控制。

- **If 天体正在被引力吸入过程中（还没碰到）**: 不触发碰撞——只有 Area2D 实际重叠才判定。引力吸附加速物体接近但不跳过碰撞检测。

- **If collision_scale < 1.0 导致视觉重叠但碰撞未触发**: 这是设计意图——给玩家"擦肩而过"的惊险体验。视觉上看起来很近但碰撞体稍小，营造紧张感。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 质量/成长 | `get_absolute_mass()`, `add_mass()`, `get_visual_radius()` | 硬 | 判定的核心数据来源 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 死亡/重生 | signal `player_killed` | 硬 | 触发死亡流程 |
| 粒子/VFX | signal `body_consumed` | 软 | 触发视觉反馈 |
| 音频 | signal `body_consumed` | 软 | 触发音频反馈 |
| 图鉴收集 | signal `body_consumed` | 软 | 记录吞噬的天体种类 |

**接口契约：**
- 碰撞判定结果在碰撞发生的同一帧内确定并广播，无延迟
- `body_consumed` 信号在 `add_mass()` 调用之后发出（保证监听者读取到更新后的质量）
- `player_killed` 信号发出后，本系统停止所有后续判定直到死亡/重生系统发出复活信号

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `collision_scale` | 0.85 | 0.7-1.0 | =1.0时碰撞=视觉，无容错→玩家挫败感强 | <0.7时视觉明显穿模→失去真实感 | "擦肩而过"的惊险度 |
| `invincibility_duration` | 由进化阶段系统控制 | 1.0-3.0 s | 太长→进化后无风险期太安全 | 太短→进化刚完成就被撞死→极度挫败 | 进化时刻的安全感 |

**交互关系：**
- `collision_scale` < 1.0 意味着视觉上"很近"但碰撞未发生——配合 Art Bible "危险逼近"的色温变化产生紧张感
- 质量/成长系统的 `visual_radius` 变化直接影响碰撞体大小——进化后碰撞体突然变大需要确保不会立即与已在附近的物体碰撞（由无敌帧保护）

## Acceptance Criteria

1. **GIVEN** 玩家 absolute_mass=500，**WHEN** 碰到 mass_value=200 的天体，**THEN** 判定为吞噬，玩家质量增加 200，目标天体消失。

2. **GIVEN** 玩家 absolute_mass=500，**WHEN** 碰到 mass_value=500 的天体（相等），**THEN** 判定为死亡，`player_killed` 信号触发。

3. **GIVEN** 玩家 absolute_mass=500，**WHEN** 碰到 mass_value=800 的天体，**THEN** 判定为死亡，玩家质量不变。

4. **GIVEN** collision_scale=0.85 且 visual_radius=60px，**WHEN** 另一天体中心距离玩家中心=55px，**THEN** 视觉上重叠但碰撞未触发（碰撞半径=51px，双方碰撞体未重叠）。

5. **GIVEN** 进化动画正在播放，**WHEN** 天体碰到玩家，**THEN** 无判定发生（无敌帧生效）。

6. **GIVEN** 同帧两个天体碰撞玩家（mass_value=100 和 mass_value=50），**WHEN** 依次处理，**THEN** 第一个吞噬后质量增加 100，第二个使用更新后的质量判定（也吞噬）。

7. **GIVEN** 死亡判定已触发，**WHEN** 同帧还有其他碰撞待处理，**THEN** 后续碰撞全部忽略。

8. **GIVEN** 玩家质量变化，**WHEN** 下一帧碰撞检测，**THEN** 碰撞体半径已同步更新。

9. **性能**: 单次碰撞判定（含信号广播）< 0.1ms。同帧最大碰撞处理数 ≤ 10（超出部分延迟到下帧）。
