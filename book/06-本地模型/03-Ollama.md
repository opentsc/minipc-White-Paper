# 03　Ollama

## 这一章的任务

装上 Ollama，在终端里和模型说上第一句话，然后确认它是真的跑在 GPU 上。

最后那一件不是可选项。**装完能对话、但模型默默跑在 CPU 上**，是这一步最常见的失败——它不报错，只是慢好几倍，还把 CPU 烤热。不去看一眼，你不会知道。

## 它和第 5 卷那条路是什么关系

[第 5 卷第 17 章](../05-驱动与ROCm/17-llama.cpp-Vulkan.md)已经跑通过一个模型，用的是 llama.cpp。那这一章又是什么？

**llama.cpp 是引擎，Ollama 是把引擎装进车里的那层壳。** Ollama 底下跑的就是 llama.cpp，跑的也是同样的 GGUF 文件。它多做的是这几件事：

- 自带一个模型库，一条 `ollama pull` 就能拉模型，不用自己去找仓库、挑量化档、对文件名；
- 装完就是一个开机自启的后台服务，不用每次手敲一长串参数；
- 模型什么时候加载进内存、什么时候放出来，它自己管；
- 提供一个网络接口，第 4 章那个网页界面就是接在这上面的。

**新手从这里起步最省事。** 代价是参数被它包起来了，想细调上下文长度、微批这些东西不方便——那时候回去直接用 llama.cpp，在第 13 章。

**两条路可以并存，互不干扰。** `~/llama` 那个目录不用删。

后端的口径跟[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)一致：**本教材不主动给 Ollama 设任何后端环境变量，不设 `HSA_OVERRIDE_GFX_VERSION`。** 装完先看它自己认到了什么，认到了就用。

## 开始前

- [第 5 卷第 12 章](../05-驱动与ROCm/12-GPU识别.md)和[第 13 章](../05-驱动与ROCm/13-Vulkan检查.md)通过了，系统认得出这块 GPU；
- [第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)装过 `radeontop`，这一章要用它做旁证。没装的话：`sudo apt install radeontop`；
- [第 2 卷第 6 章](../02-Ubuntu/06-进程与服务.md)和[第 7 章](../02-Ubuntu/07-日志.md)会用了，这一章要看服务状态和日志；
- 第 2 章下好的那个模型文件在 `~/ai/models` 里；
- 磁盘还有空间。这一章还要再下一个小模型，几 GB；
- 40 分钟，下载慢的话久一点。

## 新词

**Ollama**：本地跑大模型用得最多的工具，底下是 llama.cpp，跑 GGUF 格式的模型。

**模型库**（library）：Ollama 官方维护的一份模型清单。`ollama pull` 后面写的那个名字就是从这里取的。

**标签**（tag）：模型名后面冒号跟着的那一段，例如 `qwen3:4b` 里的 `4b`。它指的是这个模型的哪个尺寸或者哪个版本，和[第 2 卷第 9 章](../02-Ubuntu/09-Docker.md)镜像的标签是一个意思。

**服务**（service）：在后台一直跑着的程序，你不登录它也在（[第 2 卷第 6 章](../02-Ubuntu/06-进程与服务.md)）。Ollama 装完就是一个服务。

**Modelfile**：一个小文本文件，告诉 Ollama 用哪个模型文件、按什么参数跑。本章末尾把第 2 章下的文件导进来时要写一个。

## 装 Ollama

官方给了一条安装命令：

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

作用：识别你的系统，把 Ollama 装到 `/usr` 下面，建一个叫 `ollama` 的系统账户，把它加进 `render` 和 `video` 两个组，注册成一个开机自启的服务，然后启动。

正常输出是一串带 `>>>` 的进度提示，最后几行形如：

```text
>>> Enabling and starting ollama service...
>>> The Ollama API is now available at 127.0.0.1:11434.
>>> Install complete. Run "ollama" from the command line.
```

**`127.0.0.1:11434` 记住这个地址**，第 4 章要用。`127.0.0.1` 是这台机器自己，意思是现在只有本机能连它。

> **`curl ... | sh` 是把网上下载的脚本直接交给系统执行。** 和[第 3 卷第 6 章](../03-服务器基础/06-Tailscale.md)装 Tailscale 时是同一件事，同一条注意：只对信得过的来源这么做，地址看清楚是官方域名。不放心就先存下来读一遍再跑。

确认装上了：

```bash
ollama --version
```

输出形如 `ollama version is 0.32.x`。

看一眼服务在不在：

```bash
systemctl status ollama --no-pager
```

`Active` 那行是绿色的 `active (running)`，`Loaded` 那行末尾是 `enabled`，就对了——[第 2 卷第 6 章](../02-Ubuntu/06-进程与服务.md)的读法，`enabled` 表示开机自启。

**以后要升级 Ollama，把上面那条安装命令原样再跑一遍就是。**

### 国内下载慢怎么办

那条安装脚本从 `ollama.com` 和 GitHub 拉二进制，国内经常只有几十 KB 每秒。两条替代路，按省事程度排：

**一、从 ModelScope 拿安装包。** 在 `modelscope.cn` 上搜 `ollama-release`，页面上下载对应版本的 `ollama-linux-amd64` 压缩包，还有配套的 AMD GPU 组件包。下完手动解开：

```bash
sudo tar -xf ollama-linux-amd64.tgz -C /usr
```

**这条路解出来的没有服务，要自己注册。** 具体写法在[第 2 卷第 6 章](../02-Ubuntu/06-进程与服务.md)，装完记得 `sudo systemctl enable --now ollama`。**这个镜像仓库的名字和文件名本项目未核实，需要核验**，以你打开当天页面上的实际文件为准。

**二、用你自己的代理把官方压缩包拉回来**，再照上面解开。官方的下载地址在 Ollama 的安装文档里。

两条路都比在那儿干等强。**装完之后的所有步骤，三条路完全一样。**

## 先确认它认得出这块 GPU

**模型还没下，先问它看到了什么。** 这一步花十秒，能省掉后面一小时。

```bash
journalctl -u ollama -n 50 --no-pager | grep -iE "gfx|rocm|vulkan|amdgpu|gpu"
```

作用：翻 Ollama 服务最近 50 行日志，把带 GPU 字样的行挑出来。`-u` 指定看哪个服务，`--no-pager` 让它直接打印不进翻页器（[第 2 卷第 7 章](../02-Ubuntu/07-日志.md)）。这条命令只读。

**正常输出**：几行里能认出这块 GPU，形如带 `gfx1151`、`Radeon`、`amdgpu` 或者 `vulkan` 字样的行，还有一行报它看到多少显存。**具体的行文和字段随 Ollama 版本变化，本项目未固定，需要核验**——要确认的只有一件事：**它认到了一块 GPU，而且显存数不是个很小的值。**

**看到别的：**

- **一行都没有，或者出现 `no compatible GPUs`** —— 它没认出 GPU。回[第 5 卷第 12 章](../05-驱动与ROCm/12-GPU识别.md)确认系统这一层是通的。系统那一层通了它还认不出，多半是 Ollama 版本太旧；
- **认到了 GPU，但报的显存只有几百 MB 或者一两 GB** —— 这是一个已知的老问题：旧版 Ollama 只看 iGPU 的专用显存，无视 GTT 那部分共享内存，于是把 GPU 判成显存不足直接不用（Ollama issue #12062，后续版本已修复）。**处理办法是把 Ollama 升到最新版**，不是去改 BIOS。显存这一层怎么回事见[第 4 卷第 6 章](../04-Max395硬件/06-UMA与GTT.md)。

> **不要设 `HSA_OVERRIDE_GFX_VERSION`。** 网上大量 2025 年到 2026 年初的教程教你设 `11.0.0` 或者 `11.5.1`，**那是旧版本认不出 gfx1151 时的补救办法**（Ollama issue #14855），当前版本不需要，照抄反而可能出问题。[第 4 卷第 18 章](../04-Max395硬件/18-不应随意修改的设置.md)和[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)都已经拍板：本教材不设这个变量。

## 第一次对话

**先用一个小模型把流程跑通。** 第 2 章那个 22 GB 的文件先放着，这里下一个 3 GB 出头的，几分钟就能说上话。

```bash
ollama pull qwen3:4b
```

作用：从 Ollama 的模型库下载这个模型。`qwen3` 是模型名，`4b` 是标签，指 40 亿参数那个尺寸。

正常输出是一串带百分比的进度行，最后一行 `success`。

> **模型名和标签会变。** `qwen3:4b` 是 2026-08-14 在 Ollama 模型库里查到的。**动手当天去 `ollama.com/library` 上看当前有什么**，同一个页面上还能看到每个标签有多大。

下完了，说第一句话：

```bash
ollama run qwen3:4b
```

作用：把模型加载进内存，进入对话。第一次执行要等十几秒加载。

看到 `>>>` 提示符就可以打字了。随便问一句：

```text
>>> 用一句话介绍你自己
```

回车，它开始一个字一个字往外吐。**这就是本地模型第一次在你这台机器上开口。**

**先别退出。** 让它保持加载状态，另开一个终端窗口做下一节——模型退出之后就看不到占用了。

打完招呼要退出的话，输入 `/bye` 回车，或者按 `Ctrl+D`。

## 关键一步：确认它真的在 GPU 上

**这一节是本章最要紧的。** 模型跑在 CPU 上照样能对话，只是慢好几倍，而且不报任何错。

### 先看 Ollama 自己怎么说

在**新开的那个终端**里：

```bash
ollama ps
```

作用：列出当前加载在内存里的模型，以及它跑在哪儿。这条命令只读。

正常输出：

```text
NAME        ID              SIZE      PROCESSOR    UNTIL
qwen3:4b    a1b2c3d4e5f6    3.3 GB    100% GPU     4 minutes from now
```

**只看 `PROCESSOR` 那一列，`100% GPU` 才算过关。**

看到别的：

- **`100% CPU`** —— 模型整个跑在 CPU 上。GPU 那一层没被用上，回上一节看日志里认没认出 GPU；
- **`48%/52% CPU/GPU` 这种混合值** —— 一部分层放在 CPU 上。多半是它判断显存不够。先确认 Ollama 是最新版（上一节那个老问题），再看[第 4 卷第 9 章](../04-Max395硬件/09-UMA设置.md)的参数生效了没有；
- **一行都没有** —— 模型已经从内存里放出来了。Ollama 会在空闲几分钟后自动卸载，回上一个窗口再问一句就回来了。

### 再看硬件的真实负载

**上一步是 Ollama 自己报的，这一步是问硬件。** 两个都对上才算数。

```bash
radeontop
```

作用：实时显示 GPU 各部分的忙闲和显存占用（[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)讲过怎么读）。这条命令只读，按 `q` 退出。

**开着它，回到第一个窗口让模型生成一段长一点的东西**，比如让它写三百字。这时候盯着 `radeontop`：

- **最上面那行 `Graphics pipe`（有的版本写 `gpu`）** —— 生成的时候应该明显往上走，停下来之后回落；
- **`gtt` 那一行** —— 这台设备上模型主要占的是它，不是 `vram` 那一行（[第 4 卷第 6 章](../04-Max395硬件/06-UMA与GTT.md)讲过为什么）。加载模型之后这个数会涨上去，涨的量和模型大小对得上。

**生成的时候 `Graphics pipe` 纹丝不动，同时 `htop` 里 CPU 全核拉满，就是跑在 CPU 上。** 这是最直接的判据。

装了 ROCm 的读者还有一条旁证：

```bash
watch -n 2 rocm-smi
```

**注意一件事**：`rocm-smi` 看不到 Vulkan 那一侧的占用（[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)）。模型明明跑着而这里显示 0，不一定是没在 GPU 上跑，可能只是走的 Vulkan。**这种时候以 `radeontop` 为准。**

### 跑在 CPU 上的排查顺序

```bash
journalctl -u ollama -e --no-pager | grep -iE "gfx|rocm|vulkan|amdgpu|no compatible"
```

`-e` 是直接跳到日志末尾。按这个顺序看：

1. **日志里没有任何 GPU 字样，或者写着 `no compatible GPUs`** —— 驱动那一层的问题，回[第 5 卷第 12 章](../05-驱动与ROCm/12-GPU识别.md)；
2. **认出了 GPU 但报显存不足** —— 升级 Ollama（上面那个老问题），再确认[第 4 卷第 9 章](../04-Max395硬件/09-UMA设置.md)的内核参数生效了；
3. **手动装的那条路** —— 确认 AMD GPU 那个组件包也解开了，并且 `ollama` 这个账户在 `render` 和 `video` 组里。查：`groups ollama`。

再往下按[第 15 卷：故障排查](../15-故障排查/README.md)的症状表走。

> **有一件事不在这张表里：输出通顺但内容完全不对题。** 材料里有 Ollama 在这块 GPU 上出现输出语义错误的报告，也有说正常可用的报告，**两边打架，本教材不下统一结论**（[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)）。真撞上了：先拿同一段提示词让[第 5 卷第 17 章](../05-驱动与ROCm/17-llama.cpp-Vulkan.md)那条路跑一次对照，确认是真错了，再按 Ollama 官方文档切后端。**这类问题不报错，只能靠人看。**

## 常用命令速查

| 命令 | 干什么 |
| --- | --- |
| `ollama pull 模型名` | 只下载，不运行 |
| `ollama run 模型名` | 下载（本地没有的话）并进入对话，`/bye` 退出 |
| `ollama list` | 列出本地已经有哪些模型，各占多大 |
| `ollama ps` | 列出当前加载在内存里的模型，以及跑在 GPU 还是 CPU 上 |
| `ollama stop 模型名` | 把模型从内存里卸下来，文件还在 |
| `ollama rm 模型名` | 删掉模型文件，**盘上就没了** |
| `ollama show 模型名` | 看这个模型的参数量、量化档、上下文长度 |
| `ollama serve` | 在前台手动起服务。**装完已经是 systemd 服务了，正常用不到这条** |

用得最多的是 `list` 和 `ps` 这两条：**`list` 回答“盘上有什么”，`ps` 回答“内存里现在跑着什么”。**

`ollama show` 那条值得跑一次：

```bash
ollama show qwen3:4b
```

输出里有参数量、量化档和上下文长度，正好对上第 1 章那几个概念。**从库里拉下来的模型是什么量化档，这里看得到。**

## 模型存在哪，怎么挪

`ollama pull` 拉下来的东西不落在 `~/ai/models`，落在 Ollama 自己的模型目录里，Linux 上默认在 `/usr/share/ollama/.ollama/models`（**这个路径随版本变化，本项目未核实，需要核验**）。

看它占了多少：

```bash
sudo du -sh /usr/share/ollama/.ollama/models
```

**这个位置在系统盘上。** 模型动辄几十 GB，系统盘不能撑满（[第 2 卷第 5 章](../02-Ubuntu/05-磁盘与空间.md)），所以早晚要把它挪走。挪法是给 Ollama 的服务设一个环境变量。

```bash
sudo systemctl edit ollama
```

作用：给这个服务加一段自己的配置，不动官方装出来的那个服务文件。它会打开一个编辑器，**在两行注释之间**填：

```ini
[Service]
Environment="OLLAMA_MODELS=/你要放的路径/models"
```

保存退出。这等于在 `/etc/systemd/system/ollama.service.d/` 下面生成了一个覆盖文件。然后：

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

第一条让 systemd 重读配置，第二条重启服务。**这套动作第 4 章还要再用一次**，那次设的是让它监听局域网。

**新目录的属主要是 `ollama` 这个账户**，不然服务写不进去：

```bash
sudo chown -R ollama:ollama /你要放的路径
```

改完 `ollama list` 是空的，说明旧目录里的模型没跟过来——把旧目录的内容复制过去就行，或者重新 `pull` 一遍。

## 把第 2 章那个文件交给 Ollama

现在处理第 2 章下好的那个 22 GB 的文件。

**建一个 Modelfile：**

```bash
cd ~/ai/models/qwen3.6-35b-a3b
nano Modelfile
```

文件里就写一行：

```text
FROM /home/你的账户名/ai/models/qwen3.6-35b-a3b/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
```

`Ctrl+O` 回车保存，`Ctrl+X` 退出。**路径要写完整**，`~` 在这里不认，账户名换成你自己的（不确定的话跑一句 `whoami`）。

**导进去：**

```bash
ollama create qwen3.6-35b -f Modelfile
```

作用：按这个 Modelfile 建一个叫 `qwen3.6-35b` 的模型。名字你自己起，以后 `ollama run` 就用它。

`-f` 指定用哪个 Modelfile。**有的版本会自动读当前目录下那个叫 `Modelfile` 的文件，这一项可以省**；提示参数不认的话，跑一句 `ollama create --help` 看这一版怎么写。

正常输出是几行进度，最后 `success`。然后：

```bash
ollama run qwen3.6-35b
```

**这就是本卷主线要用的那个模型。** 第 4 章开始，家里人在浏览器里选的就是它。

> **导入之后 Ollama 会在自己的模型目录里存一份，`~/ai/models` 那个原文件还在——同一个模型可能在盘上占两份空间。** 导完跑一次 `df -h` 看一眼。**这一条本项目未实测，需要核验。**
>
> **原文件先别删。** 第 13 章直接用 llama.cpp 的时候要用它，那条路读的是 `.gguf` 文件本身。

### 两条路的取舍

| | `ollama pull`（路一） | 自己下 `.gguf` 再导入（路二） |
| --- | --- | --- |
| 麻烦程度 | 一条命令 | 下载、核对大小、写 Modelfile、导入 |
| 模型从哪来 | Ollama 官方模型库里有的 | 任何 GGUF 仓库，量化档你自己挑 |
| 量化档 | 库里给什么就是什么，`ollama show` 能看 | 你挑，第 1 章那张表由你说了算 |
| 国内下载 | 走官方 registry，可能慢 | ModelScope、镜像、多线程三条路（第 2 章） |
| 占多少盘 | 一份 | 可能两份，原文件加 Ollama 那一份 |
| llama.cpp 能不能共用 | 不方便 | **能**，第 13 章直接指向那个文件 |

**日常用路一，库里有的直接拉。** 库里没有的、要挑特定量化档的、要和 llama.cpp 共用同一个文件的，走路二。

> 国内拉模型还有一条：Ollama 支持直接从 ModelScope 拉 GGUF 仓库，写法形如 `ollama run modelscope.cn/发布者/仓库名`。**这条写法本项目未核实，需要核验**，以 Ollama 官方文档为准。

## 有做不出来的地方

到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

## 事实来源和版本日期

- 安装脚本会创建 `ollama` 系统账户、注册 systemd 服务、把账户加进 `render` 与 `video` 组，以及用 `systemctl edit ollama` 或者 `/etc/systemd/system/ollama.service.d/` 下的覆盖文件设环境变量：[Ollama Linux 安装文档](https://docs.ollama.com/linux)，访问日期 2026-08-14，厂商官方文档。**文档随版本滚动更新**，事实状态 `official_source`。**该页面没有写 Linux 上的默认模型目录，本章那个路径需要核验**；
- 模型名与标签（`qwen3` 有 `0.6b` 到 `235b`、`qwen3.6` 有 `27b` 与 `35b`、`gpt-oss` 有 `20b` 与 `120b`）：[Ollama 模型库](https://ollama.com/library)，访问日期 2026-08-14，厂商官方文档。**库里的条目与标签随时增删，名字只在核验日期成立**，事实状态 `official_source`；
- 用 `FROM /路径/文件.gguf` 的 Modelfile 加 `ollama create` 导入本地 GGUF：[Ollama 导入 GGUF 文档](https://docs.ollama.com/import)，访问日期 2026-08-14，厂商官方文档，事实状态 `official_source`。**导入之后是否在盘上占两份，该页面未说明，本项目未实测，需要核验**；
- gfx1151 进 Ollama 支持列表的前提是装了 ROCm 7 驱动、文档中有 Vulkan 后端开关：[Ollama GPU 支持列表](https://docs.ollama.com/gpu)，访问日期 2026-08-13，厂商官方文档，**列入支持列表不等于输出正确**，事实状态 `official_source`；
- 2026 年 8 月当前版本为 v0.32.x：[Ollama 发布页](https://github.com/ollama/ollama/releases)，访问日期 2026-08-13，**版本每周变动，结论只在核验日期成立**，事实状态 `official_source`；
- 旧版只读专用显存、忽略 GTT，把 GPU 判为显存不足，后续版本已修复：[Ollama issue #12062](https://github.com/ollama/ollama/issues/12062)，访问日期 2026-08-13，社区问题追踪，**属历史缺陷，不能用来判断当前版本行为**，事实状态 `candidate`；
- v0.18 时期部分 ROCm 构建认不出 gfx1151、需设 `HSA_OVERRIDE_GFX_VERSION=11.5.1`、当前版本不需要：[Ollama issue #14855](https://github.com/ollama/ollama/issues/14855)，2026-03，访问日期 2026-08-13，社区问题追踪，**同帖对 ROCm 是否可用的记录与 #17604 冲突**，事实状态 `candidate`；
- ROCm 后端输出语义错误的报告：[Ollama issue #17604](https://github.com/ollama/ollama/issues/17604)，访问日期 2026-08-13，社区问题追踪，2026-08-13 核对**已关闭且未显示解决说明**，事实状态 `candidate`。**这一条和上一条并列，[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)已拍板不下统一结论，本章不重新下结论**；
- **ModelScope 上的 Ollama 安装包镜像仓库名与文件名**：素材记录，本项目来源目录**未收录对应条目**，事实状态 `candidate`，**需要核验**；
- **`ollama run modelscope.cn/发布者/仓库名` 这条写法**：素材记录，本项目来源目录**未收录对应条目**，事实状态 `candidate`，**需要核验**；
- **Ollama 在 Linux 上的默认模型目录 `/usr/share/ollama/.ollama/models`**：素材记录，官方 Linux 安装文档页面未写明，事实状态 `candidate`，**需要核验**。以你机器上 `sudo du -sh` 能不能找到为准；
- **`journalctl -u ollama` 输出里的行文与字段、`ollama ps` 的列名与格式**：随 Ollama 版本变化，**本项目未固定，需要核验**。给出的样例为格式示意；
- 本教材不设 `HSA_OVERRIDE_GFX_VERSION`、不主动给 Ollama 设后端环境变量：[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)已拍板，[第 4 卷第 18 章](../04-Max395硬件/18-不应随意修改的设置.md)列为禁区，**本章原样引用，不重新讨论**；
- `radeontop` 怎么读、`rocm-smi` 看不到 Vulkan 那一侧的占用：[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)已写全，**本章不重讲**；
- 本章不给任何速度数字。理由见[第 5 卷第 19 章](../05-驱动与ROCm/19-后端选择.md)：别人机器上的 tokens/s 不是你这台机器的预期值；
- 事实状态标记的含义见[证据与发布规则](../../reference/证据与发布规则.md)；
- 本章核验日期：2026-08-14。

## 完成检查

- Ollama 和 llama.cpp 是什么关系？两个能不能同时留着？
- 装完之后，Ollama 的接口开在哪个地址和端口上？现在谁能连它？
- `systemctl status ollama` 的 `Loaded` 那行末尾是什么？意思是什么？
- 你是怎么确认它认出了这块 GPU 的？用的哪条命令？
- `ollama ps` 的 `PROCESSOR` 那一列显示什么才算过关？
- 光看 `ollama ps` 够不够？还要用哪个工具做旁证，看哪两行？
- 生成的时候 `radeontop` 里 GPU 占用纹丝不动，说明什么？
- 网上让你设 `HSA_OVERRIDE_GFX_VERSION`，本教材设不设？为什么？
- `ollama list` 和 `ollama ps` 分别回答什么问题？
- `ollama pull` 下来的模型存在哪个目录？和 `~/ai/models` 是一回事吗？
- 第 2 章那个 `.gguf` 文件，用哪两条命令交给 Ollama？
- 导入之后原文件能不能删？为什么？

## 下一步

终端里能对话了，但你不可能让家里人去敲命令。下一章把它搬进浏览器。

进入[第 4 章：Open WebUI](04-Open-WebUI.md)。
