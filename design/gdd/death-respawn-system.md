# 死亡/重生系统 (Death & Respawn System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 心流至上

## Overview

死亡/重生系统处理玩家碰到比自己大的天体后的后果——快速的死亡表现、阶段回退、和迅速的重新投入。系统的设计目标是"快进快出"：死亡产生短暂的震撼（0.15秒白闪+碎裂），然后在 2.5 秒内完成回退和重生，让玩家以最快速度回到游戏中。死亡不应让人愤怒或想放弃，而是让人想"再试一次"——服务"心流至上"支柱，死亡是节奏的短暂中断而非惩罚性的停顿。

## Player Fantasy

"骤然坠落——然后重新点燃。"死亡的感觉是高处踩空的一瞬失重，不是结束而是"从刚才的检查点再来"的短暂挫折。回退一个进化阶段有足够的后果让玩家在意（不想浪费时间重新吃回来），但不至于让人放弃（不是从头开始）。重生的感觉是"宇宙深处重新亮起一颗微弱的火星"——安静但充满希望。

## Detailed Design

### Core Rules

1. **死亡触发**：监听碰撞判定系统的 `player_killed(killer_node)` 信号。

2. **死亡表现**（总时长2.5秒，Art Bible 2.5节定义）：
   - **白闪**（0-0.15s）：全屏白化，突切（唯一允许的突切）
   - **碎裂/灰暗**（0.15-1.15s）：天体碎裂粒子效果，画面极暗，余光衰减
   - **静默期**（1.15-1.15s）：纯黑静止，让"空白"被感受到
   - **重生亮起**（1.15-2.5s）：新天体在中心以呼吸微光缓慢亮起

3. **阶段回退规则**：
   - 默认回退 1 个进化阶段：`new_stage = current_stage - 1`
   - 回退后 progress 重置为 0.0
   - 如果已在阶段1（最低）：不再回退，保持阶段1 progress=0.0
   - 通过进化阶段系统执行：`evolution_system.execute_death_rollback(target_stage)`

4. **操控暂停**：死亡表现期间玩家操控完全暂停（无移动输入响应）。重生亮起完成后恢复操控。

5. **位置重置**：重生时天体出现在死亡位置附近的安全区域——检查周围是否有威胁体，如有则偏移到最近的安全位置。

6. **重生无敌帧**：重生后给予额外 1.0s 无敌帧，防止"重生即死"。

7. **碰撞清除**：死亡瞬间将击杀者天体标记为"最近击杀源"，重生无敌帧结束前该天体如果仍在附近则被强制推离（避免原地循环死亡）。

### States and Transitions

| 状态 | 持续 | 操控 | 碰撞 |
|------|------|------|------|
| Alive（存活）| 持续 | 正常 | 正常 |
| Dying（死亡播放）| 2.5s | 暂停 | 关闭 |
| Respawning（重生中）| 即时 | 暂停 | 关闭 |
| Invulnerable（重生无敌）| 1.0s | 正常 | 关闭 |

转换：
- Alive → Dying：`player_killed` 信号
- Dying → Respawning：死亡表现完成
- Respawning → Invulnerable：位置重置完成，新形态显示
- Invulnerable → Alive：1.0s 无敌帧结束

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 碰撞判定 | ← 信号 | `player_killed(killer)` | 死亡触发源 |
| 进化阶段 | → 调用 | `execute_death_rollback(stage)` | 请求阶段回退 |
| 进化阶段 | ← 信号 | `respawn_completed` | 回退完成确认 |
| 质量/成长 | → 间接 | 通过进化阶段系统的 `set_stage()` | 质量/阶段回退 |
| 粒子/VFX | → 信号 | `death_triggered`, `respawn_triggered` | 死亡碎裂+重生特效 |
| 音频 | → 信号 | `death_triggered`, `respawn_triggered` | 死亡+重生音效 |
| 存档检查点 | ← 读取 | 获取回退目标阶段 | 确认上次存档的阶段 |

## Formulas

### 1. 回退目标阶段 (Rollback Target)

`target_stage = max(1, current_stage - rollback_stages)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| current_stage | S_c | int | 1-6 | 死亡时的阶段 |
| rollback_stages | R | int | 1 | 回退阶段数（固定为1） |

**Output Range:** 1-5
**Example:** S_c=4, R=1 → target=3. S_c=1, R=1 → target=1（不低于1）

### 2. 安全重生位置 (Safe Respawn Position)

`respawn_position = death_position + offset_from_threats`

如果 `death_position` 周围 `safe_radius` 内有威胁体：沿远离最近威胁体的方向偏移 `safe_offset` 像素。

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| safe_radius | R_s | float | 100-200 px | 安全检测范围 |
| safe_offset | O_s | float | 80-150 px | 偏移距离 |

## Edge Cases

- **If 死亡位置周围全是威胁体（无安全点）**: 重生在屏幕中心。极端情况下所有威胁体在重生无敌帧期间被强制推离。

- **If 重生无敌帧期间玩家主动冲向威胁体**: 无敌帧保护生效，碰撞不触发。无敌帧结束后如果仍在碰撞范围内则正常触发死亡。不做额外保护。

- **If 死亡回退目标阶段的存档检查点数据损坏**: fallback 到 stage=1, progress=0.0。

- **If 连续快速死亡（刚重生无敌帧结束就又碰到威胁）**: 正常触发第二次死亡。不增加额外保护。但如果 5 秒内死亡 3 次，记录为"困难区域"用于未来难度调整分析。

- **If 死亡动画期间游戏暂停**: 暂停计时器。恢复后从暂停点继续。

- **If 阶段1 progress=0.0 时死亡（已是最低点）**: 执行死亡动画但不回退。重生在阶段1 progress=0.0。纯视觉惩罚，无数据损失。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 碰撞判定 | `player_killed` 信号 | 硬 | 触发源 |
| 进化阶段 | `execute_death_rollback()` | 硬 | 执行回退 |
| 存档检查点 | 获取目标阶段数据 | 软 | MVP中不需要——直接回退 current_stage-1。Demo阶段后可读取存档确认目标 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 粒子/VFX | 死亡/重生信号 | 软 | 视觉特效 |
| 音频 | 死亡/重生信号 | 软 | 音效 |

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `death_animation_duration` | 2.5s | 2.0-3.5 | 太长→玩家烦躁等待 | 太短→死亡无"重量感" | 死亡的情绪冲击 |
| `respawn_invulnerability` | 1.0s | 0.5-2.0 | 太长→无风险安全期太久 | 太短→"重生即死"挫败 | 重生的安全感 |
| `rollback_stages` | 1 | 1-2 | 2阶回退太狠→玩家放弃 | 1阶已是最佳平衡 | 死亡的惩罚力度 |
| `safe_radius` | 150px | 100-200 | 太大→安全区太空旷 | 太小→重生时仍有威胁贴脸 | 重生的安全感 |

## Acceptance Criteria

1. **GIVEN** 碰撞判定发出 `player_killed`，**WHEN** 死亡流程开始，**THEN** 操控立即暂停，白闪在 0.15s 内出现。

2. **GIVEN** 死亡时 current_stage=3，**WHEN** 回退执行，**THEN** 回退到 stage=2, progress=0.0。

3. **GIVEN** 死亡时 current_stage=1，**WHEN** 回退执行，**THEN** 保持 stage=1, progress=0.0，不低于1。

4. **GIVEN** 重生完成，**WHEN** 检查周围150px内，**THEN** 无威胁体存在（已被推离或玩家已偏移到安全位置）。

5. **GIVEN** 重生无敌帧生效（1.0s），**WHEN** 天体碰到玩家，**THEN** 不触发死亡。

6. **GIVEN** 无敌帧结束，**WHEN** 天体仍在碰撞范围，**THEN** 正常触发碰撞判定（可能再次死亡）。

7. **GIVEN** 死亡触发到操控恢复，**WHEN** 计时，**THEN** 总时长 = death_animation_duration + respawn_invulnerability ≈ 3.5s。

8. **性能**: 死亡/重生状态管理 < 0.05ms/帧。安全位置计算 < 0.2ms（仅死亡时单次执行）。
