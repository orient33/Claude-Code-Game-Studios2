# 镜头系统 (Camera System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 尺度震撼

## Overview

镜头系统控制玩家的视野范围和观察视角——它跟随玩家天体保持居中，并根据玩家当前视觉半径动态调整缩放级别。系统的核心戏剧性时刻是进化时的"镜头拉远"：当玩家从一个阶段进化到下一个阶段时，镜头平滑缩小，揭示更广阔的宇宙空间——曾经巨大的天体在新视角下变得渺小。这种尺度对比是"尺度震撼"支柱的直接实现手段。

## Player Fantasy

"世界在我脚下缩小。"每次进化后的镜头拉远让玩家直观感受到自己的成长——不是通过数字，而是通过世界本身的相对缩小。那些曾经需要躲避的庞然大物，在新的镜头尺度下变成了可以随手吞噬的碎屑。这种视觉上的"地位反转"是整个游戏最令人满足的时刻之一。

## Detailed Design

### Core Rules

1. **跟随**：镜头每帧跟随玩家天体位置，保持玩家在屏幕中央。使用平滑跟随（轻微延迟）使镜头感觉"有质量"而非机械锁定。

2. **缩放基准**：镜头的缩放级别基于玩家的 `visual_radius`——确保玩家天体始终占据屏幕短边的 `player_screen_ratio`（默认12-18%）。

3. **进化拉远**：当进化触发时，镜头在 `zoom_transition_duration` 秒内平滑缩小到新的缩放级别。使用 ease-out 缓动——快速开始，慢慢稳定。

4. **阶段内微调**：阶段内随质量增长，镜头也微幅缩小（配合 `intra_stage_growth` 的 visual_radius 增长），保持 `player_screen_ratio` 恒定。

5. **死亡回退拉近**：死亡回退到较小阶段时，镜头在重生过程中平滑拉近（放大），配合重生动画的 1.5秒节奏。

6. **无手动缩放**：玩家不能手动缩放镜头（防止与拖拽移动的触控冲突）。

7. **视口边界**：镜头的可视范围定义了物体生成系统的"屏幕边缘"和离屏回收的判定基准。

### States and Transitions

| 状态 | 条件 | 行为 |
|------|------|------|
| Following（平稳跟随）| 无进化/死亡事件 | 平滑跟随 + 微幅缩放适应成长 |
| Zooming Out（进化拉远）| evolution_ready 触发 | zoom 在 transition_duration 内 ease-out 到新级别 |
| Zooming In（死亡拉近）| 死亡回退触发 | zoom 在 1.5s 内 ease-in 到旧级别 |
| Locked（锁定）| 进化爆发动画峰值 0.4s | 暂停跟随，居中固定（配合全屏白化） |

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 玩家移动 | ← 读取 | `get_position() -> Vector2` | 跟随目标 |
| 质量/成长 | ← 读取 | `get_visual_radius() -> float` | 计算缩放级别 |
| 进化阶段 | ← 信号 | `evolution_started`, `evolution_completed` | 触发拉远/锁定/恢复 |
| 死亡/重生 | ← 信号 | `respawn_started` | 触发拉近 |
| 物体生成 | → 提供 | `get_viewport_rect() -> Rect2` | 生成/回收的边界参考 |
| 粒子/VFX | → 提供 | `get_zoom_level() -> float` | 粒子大小需配合缩放 |

## Formulas

### 1. 缩放级别 (Zoom Level)

`zoom_level = (player_screen_ratio * viewport_short_edge) / (visual_radius * 2)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| player_screen_ratio | P_r | float | 0.12-0.18 | 玩家天体占屏幕短边的比例 |
| viewport_short_edge | V_s | float | 设备相关 | 视口短边像素数 |
| visual_radius | R_v | float | 16-224 px | 来自质量/成长系统 |

**Output Range:** ~1.5（黑洞阶段，大天体小zoom）→ ~10（尘埃阶段，小天体大zoom）
**Example:** P_r=0.15, V_s=1080, R_v=60 → zoom = (0.15*1080)/(60*2) = 162/120 = 1.35

### 2. 跟随平滑 (Follow Smoothing)

`camera_position = camera_position.lerp(player_position, follow_weight * delta * 60)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| follow_weight | F_w | float | 0.85-0.98 | 跟随权重（越高越紧跟） |

**Output:** 镜头每帧接近玩家位置的 85-98%
**Example:** F_w=0.92, 玩家在镜头右方 100px → 镜头本帧移动 92px 向右

### 3. 进化缩放过渡 (Evolution Zoom Transition)

`current_zoom = old_zoom + (new_zoom - old_zoom) * ease_out(t / zoom_transition_duration)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| zoom_transition_duration | Z_d | float | 1.5-2.5 s | 过渡总时长 |
| t | t | float | 0-Z_d | 当前过渡经过时间 |

## Edge Cases

- **If 进化发生在屏幕边缘附近**: 镜头拉远后如果玩家位置相对于新视口边界过于靠边，在拉远完成后的 0.5s 内平滑将玩家"推"回中央区域。

- **If 连续进化（溢出触发多次进化）**: 镜头执行连续拉远——第一次拉远未完成时第二次紧接着叠加。使用当前 zoom 作为新的 old_zoom 起点，不重置过渡。

- **If 死亡时正在进化拉远中**: 中断拉远，以当前 zoom 值为起点开始拉近。不完成未结束的拉远。

- **If 设备旋转导致 viewport_short_edge 变化**: 立即重新计算 zoom_level，但变化通过 0.3s 过渡平滑，不跳切。

- **If follow_weight 太低导致玩家快速移动时离开屏幕中心过多**: follow_weight 有动态下限——当玩家距离屏幕中心超过视口短边 20% 时，临时提高 weight 到 0.98 直到回到中心附近。

## Dependencies

**上游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 玩家移动 | `get_position()` | 硬 | 跟随目标 |
| 质量/成长 | `get_visual_radius()` | 硬 | 缩放计算 |

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 物体生成 | `get_viewport_rect()` | 硬 | 生成边界参考 |
| 粒子/VFX | `get_zoom_level()` | 软 | 粒子缩放适配 |

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `player_screen_ratio` | 0.15 | 0.10-0.20 | 太大→玩家天体占太多屏幕→看不见远处 | 太小→天体太小难以关注 | 视野宽广度 vs 天体存在感 |
| `follow_weight` | 0.92 | 0.85-0.98 | 太高→镜头机械跟随感→眩晕 | 太低→镜头滞后→操控断裂感 | 镜头的"呼吸感" |
| `zoom_transition_duration` | 2.0 s | 1.5-2.5 | 太长→拉远太慢→失去冲击力 | 太短→拉远太快→来不及感受 | 进化时刻的"壮观持续时间" |

## Acceptance Criteria

1. **GIVEN** 玩家正在移动，**WHEN** 每帧更新，**THEN** 镜头中心平滑趋近玩家位置，偏差 < 视口短边 5%。

2. **GIVEN** 玩家 visual_radius=60px，viewport_short_edge=1080，P_r=0.15，**WHEN** 计算 zoom，**THEN** zoom_level ≈ 1.35。

3. **GIVEN** 进化触发（阶段2→3），**WHEN** 2.0秒过渡期间，**THEN** zoom 从旧值平滑变化到新值，无跳变。

4. **GIVEN** 进化拉远完成，**WHEN** 查看曾经巨大的天体，**THEN** 它们在新视角下视觉上变小了（尺度对比可见）。

5. **GIVEN** 死亡回退（阶段3→2），**WHEN** 重生，**THEN** 镜头在 1.5s 内平滑拉近到阶段2对应的zoom级别。

6. **GIVEN** 玩家快速移动到屏幕边缘方向，**WHEN** 距中心 > 20% 视口，**THEN** follow_weight 临时增加，玩家被拉回中心区域。

7. **性能**: 镜头计算每帧 < 0.05ms。
