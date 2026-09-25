# bmad-codex-team

在 **不 fork、不改写 BMAD 原始工作流 prompt** 的前提下，为 Codex 中运行的 BMAD `bmad-build` 按阶段指定子智能体模型和推理强度。

核心思路：

- `.codex/agents/*.toml`：定义 Codex 项目级角色、模型和 `model_reasoning_effort`。
- `.codex/bmad-build-routing.md`：只定义“BMAD 当前阶段 / review layer → 哪个 Codex agent”。
- `_bmad/custom/bmad-build.user.toml`：通过 BMAD 的 `persistent_facts` 注入路由规则。
- `AGENTS.md`：告诉 Codex 在运行 `bmad-build` 时读取项目级路由。
- **BMAD 原有 route、implementation/reviewer prompt、reviewer instruction file、上下文隔离、同步等待和父智能体 triage 全部保留。**

这比直接覆盖 `workflow.implementation_handoff` 或各 review lens 的完整 instruction 更抗 BMAD 上游升级。

## 当前角色

| BMAD 场景 | Codex agent | 模型 | 推理强度 |
| --- | --- | --- | --- |
| step-02 独立代码库探索（仅 BMAD 原流程决定分派时） | `BmadExplorer` | `gpt-6-luna` | `medium` |
| step-03 full-route 实现 | `BmadImplementer` | `gpt-6-luna` | `xhigh` |
| step-04 `blind-hunter` | `BmadAdversarialReviewer` | `gpt-6-sol` | `high` |
| step-04 `edge-case-hunter` | `BmadEdgeCaseReviewer` | `gpt-6-sol` | `high` |
| step-04 `verification-gap` | `BmadVerificationReviewer` | `gpt-6-sol` | `high` |
| oneshot `blind-hunter` | `BmadAdversarialReviewer` | `gpt-6-sol` | `high` |

当前 `bmad-build` 没有单独的 acceptance/intent 审查 layer，因此本项目**不额外创造一层**；验收标准和任务意图仍由 BMAD 父智能体按原工作流核对。

## 为什么不直接改写 BMAD lens prompt

BMAD 自己控制：

- reviewer prompt 的具体内容；
- reviewer instruction file 的读取顺序；
- `claims_file` 何时允许读取；
- diff / spec 等绝对路径占位符替换；
- reviewer 是否并行启动；
- findings 的 triage、patch、defer 和 loopback。

本项目只解决一个问题：

> 当 BMAD 已决定“现在要派这个子任务”时，在 Codex 中应该用哪个 agent / model / reasoning effort。

因此升级 BMAD 后，只要阶段和 layer id 没有变化，通常无需同步复制新的 reviewer prompt。

## 路由行为

完整规则见 [`.codex/bmad-build-routing.md`](.codex/bmad-build-routing.md)。

优先级：

1. **宿主公开项目自定义 agent 类型**：直接指定相应 `Bmad*` agent，使用 profile 中的模型、推理强度、sandbox 和 developer instructions。
2. **没有自定义类型，但通用子智能体调用支持按次指定模型/推理强度**：读取对应 profile 的 `model` 与 `model_reasoning_effort` 显式分派；此时不能声称 profile 的 developer instructions / sandbox 已加载。
3. **通用子智能体存在，但不能选模型**：继续使用 BMAD 原子任务 prompt 和宿主默认模型，并明确该轮没有应用项目级模型绑定。
4. **子智能体整体不可用**：才回到 BMAD 原工作流定义的直接实现或阻塞处理。

缺少某个 custom agent 类型，不等于“子智能体整体不可用”。

## 安装

在本仓库中：

```bash
bash install.sh /absolute/path/to/your-bmad-project
```

安装内容：

```text
.codex/
├── agents/
│   ├── BmadExplorer.toml
│   ├── BmadImplementer.toml
│   ├── BmadAdversarialReviewer.toml
│   ├── BmadEdgeCaseReviewer.toml
│   └── BmadVerificationReviewer.toml
└── bmad-build-routing.md

_bmad/custom/
└── bmad-build.user.toml

AGENTS.md
```

安装脚本不会直接覆盖已有 `AGENTS.md`；若已有文件，会仅在缺少本项目段落时追加。若目标项目已有自己的 `_bmad/custom/bmad-build.user.toml` 且其中没有本路由，脚本不会危险地重写 TOML，而会生成一个待人工合并的示例文件。

安装/修改 agent profile 后，建议新开 Codex 会话，让自定义角色 schema 重新加载。

## 与 ZCode 共存

本配置只约束 **Codex 宿主**。

如果项目还使用 ZCode，可以继续维护：

```text
.zcode/bmad-review-routing.md
```

`bmad-build.user.toml` 中的 persistent fact 明确要求其他宿主忽略 Codex 路由，因此不会要求 ZCode 使用这些 `.codex/agents`。

## 项目结构

```text
.
├── AGENTS.md
├── .codex/
│   ├── agents/
│   │   ├── BmadExplorer.toml
│   │   ├── BmadImplementer.toml
│   │   ├── BmadAdversarialReviewer.toml
│   │   ├── BmadEdgeCaseReviewer.toml
│   │   └── BmadVerificationReviewer.toml
│   └── bmad-build-routing.md
├── _bmad/
│   └── custom/
│       └── bmad-build.user.toml
├── docs/
│   └── architecture.md
└── install.sh
```

## 设计原则

- BMAD 是流程真相来源；本项目不复制它的工作流逻辑。
- 父智能体保留 route、triage、验收和最终决策权。
- Implementer 可保持会话以接受 step-04 patch。
- Reviewer 使用独立上下文，不继承实现会话。
- Reviewer 只报告证据充分的实际问题；零 findings 合法。
- 子智能体不再派生子智能体。
- 项目级模型绑定优先于“reviewer 与父会话同模型”的默认约定，但仅在宿主确实支持该绑定时声称生效。

## 参考

- `oil-oil/codex-team-mode`：Codex 自定义 agent、模型和 reasoning effort 的配置方式。
- `bmad-code-org/BMAD-METHOD`：BMAD Build 的 route、implementation handoff、review layers 和 customization 机制。
