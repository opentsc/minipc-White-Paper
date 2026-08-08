# 案例 03　本地多 Agent 工作节点

这组文件用于搭建一个脱敏的多 Agent 工作节点。它只给出目录、工单、Schedule、浏览器锁和人工确认的结构，不包含真实账号和可直接进入内部系统的配置。

## 做完会得到什么

- 一个岗位 Agent 配置模板。
- 一份结构化工单模板。
- 一份 Schedule Registry 示例。
- 一份 Browser Registry 示例。
- 一份人工确认策略。

## 目录

```text
WORKFORCE_ROOT/
├─ agents/
│  └─ AGENT_ID/
│     ├─ workspace/
│     ├─ state/
│     ├─ logs/
│     ├─ credentials/
│     └─ agent.yaml
├─ jobs/
├─ registry/
└─ runtime/
   ├─ browser/
   └─ locks/
```

## 文件

| 文件 | 用途 |
| --- | --- |
| `agent.example.yaml` | 定义一个岗位 Agent 的目录、模型和工具边界 |
| `job.schema.example.yaml` | 定义协调 Agent 与岗位 Agent 之间的工单 |
| `schedule.registry.example.yaml` | 定义资源队列和后台任务 |
| `browser.registry.example.json` | 定义浏览器 Profile、端口和锁 |
| `approval.policy.example.yaml` | 定义需要人工确认的动作 |

## 使用顺序

1. 建立 `WORKFORCE_ROOT`，并把示例复制到它的 `registry/` 目录。
2. 在部署副本中替换 `AGENT_ID`、`SERVICE_NAME`、`MODEL_ENDPOINT`、`PROFILE_ID` 和 `CDP_PORT`。
3. 为每个 Agent 建立独立的工作区、状态、日志和凭据目录。
4. 先提交一张只读工单。检查协调 Agent 审核前不会执行，审核后结果写入指定位置。
5. 再测试两个空白浏览器 Profile。检查它们使用不同端口和锁，同一个 Profile 的第二个任务应当停止。
6. 外部发送、发布、生产部署、删除、付款、账号恢复和权限扩大继续停在人工确认状态。

## 可见结果

- 工单包含允许路径、允许工具、禁止动作和验收条件。
- 岗位 Agent 只能写自己的工作区和状态目录。
- Schedule 按资源队列发放任务。
- 浏览器任务持有自己的 Profile 和锁。
- 需要人工确认的工单不会直接进入执行状态。

## 停止方法

出现目录越界、缺少人工确认、同一 Profile 重复运行或日志写入凭据时，停止对应的 `SERVICE_NAME`。保留工单、状态和日志，回到最近一次可用配置。

这些文件只说明配置结构。它们没有创建服务，也没有连接模型、浏览器或外部账户。
