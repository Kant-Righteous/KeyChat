# 附件能力自动检测设计

## 背景与目标

当前迭代 C 使用 Provider 级 `supportsImageInput` / `supportsFileInput` 布尔值决定是否发送附件。该方式无法准确描述同一 Provider 下不同模型的能力，也要求用户预先知道模型是否支持附件。

本次改动将能力判断调整为按 `providerId + modelId + attachmentKind` 保存的三态结果：`unknown`、`supported`、`unsupported`。未知模型首次发送时直接携带附件；只有在收到明确的附件拒绝错误、用户确认纯文字重试且重试成功后，才学习为不支持。

不改变附件文件保存、消息历史、Markdown 导出、Stop 行为，也不增加 OCR、文档解析、云端文件上传或批量附件管理。

## 能力模型与优先级

新增模型附件能力领域对象和存储接口。能力按图片和普通文件分别保存，解析优先级为：

1. 用户对具体 Provider 和模型的手动覆盖；
2. 自动检测并持久化的结果；
3. 已知预设模型的保守建议；
4. `unknown`。

`unknown` 和 `supported` 都允许携带附件发送；`unsupported` 在发送前直接提示仅发送文字，避免重复制造已知失败。

Drift schema 升级到 v7，新增 `model_attachment_capabilities` 表，字段为 `providerId`、`modelId`、`kind`、`status`、`source`、`updatedAt`，前三者构成唯一能力键。`source` 区分 `detected` 与 `manual`。Provider 删除时能力记录级联删除。

从 v6 迁移时，仅把旧配置中值为 `true` 且存在默认模型的能力迁移为该模型的手动 `supported`；旧值 `false` 视为“未声明”而不是“不支持”，避免阻止首次探测。旧列保留以兼容已有数据库结构，但聊天发送不再依赖它们。

## 请求与自动学习流程

每次 Normal、Retry 或 Regenerate 开始前，ChatPage 针对目标 Provider、模型和附件类型解析能力：

- 没有附件：保持现有文字发送流程。
- 能力为 `unknown` 或 `supported`：以 OpenAI-compatible 内容分段格式发送文字和附件。
- 当前 user 附件存在已知 `unsupported`：发送前提示；确认后只为本次请求移除附件，历史中的 user 消息和本地附件保持不变。

一次请求中历史消息也可能包含附件。已知不支持的类型在请求编码阶段过滤；未知或支持的类型继续发送。生成目标记录本次实际发出的附件类型，用于成功后的能力学习。

附件请求成功并产生有效 assistant 内容后，以最佳努力方式把实际发送的附件类型记录为 `supported`。能力存储失败不得使已成功的聊天失败。

## 附件拒绝与纯文字重试

Dio 层只在内存中检查 400/415/422 等客户端响应的有限错误文本，将明确包含附件/图片/文件模态和“不支持、无效内容类型”等组合的错误映射为 `attachmentRejected`。鉴权、限流、网络、超时、5xx、文件过大或普通参数错误沿用现有分类，不触发能力学习。

原始响应体只用于本次内存分类：不写数据库、不写日志、不放入用户提示，也不加入异常信息。对外事件只携带非敏感错误枚举和可选的拒绝附件类型。

当附件请求在尚未产生 assistant 内容时收到 `attachmentRejected`：

1. 结束当前生成，不保存空 assistant；
2. 提示“模型拒绝了附件，是否仅发送文字重试”；
3. 用户确认后，使用同一 `_GenerationTarget` 重新请求，但强制过滤全部附件；
4. 不重复创建或保存 user 消息，原附件仍显示在气泡和历史中；
5. 纯文字重试成功后，才把可确定的原附件类型记录为 `unsupported`；
6. 用户取消或纯文字重试失败时，不记录 `unsupported`。

若错误只表明“附件被拒绝”但请求同时含图片和文件、无法确定具体类型，则仍可提供纯文字重试，但不持久化具体类型为不支持。若已产生部分 assistant 内容，则沿用“响应中断”行为，不自动重试。

Retry 和 Regenerate 使用完全相同的解析与学习流程。Regenerate 继续排除旧 assistant，且不丢失原 user 附件上下文。

## 配置 UI

Provider 配置页把现有两个简单布尔开关调整为针对“默认模型”的图片和文件能力设置：自动检测、支持、不支持。

- 自动检测：删除该模型对应类型的手动覆盖，展示当前自动学习或预设结果；
- 支持 / 不支持：写入 `manual` 来源的精确模型覆盖；
- 提供“重置自动检测结果”，只清除该 Provider 当前默认模型的 `detected` 记录，不删除附件或聊天历史。

Custom Provider 与预设 Provider 均可覆盖。切换默认模型后读取该模型自己的状态，不把一个模型的能力传播给同 Provider 的其他模型。

## 测试与验收

测试遵循先失败后实现，至少覆盖：

- 未知模型即使旧 Provider 开关为 false 也携带附件；
- 图片和文件能力互相独立；
- 明确附件拒绝触发提示，普通 400/鉴权/限流/网络/5xx 不触发；
- 确认后纯文字重试不重复 user 消息，附件仍在本地历史；
- 纯文字重试成功才记录 `unsupported`，失败或取消不记录；
- 附件请求成功记录 `supported`；
- 已知不支持时发送前提示并直接只发文字；
- Retry / Regenerate 保持相同规则和附件上下文；
- Stop、部分响应失败不触发错误学习；
- 配置页三态手动覆盖、重置及中英文切换；
- Drift v6 → v7 迁移、级联删除和敏感信息不持久化；
- 全量回归及 Debug APK 构建。

最终执行 `dart format .`、`flutter analyze`、`flutter test`、`flutter build apk --debug`，不运行 Vivo 真机测试。
