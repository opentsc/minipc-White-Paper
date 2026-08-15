# 分级实验

实验按完成结果分级，不按软件名称分级。

## 已有实验归类

| 等级 | 实验 | 分类 | 完成结果 | 商业用途 |
| --- | --- | --- | --- | --- |
| 20 | [每周自动备份](level-20/01-daily-backup/README.md) | 文件与备份 | 自动备份重要目录并验证能还原 | 备份配置交付和定期还原演练 |
| 30 | [可远程管理、断电自恢复的机器](level-30/01-remote-managed-box/README.md) | 远程管理与自启 | 远程能连、门只开该开的、断电来电自己回来 | 远程管理交付和断电恢复演练 |
| 50 | [全家的 ChatGPT](level-50/01-family-chatgpt/README.md) | 本地模型服务 | 手机能用、接口能调、模型真跑在 GPU 上 | 预装本地 AI 工作站的交付基础 |
| 60 | [本地聊天记录检索](level-60/01-local-chat-search/README.md) | 本地数据检索 | 导入、定时更新并检索本地记录 | 知识库和资料检索的基础实验 |
| 60 | [私有知识库](level-60/02-private-rag/README.md) | 知识库与验收 | 回答带来源、查不到就说查不到、断网可用 | 企业私有知识库的交付基础 |
| 60 | [发票台账](level-60/03-invoice-ocr/README.md) | 单据处理与交付 | 一个文件夹的单据跑成台账，错的被挑出来 | 单据自动化的交付基础 |
| 60 | [信息抓取日报](level-60/04-daily-digest/README.md) | 自动化与交付 | 定时抓取、本地模型摘要、按日期落盘 | 信息简报与工作流交付的基础实验 |
| 70 | [飞书智能体输出过滤](level-70/02-feishu-agent-output-filter/README.md) | Agent-to-Human | 只发送人需要阅读的结果 | 企业消息交付和人工确认 |
| 70 | [把一个案例做成商品](level-70/04-productize-one-case/README.md) | 产品化 | 演示、说明书、验收单三样齐了 | 任何一个案例的交付准备 |
| 80 | [第一单全过程](level-80/01-first-deal-walkthrough/README.md) | 客户与报价 | 线索、访谈、算账、报价四份材料串成一单 | 成交动线的完整演练 |
| 90 | [一次完整交付的记录](level-90/01-first-delivery-record/README.md) | 交付与验收 | 进场、交接、复盘三份表串成一次交付 | 交付流程的完整演练 |
| 100 | [月度巡检](level-100/01-monthly-checkup/README.md) | 运维与续费 | 一个脚本跑完六项巡检，输出直接进月度报告 | 月维护服务的交付凭据 |
| 70 | [本地多 Agent 工作节点](level-70/03-local-agent-workforce/README.md) | Agent 运行治理 | 定义任务、时间、浏览器和审批边界 | Agent 工作流交付的配置基础 |

## 后续实验等级

- `level-10`：开机、系统和网络；
- `level-20`：文件、服务和 Docker；
- `level-30`：远程管理、备份和恢复；
- `level-40`：BIOS、UMA、驱动和 ROCm；
- `level-50`：本地模型、Web UI 和 API；
- `level-60`：RAG、OCR 和自动化；
- `level-70`：产品化；
- `level-80`：演示和报价；
- `level-90`：交付和验收；
- `level-100`：运维、续费和追加销售。

## 实验要求

每个实验要写明准备、操作、正常结果、错误处理、停止、恢复、验收和可出售的结果。实验使用样本数据，不提交真实客户资料、令牌和内网地址。
