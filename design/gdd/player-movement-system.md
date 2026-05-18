# 玩家移动系统 (Player Movement System)

> **Status**: In Design
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 心流至上

## Overview

玩家移动系统是星噬中唯一的主动操控入口——玩家通过单指拖拽控制天体在二维宇宙中的移动方向和速度。系统的核心目标是"手指即天体"：手指移动的方向和距离应即时、无延迟地映射为天体的运动，创造出"天体是手指延伸"的一体感。无摩擦、无惯性残留、无额外操作步骤——手指抬起，天体停止。这种零门槛的操控让玩家的注意力完全留给"吃什么、躲什么"的策略决策，而非与操控系统本身搏斗。

## Player Fantasy

玩家的幻想不是"我在操控一个角色"，而是"我*就是*这颗天体"。手指在屏幕上的每一次滑动都不应感觉像在下达指令——它应该感觉像是天体自身意志的自然延伸，如同在水中划动手指带起涟漪一般毫无阻力。当这个系统做对了，玩家会忘记自己在"操控"什么，进入纯粹的心流：注意力全在宇宙中的物体上，而非自己的手指上。服务支柱"心流至上"——最好的操控是让人忘记操控本身存在的操控。

## Detailed Design

### Core Rules

1. **输入捕获**：系统监听 `InputEventScreenDrag` 事件。手指按下时记录初始触控点与天体当前位置的偏移量 `touch_offset`。

2. **目标位置计算**：每帧根据手指当前位置和偏移量计算天体的目标位置：
   `target_position = finger_position - touch_offset`

3. **平滑追赶**：天体以不超过 `max_speed` 的速度向 `target_position` 移动。当天体位置与目标位置的距离小于 `snap_threshold` 时，直接吸附到目标位置（消除微小抖动）。

4. **即停**：手指抬起时，天体立即停止移动（velocity 归零），不保留任何惯性或滑行。

5. **无输入时静止**：无触控输入时天体保持当前位置不变，不受任何外力影响（引力吸附系统只影响其他物体向玩家移动，不影响玩家自身位置）。

6. **边界约束**：天体不可移出可视区域。到达屏幕边缘时，位置被 clamp 在可视边界内（考虑天体当前 visual_radius 使得整个天体可见）。

7. **单指专属**：仅响应第一根手指的输入，忽略多点触控的额外手指。

### States and Transitions

| 状态 | 条件 | 行为 |
|------|------|------|
| Idle（静止）| 无触控输入 | 天体保持当前位置不变 |
| Following（跟随）| 手指按下且正在拖拽 | 天体以 ≤max_speed 追赶目标位置 |
| Snapped（吸附）| 跟随中，距离 < snap_threshold | 天体锁定在目标位置，零延迟 |

转换：
- Idle → Following：手指按下，记录 touch_offset
- Following → Snapped：distance < snap_threshold
- Snapped → Following：手指移动使 distance > snap_threshold
- Following/Snapped → Idle：手指抬起，velocity 归零

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 引力吸附 | → 读取 | `get_position() -> Vector2` | 获取玩家位置作为引力中心 |
| 镜头 | → 读取 | `get_position() -> Vector2` | 镜头跟随目标 |
| 碰撞判定 | → 读取 | `get_position() -> Vector2` | 碰撞检测的天体中心点 |
| 质量/成长 | ← 读取 | `get_visual_radius() -> float` | 用于边界约束计算（不可超出屏幕） |

## Formulas

### 1. 追赶速度公式 (Chase Velocity)

`velocity = direction_to_target * min(distance_to_target / smoothing_factor, max_speed)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| direction_to_target | D | Vector2 | normalized | 天体指向目标位置的单位向量 |
| distance_to_target | d | float | 0-∞ px | 天体与目标位置的距离 |
| smoothing_factor | S | float | 0.05-0.2 s | 追赶平滑系数（越小越灵敏） |
| max_speed | V_max | float | 400-1200 px/s | 天体最大移动速度 |

**Output Range:** 0 px/s（已到达目标）→ max_speed px/s（目标远处）
**Example:** d=100px, S=0.1, V_max=800 → min(100/0.1, 800) = min(1000, 800) = 800 px/s

### 2. 边界约束公式 (Boundary Clamp)

`clamped_position.x = clamp(target_x, visual_radius + margin, viewport_width - visual_radius - margin)`
`clamped_position.y = clamp(target_y, visual_radius + margin, viewport_height - visual_radius - margin)`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| visual_radius | R | float | 16-224 px | 来自质量/成长系统的当前视觉半径 |
| margin | M | float | 8-16 px | 天体边缘与屏幕边缘的最小间距 |
| viewport_width/height | W/H | float | 设备相关 | 当前可视区域尺寸 |

**Output Range:** 天体始终完全可见于屏幕内
**Example:** R=24, M=10, W=1080 → x ∈ [34, 1046]

### 3. 吸附判定 (Snap Threshold)

`if distance_to_target < snap_threshold: position = target_position`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| snap_threshold | T_snap | float | 1-4 px | 低于此距离直接吸附，消除亚像素抖动 |

**Output:** 布尔判定——吸附或继续追赶

## Edge Cases

- **If 手指按下位置恰好在天体外部很远处**: 正常记录 touch_offset，天体不会瞬移到手指位置——它从当前位置开始追赶。偏移量确保天体相对手指的初始位移关系被保持。

- **If 手指快速滑过整个屏幕（flick）**: 天体以 max_speed 追赶但不会瞬移。手指抬起后即停——不产生惯性滑行。天体可能未到达手指最终位置就停下了。

- **If 进化发生时天体正在移动（visual_radius 突然增大）**: 边界约束立即使用新的 visual_radius 重新计算。如果新半径使得当前位置超出边界，平滑推入合法区域（不突切）。

- **If 屏幕旋转或 viewport 尺寸变化**: 边界约束立即使用新的 viewport 尺寸重新计算。如果当前位置不再合法，平滑推入。

- **If 两根手指同时按下**: 仅响应第一根手指（最先触发 `InputEventScreenTouch` 的 finger_index）。第二根手指的所有事件被忽略直到第一根手指抬起。

- **If 手指在 UI 按钮上按下（如暂停按钮）**: 移动系统不响应——UI 层拦截该输入。通过 Godot 的输入传播机制（`_gui_input` 优先级高于 `_unhandled_input`）自然实现。

- **If 手指按下后不移动（长按不动）**: 天体保持静止在当前位置，状态为 Snapped（因为 distance = 0 < snap_threshold）。不产生任何移动或漂移。

- **If max_speed 在运行时被修改（debug调参）**: 下一帧立即生效，天体追赶速度瞬间改变。无需重启或状态重置。

## Dependencies

**上游依赖（本系统需要的）：** 无——玩家移动系统是零依赖的 Foundation 层。

**软依赖（增强但非必需）：**

| 系统 | 接口 | 用途 |
|------|------|------|
| 质量/成长 | `get_visual_radius() -> float` | 边界约束计算需要天体半径。若不可用，使用默认值 24px。 |

**下游依赖（需要本系统的）：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 引力吸附 | `get_position() -> Vector2` | 硬 | 引力中心点 |
| 镜头 | `get_position() -> Vector2` | 硬 | 镜头跟随目标 |
| 碰撞判定 | `get_position() -> Vector2` | 硬 | 碰撞检测中心 |

**接口契约：**
- `get_position()` 返回天体当前帧的精确像素位置（Vector2）
- 位置保证在可视区域边界内（已 clamp）
- 无输入时位置保证不变（帧间稳定，不抖动）

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `max_speed` | 800 px/s | 400-1200 | 太快→玩家轻易躲避一切，游戏无挑战 | 太慢→天体跟不上手指，操控沮丧 | 操控响应感与游戏难度的平衡 |
| `smoothing_factor` | 0.1 s | 0.05-0.2 | 太高→天体感觉"黏腻"、迟钝 | 太低→天体感觉"硬"、机械 | 移动的"丝滑"品质 |
| `snap_threshold` | 2 px | 1-4 | 太高→低速运动出现明显跳跃 | 太低→亚像素抖动可能可见 | 静止时的视觉稳定性 |
| `margin` | 10 px | 4-20 | 太高→可用游戏区域缩小 | 太低→天体几乎贴到屏幕边缘 | 屏幕边缘的视觉舒适度 |

**交互关系：**
- `max_speed` 与物体生成系统的物体速度有关——如果物体速度接近 max_speed，玩家无法有效躲避
- `smoothing_factor` 越低，`snap_threshold` 需要越大（更灵敏的追赶意味着更容易出现亚像素抖动）
- `max_speed` 直接影响游戏难度——应作为难度平衡的间接杠杆而非直接暴露给玩家

## Acceptance Criteria

1. **GIVEN** 天体静止在屏幕中央，**WHEN** 手指按下并向右拖拽 100px，**THEN** 天体在 smoothing_factor 时间内移动到新目标位置右方，最终偏移量恰好为 100px。

2. **GIVEN** 天体正在跟随手指，**WHEN** 手指抬起，**THEN** 天体在下一帧 velocity 归零，不产生任何惯性滑行。

3. **GIVEN** 天体靠近屏幕右边缘（距离 < visual_radius + margin），**WHEN** 手指继续向右拖拽，**THEN** 天体被 clamp 在边界内，整个天体可见。

4. **GIVEN** 手指快速滑过整个屏幕（产生极大 distance_to_target），**WHEN** 计算速度，**THEN** 实际速度不超过 max_speed。

5. **GIVEN** 天体与目标位置距离 < snap_threshold，**WHEN** 下一帧计算位置，**THEN** 天体直接吸附到目标位置，无亚像素抖动。

6. **GIVEN** 两根手指同时在屏幕上，**WHEN** 第二根手指移动，**THEN** 天体仅响应第一根手指，忽略第二根。

7. **GIVEN** 暂停按钮区域，**WHEN** 手指在该区域按下，**THEN** 移动系统不响应，天体不动。

8. **GIVEN** 进化发生使 visual_radius 从 24px 变为 36px，**WHEN** 天体当前位置在新半径下超出边界，**THEN** 天体平滑移入合法区域（不突切）。

9. **GIVEN** 无触控输入持续 10 秒，**WHEN** 每帧检查天体位置，**THEN** 位置帧间差为精确零（Vector2.ZERO），无漂移。

10. **性能**: 移动计算（含边界 clamp）单帧耗时 < 0.05ms。
