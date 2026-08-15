# 14　Lemonade 与 NPU

## 这一章的任务

搞清楚这台机器上那块一直没动过的 NPU 现在能干什么，以及你要不要装 Lemonade。

**这一章大半是读和核对，不是敲命令。** 结论放在最后一节：**绝大多数读者不用装**，前面十三章那套已经够用。但这块芯片是买这台机器时付过钱的，它现在是什么状态，值得说清楚。

## 开始前

- [第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)读过。**NPU 是什么、它和 CPU、iGPU 什么关系、为什么跑模型用的是 iGPU，那一章已经讲透，这一章不重抄**；
- 第 3 章做完，Ollama 在跑。**这一章装的东西和它并存，不冲突**；
- 第 4 章做完最好，Open WebUI 在跑。**这一章末尾要把 Lemonade 接进去**；
- 会查内核版本（`uname -r`）；
- 40 分钟。**只读那一半十分钟就够。**

## 新词

**Lemonade Server**：AMD 发起并维护的一个开源本地推理服务器，专门冲着 Ryzen AI 这一系硬件做的。**它和 Ollama 是同一类东西**——起一个服务，提供接口，管模型。

**引擎**（engine）：真正跑模型的那一层。**Ollama 底下只有 llama.cpp 一个引擎**（第 3 章讲过）；Lemonade 在一个服务器里挂了好几个。

**ONNX**：一种模型文件格式，和 GGUF 并列。**NPU 那条路走的是它，不是 GGUF。**

**FastFlowLM**：Linux 上跑 NPU 的那个运行时，命令名是 `flm`。**这台机器上要用 NPU，绕不开它。**

**`amdxdna`**：NPU 的内核驱动（[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)新词）。**它没加载，`/dev/accel/` 这个目录就是空的或者不存在。**

**DKMS**：一套让内核模块跟着内核升级自动重新编译的机制。**内核里没内置某个驱动的时候，走这条路补上。**

**PPA**：Ubuntu 上的第三方软件源。加一个 PPA 之后，那个源里的包就能用 `apt` 装了。

## Lemonade 和 Ollama 的区别

**三点，只有第二点是它独有的。**

**一、引擎不止一个。** Ollama 只有 llama.cpp 这一条路，跑 GGUF。Lemonade 在一个服务器里聚合了三个：llama.cpp（跑 GGUF，走 Vulkan 或者 ROCm）、ONNX Runtime GenAI（跑 ONNX，走 NPU 或者 NPU 加 iGPU 混合）、FastFlowLM（Linux 上的 NPU 专用运行时）。

**二、它碰 NPU。** **Ollama 完全不碰。** 这台机器上要把 XDNA2 那块芯片用起来跑语言模型，Lemonade 加 FastFlowLM 是目前唯一一条常规路线。

**三、自带管理界面。** 下载模型、切换模型、聊天，都在浏览器里点。**同时提供 OpenAI 兼容和 Ollama 兼容两套接口**，所以它能当成一个外部连接接进 Open WebUI。

**端口是 13305**，和 Ollama 的 11434、Open WebUI 的 3080 都不撞。**三个可以同时装、同时跑。**

## 装它

官方在 Ubuntu 上的路线是 apt 包，通过一个 PPA 分发：

```bash
sudo add-apt-repository ppa:lemonade-team/stable
sudo apt update
sudo apt install lemonade-server
```

作用：把官方那个源加进来，刷新包列表，装上服务。**装完服务自动启动，而且开机自启。**

> **`curl ... | sh` 和加 PPA 是同一类动作**：都是把一个外部来源接进你的系统（第 3 章装 Ollama 时说过同一条）。**地址看清楚，只对信得过的来源这么做。**

不想加 PPA 的话，官方还给了 snap 这条路：

```bash
sudo snap install lemonade-server
```

装完看一眼：

```bash
lemonade status
```

作用：问服务在不在跑。**正常输出会带版本号和端口信息**，具体行文随版本变化。

浏览器打开管理界面：

```text
http://localhost:13305
```

**能看到模型管理和聊天页，就是装好了。**

常用命令就这几条：

| 命令 | 干什么 |
| --- | --- |
| `lemonade list` | 列出全部可用模型，加 `--downloaded` 只看本地已有的 |
| `lemonade pull 模型名` | 下载一个模型 |
| `lemonade delete 模型名` | 删掉本地的模型 |
| `lemonade status` | 服务在不在跑 |
| `lemonade --version` | 版本号 |

**跑 GGUF 模型的时候，它的 llama.cpp 引擎默认走 Vulkan**，也提供 ROCm 变体，Web 界面里选模型时能看到用的是哪个。**这一条和[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)本教材默认 Vulkan 优先的口径是一致的。**

> **局域网访问这一项要注意。** 命令行默认连的是 `127.0.0.1:13305`，**只有本机能用**。把服务绑到 `0.0.0.0` 对外的配置项在官方文档的 Configuration 那一节，**本项目未逐条验证，需要核验**。在验证之前，先在本机用，或者走 SSH 端口转发。

## 它也提供 OpenAI 兼容接口

**和第 8 章、第 13 章是同一套写法，程序不用改。**

基地址是 `http://localhost:13305/api/v1`。**注意这里多了一段 `/api`**，和 Ollama 的 `/v1`、llama-server 的 `/v1` 都不一样，**照抄的时候别漏。**

命令行验一下通不通：

```bash
curl -s http://localhost:13305/api/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "你在 lemonade list --downloaded 里实际有的那个名字",
    "messages": [{"role": "user", "content": "你好"}],
    "stream": false
  }' | python3 -m json.tool
```

**返回里有 `choices` 那个字段就是通的。** 形状和第 8 章那一段一样，**看懂返回那一节在这里原样成立**。

### 接进 Open WebUI

第 4 章那个界面里，Lemonade 当成一个外部的 OpenAI 接口加进去：

1. 打开 Open WebUI，进管理设置里的**外部连接**；
2. 加一个 OpenAI API 连接，地址填 `http://localhost:13305/api/v1`。**Open WebUI 跑在容器里，`localhost` 指的是容器自己**——第 4 章那个 `host.docker.internal` 的写法在这里同样要用上，或者直接填这台机器的固定地址；
3. API Key 随便填一个，本地不校验；
4. 保存之后，模型列表里会多出 Lemonade 已经下载的那些。

**这样一来，家里人还是在同一个界面上选模型，底下跑的是哪一套他们不用知道。**

## NPU 在 Linux 上现在能做什么

**这一节是这一章的核心。核对日期 2026-08-14，这块的状态变得快，动手当天要重新核对。**

### 能做的：NPU 单独推理

**能用。** 走 Lemonade 加 FastFlowLM 这条路，**整个模型完全在 NPU 上跑**（[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)那个词叫 NPU-only 推理）。

**前提有四条，一条都不能少：**

- **硬件是 XDNA 2。** Ryzen AI 300、400 系和 Ryzen AI Max 系是，**这台机器在列**。老的 7000、8000、200 系是 XDNA 1，官方明说不支持，也没有支持计划；
- **内核里有 `amdxdna`。** Linux 7.0 以上的内核内置了它；**Ubuntu 24.04 的 6.x 内核没有，要走 DKMS 单独装**；
- **NPU 固件 1.1.0.0 或更新**；
- **IOMMU 开着**，用户能访问 `/dev/accel/accel0`，`memlock` 限制够大。

装的步骤（**和 Lemonade 同一个 PPA**）：

```bash
sudo add-apt-repository ppa:lemonade-team/stable
sudo apt update
sudo apt install libxrt-npu2 amdxdna-dkms
sudo reboot
```

重启之后确认设备节点在：

```bash
ls /dev/accel/
```

**期望输出是 `accel0`。** 目录不存在或者是空的，说明驱动没加载起来（[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)那一节讲过同一条）。

然后自检：

```bash
flm validate
```

作用：逐项检查固件版本、驱动、`memlock`、IOMMU。**哪一项不过它会说，按提示修哪一项。**

**过了之后**，在 Lemonade 的 Web 界面里选带 NPU 或者 FLM 标记的模型就行。**跑起来的时候 CPU 和 GPU 都应该接近空闲**——那是它真在 NPU 上跑的旁证，读法和第 3 章那三层判断是同一个思路。

> **`flm` 这个运行时在 Lemonade 需要的时候会自动装**，也可以从 FastFlowLM 的发布页手动下 deb 包再 `sudo apt install ./包名.deb`。**具体包名以官方页面上的链接为准，本项目未核实，需要核验。**

### 做不到的：NPU 和 iGPU 混合推理

**Linux 上没有这条路。混合推理仍然是 Windows 专属。**

两个词的区别[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已经拆开讲过，这里只重复结论：

- **NPU-only** —— 整个模型从头到尾在 NPU 上算。**Linux 上有这条路**，但受 NPU 本身的规模和内存路径限制，**能跑的模型和吞吐都有限**；
- **混合推理** —— 把同一个模型的不同部分分给 NPU 和 iGPU，两边一起出力。**Windows 上有，Linux 上没有。**

**这不是配置问题，是当前的支持范围问题。** 按官方指南照做也做不出混合推理来。

### 一个别踩的坑

网上有些性能教程让你在内核参数里加 `amd_iommu=off`，理由是内存读取更快。

**加了之后 NPU 直接消失。** `amdxdna` 依赖 IOMMU 提供的地址隔离，关掉它设备节点就没了，FastFlowLM 和 Lemonade 的 NPU 路线全部关门。

**[第 4 卷第 18 章](../04-Max395硬件/18-不应随意修改的设置.md)已经把这一项列进禁区清单，本卷不重新讨论。** 这一章只补一句：**要用 NPU，IOMMU 必须开着。**

### 两条已知的工程缺陷

核对日期 2026-08-13，**这两条都是单一版本的报告，不代表当前版本的状态**：

- Lemonade 10.3.0 忽略 `LEMONADE_LLAMACPP_PREFER_SYSTEM=true` 这个变量（Lemonade issue #1791）；
- Lemonade 10.2.0 宣称 Day Zero 支持 Strix Halo，实际调用受阻（RyzenAI-SW issue #367）。

**撞上了就去看这两个 issue 的当前状态，别在自己机器上瞎试。**

### 不给性能数字

**本章不给 NPU 的任何速度数字，也不给“NPU 比 iGPU 快”或者“慢”的结论。**

材料里的说法是：NPU 这条路的价值在低功耗，以及**把 iGPU 让出来干别的**——比如 NPU 上挂一个小模型常驻做嵌入或者路由，iGPU 同时跑大模型。**不要指望它比 8060S 快**，大模型的吞吐同样卡在内存带宽上。

**这一段是社区口径，本项目未在这台设备上实测，需要核验。**

[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)那句话在这里重复一次：**50 TOPS 是 NPU 的峰值指标，不是这台设备跑模型的速度。** 给客户做方案的时候，**不要把 NPU 算进承诺范围**，除非你自己这台机器上验过了。

## 结论：谁该装，谁不用装

**该装的两种人：**

- **想试 NPU 的。** 这是唯一一条常规路线，别处没有。做好折腾内核、固件和驱动的准备，按上面四个前提逐条核对；
- **想要 AMD 官方那套管理界面的。** 模型下载、切换、后端选择全在浏览器里点，比 Ollama 那套命令行直观。做交付演示的时候，这个界面本身也是能拿出手的东西。

**不用装的：**

**绝大多数读者。** 前面十三章那套——Ollama 加 Open WebUI 加局域网 API——覆盖了日常和交付要用的全部场景。**Lemonade 装了不会坏事，但它解决的不是你现在的问题。**

**一句话：装 Ollama，它覆盖绝大多数场景；明确要玩 NPU、或者要 AMD 官方的管理界面，再装 Lemonade。两者互不冲突，端口一个 11434 一个 13305，可以同时装，都接进同一个 Open WebUI。**

## 装了就记进基线

不管你装的是 Lemonade 还是 NPU 那一套，**把结果记进[第 4 卷第 16 章](../04-Max395硬件/16-设备基线.md)那份设备基线**：

- Lemonade 的版本号、端口、装的是 PPA 还是 snap；
- `ls /dev/accel/` 的输出（有没有 `accel0`）；
- `flm validate` 每一项过没过；
- 内核版本、NPU 固件版本。

**这几项以后升级内核之后要重新对一次**——DKMS 那条路上，内核一换，模块要重新编译，编译失败的话 NPU 就悄悄没了。**基线里有旧记录，你才能发现它没了。**

## 有做不出来的地方

到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

## 事实来源和版本日期

- Ubuntu 上通过官方 PPA 用 `apt` 安装、默认端口 13305：[Lemonade Server Ubuntu 安装文档](https://lemonade-server.ai/docs/guide/install/ubuntu/)，访问日期 2026-08-13，厂商官方文档，事实状态 `official_source`。**绑到 `0.0.0.0` 对外的配置项材料未逐条验证，需要核验**；
- 提供 `/api/v1` 的 OpenAI 兼容端点、可以作为外部连接接进 Open WebUI：[Lemonade OpenAI 兼容 API 文档](https://lemonade-server.ai/docs/api/openai/)，访问日期 2026-08-13，厂商官方文档，事实状态 `official_source`。**接口文档不含并发、延迟与稳定性数据**；
- llama.cpp、ONNX Runtime GenAI、FastFlowLM 三个引擎的分工与 Linux 上的 NPU 状态：[Lemonade FAQ](https://lemonade-server.ai/docs/guide/faq/)，访问日期 2026-08-13，厂商官方文档，事实状态 `official_source`。**这是厂商自述的支持状态，同期有实际调用受阻的 issue**；
- `lemonade list`、`pull`、`delete`、`status` 等命令：[Lemonade CLI 文档](https://lemonade-server.ai/docs/guide/cli/)，访问日期 2026-08-13，厂商官方文档，事实状态 `official_source`。**命令随版本变化，动手当天以该页面为准**；
- Linux 上的 NPU 路线要求 XDNA 2 硬件、内核 7.0 以上内置 `amdxdna`（6.x 走 DKMS）、NPU 固件 1.1.0.0 以上、IOMMU 开启，并提供 `flm validate` 自检；**只支持 NPU 单独推理，NPU 与 iGPU 混合推理仍是 Windows 专属**：[FastFlowLM Linux NPU 指南](https://lemonade-server.ai/flm_npu_linux.html)，Lemonade／FastFlowLM，访问日期 2026-08-13，厂商官方文档。**原文标注材料未在本机实测**，事实状态 `candidate`，**需要核验**。[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已引用同一条；
- `amdxdna` 负责 NPU 硬件阵列、微控制器与邮箱管理；AMD NPU 是集成在 APU 内的多用户推理加速器，可跑 CNN 与部分 LLM 任务：[amdxdna 内核驱动文档](https://docs.kernel.org/accel/amdxdna/index.html)、[AMD NPU 内核文档](https://docs.kernel.org/accel/amdxdna/amdnpu.html)，kernel.org，访问日期 2026-08-13，厂商官方文档，事实状态 `official_source`。**这两份文档说明的是驱动职责，不证明任何框架能在 Linux 上真的调用到 NPU**，[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已写清这一区分；
- Lemonade 10.3.0 忽略 `LEMONADE_LLAMACPP_PREFER_SYSTEM=true`：[Lemonade issue #1791](https://github.com/lemonade-sdk/lemonade/issues/1791)，访问日期 2026-08-13，社区问题追踪，**单一版本的工程缺陷，未给修复版本**，事实状态 `candidate`；
- Lemonade 10.2.0 宣称 Day Zero 支持 Strix Halo、实际调用受阻：[RyzenAI-SW issue #367](https://github.com/amd/RyzenAI-SW/issues/367)，访问日期 2026-08-13，社区问题追踪，**单一版本的报告，不代表后续版本状态**，事实状态 `candidate`；
- **`sudo apt install libxrt-npu2 amdxdna-dkms` 这一条安装命令、`ls /dev/accel/` 的路径写法、`flm` 的 deb 包名、以及 Lemonade 是否会自动装 `flm`**：素材记录，本项目**未在这台设备上验证过**，事实状态 `candidate`，**需要核验**，以 FastFlowLM 官方页面上当天的写法为准。[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已对 `/dev/accel/` 那一条标注同一句；
- **NPU 路线的价值在低功耗和让出 iGPU、不要指望它比 8060S 快**：社区口径，**本项目未实测，事实状态 `candidate`，需要核验**；
- **NPU 用 snap 装的可用性、`lemonade status` 与 `lemonade list` 的输出格式、Web 界面上后端标记的写法**：**随版本变化，本项目未固定，需要核验**；
- NPU 是什么、和 CPU、iGPU 的分工、50 TOPS 是峰值指标不是推理速度、三者共用一份功耗预算：[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已写全，**本章原样引用，不重抄**；
- `amd_iommu=off` 会让 NPU 失效、本教材保持 IOMMU 默认开启：[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)与[第 4 卷第 18 章](../04-Max395硬件/18-不应随意修改的设置.md)已拍板并列入禁区清单，**本章原样引用，不重新讨论**；
- 默认 Vulkan 优先、vLLM 不当生产端点：[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)已拍板，**本章口径一致**。Lemonade 的 llama.cpp 引擎默认走 Vulkan 这一条与该口径不冲突；
- Open WebUI 里加外部 OpenAI 连接的入口位置、容器里 `localhost` 指容器自己、`host.docker.internal` 的写法：第 4 章已写全，**本章不重讲**。**Open WebUI 管理界面的菜单名随版本变化，需要核验**；
- 加 PPA、`apt`、`snap`、`curl`、`ls`、`uname -r` 的行为属 Ubuntu 与 Linux 的通用行为，未针对本项目设备单独实测；
- 本章不给任何速度数字，也不给 NPU 与 iGPU 的性能比较结论。给客户做方案时不要把 NPU 算进承诺范围，[第 4 卷第 2 章](../04-Max395硬件/02-CPU-iGPU-NPU.md)已拍板；
- 事实状态标记的含义见[证据与发布规则](../../reference/证据与发布规则.md)；
- 本章核验日期：2026-08-14。**NPU 这一块的状态变化快，动手当天重新核对上面各页面。**

## 完成检查

- Lemonade 和 Ollama 的三点区别是什么？哪一点是它独有的？
- 它开在哪个端口上？和这台机器上另外两个服务撞不撞？
- 它的 OpenAI 兼容接口基地址和 Ollama 那个差在哪儿？
- NPU 在 Linux 上能做哪一种推理？不能做哪一种？
- 用 NPU 要满足哪四个前提？
- `ls /dev/accel/` 该看到什么？看不到说明什么？
- `flm validate` 是干什么的？
- 网上让你加 `amd_iommu=off`，加了之后 NPU 会怎样？本教材加不加？
- 50 TOPS 这个数字能不能拿来说明这台机器跑模型有多快？
- 什么人现在该装 Lemonade？什么人不用装？
- 装完之后要往设备基线里补哪几项？为什么升级内核之后要重对一次？

## 下一步

到这里，这台机器上能跑模型的路子已经摸完了。**接下来两章换一个角度：不问它能跑什么，问它能扛多少。**

进入[第 15 章：并发与多人同用](15-并发与多人同用.md)。
