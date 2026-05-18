# Systems Index: 星噬 (Starvore)

> **Status**: Approved
> **Created**: 2026-05-15
> **Last Updated**: 2026-05-15
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

星噬是一款以"吞噬成长"为核心循环的移动端2D休闲游戏。系统设计围绕四大支柱展开：尺度震撼（视觉反馈驱动）、心流至上（无压力节奏）、一目了然（零文字信息传递）、宇宙奇观（敬畏感激发）。核心循环为"移动→吸附→吞噬→成长→进化→探索"，机械上需要物理模拟（引力+碰撞）、视觉反馈（粒子+镜头）、状态管理（质量+进化+存档）三大类系统协同运作。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 质量/成长系统 | Core | MVP | Designed | design/gdd/mass-growth-system.md | (none) |
| 2 | 玩家移动系统 | Core | MVP | Designed | design/gdd/player-movement-system.md | (none) |
| 3 | 对象池系统 | Infrastructure | MVP | Designed | design/gdd/object-pool-system.md | (none) |
| 4 | 碰撞判定系统 | Gameplay | MVP | Designed | design/gdd/collision-system.md | 质量/成长 |
| 5 | 引力吸附系统 | Gameplay | MVP | Designed | design/gdd/gravity-system.md | 玩家移动, 质量/成长 |
| 6 | 物体生成系统 | Gameplay | MVP | Designed | design/gdd/spawner-system.md | 对象池, 质量/成长 |
| 7 | 镜头系统 | Core | MVP | Designed | design/gdd/camera-system.md | 玩家移动, 质量/成长 |
| 8 | 进化阶段系统 | Gameplay | MVP | Designed | design/gdd/evolution-system.md | 质量/成长, 镜头 |
| 9 | 死亡/重生系统 | Gameplay | MVP | Designed | design/gdd/death-respawn-system.md | 碰撞判定, 进化阶段, 存档检查点 |
| 10 | 粒子/VFX系统 | Presentation | MVP | Designed | design/gdd/vfx-particle-system.md | 引力, 碰撞, 进化, 区域 |
| 11 | 区域系统 | Gameplay | Demo | Not Started | — | 物体生成, 进化阶段 |
| 12 | 存档检查点系统 | Persistence | Demo | Not Started | — | 进化阶段, 质量/成长 |
| 13 | 音频系统 | Audio | Demo | Not Started | — | 碰撞, 进化, 区域 |
| 14 | 图鉴收集系统 | Progression | Full | Not Started | — | 碰撞判定, 区域 |
| 15 | UI/菜单系统 | UI | Full | Not Started | — | 图鉴, 存档, 进化 |

---

## Categories

| Category | Description |
|----------|-------------|
| **Core** | 基础系统，几乎所有其他系统依赖它们 |
| **Infrastructure** | 性能和技术基础设施 |
| **Gameplay** | 直接构成核心循环的玩法系统 |
| **Presentation** | 视觉和听觉反馈系统 |
| **Persistence** | 存档和状态持久化 |
| **Progression** | 长期成长和收集 |
| **UI** | 菜单和信息展示 |
| **Audio** | 音乐和音效 |

---

## Priority Tiers

| Tier | Definition | Target | Count |
|------|------------|--------|-------|
| **MVP** | 核心循环运转所需——能验证"吞噬+成长+进化的循环好不好玩" | 2-4 周 | 10 |
| **Demo** | 完整体验所需——多区域、存档、音效构成完整15分钟会话 | 2-3 月 | 3 |
| **Full** | 长期留存和打磨——图鉴、完整UI | 4-6 月 | 2 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **质量/成长系统** — 全局共享数据模型，7个系统读取它，最高优先瓶颈
2. **玩家移动系统** — 触控输入→天体位置，一切交互的起点
3. **对象池系统** — 移动端性能基础，物体高频生成/销毁必须池化

### Core Layer (depends on Foundation)

4. **碰撞判定系统** — depends on: 质量/成长（比较双方质量决定吃/死）
5. **引力吸附系统** — depends on: 玩家移动, 质量/成长（位置+质量=引力范围）
6. **物体生成系统** — depends on: 对象池, 质量/成长（池化生成，质量决定大小分布）
7. **镜头系统** — depends on: 玩家移动, 质量/成长（跟随+缩放）

### Feature Layer (depends on Core)

8. **进化阶段系统** — depends on: 质量/成长, 镜头（质量触发进化→镜头拉远）
9. **死亡/重生系统** — depends on: 碰撞判定, 进化阶段, 存档检查点
10. **区域系统** — depends on: 物体生成, 进化阶段（区域决定生成物种类）
11. **存档检查点系统** — depends on: 进化阶段, 质量/成长

### Presentation Layer (depends on Features)

12. **粒子/VFX系统** — depends on: 引力, 碰撞, 进化, 区域（为事件提供视觉反馈）
13. **音频系统** — depends on: 碰撞, 进化, 区域（为事件提供音频反馈）
14. **图鉴收集系统** — depends on: 碰撞判定, 区域（吞噬时记录天体）
15. **UI/菜单系统** — depends on: 图鉴, 存档, 进化（展示数据）

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | 质量/成长系统 | MVP | Foundation | S |
| 2 | 玩家移动系统 | MVP | Foundation | S |
| 3 | 对象池系统 | MVP | Foundation | S |
| 4 | 碰撞判定系统 | MVP | Core | S |
| 5 | 引力吸附系统 | MVP | Core | M |
| 6 | 物体生成系统 | MVP | Core | M |
| 7 | 镜头系统 | MVP | Core | S |
| 8 | 进化阶段系统 | MVP | Feature | M |
| 9 | 死亡/重生系统 | MVP | Feature | S |
| 10 | 粒子/VFX系统 | MVP | Presentation | L |
| 11 | 区域系统 | Demo | Feature | M |
| 12 | 存档检查点系统 | Demo | Feature | S |
| 13 | 音频系统 | Demo | Presentation | M |
| 14 | 图鉴收集系统 | Full | Presentation | M |
| 15 | UI/菜单系统 | Full | Presentation | M |

Effort: S = 1 session, M = 2-3 sessions, L = 4+ sessions

---

## Circular Dependencies

None found. The dependency graph is a clean DAG (directed acyclic graph).

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| 质量/成长系统 | Design | 瓶颈系统——7个系统依赖它，接口设计错误影响全局 | 首个设计+原型验证，保持接口极简 |
| 粒子/VFX系统 | Technical | 移动端≤300粒子/帧+≤8发射器的预算能否撑住视觉要求 | MVP阶段早期性能测试，备选方案：shader模拟 |
| 物体生成系统 | Design | 生成节奏直接决定"好不好玩"——太密太疏都破坏心流 | 参数化设计+大量playtesting |
| 引力吸附系统 | Design | 引力范围/强度曲线需要大量调参才能"感觉对" | 暴露为调试面板，快速迭代 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 15 |
| Design docs started | 10 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 0/10 |
| Demo systems designed | 0/3 |
| Full systems designed | 0/2 |

---

## Next Steps

- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Start with: 质量/成长系统 → 玩家移动系统 → 对象池系统
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype core loop after first 7 systems are designed
