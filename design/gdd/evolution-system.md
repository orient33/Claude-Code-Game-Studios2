# 进化阶段系统 (Evolution Stage System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 尺度震撼, 宇宙奇观

## Overview

进化阶段系统管理玩家天体从尘埃到黑洞的6阶变身过程——它监听质量/成长系统的 `evolution_ready` 信号，触发进化流程（变身动画、无敌帧、镜头拉远协调、形态切换），并在死亡时执行阶段回退。进化是整个游戏的高潮时刻：每次变身都是对玩家"你成长了"的最大视觉奖励。系统同时管理进化期间的无敌帧，保护玩家在最激动的时刻不被打断。

## Player Fantasy

"我正在蜕变为更高级的存在。"进化的瞬间是星噬中最令人狂喜的体验——屏幕爆发白光，天体形态蜕变，镜头拉远揭示新的宇宙尺度，曾经的巨物变成了新的食物。这不是简单的"升级"，而是存在层次的跃迁——从一粒尘埃成长为吞噬一切的黑洞的旅程中，每一次进化都是"我比之前强大了一个量级"的确认。

## Detailed Design

### Core Rules

1. **进化触发**：监听质量/成长系统的 `evolution_ready` 信号。收到信号后启动进化流程。

2. **进化流程**（总时长约 2.5-3.0秒）：
   - **积蓄期**（0-0.6s）：亮度上升，天体开始膨胀发光。玩家仍可操控。
   - **爆发期**（0.6-1.0s）：全屏白化，旧形态消融，新形态在白光中成型。操控暂停。
   - **新生期**（1.0-2.5s）：白光消退，新形态首次完整显现。镜头开始拉远。操控恢复。

3. **形态切换**：爆发期中将天体的视觉外观从当前阶段切换到下一阶段（更新 sprite/shader 参数、层级结构、发光行为）。

4. **无敌帧**：从积蓄期开始到新生期结束（整个进化流程期间），碰撞判定暂停。持续 `invincibility_duration` 秒。

5. **通知质量/成长系统**：进化流程完成后调用 `mass_growth.set_stage(current_stage + 1, overflow_progress)` 完成阶段提升。

6. **死亡回退**：收到死亡/重生系统的回退指令时，执行反向流程：
   - 白闪（0.15s）→ 碎裂/灰暗（1.0s）→ 新形态亮起（1.5s）
   - 调用 `mass_growth.set_stage(target_stage, 0.0)` 执行回退

7. **阶段上限**：阶段6（黑洞）后不再触发进化。`evolution_ready` 信号在阶段6被忽略。

8. **进化进度指示**：向UI系统提供 `get_evolution_progress() -> float`（0.0-1.0）用于进度弧显示。

### States and Transitions

| 状态 | 持续时间 | 操控 | 碰撞 |
|------|---------|------|------|
| Idle（等待中）| 持续 | 正常 | 正常 |
| Accumulating（积蓄）| 0.6s | 正常 | 关闭（无敌） |
| Bursting（爆发）| 0.4s | 暂停 | 关闭（无敌） |
| Emerging（新生）| 1.5s | 恢复 | 关闭（无敌） |
| Dying（死亡播放）| 2.5s | 暂停 | 关闭 |

转换：
- Idle → Accumulating：`evolution_ready` 信号
- Accumulating → Bursting：0.6s 计时到
- Bursting → Emerging：0.4s 计时到
- Emerging → Idle：1.5s 计时到，无敌帧结束
- Idle → Dying：`player_killed` 信号
- Dying → Idle：回退完成，`respawn_completed` 信号

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 质量/成长 | ← 信号 | `evolution_ready` | 触发进化 |
| 质量/成长 | → 调用 | `set_stage(stage, progress)` | 完成进化/死亡回退 |
| 碰撞判定 | → 通知 | `invincibility_active: bool` | 碰撞系统检查此标志 |
| 镜头 | → 信号 | `evolution_started`, `evolution_completed` | 触发镜头拉远 |
| 死亡/重生 | ← 调用 | `execute_death_rollback(stage)` | 执行阶段回退 |
| 死亡/重生 | → 信号 | `respawn_completed` | 回退完成通知 |
| 粒子/VFX | → 信号 | `evolution_phase_changed(phase)` | 触发各阶段视觉特效 |
| 音频 | → 信号 | `evolution_phase_changed(phase)` | 触发进化音效序列 |

## Formulas

### 1. 无敌帧总时长 (Invincibility Duration)

`invincibility_duration = accumulate_time + burst_time + emerge_time`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| accumulate_time | T_a | float | 0.4-0.8 s | 积蓄期时长 |
| burst_time | T_b | float | 0.3-0.5 s | 爆发期时长 |
| emerge_time | T_e | float | 1.0-2.0 s | 新生期时长 |

**Output Range:** 1.7-3.3 s
**Default:** 0.6 + 0.4 + 1.5 = 2.5s

### 2. 进化进度（用于HUD弧线显示）

`evolution_progress = mass_growth.get_stage_progress()`

直接透传质量/成长系统的阶段进度值（0.0-1.0）。

## Edge Cases

- **If 进化期间收到第二个 `evolution_ready`（连续进化溢出）**: 队列等待。当前进化完成后立即启动下一次进化（Emerging → Accumulating 无 Idle 间隔）。

- **If 死亡回退到阶段1（最低阶段）**: 正常回退到 stage=1, progress=0.0。这是最大惩罚——从头开始当前区域。

- **If 死亡回退期间手指仍在屏幕上**: 忽略所有移动输入直到 `respawn_completed`。重生后以手指当前位置重新建立 touch_offset。

- **If 阶段6收到 `evolution_ready`**: 忽略。不执行进化流程。质量/成长系统的 stage_progress 继续累积但无视觉事件。

- **If 进化期间游戏被暂停（后台/暂停菜单）**: 进化计时器暂停。恢复后从暂停点继续。不跳过任何动画阶段。

- **If 网络延迟导致信号延迟到达（未来多人扩展预留）**: 不适用——单机游戏，信号同帧到达。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 质量/成长 | `evolution_ready` 信号, `set_stage()` | 硬 | 触发源和状态写入 |
| 死亡/重生 | `player_killed` 信号 | 硬 | 回退触发源 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 碰撞判定 | `invincibility_active` | 硬 | 控制碰撞暂停 |
| 镜头 | 进化信号 | 硬 | 触发缩放变化 |
| 粒子/VFX | `evolution_phase_changed` | 软 | 视觉特效 |
| 音频 | `evolution_phase_changed` | 软 | 音效 |
| 存档检查点 | `evolution_completed` | 硬 | 进化完成时自动存档 |

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `accumulate_time` | 0.6s | 0.4-0.8 | 太长→进化"启动慢"，失去冲击力 | 太短→玩家来不及意识到"正在进化" | 进化的"蓄力感" |
| `burst_time` | 0.4s | 0.3-0.5 | 太长→操控暂停时间过长→焦虑 | 太短→爆发不够震撼 | 高潮时刻的持续感 |
| `emerge_time` | 1.5s | 1.0-2.0 | 太长→无敌帧太久→无风险 | 太短→来不及欣赏新形态 | 新生的"展示时间" |
| `death_blackout_time` | 1.0s | 0.5-1.5 | 太长→等待烦躁 | 太短→死亡没有"重量感" | 死亡的"肃穆感" |

## Acceptance Criteria

1. **GIVEN** 质量/成长系统发出 `evolution_ready`，**WHEN** 进化流程开始，**THEN** 无敌帧立即激活，碰撞判定暂停。

2. **GIVEN** 进化流程进入爆发期，**WHEN** 检查玩家操控，**THEN** 移动输入被忽略，天体静止。

3. **GIVEN** 进化流程完成（新生期结束），**WHEN** 检查 `current_stage`，**THEN** 已从 N 变为 N+1。

4. **GIVEN** 进化完成后，**WHEN** 无敌帧结束，**THEN** 碰撞判定恢复正常。

5. **GIVEN** 死亡回退触发，**WHEN** 回退到阶段2，**THEN** `set_stage(2, 0.0)` 被调用，视觉形态切换到阶段2。

6. **GIVEN** 阶段6收到 `evolution_ready`，**WHEN** 检查系统状态，**THEN** 无进化流程触发，系统保持 Idle。

7. **GIVEN** 进化中连续溢出触发第二次 `evolution_ready`，**WHEN** 第一次进化完成，**THEN** 第二次进化立即开始，无间隔。

8. **性能**: 进化流程的状态管理每帧 < 0.05ms（不含 VFX/音频的实际渲染）。
