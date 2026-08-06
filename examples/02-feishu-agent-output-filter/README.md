# 案例 02　飞书智能体输出过滤

这份样例用于已经接入飞书的 Python 智能体。它处理两个问题。

- 模型运行对象中包含 `thought`、Token 用量和会话标识。
- 平台在短时间内重复投递同一项任务。

样例不包含飞书密钥，也不调用真实飞书接口。先在本地完成过滤测试，再把发送函数接到现有机器人。

## 文件

```text
output_filter.py       输出提取、发送前过滤和重复请求检查
adapter_example.py     接入现有飞书机器人的位置
test_output_filter.py  本地测试
fixtures/              使用虚构内容的模型返回样例
```

## 1　运行测试

进入本目录。

```bash
python3 -m unittest -v test_output_filter.py
```

5项测试应当全部显示 `ok`。

## 2　先分开两种数据

智能体运行层可以保留完整对象，用于服务端日志和费用统计。飞书消息只接收公开正文。

```text
智能体 stdout
    ↓
extract_agent_text
    ↓
正文
    ↓
guard_outbound
    ↓
飞书发送函数
```

`extract_agent_text` 支持完整 JSON 和 JSONL。它只读取 `text`、`result` 等公开字段。`guard_outbound` 放在发送函数之前。如果前面的解析被改坏，这一层仍会检查内部字段。

## 3　接入现有机器人

复制过滤文件。

```bash
cp output_filter.py /你的机器人项目/output_filter.py
```

在机器人入口中导入。

```python
from output_filter import DuplicateGuard, extract_agent_text, guard_outbound

duplicate_guard = DuplicateGuard(window_seconds=30)
```

收到飞书消息以后，先检查重复任务。

```python
if duplicate_guard.seen_recently(chat_id, user_text):
    return
```

模型运行结束后，先提取正文。

```python
raw_result = run_agent(user_text)
answer = guard_outbound(extract_agent_text(raw_result))
```

发送前再检查一次。

```python
outbound = "✅ 完成\n" + answer
send_to_feishu(chat_id, outbound)
```

`adapter_example.py` 放出了完整连接位置。`run_agent` 和 `send_to_feishu` 由现有项目提供。

## 4　怎样判断修复生效

准备一个包含内部字段的虚构对象。

```bash
python3 -c 'from pathlib import Path; from output_filter import extract_agent_text; print(extract_agent_text(Path("fixtures/agent-result.json").read_text()))'
```

终端只应显示下面这一句。

```text
资料已经整理完成，共找到 4 条有效记录。
```

下面这些字段不能出现在结果里。

```text
thought
usage
sessionId
requestId
modelUsage
```

## 5　重复任务怎样处理

`DuplicateGuard` 使用聊天 ID 和用户文字的 SHA-256 摘要。默认窗口是30秒。相同聊天和相同文字在窗口内只执行一次，不同任务不会被拦截。

去重记录只保存在内存中。机器人重启以后记录会清空。需要跨进程去重时，可以把摘要和过期时间放进 Redis 或 SQLite，发送正文的规则不变。

## 6　日志里保留什么

运行日志可以记录模型、耗时和 Token 数量。不要记录模型的内部推理全文，也不要把完整运行对象放进普通聊天日志。

建议记录下面这些内容。

```text
任务是否成功
运行耗时
模型名称
输入和输出 Token 数量
公开正文的字符数
错误类型
```

用户原文和最终正文是否进入日志，需要按照项目的数据权限决定。

## 7　停止和回退

修改运行中的机器人以前，先备份原文件。

```bash
cp bot.py bot.py.before-output-filter
python3 -m py_compile bot.py
```

发生问题时恢复备份，再重启服务。

```bash
cp bot.py.before-output-filter bot.py
python3 -m py_compile bot.py
systemctl --user restart 你的机器人.service
```

回退只恢复代码。已经发送到飞书的旧消息不会自动撤回。
