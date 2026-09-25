# Architecture

## 目标

`bmad-codex-team` 不是新的 BMAD orchestrator，也不 fork BMAD。它是一个 **Codex 宿主适配层**：当 BMAD 已经决定派发某个实现或审查子任务时，为该子任务选择项目级 Codex agent、模型和推理档位。

## 三层结构

### 1. BMAD：流程控制层

BMAD 继续负责：

- route 选择；
- planning / spec 状态；
- step-02 是否需要独立探索；
- step-03 implementation handoff 的原始 prompt；
- step-04 reviewer prompt 与 reviewer instruction file；
- 占位符和绝对路径替换；
- reviewer 同步/并行启动；
- findings triage；
- patch、defer、loopback；
- 最终验收与完成状态。

本项目不复制这些 prompt，也不重新定义这些流程。

### 2. Codex routing：角色映射层

`.codex/bmad-build-routing.md` 只维护阶段映射：

| BMAD 阶段/layer | Agent |
| --- | --- |
| step-02 independent exploration | `BmadExplorer` |
| step-03 implementation | `BmadImplementer` |
| step-04 blind-hunter | `BmadAdversarialReviewer` |
| step-04 edge-case-hunter | `BmadEdgeCaseReviewer` |
| step-04 verification-gap | `BmadVerificationReviewer` |
| oneshot blind-hunter | `BmadAdversarialReviewer` |

`AGENTS.md` 与 `_bmad/custom/bmad-build.user.toml` 负责让 Codex 父会话在正确场景读取该路由。

### 3. Codex agents：执行配置层

`.codex/agents/*.toml` 固定：

- `model`
- `model_reasoning_effort`
- `sandbox_mode`
- 与角色边界有关的 `developer_instructions`

角色本身不重新定义 BMAD reviewer 的任务内容。Reviewer 必须遵循父智能体传入的完整 BMAD 原始 prompt 和 reviewer instruction file。

## 上下文原则

### Explorer

- read-only；
- 只回答父智能体指定的探索问题；
- 返回路径、symbol、call path、tests 和约束证据；
- 不实现。

### Implementer

- workspace-write；
- full-route 时以 approved spec 为唯一事实来源；
- 加载 spec 声明的 context files；
- 后续可被同一父会话重新联系，只做 review patch 指定的小修正。

### Reviewers

- read-only；
- 无先前会话上下文；
- 父智能体原样传递 BMAD 渲染后的任务 prompt；
- 保留 BMAD 指定的 reading order；
- 不调用 skill、不编辑文件、不派生 agent；
- 只返回 evidence-backed findings，允许零 findings。

## 宿主能力降级

路由不是 all-or-nothing：

1. Custom agent type 可用 → 使用完整 profile。
2. Custom type 不可用，但通用 spawn 可选 model/effort → 只应用模型和 reasoning effort。
3. Spawn 可用但不能选模型 → 使用宿主默认模型，继续执行 BMAD 原 prompt。
4. Spawn 整体不可用 → 才按 BMAD 原流程 fallback。

这避免把“某个自定义 agent 未注册”误判为“平台没有子智能体能力”。

## 为什么不覆盖 bmad-build.toml

早期方案通过覆盖 `implementation_handoff` 和每个 lens 的 `instruction` 来强制 agent 类型。这样虽然直接，但会复制 BMAD 的 reviewer prompt，产生上游升级漂移。

当前方案只通过 `bmad-build.user.toml` 增加一条 persistent fact，让父智能体在派发时应用 Codex 路由，而 BMAD 的原始任务 prompt 始终来自当前安装版本。

因此：

- BMAD 更新 reviewer prompt 时自动继承；
- claims/spec/diff 的读取语义不被二次维护；
- ZCode 等其他宿主可以使用自己的路由实现；
- 本项目只维护“角色选择策略”这一层。
