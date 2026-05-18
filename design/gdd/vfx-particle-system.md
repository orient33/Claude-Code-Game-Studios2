# 粒子/VFX系统 (VFX & Particle System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 尺度震撼, 宇宙奇观, 心流至上

## Overview

粒子/VFX系统为星噬的所有游戏事件提供视觉反馈——从吞噬时的能量流入、进化时的光芒爆发、到引力场的微光圈和环境深空粒子。它是"尺度震撼"支柱的直接执行者：没有VFX，吞噬只是数字变化；有了VFX，吞噬变成了可见的能量吸收。系统在移动端 ≤300粒子/帧、≤8发射器同屏的性能预算内运作，通过 GPUParticles2D 优先和程序化动画最大化视觉冲击力。

## Player Fantasy

"每一次互动都有可见的宇宙回应。"当玩家吞噬天体时，不只是它"消失了"——而是能量流如同河流一般涌向玩家天体。当进化爆发时，全屏白光和粒子爆散让人感觉自己刚刚经历了一次超新星级别的事件。VFX系统的幻想是：你的每一个动作都在宇宙中留下可见的痕迹——涟漪、光芒、轨迹、能量流。宇宙因你的存在而生动。

## Detailed Design

### Core Rules

1. **事件驱动**：VFX系统不自主运行——它监听其他系统的信号并响应。每种游戏事件对应一个VFX配方（VFX Recipe）。

2. **VFX 事件表**：

| 事件 | 触发信号 | VFX 类型 | 优先级 | 预算分配 |
|------|---------|----------|--------|---------|
| 吞噬 | `body_consumed` | 能量流入粒子（径向向玩家） | High | 32粒子/次, 0.3s |
| 进化积蓄 | `evolution_phase_changed(accumulating)` | 天体膨胀光环 | Critical | 64粒子, 持续 |
| 进化爆发 | `evolution_phase_changed(bursting)` | 全向爆散+全屏白化 | Critical | 128粒子, 0.4s |
| 进化新生 | `evolution_phase_changed(emerging)` | 光芒退散+新形态光晕 | Critical | 64粒子, 1.5s |
| 死亡白闪 | `death_triggered` | 全屏白化+碎裂粒子 | Critical | 64粒子, 0.15s+1.0s |
| 重生亮起 | `respawn_triggered` | 中心微光渐亮 | Medium | 16粒子, 1.5s |
| 引力场指示 | 每帧（active时） | 极淡圆环光圈 | Low | shader绘制, 0粒子 |
| 危险逼近 | 威胁体进入感知范围 | 背景微粒加速+色温偏移 | Medium | shader参数调整 |
| 环境深空粒子 | 常驻 | 缓慢漂移的远景微粒 | Low | ≤32粒子/常驻 |

3. **优先级抢占**：当同时需要的粒子数超过预算（300）时，低优先级VFX被暂时压制（降低粒子数或跳过）。Critical优先级永远不被压制。

4. **程序化优先**：尽可能用 Tween + Shader 实现视觉效果，而非粒子发射器。粒子仅用于无法用 shader 表达的"多点独立运动"效果。

5. **缩放适配**：所有VFX的大小和密度随镜头缩放级别调整——进化后镜头拉远时，粒子不应变得微小不可见。

6. **Art Bible 合规**：
   - "寂生辉"：VFX只在事件触发时出现，不凭空持续发光
   - 同屏最多3处光源争夺视线
   - 进化光量是漂流的6倍以上

### States and Transitions

VFX系统无全局状态——每个VFX实例有独立生命周期：
| 状态 | 描述 |
|------|------|
| Inactive（未激活）| 粒子发射器停止，shader参数为默认 |
| Playing（播放中）| 发射粒子/动画进行中 |
| Fading（淡出中）| 停止新粒子发射，已有粒子自然消亡 |

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 碰撞判定 | ← 信号 | `body_consumed(node, mass)` | 触发吞噬VFX |
| 进化阶段 | ← 信号 | `evolution_phase_changed(phase)` | 触发进化VFX序列 |
| 死亡/重生 | ← 信号 | `death_triggered`, `respawn_triggered` | 触发死亡/重生VFX |
| 引力吸附 | ← 读取 | `gravity_radius` | 绘制引力场视觉圈 |
| 镜头 | ← 读取 | `get_zoom_level()` | 缩放适配 |
| 质量/成长 | ← 读取 | `get_current_stage()` | 阶段决定VFX主色调 |

## Formulas

### 1. 吞噬粒子数量（基于质量比）

`particle_count = base_consume_particles * clamp(target_mass / player_mass, 0.1, 1.0)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| base_consume_particles | P_b | int | 24-48 | 基础吞噬粒子数 |
| target_mass | M_t | float | — | 被吞噬天体质量 |
| player_mass | M_p | float | — | 玩家当前质量 |

**Output Range:** 3-48 粒子。吃微尘→少量粒子；吃接近自身大小的天体→大量粒子
**Example:** P_b=32, M_t=200, M_p=500 → 32 * clamp(0.4, 0.1, 1.0) = 32 * 0.4 = 13 粒子

### 2. 粒子预算实时检查 (Budget Check)

`available_budget = max_total_particles - current_active_particles`
`actual_spawn = min(requested_particles, available_budget)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| max_total_particles | P_max | int | 300 | 全局硬上限 |
| current_active_particles | P_active | int | 0-300 | 当前活跃粒子数 |

### 3. 缩放适配因子 (Zoom Adaptation)

`vfx_scale = 1.0 / zoom_level`

粒子大小和发射范围乘以此因子，确保镜头拉远后VFX不会变得不可见。

## Edge Cases

- **If 快速连续吞噬导致粒子预算耗尽**: 降级处理——减少每次吞噬的粒子数（`actual_spawn = min(requested, available)`），但保证至少 4 个粒子可见（最低反馈阈值）。

- **If 进化VFX（Critical）和多个吞噬VFX（High）同时需要**: 进化VFX获得完整预算分配，吞噬VFX被压制到剩余预算内。

- **If 镜头缩放中途VFX正在播放**: 已发射的粒子不改变大小（避免视觉跳变），新发射的粒子使用新的缩放因子。

- **If 设备性能不足（帧时间超标）**: 通过全局 `vfx_quality_level` 降级：减少粒子数上限（300→150→75）、禁用低优先级VFX、简化shader。

- **If 吞噬发生在进化爆发期间（理论上不可能因为无敌帧）**: 双重保护——即使信号意外到达，Critical优先级VFX不被中断。

- **If 引力场视觉圈随质量增长需要扩大**: 使用 shader uniform 参数动态调整圈大小，无粒子开销——纯GPU渲染。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 碰撞判定 | `body_consumed` 信号 | 硬 | 吞噬VFX触发 |
| 进化阶段 | `evolution_phase_changed` 信号 | 硬 | 进化VFX触发 |
| 死亡/重生 | 死亡/重生信号 | 硬 | 死亡VFX触发 |
| 引力吸附 | gravity_radius 数据 | 软 | 场视觉 |
| 镜头 | zoom_level | 软 | 缩放适配 |

**下游依赖：** 无——VFX是终端展示层，无系统依赖它。

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `max_total_particles` | 300 | 75-500 | GPU压力→掉帧 | VFX单薄→缺乏视觉冲击 | 视觉丰富度 vs 性能 |
| `base_consume_particles` | 32 | 16-48 | 每次吞噬粒子过多→视觉混乱 | 过少→吞噬反馈不足 | 吞噬的"满足感" |
| `evolution_burst_particles` | 128 | 64-200 | 太多→设备可能掉帧 | 太少→进化不够震撼 | 进化时刻的"壮观度" |
| `vfx_quality_level` | 3 (最高) | 1-3 | — | 低端设备降级保帧率 | 性能适配 |
| `gravity_ring_opacity` | 0.08 | 0.03-0.15 | 太亮→分散注意力 | 太暗→看不见引力场 | 引力场的"存在感" |

**交互关系：**
- `max_total_particles` 必须匹配设备GPU能力——低端设备自动降级
- `base_consume_particles` × 物体生成系统的吞噬频率 = 稳态粒子负载
- 进化VFX使用的 128 粒子在进化期间独占预算——其他VFX此时被压制

## Acceptance Criteria

1. **GIVEN** 吞噬事件触发，**WHEN** VFX响应，**THEN** 能量流粒子从被吞噬位置向玩家中心汇聚，持续 0.3s。

2. **GIVEN** 进化爆发期，**WHEN** VFX播放，**THEN** 128粒子全向爆散+全屏白化效果，持续 0.4s。

3. **GIVEN** 当前活跃粒子=280，吞噬请求32粒子，**WHEN** 预算检查，**THEN** 实际发射 20 粒子（300-280=20），不超预算。

4. **GIVEN** 进化VFX（Critical）正在播放，吞噬VFX（High）同时请求，**WHEN** 预算冲突，**THEN** 进化VFX不被影响，吞噬VFX使用剩余预算。

5. **GIVEN** zoom_level 从 2.0 变为 1.5（镜头拉远），**WHEN** 新粒子发射，**THEN** 粒子 scale = 1.0/1.5 ≈ 0.67，在新视角下保持合理可见大小。

6. **GIVEN** 引力场随质量增长，**WHEN** 检查引力视觉圈，**THEN** 圈的半径与 gravity_radius 同步，使用 shader 渲染无粒子开销。

7. **GIVEN** 无任何事件触发（纯漂流状态），**WHEN** 检查VFX，**THEN** 仅环境深空粒子（≤32）在运行，总负载极低。

8. **性能**: 粒子系统在满载（300粒子）时 GPU 时间 < 2ms。事件响应逻辑 < 0.1ms/帧。

9. **GIVEN** `vfx_quality_level` 从3降至1，**WHEN** 粒子上限变化，**THEN** 新上限=75，低优先级VFX自动禁用，无崩溃。
