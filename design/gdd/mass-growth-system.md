# 质量/成长系统 (Mass & Growth System)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 尺度震撼, 一目了然

## Overview

质量/成长系统是星噬的核心数据层——它拥有玩家天体的唯一质量值（mass），并通过信号广播质量变化事件。所有依赖系统（碰撞判定、引力吸附、物体生成、镜头、进化阶段、存档、死亡/重生）均通过读取此系统的质量值来驱动各自行为。该系统不直接产生任何视觉或音频输出，但它的每一次数值变动都是其他系统产生可见反馈的触发源。玩家不会意识到这个系统的存在——他们感受到的是"我在变大"，而这个感受的底层真相就是 mass 值的单调递增。

## Player Fantasy

玩家不会意识到"质量系统"的存在。他们感受到的是：每一次吞噬都让我**不可逆地**变得更强大。这种感受来自质量值的单调递增特性——你永远不会无缘无故缩小（死亡回退是进化系统的职责，不是质量系统自发的行为）。质量系统的间接幻想是"宇宙中最基本的真理：质量即权力，质量即引力，质量即存在感"。

## Detailed Design

### Core Rules

1. 玩家天体拥有两个核心状态值：
   - `current_stage: int` — 当前进化阶段（1-6）
   - `stage_progress: float` — 当前阶段内的进度（0.0 → 1.0）

2. 每个可吞噬物体拥有一个固定的 `mass_value: float` 属性，由物体生成系统在创建时赋予。

3. 吞噬发生时：`stage_progress += mass_value / stage_threshold[current_stage]`

4. 当 `stage_progress >= 1.0` 时：
   - 触发信号 `evolution_ready`（进化阶段系统监听）
   - `stage_progress` 溢出部分保留（不浪费最后一口的多余质量）
   - 进化完成后：`current_stage += 1`，`stage_progress = overflow`

5. 质量值只在吞噬事件中增加，不自然衰减，不受时间影响（单调递增保证）。

6. 死亡回退时，进化阶段系统直接设置 `current_stage` 和 `stage_progress`（本系统只接收指令，不自主决定回退）。

### States and Transitions

| 状态 | 条件 | 转出 |
|------|------|------|
| Growing（成长中）| stage_progress < 1.0 | → Ready to Evolve |
| Ready to Evolve（准备进化）| stage_progress >= 1.0 | → Growing (进化完成后 stage+1, progress=overflow) |
| Max Stage（终极形态）| current_stage == 6 | 无转出——黑洞阶段 progress 继续累积但不再触发进化 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 碰撞判定 | → 读取 | `get_current_mass() -> float` | 返回绝对质量用于大小比较 |
| 碰撞判定 | → 调用 | `add_mass(value: float)` | 吞噬成功时调用 |
| 引力吸附 | → 读取 | `get_current_mass() -> float` | 计算引力范围 |
| 物体生成 | → 读取 | `get_current_stage() -> int` | 决定生成物的大小分布 |
| 镜头 | → 读取 | `get_visual_radius() -> float` | 决定镜头缩放级别 |
| 进化阶段 | ← 监听 | signal `evolution_ready` | 触发进化流程 |
| 进化阶段 | → 调用 | `set_stage(stage, progress)` | 进化完成或死亡回退时重设 |
| 存档 | → 读取 | `get_state() -> Dictionary` | 序列化当前状态 |
| 存档 | → 调用 | `restore_state(data: Dictionary)` | 恢复存档状态 |

**辅助接口：**
- `get_absolute_mass() -> float` = 累计所有阶段的质量总和（用于碰撞比较）
- `get_stage_progress() -> float` = 当前阶段进度 0.0-1.0（用于 HUD 进度弧）
- `get_visual_radius() -> float` = 基于质量计算的视觉半径（用于碰撞体和渲染）
- signal `mass_changed(new_progress: float)` — 每次质量变化时广播
- signal `evolution_ready` — stage_progress >= 1.0 时触发

## Formulas

### 1. 阶段阈值公式 (Stage Threshold)

`stage_threshold[n] = base_threshold * growth_factor ^ (n - 1)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_threshold | T₀ | float | 50-200 | 第1阶段（尘埃→陨石）所需的总吞噬量 |
| growth_factor | G | float | 1.5-3.0 | 每阶段阈值递增倍数 |
| n | n | int | 1-5 | 阶段编号（第6阶段无阈值） |

**Output Range:** stage_threshold[1]=100, stage_threshold[5]=8100 (G=3时)
**Example:** T₀=100, G=3 → 阈值为 [100, 300, 900, 2700, 8100]

### 2. 视觉半径公式 (Visual Radius)

`visual_radius = base_radius * radius_scale[current_stage] * (1.0 + stage_progress * intra_stage_growth)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_radius | R₀ | float | 16-32 px | 尘埃阶段的基础半径 |
| radius_scale | S[n] | float[] | [1.0, 1.5, 2.2, 3.5, 5.0, 7.0] | 各阶段的半径倍数 |
| stage_progress | P | float | 0.0-1.0 | 当前阶段进度 |
| intra_stage_growth | I | float | 0.2-0.5 | 阶段内成长带来的半径增幅比例 |

**Output Range:** 16px（尘埃起始）→ 224px（黑洞满级, R₀=32时）
**Example:** R₀=24, stage=3, P=0.5, I=0.3 → 24 * 2.2 * (1.0 + 0.5 * 0.3) = 24 * 2.2 * 1.15 = 60.7px

### 3. 绝对质量公式 (Absolute Mass)

`absolute_mass = sum(stage_threshold[1..current_stage-1]) + stage_progress * stage_threshold[current_stage]`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| stage_threshold[] | T[] | float[] | — | 各阶段阈值（由公式1计算） |
| current_stage | n | int | 1-6 | 当前阶段 |
| stage_progress | P | float | 0.0-1.0 | 当前进度 |

**Output Range:** 0（初始）→ 12100+（5阶段全完成, T₀=100,G=3时）
**Example:** stage=3, P=0.5, thresholds=[100,300,900...] → (100+300) + 0.5*900 = 850

**用途:** 碰撞判定用 absolute_mass 比较双方大小。玩家的 absolute_mass > 物体的 mass_value → 可吞噬；反之 → 死亡。

## Edge Cases

- **If `stage_progress` 溢出超过 1.0 很多**（一次吞噬巨大物体）: 溢出部分保留并传递到新阶段。若溢出超过下一阶段的整个阈值（极端情况），递归处理直到溢出 < 1.0，触发连续进化（多次进化信号依序发送，每次间隔由进化阶段系统的动画时间决定）。

- **If `current_stage == 6` 且继续吞噬**: `stage_progress` 继续累积超过 1.0，但不再触发 `evolution_ready`。此值可被图鉴系统用于记录"黑洞阶段最高质量"成就。

- **If `add_mass(0)` 被调用**（零质量物体）: 忽略，不广播 `mass_changed` 信号，不产生任何副作用。

- **If `add_mass(negative)` 被调用**: 断言失败（debug模式）或 clamp 到 0（release模式）。本系统不支持质量减少——减少是进化阶段系统通过 `set_stage()` 实现的回退。

- **If `set_stage()` 设置的阶段 > 当前阶段**: 允许（用于debug跳关或未来可能的加速道具），视为"向前设置"。

- **If `set_stage()` 设置的阶段 < 1 或 > 6**: Clamp 到 [1, 6]。

- **If 同一帧内多个物体同时被吞噬**（引力吸附批量触发）: 依次调用 `add_mass()`，每次都广播信号。若累计后越过阈值，只触发一次 `evolution_ready`。

- **If `restore_state()` 传入无效数据**（损坏存档）: 回退到默认初始状态（stage=1, progress=0.0），记录警告日志。

## Dependencies

**上游依赖（本系统需要的）：** 无——质量/成长系统是零依赖的 Foundation 层。

**下游依赖（需要本系统的）：**

| 系统 | 接口 | 硬/软依赖 | 描述 |
|------|------|-----------|------|
| 碰撞判定 | `get_absolute_mass()`, `add_mass()` | 硬 | 无法判定吃/死 without 质量数据 |
| 引力吸附 | `get_current_mass()` | 硬 | 无法计算引力范围 without 质量值 |
| 物体生成 | `get_current_stage()` | 硬 | 无法决定生成物大小分布 without 阶段信息 |
| 镜头 | `get_visual_radius()` | 硬 | 无法决定缩放级别 without 半径 |
| 进化阶段 | signal `evolution_ready`, `set_stage()` | 硬 | 互为关键通信 |
| 存档检查点 | `get_state()`, `restore_state()` | 硬 | 无法持久化 without 序列化接口 |
| 死亡/重生 | 通过进化阶段间接 | 软 | 死亡系统调用进化系统的回退，进化系统再调用 `set_stage()` |
| 粒子/VFX | signal `mass_changed` | 软 | 监听信号产生吞噬特效，不影响核心功能 |

**接口契约：**
- 本系统保证 `get_absolute_mass()` 返回值单调递增（除非 `set_stage()` 被外部调用）
- 本系统保证所有 signal 在同一帧内状态变化完成后发出（不会发出中间状态）
- 本系统保证 `get_state()` / `restore_state()` 是完整可逆的（序列化→反序列化=原始状态）

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `base_threshold` | 100 | 50-200 | 每阶段需要吞噬更多物体→节奏偏慢 | 几口就进化→缺乏成就感 | 每次进化的"份量感" |
| `growth_factor` | 3.0 | 1.5-4.0 | 后期阶段极长→玩家可能中途放弃 | 所有阶段时间接近→进化节奏平淡 | 后期的"挑战升级感" |
| `base_radius` | 24 px | 16-32 | 初始天体太大→画面拥挤 | 初始天体太小→难以看清和操控 | 起始阶段的视觉存在感 |
| `radius_scale[]` | [1.0, 1.5, 2.2, 3.5, 5.0, 7.0] | 每级1.3-2.0倍增幅 | 后期天体占满屏幕→镜头拉远太多 | 进化后视觉变化不明显→缺少"震撼感" | 进化时刻的视觉冲击力 |
| `intra_stage_growth` | 0.3 | 0.1-0.5 | 阶段内成长太明显→进化对比减弱 | 吞噬了很多但看不出变化→反馈不足 | 持续游玩中的"我在长大"感 |

**交互关系：**
- `base_threshold` × `growth_factor` 共同决定全局游玩时长——调一个必须检查另一个
- `radius_scale[]` × `intra_stage_growth` 共同决定视觉尺度曲线——调半径必须同步调镜头系统的缩放参数
- `growth_factor` 设太高会让后期物体生成系统压力大（需要生成足够多的物体供玩家吞噬）

## Acceptance Criteria

1. **GIVEN** 玩家处于阶段1、progress=0.0，**WHEN** 吞噬一个 mass_value=10 的物体，**THEN** stage_progress 增加 10/base_threshold（默认=0.1），signal `mass_changed` 被触发一次。

2. **GIVEN** 玩家处于阶段2、progress=0.95，**WHEN** 吞噬一个使 progress 超过 1.0 的物体，**THEN** signal `evolution_ready` 触发，溢出部分正确传递到阶段3的 progress。

3. **GIVEN** 玩家处于阶段6，**WHEN** 继续吞噬，**THEN** progress 超过 1.0 不触发 `evolution_ready`，值继续累积。

4. **GIVEN** 玩家处于任意阶段，**WHEN** `add_mass(0)` 被调用，**THEN** 无信号广播，state 不变。

5. **GIVEN** 玩家当前 absolute_mass=850，**WHEN** 调用 `get_absolute_mass()`，**THEN** 返回值精确等于 sum(已完成阶段阈值) + current_progress * current_threshold。

6. **GIVEN** 玩家处于阶段3、progress=0.5，**WHEN** 调用 `get_visual_radius()`，**THEN** 返回值等于 base_radius * radius_scale[3] * (1.0 + 0.5 * intra_stage_growth)，误差 < 0.01。

7. **GIVEN** 玩家状态被 `get_state()` 序列化为字典，**WHEN** 用该字典调用 `restore_state()`，**THEN** 之后的 `get_current_stage()`、`get_stage_progress()`、`get_absolute_mass()` 返回值与序列化前完全相同。

8. **GIVEN** 同一帧内 3 个物体同时被引力吸入，**WHEN** 依次调用 3 次 `add_mass()`，**THEN** 最多触发 1 次 `evolution_ready`（即使前两次未越过阈值但第三次越过）。

9. **GIVEN** 调用 `set_stage(1, 0.0)` 进行死亡回退，**WHEN** 回退完成，**THEN** `current_stage==1`，`stage_progress==0.0`，`get_absolute_mass()==0`。

10. **性能**: `add_mass()` 单次调用耗时 < 0.1ms（不含信号接收端处理时间）。
