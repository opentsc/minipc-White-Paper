# 本地风格库改写

## 完成结果

给本地模型一份原文和 3 到 5 篇代表作，得到：

- 风格指纹；
- 轻改、标准、猛改三份草稿；
- 每份草稿的事实检查；
- 一份可以人工复核的运行记录。

原文不会被覆盖，脚本不会自动发布或发送结果。

## 目录

```text
05-style-rewriter/
├── README.md
├── rewrite.py
├── input.example.md
├── style-library/
│   ├── 01-代表作.example.md
│   └── 风格说明.example.md
└── outputs/                 # 本地运行后生成，不提交真实内容
```

## 开始前

- 本地 OpenAI 兼容接口已经能回答问题；
- Python 3 已安装；
- 准备一份样本文本和 3 到 5 篇代表作；
- 实验只使用样本数据，不放客户资料、密钥、内网地址和未公开文章。

## 运行

在本目录执行：

```bash
export MODEL_ENDPOINT="http://MINIPC_IP:PORT/v1"
export MODEL_NAME="MODEL_NAME"
python3 rewrite.py \
  --style-dir style-library \
  --input input.example.md \
  --output-dir outputs
```

也可以把 `MODEL_ENDPOINT` 和 `MODEL_NAME` 直接作为参数传入：

```bash
python3 rewrite.py \
  --endpoint "http://MINIPC_IP:PORT/v1" \
  --model "MODEL_NAME" \
  --style-dir style-library \
  --input input.example.md \
  --output-dir outputs
```

## 正常结果

`outputs/` 中应有：

```text
style-fingerprint.md
light.md
standard.md
strong.md
run.jsonl
```

`run.jsonl` 只记录时间、模型名、接口地址和输出文件，不记录令牌。输入和输出内容由本地文件保存。

## 验收

```text
□ 四个输出文件都生成
□ 原文文件内容没有改变
□ 三份改写都保留数字、日期、链接和限定条件
□ 事实检查可以逐条回到原文
□ 没有自动发送或公开发布
□ 模型名、接口地址和运行时间已经记录
```

## 错误处理

- 接口连不上：先检查 `MODEL_ENDPOINT` 和端口，再检查本地服务日志；
- 模型名错误：用本地服务的模型列表确认 `MODEL_NAME`；
- 输出不是 JSON：脚本会保留原始响应，检查 `run.jsonl`；
- 模型新增事实：停止使用该份草稿，回到事实规则重新运行；
- 风格库混入了别人的文章：删除该文件，重新生成风格指纹。

## 停止和恢复

运行中按 `Ctrl+C` 停止。已经写出的文件保留，原文不变。删除 `outputs/` 后可以重新运行，不影响风格库和输入文件。

## 商业边界

这项实验可以作为本地写作改稿工具的演示基础。交付时需要另外约定文件格式、字数、保存期限、风格库维护人、人工复核和模型升级后的重测。检测器分数不是验收承诺。
