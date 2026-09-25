# Codex bmad-build 子智能体路由

本文件只适用于 Codex 宿主运行本项目的 `bmad-build`。保留 BMAD 原有的 route
选择、子任务 prompt、reviewer 指令文件读取顺序、上下文隔离、同步等待和父智能体
triage。ZCode 继续使用 `.zcode/bmad-review-routing.md`。

| BMAD 阶段或 layer id | Codex 自定义 agent |
| --- | --- |
| step-02 的独立代码库探索（仅原工作流决定分派时） | `BmadExplorer` |
| step-03 `implementation_handoff` | `BmadImplementer` |
| step-04 `blind-hunter` | `BmadAdversarialReviewer` |
| step-04 `edge-case-hunter` | `BmadEdgeCaseReviewer` |
| step-04 `verification-gap` | `BmadVerificationReviewer` |
| oneshot `blind-hunter` | `BmadAdversarialReviewer` |

启动前检查当前宿主是否公开对应的自定义 agent 类型。若支持，按表指定类型并使用
`.codex/agents/` 中的模型和推理档位；这一项目选择优先于审查步骤的“与父会话同模型”
默认句子。实施子智能体应保持可再次联系，以处理 step-04 的 patch；审查子智能体
保持无先前会话上下文。父智能体仍需传递 BMAD 渲染后的完整原始任务 prompt，
包括绝对路径占位符替换，不把本路由文件当成审查任务 prompt。

若宿主没有公开自定义类型，但通用子智能体工具允许选择模型和推理档位，读取
对应 profile 的 `model` 与 `model_reasoning_effort` 并在分派时显式指定，同时保持
无先前会话上下文，传递相同的 BMAD 原始任务 prompt。此时只应用模型选择；
不要声称 profile 的 `developer_instructions` 或 `sandbox_mode` 已加载。若通用工具
也不允许指定模型，则使用其默认设置并明确报告该轮没有应用项目级模型绑定。
不要把缺少自定义类型当成子智能体整体不可用。
若子智能体整体不可用，再执行原工作流相应的直接实现或阻塞处理。

当前 bmad-build 没有独立的 acceptance/intent 审查层，因此不额外增加这一层；
父智能体仍按原工作流核对任务和验收标准。
