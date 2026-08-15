# 2026-08-14 来源核查

以下记录取自各份研究材料在 2026-08-13 的复查结果，本次整理没有重新联网访问。

## 一、无法访问或已失效的链接

| 链接 | 涉及的说法 | 复查记录 | 处理 |
| --- | --- | --- | --- |
| https://getprivateofficeai.com/private-ai-box/ 、https://getprivateofficeai.com/pricing/ 、https://getprivateofficeai.com/medical-firms/ | PrivateOfficeAI 一体机 US$4,900（15 人）与 US$7,500（40 人 Pro）、Care Plan 每月 US$99、Remote Access 每月 US$29，以及面向牙科与医疗诊所的病历图表提取功能 | 2026-08-13 连接被拒（ECONNREFUSED），Wayback Machine 没有任何存档；品牌迁到 privateofficeai.com，新域名当次 DNS 解析失败，未能打开页面核对全文 | 不进来源目录。引用其报价须改用新域名并重新核验，且只能写成报价页，不能写成成交 |
| https://x.com/vargaonchain/status/2087508921959240115 | 布拉格开发者 Tomas 用一台机器为 3 家律所托管私有 AI，每家每月 US$400 | 2026-08-13 该帖无法访问，账号名在搜索引擎无痕迹；“Tomas + 布拉格 + 律所 + 每月 400 美元”组合检索无独立来源 | 不可引用。原始说法本身是第三方转述，主人公只有名字与城市 |
| https://pcforum.amd.com/s/question/0D5Pd00001ieWigKAE/... | Ryzen AI Max+ 395 在持续高负载下出现硬件级断电与 data fabric sync flood 错误 | 材料给出的链接末尾被截断，无法直接打开 | 补齐可打开的链接前，这条故障不作证据 |
| https://hf.co/cli/install.sh | Hugging Face 官方 CLI 一键安装脚本 | 材料记录国内网络通常打不开 hf.co | 属地区可达性问题，不是页面失效；安装改走 pip 或镜像站 |

## 二、相互冲突的说法

### 1. 是否存在已验证的 Max395 付费商业案例

- 《实际商业交付与付费案例研究》：精确 Max395／Strix Halo 的 A1 加 A2 案例有 4 个，分别是 Framework、Beelink、GMKtec、Altronis。
- 《Grok Community Report》：本轮没有找到任何 A1／A2 案例，明确写没有找到带公开定价与付款证据的多客户付费服务。
- 《商业化潜力与交付模式深度调研报告》：不主张 A 级，14 个案例全部为 B1／B2／B3，其中明确写 Max395 的只有 Beelink 一个。

冲突点有两层。口径层：硬件零售付款是否算 A1，厂商平台的买家评价与服务商自述是否算 A2，三份报告的答案不同。事实层：Grok 那一轮没有检索到 Altronis，而 Altronis 页面在 2026-08-13 复查时在线。不下结论。

### 2. BIOS UMA 该设多少

- 全栈部署报告（材料中的转述，该报告不在本仓库 `source/` 内）：UMA Frame Buffer 硬设 96 GB 跑 70B，多模态设 80 GB。
- AMD ROCm 官方 Strix Halo 优化文档、Jeff Geerling、strixhalo.wiki、hogeheer499 指南、Grok 报告：设最低档 512 MB 到 2 GB，扩容交给 `ttm.pages_limit` 动态映射；静态大 UMA 会造成宿主内存饥饿。

冲突点是静态划分与动态 GTT 两条路线，以及 96 GB 是否为 Linux 上限。

### 3. amdgpu.gttsize 加不加

- 多份指南（hogeheer499 旧版、antirez/ds4、note.com、Gygeek、kyuz0 的 README）在旧内核上用 `amdgpu.gttsize=126976`／`131072`／`124928` 配 `ttm.pages_limit`，报告实测有效。
- Zenn grainpatha 在 GMKtec EVO-X2、内核 6.17 OEM 上实测该参数导致 ROCm 误检显存池、hipMalloc 报 OOM；Jeff Geerling、webonomic 与 AMD 官方文档称该参数已废弃，应只用 `ttm.pages_limit` 或 `amd-ttm`。

冲突点按内核版本切分（6.16 以前与 6.17 以后），但各份材料对分界线的表述不完全一致。

### 4. IOMMU 开还是关

- 关闭（`amd_iommu=off`）：kyuz0 跑分口径快 5% 到 12%，strixhalo.wiki 记约 6%。
- 开启或 `iommu=pt`：NPU、休眠、虚拟化与 eGPU 需要；《深度核验与生态系统研究报告》判断 pt 是长期跑推理的唯一合理选择；kyuz0 实测 pt 慢于 off。

冲突点是收益数值只有两家口径且无第三方复测，以及 pt 与 off 的相对性能结论不一致。

### 5. gfx1151 稳定性评价

- 《深度核验与生态系统研究报告》：ROCm 路径是带病实验性支持，Vulkan 路径几乎无可挑剔。
- 《Grok Community Report》冲突记录：同一模型是 Vulkan 快还是 ROCm 快，取决于量化档、上下文长度、fork 与环境变量，不能一概而论；其收录的调优帖称 hipBLASLt 调优后 HIP 反超 Vulkan。
- llama.cpp issue #24438：针对 gfx1151，Vulkan 后端效率高于 ROCm／HIP 实验构建。

冲突点是两条后端的性能排序结论互相矛盾，且与版本、量化和 fork 强相关。

### 6. Ollama 走 ROCm 时输出是否正确

- Ollama issue #14855：30B 模型约 40 tokens/s，可用。
- Ollama issue #17604 与《深度核验与生态系统研究报告》：ROCm 后端输出语义乱码，切到 Vulkan 后正常。
- 2026-08-13 核对 #17604：已关闭且未显示解决说明，原帖标题写的是 Vulkan 与 ROCm 两个后端都出过输出错误。

冲突点是 ROCm 后端能否使用，以及切 Vulkan 是否就能解决。

### 7. A2A issue #1672 的性质

- 《深度核验与生态系统研究报告》正文把该 issue 写成 A2A 已实施 XChaCha20-Poly1305 双棘轮端到端加密、密钥交换用 X3DH。
- 同一报告末尾的来源列表把该 issue 标题记为 Proposal: Agent Identity Verification for Agent Cards。

冲突点是提案讨论与已生效规范被写成了同一件事。

### 8. CPU 是否该锁 performance

- 社区优化脚本一派：锁 performance、屏蔽 C-state 能提速。
- nix-amd-ai 开发者：APU 共享功耗预算，CPU 满频挤占 iGPU 功耗，对带宽敏感的 decode 阶段是负优化。

两派都没有实机复测数据，且材料只给了转述，没有给原始链接。

## 三、只有摘要或转述、缺原始页面的说法

以下说法在材料里没有可核验的原始页面，正文补上链接并重新核验之前，不可用作证据。

- PrivateOfficeAI 新域名的报价（Box Pro 一次性 US$7,500、Care Plan 每月 US$99、Remote Access 每月 US$29、Web Access 每月 US$19）：当次只从搜索引擎索引读到，没有打开原始页面核对。
- @adiix_official 自述用 EVO-X2 做本地 AI 咨询、8 个月约 US$47,000、5 个长期客户月均 US$4,100：没有链接，收入数字没有独立佐证，材料记录社区有质疑。
- 材料只给了编号、注明未上网核对的 issue：ollama/ollama#16567、ollama/ollama PR #15509、lmstudio-ai/lms#589、amd/xdna-driver#1469、vllm-project/vllm#28310、ROCm/ROCm#5747、ROCm/ROCm#6004、Framework Community Issue #206 与帖 82310。
- 《Grok Community Report》的 45 条来源清单只保留了标题、机器与等级摘要，原始 JSONL 未随材料提供，其中 Zenn grainpatha、AGLedger、note.com、omarchy、Hardware Corner、掘金、什么值得买、Medium 调优帖、CachyOS 黑屏等条目都没有可核验链接。
- 补充材料中的应用层选型判断：PaddleOCR-VL 的 ROCm 适配只面向 Instinct MI 系列、olmOCR 在消费级 ROCm 上有失败记录、MinerU 只在 gfx1100 有社区验证、Dify Compose 为 16 个组件、n8n 2.0 默认禁用 Execute Command 与 Local File Trigger 及其在 Docker 挂载卷上的已知问题。材料写明已查证，但没有给链接。
- 补充材料中的模型清单：Hugging Face CLI 从 huggingface-cli 改名为 hf、huggingface_hub 1.0 移除旧命令，以及除 `unsloth/Qwen3.6-35B-A3B-GGUF` 外各 GGUF 仓库的存在性与字节数，都只给了仓库名。
- 浙江大学 Ollama 镜像 https://ollama.zju.edu.cn ：材料自己标注未验证。
- 《Grok Community Report》的搜索日志（英文 22 条、中文 16 条查询词）是检索过程记录，本身不构成证据。
- Max395 的内存带宽数值。材料给出三个口径：256 GB/s 按 256 位总线配 LPDDR5X-8000 推算的理论峰值、约 212 GB/s 称为底层物理带宽但未说明测法、218 GB/s 出自 The Phawx 评测且经 Reddit 转述。三者都没有可打开的原始测试页面，来源目录里也没有对应条目。第 4 卷正文并列写出三个数值、注明各自性质并标注需要核验，在取得原始测试页面之前不作为速度依据使用。
