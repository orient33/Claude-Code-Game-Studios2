# 对象池系统 (Object Pool System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-15
> **Implements Pillar**: 心流至上（60fps无卡顿保证）

## Overview

对象池系统是星噬的性能基础设施——它预分配并复用游戏中频繁生成/销毁的天体节点，避免运行时的内存分配和 GC 抖动。在移动端 60fps 的硬约束下，每帧潜在的数十次天体创建/销毁如果走标准 `instantiate()`/`queue_free()` 路径，会产生不可接受的帧时间尖峰。对象池将这些开销前置到加载阶段，保证游玩期间的帧时间平稳。玩家不会意识到这个系统的存在——他们感受到的是"画面始终流畅，从不卡顿"。

## Player Fantasy

纯基础设施系统，玩家不直接感知。它的间接贡献是：保证"心流至上"支柱的技术前提——60fps 的帧率稳定性。没有对象池，大量天体同时出现/消失的瞬间会产生明显卡顿，打断玩家沉浸在吞噬成长中的心流状态。

## Detailed Design

### Core Rules

1. **预分配**：游戏加载时，为每种天体类型预创建一批节点实例放入池中。预创建数量由 `initial_pool_size` 决定。

2. **获取（Checkout）**：物体生成系统需要天体时，从池中取出一个已存在的节点，重置其属性（位置、质量值、外观），然后加入场景树。

3. **归还（Return）**：天体被吞噬、离开屏幕、或需要销毁时，从场景树移除，重置状态，放回池中等待复用。不调用 `queue_free()`。

4. **动态扩容**：如果池中无可用节点，创建新实例并加入池中。扩容时单帧最多创建 `max_expand_per_frame` 个节点（防止突发性帧时间尖峰）。

5. **分类池**：不同类型的天体（微尘、岩屑、天体、威胁体、稀有体）使用独立的池，避免类型混淆。

6. **节点状态契约**：从池中取出的节点保证处于"干净"初始状态——所有游戏逻辑属性已重置，无上一次使用的残留数据。

### States and Transitions

| 节点状态 | 位置 | 行为 |
|---------|------|------|
| Pooled（池中待命）| 不在场景树中，不处理 _process | 等待被取出 |
| Active（活跃使用中）| 在场景树中，正常执行游戏逻辑 | 物体生成系统管理其生命周期 |
| Resetting（重置中）| 从场景树移除，正在清理状态 | 单帧内完成，立即回到 Pooled |

转换：
- Pooled → Active：`checkout()` 被调用
- Active → Resetting → Pooled：`return_to_pool()` 被调用
- (Dynamic) → Pooled：池空时动态扩容创建新节点

### Interactions with Other Systems

| 系统 | 方向 | 接口 | 描述 |
|------|------|------|------|
| 物体生成 | ← 调用 | `checkout(type: String) -> Node2D` | 获取一个指定类型的可用节点 |
| 物体生成 | ← 调用 | `return_to_pool(node: Node2D)` | 归还不再需要的节点 |
| 碰撞判定 | ← 间接 | 通过物体生成系统归还被吞噬的天体 | 碰撞→吞噬→归还 |

## Formulas

### 1. 预分配数量 (Initial Pool Size per Type)

`initial_pool_size[type] = expected_peak_count[type] * pool_headroom`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| expected_peak_count | P | int | 10-50 | 该类型天体同屏峰值数量（由物体生成系统的密度参数决定） |
| pool_headroom | H | float | 1.2-1.5 | 余量系数，防止频繁扩容 |

**Output Range:** 12-75 个节点/类型
**Example:** P=25（微尘峰值）, H=1.3 → initial_pool_size = 33

### 2. 总内存预算 (Total Pool Memory)

`total_pool_memory = sum(initial_pool_size[type] * node_memory_cost[type])`

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| node_memory_cost | C | float | 0.5-2 KB | 单个天体节点的内存占用（含纹理引用） |

**Output Range:** < 1 MB（所有池合计，远低于 512MB 预算）
**Example:** 5类 × 平均30个 × 1.5KB = 225KB

## Edge Cases

- **If 池完全耗尽且当前帧已达 max_expand_per_frame**: 返回 null。物体生成系统必须处理 null（跳过本次生成，下一帧重试）。不崩溃。

- **If 归还的节点仍有活跃的 Tween 或粒子发射器**: `return_to_pool()` 在重置时强制停止所有 Tween、禁用所有粒子发射器、断开所有临时信号连接。

- **If 同一节点被 return_to_pool() 调用两次**（double-free）: 第二次调用检测节点已在池中（通过状态标记），忽略并记录警告。不产生副作用。

- **If 游戏暂停时大量天体在场景中**: 暂停不影响池状态。恢复时所有节点继续正常。

- **If 进化导致屏幕上物体类型需求骤变**（如从微尘阶段进入行星阶段，微尘不再生成）: 已分配的微尘节点自然随时间归还（离开屏幕后回池）。池不主动回收内存——预分配的节点保留至场景切换。

- **If 场景切换（如回到主菜单）**: 所有池清空，`queue_free()` 所有节点，释放内存。下次进入游戏场景时重新预分配。

## Dependencies

**上游依赖：** 无——对象池系统是零依赖的 Foundation 层。

**下游依赖：**

| 系统 | 接口 | 硬/软 | 描述 |
|------|------|-------|------|
| 物体生成 | `checkout()`, `return_to_pool()` | 硬 | 物体生成系统必须通过池获取/归还节点 |

**接口契约：**
- `checkout()` 保证返回的节点状态干净（或 null），单次调用 < 0.01ms
- `return_to_pool()` 保证节点在下一帧前完全从场景树脱离
- 池在场景加载完成后才可使用（`_ready()` 之后）

## Tuning Knobs

| 调参名称 | 默认值 | 安全范围 | 过高影响 | 过低影响 | 影响的游戏感受 |
|---------|--------|---------|---------|---------|--------------|
| `initial_pool_size` | 每类30 | 10-75 | 加载时间变长、内存占用增加 | 运行时频繁扩容→偶发卡顿 | 加载速度 vs 运行流畅度 |
| `max_expand_per_frame` | 3 | 1-5 | 扩容帧的帧时间尖峰更高 | 池耗尽恢复更慢→物体生成延迟可见 | 突发高密度场景的流畅度 |
| `pool_headroom` | 1.3 | 1.1-1.5 | 内存浪费 | 正好不够时触发扩容 | 内存效率 vs 运行时稳定性 |

**交互关系：**
- `initial_pool_size` 应根据物体生成系统的密度参数同步调整
- 进化阶段越高画面密度越低（Art Bible 6.3），后期阶段对池压力更小

## Acceptance Criteria

1. **GIVEN** 池已预分配30个微尘节点，**WHEN** 调用 `checkout("micro_dust")` 30次，**THEN** 每次都返回有效节点，无 null。

2. **GIVEN** 池中微尘节点已全部取出，**WHEN** 再次 `checkout("micro_dust")`，**THEN** 动态扩容创建新节点并返回（非 null），本帧扩容数 ≤ max_expand_per_frame。

3. **GIVEN** 一个活跃节点有运行中的 Tween，**WHEN** `return_to_pool()` 被调用，**THEN** Tween 被强制停止，节点状态干净，下次 checkout 无残留行为。

4. **GIVEN** 同一节点连续两次 `return_to_pool()`，**WHEN** 第二次调用发生，**THEN** 无副作用，仅记录警告。

5. **GIVEN** 游戏运行中高密度天体场景，**WHEN** 持续60秒的峰值负载，**THEN** 无帧时间超过 16.6ms 的情况（排除 GPU 瓶颈）——所有分配/归还操作在 CPU 侧 < 0.01ms。

6. **GIVEN** 场景切换到主菜单，**WHEN** 切换完成，**THEN** 所有池节点被 free，内存正确释放（可通过 Godot Profiler 验证）。

7. **GIVEN** 扩容达到 max_expand_per_frame 上限，**WHEN** 同帧再次请求，**THEN** 返回 null，不崩溃。

8. **性能**: `checkout()` < 0.01ms, `return_to_pool()` < 0.05ms（含状态重置）。
