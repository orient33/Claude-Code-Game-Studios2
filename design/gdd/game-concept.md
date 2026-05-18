# Game Concept: 星噬 (Starvore)

*Created: 2026-05-15*
*Status: Draft*

---

## Elevator Pitch

> 一款宇宙吞噬成长游戏——你从一粒宇宙尘埃开始，通过引力吸附和主动吞噬比你小的天体不断成长，经历陨石、小行星、行星、恒星直到黑洞的进化之旅。碰到比你大的物体则死亡回退。在放松的心流中体验宇宙尺度的震撼。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 休闲吞噬成长 (Casual Growth / .io-like) |
| **Platform** | Mobile (iOS / Android) |
| **Target Audience** | 休闲玩家、收藏驱动型玩家（详见 Player Profile） |
| **Player Count** | Single-player |
| **Session Length** | 15-30 分钟 |
| **Monetization** | 待定（倾向 Premium 或轻度 IAP） |
| **Estimated Scope** | Medium (4-6 months, solo) |
| **Comparable Titles** | Agar.io, Hole.io, Osmos, Alto's Odyssey |

---

## Core Fantasy

你是宇宙中一个不断膨胀的存在。从微不足道的尘埃开始，每一次吞噬都让你更大、更强、引力更不可抗拒。曾经让你恐惧的巨大天体，终将变成你的食物。最终，你成为吞噬一切的黑洞——光都无法逃脱。

这是一种纯粹的"从弱到强"的幂律成长幻想，包裹在宇宙尺度的视觉壮观中。

---

## Unique Hook

像 Agar.io 的吞噬成长游戏，**并且**每次跨越质量阈值时会触发华丽的进化变身动画，镜头拉远揭示全新的宇宙尺度——曾经巨大的恒星变成你身边的小光点。

吞噬不只是数字增长，而是一场肉眼可见的宇宙进化之旅。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 1 | 进化动画、粒子特效、光晕、尺度跃迁的视觉冲击、环境音乐 |
| **Submission** (relaxation, comfort zone) | 2 | 无压力的心流循环、柔和的操作手感、宽容的死亡惩罚 |
| **Discovery** (exploration, secrets) | 3 | 新区域解锁、稀有天体发现、图鉴收集 |
| **Fantasy** (make-believe) | 4 | 宇宙尺度的成长幻想、从尘埃到黑洞的身份转变 |
| **Challenge** (mastery) | 5 | 规避大型物体的路径规划、后期节奏加快 |
| **Narrative** | N/A | 无剧情叙事 |
| **Fellowship** | N/A | 单人游戏 |
| **Expression** | N/A | 无自定义创造 |

### Key Dynamics (Emergent player behaviors)

- 玩家会自然地在"贪婪吞噬"和"谨慎规避"之间切换节奏
- 玩家会主动寻找小物体密集的区域来快速成长
- 玩家会在接近进化阈值时变得更大胆（为了"再吃一个就进化"的冲动）
- 玩家会为了图鉴完整度而探索不同区域寻找稀有天体

### Core Mechanics (Systems we build)

1. **引力吸附系统** — 被动引力场自动吸附附近比自己小的物体，范围随质量增长
2. **碰撞判定系统** — 比自己小的物体被吞噬并增加质量；比自己大的物体碰撞则死亡
3. **进化阶段系统** — 固定质量阈值触发进化变身（6阶），伴随动画和镜头缩放
4. **物体生成系统** — 从画面四周持续生成大小不一的天体，保证密度和节奏
5. **存档检查点系统** — 每次进化自动存档，死亡回退到上一进化阶段

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 自由选择移动路径、决定吃什么躲什么、选择探索哪个区域 | Supporting |
| **Competence** (mastery, skill growth) | 进化阶段的清晰进步、操控越来越大的引力场、图鉴完成度百分比 | Core |
| **Relatedness** (connection, belonging) | 与宇宙天体的"收集关系"、图鉴中融入真实天文知识 | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** (goal completion, collection, progression) — 进化链完成、图鉴收集、区域全解锁
- [x] **Explorers** (discovery, understanding systems, finding secrets) — 发现稀有天体、解锁新区域、图鉴百科
- [ ] **Socializers** — 单人游戏，不涉及
- [ ] **Killers/Competitors** — 无 PvP，不涉及

### Flow State Design

- **Onboarding curve**: 前 30 秒只有小物体，没有危险；第 1 分钟引入第一个比你大的物体；逐步增加密度
- **Difficulty scaling**: 引力随质量增强→吸引更多物体→大物体也更频繁出现→自然加速节奏
- **Feedback clarity**: 体积可见增长、进化进度条（视觉化非数字）、吞噬时的粒子爆发
- **Recovery from failure**: 死亡回退一个进化阶段（非从头开始），几秒内即可继续

---

## Core Loop

### Moment-to-Moment (30 seconds)

手指拖拽移动天体 → 靠近小物体 → 引力自动吸附吞噬 → 体积可见增大 → 粒子特效+音效反馈 → 规避飘来的大物体 → 继续寻找食物

### Short-Term (5-15 minutes)

积累质量接近阈值 → 触发进化变身 → 华丽变身动画 → 镜头拉远揭示新尺度 → 曾经的威胁变成新食物 → 追求下一次进化

### Session-Level (15+ minutes)

穿越一个完整的宇宙区域 → 收集该区域的特有天体 → 完成进化阶段 → 解锁新区域 → 自然暂停存档点

### Long-Term Progression

- 解锁全部 6 个宇宙区域
- 完善天体图鉴（30-50 种）
- 追求全图鉴收集完成

### Retention Hooks

- **Curiosity**: 下一个区域是什么样的？还有什么稀有天体没见过？
- **Investment**: 图鉴完成度、已解锁区域进度不想浪费
- **Mastery**: 尝试在更少死亡次数内完成一个区域
- **Social**: N/A（单人游戏）

---

## Game Pillars

### Pillar 1: 尺度震撼 (Scale Spectacle)

每一次成长都必须被*看见*和*感受到*。视觉反馈是第一优先级。

*Design test*: 如果在"更多游戏内容"和"更华丽的进化动画"之间选择，选后者。

### Pillar 2: 心流至上 (Flow First)

游戏节奏不应产生焦虑，而是让人进入舒适的沉浸状态。

*Design test*: 如果一个设计让玩家感到压力大于享受，削弱它或移除它。

### Pillar 3: 一目了然 (Instant Read)

所有信息通过视觉尺寸和颜色传达，无需 UI 数字或文字提示。

*Design test*: 如果需要加 HUD 文字才能让玩家理解某样东西，重新设计视觉语言。

### Pillar 4: 宇宙奇观 (Cosmic Wonder)

游戏世界应激发对宇宙的好奇心和敬畏感。

*Design test*: 如果一个天体设计不能让人觉得"哇这很酷"，重新设计它。

### Anti-Pillars (What This Game Is NOT)

- **NOT 社交/PvP**: 不加多人竞争，会破坏心流和放松感
- **NOT 复杂系统**: 不加技能树、装备、货币等重度系统，会破坏"一目了然"
- **NOT 惩罚性难度**: 不加计时器、排名压力、连败惩罚，会破坏心流至上
- **NOT 碎片化付费**: 不卖数值、不卖体力，会破坏成长的纯粹感

---

## Visual Identity Anchor

**方向：简洁矢量 + 粒子光晕**

- 几何抽象的天体形态，用色彩和发光效果区分阶段和种类
- 大量粒子特效：吞噬时的能量流入、进化时的光芒爆发、引力场的微光圈
- 深空背景渐变，每个区域有独特色调（星云紫、恒星金、虚空蓝黑）
- 镜头缩放时的尺度对比是核心视觉叙事手段

*Visual Rule*: 画面任何时刻都必须有至少一个发光或运动的粒子元素，保持视觉活力。

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Agar.io / Hole.io | 吞噬成长的核心循环验证 | 宇宙主题+进化阶段+存档制 | 验证核心循环的市场需求 |
| Alto's Odyssey | 心流+视觉美学+环境音乐 | 吞噬而非跑酷，有成长曲线 | 验证"禅意手游"的商业可行性 |
| Osmos | 引力物理+吞噬+宇宙主题 | 更直觉的操作（拖拽vs弹射）、更华丽的视觉 | 验证引力吞噬概念在indie市场的定位 |
| Katamari Damacy | 尺度跃迁的快感、物体变小的对比 | 2D+移动端+宇宙主题 | 验证"越滚越大"带来的视觉满足感 |

**Non-game inspirations**: NASA 哈勃/韦伯望远镜拍摄的深空照片（色彩参考）、宇宙纪录片（尺度感）、环境音乐（Brian Eno 式氛围）

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-35 |
| **Gaming experience** | 休闲至中度 (Casual to Mid-core) |
| **Time availability** | 通勤、睡前、碎片时间中的15-30分钟 |
| **Platform preference** | 手机（iOS / Android） |
| **Current games they play** | Hole.io, Alto's Odyssey, Monument Valley, 各类 .io 游戏 |
| **What they're looking for** | 有视觉满足感的放松游戏，不需要大量精力投入但有成长获得感 |
| **What would turn them away** | 强制社交、付费墙、过高操作难度、过多文字阅读 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4 或 Unity（待 /setup-engine 确定） |
| **Key Technical Challenges** | 大量物体同屏性能优化（对象池）、流畅的粒子系统、镜头缩放时的物体LOD |
| **Art Style** | 2D 简洁矢量 + 粒子光晕效果 |
| **Art Pipeline Complexity** | Low-Medium（矢量天体 + Shader驱动的光效） |
| **Audio Needs** | Moderate-High（每区域环境音乐 + 吞噬/进化音效） |
| **Networking** | None（单人游戏） |
| **Content Volume** | 6 区域、30-50 种天体、6 阶进化、约 3-5 小时完整通关 |
| **Procedural Systems** | 物体生成（半随机，参数控制密度/大小分布/稀有度） |

---

## Risks and Open Questions

### Design Risks

- 核心循环 10 分钟后是否会感觉单调？需要通过节奏变化和稀有天体事件来保持新鲜感
- "被动引力"是否让操作感觉太简单？可能需要后期区域增加障碍物类型

### Technical Risks

- 移动端同屏 50+ 物体的碰撞检测和粒子渲染性能
- 镜头缩放过程中的物体平滑过渡（LOD）

### Market Risks

- .io 品类已经成熟，需要足够的差异化来吸引关注
- 付费模式选择：Premium 可能限制下载量，F2P 需要不破坏体验的变现设计

### Scope Risks

- 6 个区域的视觉差异化需要大量美术工作
- 环境音乐制作（如果外包则有成本，如果自制则有时间）

### Open Questions

- 核心循环的"有趣度"需要通过 MVP 原型验证（1 区域 + 完整进化链即可测试）
- 后期区域如何保持新鲜感？（新机制？新物体行为？环境互动？）
- 最终黑洞形态达成后的游戏结局设计？

---

## MVP Definition

**Core hypothesis**: 玩家觉得"拖拽移动 → 引力吸附 → 进化变身 → 尺度跃迁"的循环有趣且想继续体验15分钟以上。

**Required for MVP**:
1. 1 个宇宙区域，从四周生成大小不一的物体
2. 完整 6 阶进化链 + 进化变身动画 + 镜头拉远
3. 引力被动吸附 + 碰撞判定（小=吞噬，大=死亡）
4. 进化阶段存档检查点
5. 基础粒子效果和音效

**Explicitly NOT in MVP** (defer to later):
- 图鉴收集系统
- 多区域解锁
- 环境音乐（用占位音频）
- 稀有天体
- 任何付费/广告系统

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 区域, 5-8 种物体 | 核心循环 + 进化 + 存档 | 2-4 周 |
| **Demo** | 3 区域, 15-20 种物体 | + 图鉴 + 区域解锁 + 音乐 | 2-3 月 |
| **Alpha** | 6 区域, 30+ 种物体 | + 稀有天体 + 完整图鉴 | 3-4 月 |
| **Full Vision** | 6 区域, 50 种物体 | + 挑战模式 + 全打磨 | 4-6 月 |

---

## Next Steps

- [ ] Run `/setup-engine` to configure the engine and populate version-aware reference docs
- [ ] Run `/art-bible` to create the visual identity specification
- [ ] Use `/design-review design/gdd/game-concept.md` to validate concept completeness
- [ ] Decompose the concept into systems with `/map-systems`
- [ ] Author per-system GDDs with `/design-system`
- [ ] Plan the technical architecture with `/create-architecture`
- [ ] Record key architectural decisions with `/architecture-decision`
- [ ] Validate readiness with `/gate-check`
- [ ] Prototype the core mechanic with `/prototype starvore-core-loop`
- [ ] Run `/playtest-report` after the prototype
- [ ] Plan the first sprint with `/sprint-plan new`
