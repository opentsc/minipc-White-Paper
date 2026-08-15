# 08　局域网 API

## 这一章的任务

让局域网里别的程序也能调用这台机器的模型。

前面七章解决的都是“人怎么用”。这一章解决“程序怎么用”——**做完之后，你家里任何一台电脑上的一段代码、一个脚本、一个现成的软件，都能把活派给这台 Mini PC。**

**这一章是后面三卷的地基。** [第 7 卷](../07-RAG/README.md)的知识库、[第 8 卷](../08-OCR/README.md)的单据处理、[第 9 卷](../09-Agent与RPA/README.md)的自动化，连的全是这一章打开的这个接口。所以这一章写得比前面几章细，值得慢慢做完。

## 开始前

- 第 3 章做完，Ollama 是一个跑着的服务；
- 第 4 章做完（那一章已经动过一次 `OLLAMA_HOST`，这一章要把它写全）；
- [第 3 卷第 3 章](../03-服务器基础/03-固定IP.md)那个固定地址在手上。下面一律写成 `192.168.1.50`，**换成你自己那个**；
- [第 3 卷第 9 章](../03-服务器基础/09-防火墙与密钥.md)做完，ufw 开着，你会看那张规则表；
- 局域网里另外一台电脑，Windows、macOS、Linux 都行，上面有 Python 3。**没有第二台机器也能做完，把地址换成 `localhost` 在本机跑就是**；
- 60 分钟。

## 新词

**API**（应用程序接口，Application Programming Interface）：**程序对程序的入口。** 人用界面——看得见按钮，点一下有反应；程序用 API——看不见界面，发一段规定格式的数据过去，收一段规定格式的数据回来。

**端点**（endpoint）：API 上的一个具体地址，形如 `/v1/chat/completions`。**一个端点管一件事**，要对话就发到管对话的那个端点上。

**OpenAI 兼容接口**：一套接口的写法，最早是 OpenAI 定的，后来变成了事实上的通用格式。**很多本地推理软件都照着它实现一遍**，好处是：任何原本连 OpenAI 的程序，把地址一改就能连到你这台机器上，代码一个字不用动。

**JSON**：一种写数据的文本格式，用大括号和引号把“字段名”和“值”配成对。API 的请求和返回都用它。

**请求**（request）与**返回**（response）：你发过去的那一段叫请求，它回给你的那一段叫返回。

**流式**（stream）：让它一个字一个字往回吐，而不是憋完整段再一次给你。第 3 章在终端里看到的那种一个字一个字往外冒，就是流式。

**无状态**（stateless）：**这个接口不记得你上一句说了什么。** 每次请求都要把整段对话原样带过去。这一条是新手最容易漏的，下面单说。

## 人用界面，程序用 API

第 4 章那个网页界面，底下走的其实就是这个接口——你在浏览器里打的字，Open WebUI 转成一段 JSON 发给 Ollama，收到返回再画到页面上。

**所以这一章不是新装什么东西，是把已经在跑的那个接口开给别人用。**

值得先想清楚一件事：**为什么要开 API，不是让所有人都去用网页界面？**

- 网页界面一次只服务一个人的一次提问。**API 能被脚本调用，一次处理一千份文件**；
- 网页界面的输出在屏幕上。**API 的输出是数据，能直接存进表格、写进数据库、发给下一个程序**；
- 后面几卷要做的事——把一叠 PDF 变成一个能查的知识库、把一沓单据变成一张表——**没有一件是靠人在界面上一句句问能做完的。**

## Ollama 自带两套接口

装完 Ollama 就有了，不用另装。**同一个端口 11434 上，同时开着两套写法**：

| 接口 | 地址开头 | 什么时候用 |
| --- | --- | --- |
| Ollama 原生接口 | `http://地址:11434/api/...` | 要用 Ollama 特有的功能时 |
| OpenAI 兼容接口 | `http://地址:11434/v1/...` | **默认用这个** |

**本教材一律用 OpenAI 兼容那一套**，理由就是上面新词里那一条：现成的程序改个地址就能接过来，换掉 Ollama 换成别的推理软件也不用重写。

官方文档给的基地址是 `http://localhost:11434/v1/`，常用端点有这些（Ollama OpenAI 兼容接口文档，访问日期 2026-08-14）：

- **`/v1/chat/completions`** —— 对话。**这一章只用这一个**；
- `/v1/models` —— 列出有哪些模型；
- `/v1/completions` —— 老式的续写接口，新程序不用；
- `/v1/embeddings` —— 把文字转成向量，第 12 章和[第 7 卷](../07-RAG/README.md)要用；
- `/v1/responses` —— 另一套较新的写法。

同一份文档还写明一件要紧的事：**这个接口要求你填一个 api_key，但它不校验**。官方给的例值是 `ollama`。**“要求填但不校验”的意思就是没有认证**，这一章最后一节专门说这件事。

## 开放到局域网

第 3 章装完的时候，接口只开在 `127.0.0.1:11434` 上——只有这台机器自己能连。第 4 章为了让 Docker 容器连得到，已经把它改成监听全部地址了。**这一章把这段配置写全，并且解释每一行。**

### 覆盖文件是什么

Ollama 装出来的服务文件是官方的，**你不该直接改它**——下次升级会被覆盖掉。systemd 的做法是让你在旁边放一个“覆盖文件”，里面只写你要加的那几行，启动的时候两份合在一起用。

```bash
sudo systemctl edit ollama
```

作用：打开覆盖文件的编辑器。**存的位置是 `/etc/systemd/system/ollama.service.d/` 下面**（Ollama 官方 Linux 安装文档，第 3 章已引用）。

打开之后你会看到上下两行注释，**内容必须写在这两行之间**。把这台机器上要设的环境变量一次写全：

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/你要放的路径/models"
Environment="OLLAMA_KEEP_ALIVE=-1"
```

逐行解释：

- **`[Service]` 这一行是段落名，只能有一个。** 三个变量全部写在它下面，一行一个 `Environment=`。**分成三段 `[Service]` 是最常见的写错法**；
- **`OLLAMA_HOST=0.0.0.0:11434`** —— 让它在这台机器的全部地址上监听 11434 端口。`0.0.0.0` 的意思是“所有地址”，包括局域网那个。**这一行是这一章的关键**。官方文档给的就是这个带端口的写法；第 4 章写的是不带端口的 `0.0.0.0`，**两个都是让它监听全部地址**，带上端口更明确；
- **`OLLAMA_MODELS`** —— 模型存哪儿，第 3 章那一节。没挪过就不用写这一行；
- **`OLLAMA_KEEP_ALIVE=-1`** —— 让模型常驻内存，第 7 章那一节。不想常驻就不写。

`Ctrl+O` 回车保存，`Ctrl+X` 退出。然后让它生效：

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

第一条让 systemd 重读配置，第二条重启服务。**这两条第 3 章和第 4 章都用过，一样的动作。**

### 确认写对了

先看合并之后到底是什么样：

```bash
systemctl cat ollama --no-pager
```

作用：把官方那份服务文件和你的覆盖文件一起打印出来。**输出的后半段应该能看到你刚写的那几行 `Environment=`**，前面带一行 `# /etc/systemd/system/ollama.service.d/override.conf` 之类的路径注释。

再看端口：

```bash
ss -tln | grep 11434
```

`Local Address` 那一列是 `0.0.0.0:11434` 就对了。**还是 `127.0.0.1:11434`**，说明那几行没生效——十有八九写在了注释外面，或者 `[Service]` 那一行漏了。

## 防火墙放行

**第 5 章有一句话，这一章要改口。**

第 5 章说：局域网里的设备连不上 11434，“连不上才是对的”。那时候是对的——第 4 章只放行了 Docker 那个网段，家里人是从 Open WebUI 进来的，用不着直连 Ollama。

**这一章的任务就是让别的机器连得上**，所以要再加一条规则：

```bash
sudo ufw allow from 192.168.1.0/24 to any port 11434 proto tcp
```

作用：允许从你家这个网段来的连接访问 11434。写法和第 5 章放行 3080 那条一模一样，只换了端口号。**地址段换成你自己的**（[第 3 卷第 9 章](../03-服务器基础/09-防火墙与密钥.md)拆过这四段的含义）。

看一眼表：

```bash
sudo ufw status verbose
```

现在这台机器的门禁清单上应该有这么几行（省掉了前面几卷的）：

```text
To                         Action      From
--                         --          ----
3080/tcp                   ALLOW IN    192.168.1.0/24
11434/tcp                  ALLOW IN    172.17.0.0/16
11434/tcp                  ALLOW IN    192.168.1.0/24
Anywhere on tailscale0     ALLOW IN    Anywhere
```

**每一行你都该说得出这个口是给谁开的**，这是[第 3 卷第 9 章](../03-服务器基础/09-防火墙与密钥.md)的规矩。11434 那两行分别是给 Docker 容器和给局域网里的程序开的。

> **只想让某一台机器连，不想开给整个网段**，把 `192.168.1.0/24` 换成那台机器的地址，例如 `192.168.1.77`。这比开整段紧，值得做。

## 用 curl 发第一个请求

`curl` 是命令行里发网络请求的工具（[第 5 卷第 17 章](../05-驱动与ROCm/17-llama.cpp-Vulkan.md)用它下过文件）。**先在 Mini PC 本机上试，通了再去别的机器上试。**

### 先问它有哪些模型

```bash
curl -s http://localhost:11434/v1/models | python3 -m json.tool
```

作用：向列模型的那个端点发一个请求，把返回的 JSON 排版打印出来。`-s` 是安静模式，不打印进度条；后半段那个 `python3 -m json.tool` 是系统自带的 JSON 排版工具，**不加它的话返回会挤成一长行，没法看**。

正常输出是一段带缩进的 JSON，里面每个模型一段，`"id"` 那个字段就是模型名。**这些名字和 `ollama list` 里的一致**，下一步要照抄。

### 再发一句话

```bash
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.6-35b",
    "messages": [
      {"role": "user", "content": "用一句话介绍你自己"}
    ]
  }' | python3 -m json.tool
```

整段复制粘贴，最后回车。逐段说：

- **`-H "Content-Type: application/json"`** —— 告诉对面“我发过去的是 JSON”。这一行不写，多数服务会拒收；
- **`-d '...'`** —— 要发过去的那段数据。**外面那对单引号把整段 JSON 包住**，所以 JSON 内部一律用双引号；
- **`"model"`** —— 用哪个模型，**名字要和上一步 `/v1/models` 里看到的完全一致**。写错了会报模型不存在；
- **`"messages"`** —— 这次对话的内容，一个列表。每一条有 `role`（谁说的）和 `content`（说了什么）。

第一次要等模型加载，十几秒到几分钟（第 7 章那一节）。

## 看懂返回

返回是一段 JSON，形状大致是这样（**字段名沿用 OpenAI 那一套；下面是格式示意，具体数值随模型和版本变化**）：

```json
{
    "id": "chatcmpl-xxxxxxxx",
    "object": "chat.completion",
    "created": 1765000000,
    "model": "qwen3.6-35b",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "我是一个跑在本地的语言模型，可以陪你聊天、写东西、读文件。"
            },
            "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 12,
        "completion_tokens": 27,
        "total_tokens": 39
    }
}
```

**日常只看三处：**

**一、`choices[0].message.content`** —— 模型说的话。这一串就是你要的东西。念法是“choices 这个列表里第 0 个，它的 message，它的 content”。**下面 Python 那几行取的就是它。**

**二、`usage`** —— 这次用掉多少 token。`prompt_tokens` 是你发过去的那些，`completion_tokens` 是它生成的那些。

**这个数字很有用**：第 1 章讲过上下文越长 KV cache 越大，但当时只能估。**这里是实测**——想知道一份文件占多少 token，把它的内容发一次，看 `prompt_tokens` 就是了。第 10 章读代码的时候还要用这一招。

**三、`finish_reason`** —— 它为什么停下来。`stop` 是正常说完了。**看到 `length` 就是被长度上限截断了**，答案是半截的，要把生成上限调大。

## 在别的电脑上用 Python 调用

**换到局域网里另一台机器上做这一节。** 没有第二台机器就在 Mini PC 上做，把地址里的 `192.168.1.50` 换成 `localhost`。

### 先备一个 Python 环境

和第 2 章一样，装在虚拟环境里，不动系统的 Python：

```bash
python3 -m venv ~/ai-client
~/ai-client/bin/pip install requests
```

作用：建一个独立环境，往里装一个叫 `requests` 的包——它是 Python 里发网络请求最常用的一个。Windows 上把 `python3` 换成 `python`，路径写法也跟着变。

### 最小的一段代码

新建一个文件叫 `ask.py`，内容照抄：

```python
import requests

# 换成你那台 Mini PC 的固定地址
BASE = "http://192.168.1.50:11434/v1"
MODEL = "qwen3.6-35b"

resp = requests.post(
    BASE + "/chat/completions",
    json={
        "model": MODEL,
        "messages": [
            {"role": "user", "content": "用一句话介绍你自己"}
        ],
    },
    timeout=600,
)
resp.raise_for_status()
data = resp.json()

print(data["choices"][0]["message"]["content"])
print("---")
print("这次用掉的 token：", data["usage"])
```

跑它：

```bash
~/ai-client/bin/python ask.py
```

**正常输出**是模型说的那句话，然后一行 `---`，然后一行 token 统计。

**这就是整个后面三卷的地基。** 逐行说清楚：

- **`import requests`** —— 把上面装的那个包拿进来用；
- **`BASE` 和 `MODEL`** —— 两个会变的东西拎到最上面，换机器换模型只改这两行；
- **`requests.post(...)`** —— 发一个请求。第一个参数是地址，`json=` 后面那一段就是 curl 里 `-d` 的内容，**用 Python 的字典写，它自动帮你转成 JSON，也自动带上 `Content-Type`**；
- **`timeout=600`** —— 最多等 600 秒。**这一项不能省**：本地模型第一次要加载，长回答也要跑一阵，默认不设超时的话程序可能卡死在那儿；
- **`resp.raise_for_status()`** —— 对面报错就当场停下并打印出错在哪。不写这一句，出错时 `resp.json()` 会给你一段莫名其妙的东西；
- **`data["choices"][0]["message"]["content"]`** —— 就是上一节说的那条路径。

### 常见的三种报不出来

- **`Connection refused`** —— 连不上。先在 Mini PC 上跑 `ss -tln | grep 11434` 确认是 `0.0.0.0`，再确认防火墙那条规则加了；
- **卡住不动，最后超时** —— 多半是防火墙挡着（拒绝会立刻报错，丢弃会挂着）。回上面那一节看 ufw 的规则表；
- **返回里说模型不存在** —— 名字写错了。跑一次 `/v1/models` 照抄。

其余的到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

### 换成 `openai` 这个包

上面那段用的是通用的 `requests`。**换成官方那个 `openai` 包，代码更短，而且能直接说明这一章为什么用 OpenAI 兼容接口。**

```bash
~/ai-client/bin/pip install openai
```

新建 `ask_openai.py`：

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://192.168.1.50:11434/v1",
    api_key="ollama",
)

completion = client.chat.completions.create(
    model="qwen3.6-35b",
    messages=[
        {"role": "user", "content": "用一句话介绍你自己"}
    ],
)

print(completion.choices[0].message.content)
```

跑法一样。**要看的就是那两行 `base_url` 和 `api_key`。**

- **`base_url`** —— 指向你这台机器。**这个包默认指向 OpenAI 的服务器，改掉这一行就改成了你家里这台**；
- **`api_key="ollama"`** —— 官方文档说这个值“要求填但不校验”。**填什么都能过**，填成空字符串反而会被这个包本身拦下来，所以随便填一个。

**这两行就是这一章最值钱的地方。** 网上大量现成的程序、教程、示例代码，写的都是连 OpenAI。**它们绝大多数只要改这两行，就跑在你自己这台机器上了**，一分钱不花，数据不出家门。

## 常用参数

发过去那段 JSON 里，日常会用到的就这几个：

| 参数 | 干什么 | 怎么填 |
| --- | --- | --- |
| `model` | 用哪个模型 | 字符串，**和 `ollama list` 里的名字完全一致** |
| `messages` | 这次对话的全部内容 | 一个列表，每条有 `role` 和 `content` |
| `stream` | 要不要一个字一个字往回吐 | `true` 或 `false`。**不写就是 `false`** |
| `temperature` | 输出的随机程度 | 一个数。**小了更稳更死板，大了更活也更容易跑偏**。要稳定就往 `0` 靠 |

还有一个限制生成长度的参数，**名字和默认值以 Ollama 与 OpenAI 的官方文档为准，本项目未核实，需要核验**。上面说过，被它截断的表现是 `finish_reason` 变成 `length`。

### `messages` 里的三种角色

```json
"messages": [
    {"role": "system",    "content": "你是一个只回答中文的助手，回答控制在三句话以内。"},
    {"role": "user",      "content": "什么是量化？"},
    {"role": "assistant", "content": "量化就是把模型参数压到更少的位数存……"},
    {"role": "user",      "content": "那 Q4_K_M 是什么意思？"}
]
```

- **`system`** —— 给模型的总要求，放在最前面。“只说中文”“先给结论”“输出成一张表”这类话写在这里；
- **`user`** —— 你说的话；
- **`assistant`** —— 它上一轮说的话。

### 接口不记事，每次都要带全

**上面那个例子里为什么要把它自己说过的话也发回去？** 因为这个接口是无状态的——**它不记得你们聊过什么**。

第 4 章那个网页界面看起来记得，是因为 Open WebUI 在自己那头存着记录，每次帮你把整段对话重新发一遍。**你自己写程序，这件事得你自己做。**

两个后果，现在就该知道：

- **想让它记住上下文，就把前面每一轮的 `user` 和 `assistant` 都拼进 `messages` 里再发**；
- **对话越长，每次发过去的东西越多**，`prompt_tokens` 一路涨，KV cache 跟着涨（第 1 章），速度跟着降。**所以第 4 章那句“换个话题就新建一个对话”，在程序这一头同样成立**——该丢的历史要丢。

### 流式怎么写

把 `stream` 打开，返回就从“一整段 JSON”变成“一行一行地往外送”，每行以 `data: ` 开头，最后一行是 `data: [DONE]`。用 curl 看一眼：

```bash
curl -N -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.6-35b","messages":[{"role":"user","content":"数到十"}],"stream":true}'
```

`-N` 是让 curl 别攒着，收到什么立刻显示。**屏幕上会哗啦啦滚出一堆 `data:` 开头的行**，每行里带一小段文字。

自己解析这些行很麻烦，`openai` 那个包帮你做了：

```python
stream = client.chat.completions.create(
    model="qwen3.6-35b",
    messages=[{"role": "user", "content": "写一段三百字的自我介绍"}],
    stream=True,
)

for chunk in stream:
    piece = chunk.choices[0].delta.content
    if piece:
        print(piece, end="", flush=True)
print()
```

**跑起来就是第 3 章终端里那种一个字一个字往外冒的效果。**

- **`delta.content`** —— 这一小段新增的文字。**注意不是 `message.content`**，流式那边字段名不一样；
- **`if piece:`** —— 有些片段这个字段是空的，跳过；
- **`end="", flush=True`** —— 不换行、立刻显示。少了 `flush=True` 会攒一堆才吐一次，就没有流式的意义了。

**什么时候用流式**：给人看的界面用它，人不用干等。**程序对程序不用**——反正要等它说完才能做下一步，一次拿全更省事。

## 这个接口没有密码

**这一节是硬的。**

上面说过，官方文档写明 api_key “要求填但不校验”。**说白了就是**：任何能连到 `192.168.1.50:11434` 的设备，不需要账号、不需要密码、不需要任何凭证，就能用你的模型。

三条要记住的：

**一、只在局域网里开，不要开到公网。** 第 5 章为 Open WebUI 讲过三条理由，对这个接口全部成立，而且更严重——**Open WebUI 至少还有一个登录页，这个接口连登录页都没有。**

**二、别在路由器上给 11434 做端口转发。** 出门要用，走 [Tailscale](../03-服务器基础/06-Tailscale.md)（第 5 章那一节），把地址换成 `100.` 开头的那个。

**三、这个端口不只是用来提问的。** Ollama 的原生接口（`/api/...` 那一套）除了对话之外还有管理模型的动作。**能连上这个端口的人能做的事比“问几句话”多。** 具体有哪些端点、各自能干什么，**本项目未逐个核实，需要核验**，以 Ollama 官方的 API 文档为准。

**所以那条 ufw 规则值得写紧一点**：知道只有某台机器要连，就只放那台机器的地址，别放整个网段。

> **真要给这个接口加上认证**，做法是在它前面放一层网关，由网关来验密钥，再转给 Ollama。那是[第 10 卷](../10-产品化/README.md)的事，**本卷不做**。要交付给客户，这一层躲不掉。

## 关于 vLLM

有人会问：既然要做接口，为什么不用 vLLM？它就是干这个的，还快。

**这台设备上现在不建议。** [第 5 卷第 7 章](../05-驱动与ROCm/07-gfx1151.md)已经把边界写清了，口径本卷照搬，不重新论证：截至 2026-08-13 核对，vLLM 在 gfx1151 上有两条关键缺陷还没关闭（编译时共享内存超限、V1 引擎图捕获挂起），加载视觉模型另有两条；官方在这台设备上不提供预编译包，只有源码编译路径。那一章的结论是**vLLM 现在不能当生产端点**。

**本卷的接口就用 Ollama 这一个。** 它够用，而且和前面七章是同一套东西。

## 有做不出来的地方

到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

## 事实来源和版本日期

- OpenAI 兼容接口的基地址为 `http://localhost:11434/v1/`、api_key 官方例值为 `ollama` 且“要求填但不校验”、端点含 `/v1/chat/completions`、`/v1/completions`、`/v1/models`、`/v1/models/{model}`、`/v1/embeddings`、`/v1/responses`：[Ollama OpenAI 兼容接口文档](https://docs.ollama.com/api/openai-compatibility)，访问日期 2026-08-14，厂商官方文档，事实状态 `official_source`。**端点随版本增删，动手当天以该页面为准**；
- 用 `systemctl edit ollama.service` 在 `[Service]` 段加 `Environment="OLLAMA_HOST=0.0.0.0:11434"` 让它对外监听，改完 `systemctl daemon-reload` 加 `systemctl restart ollama` 生效：[Ollama FAQ](https://docs.ollama.com/faq)，访问日期 2026-08-14，厂商官方文档，事实状态 `official_source`；
- 覆盖文件落在 `/etc/systemd/system/ollama.service.d/` 下：[Ollama Linux 安装文档](https://docs.ollama.com/linux)，访问日期 2026-08-14，第 3 章已引用，**本章不重新核对**；
- **返回 JSON 的字段名与层级（`choices[0].message.content`、`usage.prompt_tokens`、`finish_reason`）以及流式返回里的 `delta.content`**：沿用 OpenAI 的接口约定，**本项目未在这台设备上逐字段核对，需要核验**，正文里的样例为格式示意，以官方文档和你自己的实际返回为准；
- **限制生成长度那个参数的名字与默认值**：**本项目未核实，需要核验**，以 Ollama 与 OpenAI 的官方文档为准。被截断的表现是 `finish_reason` 变成 `length`；
- **Ollama 原生 `/api/...` 那一套里有哪些管理模型的端点**：**本项目未逐个核实，需要核验**，以 Ollama 官方 API 文档为准。**能确定的是这个端口上没有认证**，依据是上面那条 api_key 不校验的官方说明；
- vLLM 在 gfx1151 上的缺陷状态与“不能当生产端点”的结论：[第 5 卷第 7 章](../05-驱动与ROCm/07-gfx1151.md)已拍板，依据的 issue 与核对日期（2026-08-13）都在那一章，**本章原样引用，不重新论证**；
- ufw 规则的四段写法、Docker 发布的端口不受 ufw 约束：[第 3 卷第 9 章](../03-服务器基础/09-防火墙与密钥.md)与本卷第 5 章已写全，**本章只换端口号**；
- 不做端口转发、不把服务直接暴露在公网、要出门就走 Tailscale：[第 3 卷第 6 章](../03-服务器基础/06-Tailscale.md)与本卷第 5 章已拍板，**本章原样引用**；
- `requests` 与 `openai` 两个 Python 包的用法、`python3 -m json.tool`、`curl` 的 `-s`、`-H`、`-d`、`-N` 参数：属 Python 与 Linux 的通用行为，未针对本项目设备单独实测。**`openai` 这个包的接口写法随其版本变化，以它自己的文档为准**；
- Ubuntu 24.04 禁止往系统 Python 里装包、要用虚拟环境：第 2 章已写全，**本章不重讲**；
- 事实状态标记的含义见[证据与发布规则](../../reference/证据与发布规则.md)；
- 本章核验日期：2026-08-14。

## 完成检查

- API 和网页界面的区别是什么？为什么后面三卷都要用 API？
- Ollama 在 11434 上开着几套接口？本教材用哪一套，为什么？
- 覆盖文件放在哪个目录？为什么不直接改官方那份服务文件？
- 三个环境变量要写成一段 `[Service]` 还是三段？
- `ss -tln | grep 11434` 现在显示什么地址？显示 `127.0.0.1` 说明什么？
- 第 5 章说局域网连不上 11434 才是对的，这一章为什么改口了？
- `curl` 那条命令里，`-H` 和 `-d` 各是干什么的？
- 返回的 JSON 里，模型说的话在哪个字段？完整路径怎么念？
- `usage` 有什么用？想知道一份文件占多少 token 怎么办？
- `finish_reason` 是 `length` 说明什么？
- Python 那段里 `timeout` 为什么不能省？`raise_for_status()` 不写会怎样？
- 用 `openai` 那个包的时候，要改的是哪两行？为什么说这两行最值钱？
- 这个接口记不记得你上一句说了什么？想让它记住该怎么办？
- `stream` 打开之后返回长什么样？流式那边取内容的字段名和非流式一样吗？
- api_key 填错了会怎样？这说明什么？
- 想出门也能调用这个接口，该怎么做？不该怎么做？

## 下一步

接口通了，后面几卷有地基了。

从下一章起，本卷按用途扩展。**先解决一个所有人都会问的问题**：这么多模型，中文说得好的到底怎么挑。

进入[第 9 章：中文对话模型](09-中文对话模型.md)。
