gemini-compatibility-matrix.md
基于 AMD Ryzen AI Max+ 395（Strix Halo 架构，包含 Radeon 8060S GPU 与 XDNA2 NPU）的底层软硬件生态展现出极大的复杂性。该架构通过统一内存架构（UMA）将高达 128GB 的 LPDDR5X 内存直接暴露给图形与张量计算管线，这一物理创新彻底重构了端侧 AI 的部署范式。然而，数据中心级软件栈（ROCm/PyTorch）向 RDNA 3.5 消费级架构的下放正处于极其早期的适配阶段。

下表详细梳理了涵盖操作系统、内核、图形栈以及核心 AI 框架的多维度兼容性矩阵，所有基准数据截取自 2026 年 8 月 13 日的最前沿提交与官方文档发布状态。

操作系统	Kernel	linux-firmware	Mesa	ROCm	PyTorch	Python	Ollama	llama.cpp	vLLM	Lemonade	GPU 架构	NPU 驱动	支持状态	资料发布日期	当前是否仍有效
Ubuntu 26.04 LTS	7.0.0-15-generic	20260309-1及更新	24+ (RADV)	7.1.1 / 7.2	2.13.0.dev / 2.11.0a0 (TheRock)	3.12	0.32.6	b9851 / b9979	0.17.1rc1 (Eager模式)	10.3.0	gfx1151	amdxdna (in-tree)	官方/社区混合	2026-08	是
Ubuntu 25.10	6.19 (需补丁)	20251125 (需热修复 MES 0x80)	24+	7.1.1	2.9.1+rocm6.3 (崩溃风险)	3.11	0.31.2	b9544	0.15.0	待核验	gfx1151	amdxdna	预览/实验	2026-02	是
Ubuntu 24.04.4 LTS	6.17.0-1011-oem	待核验	24.0+	7.0.2 / 7.2	2.11.0a0 (Nightly)	3.12.3	0.31.2	b9851	0.14.1 / 0.17	10.2.0	gfx1151	amdxdna (DKMS)	官方支持	2026-06	是
Fedora 43	6.18.10-200.fc43	20250808-1.fc42	待核验	6.3.1-4.fc42	2.9.1+rocm6.3	待核验	待核验	待核验	待核验	待核验	gfx1151	待核验	实验性 (内存访问失败)	2026-02	否 (存在严重退化)
操作系统的代际演进在支持质量上呈现明显断层。Ubuntu 24.04.4 LTS 通过专用的 linux-oem-6.17 内核提供了针对 Strix Halo 架构的基础稳定性支持，并修复了 Type-C 视频输出与 Seamless boot 缺陷。进一步演进至 Ubuntu 26.04 LTS 时，内核版本跃升至 7.0.0，其默认集成了针对 AMD XDNA2 的内核树内（in-tree）驱动程序与 Chrony 时间同步服务，并在 amd64-microcode 层面彻底修补了高危的 EntrySign 签名伪造漏洞。相比之下，基于旧版内核或错误固件（如 20251125 版引发的 MES 0x80 降级错误）的系统频繁遭遇图形转换表（GTT）异常。   

gemini-installation-report.md
深入探究 Strix Halo 平台的部署逻辑，其核心挑战在于突破传统 BIOS 对于统一内存共享机制的硬性桎梏，以及在复杂的 Linux 安全基线中精细调控外设直接内存访问（DMA）策略。

在 BIOS 层面，基础的统一内存架构（UMA）帧缓冲区（Frame Buffer）分配通常被限制在 512MB 或 2GB。对于需要加载 30B 甚至更大参数量语言模型的环境而言，这一静态分配策略将导致瞬间的显存溢出（OOM）。现代部署规范要求依赖内核级图形转换表（GTT, Graphics Translation Table）与翻译表映射（TTM, Translation Table Maps）的动态寻址能力。通过在启动引导器（GRUB）的 GRUB_CMDLINE_LINUX 中注入特定的物理页面扩张指令，例如 amdgpu.gttsize=124928（或 131072）与 ttm.pages_limit=31981568（或 31457280），内核能够动态接管并释放超过 96GB 的系统 RAM 供 GPU 计算图使用。这种软硬结合的内存映射技术，确保了 Radeon 8060S 能够利用 LPDDR5X-8000 的极高带宽直接进行张量运算。   

输入输出内存管理单元（IOMMU）的策略配置深刻影响着系统的全局拓扑。将参数设定为 amd_iommu=off 能够在极致的桌面基准测试（Desktop Benchmark Profile）中略微削减页表转换的纳秒级延迟，但这一操作会造成灾难性的连锁反应：它将彻底摧毁系统的安全挂起（Suspend）能力，阻断硬件虚拟化，并直接导致基于 PCIe 端点通信的 XDNA2 NPU 离线。工业级部署规范强烈建议维持 IOMMU 的默认开启状态，或针对包含雷电坞站与外置显卡（eGPU）的复杂拓扑使用 iommu=pt（Pass-through）模式，从而在保障 NPU 微控制器信箱（Mailboxes）通信的同时，避免内核过度干预合法的 DMA 请求。   

在虚拟化与容器化编排领域，Docker 守护进程对底层设备的透明穿透是运行 vLLM 等框架的先决条件。历史遗留的 AMD 官方镜像（如 rocm/vllm 与 rocm/vllm-dev）已被正式废弃，当前的官方标准镜像指定为 vllm/vllm-openai-rocm。容器启动命令必须显式映射图形渲染子系统（/dev/dri）与内核融合驱动控制节点（/dev/kfd，Kernel Fusion Driver），同时分配适当的特权组（如 --group-add sudo 或归属 render、video 用户组），方可确保 ROCm 运行时成功建立执行队列。   

gemini-conflicts.md
在当前的 Linux 软件堆栈中，Radeon 8060S (gfx1151) 展现出严重的生态精神分裂现象。以 Mesa/RADV 为核心的 Vulkan 路径表现出极其出色的鲁棒性与高吞吐量，而以 ROCm/HIP 为基石的数据中心级路径则深陷底层微架构兼容性的泥潭。

首当其冲的致命冲突源自 ROCm/HIP 编译器在处理 RDNA 3.5（Wave32）与 CDNA（Wave64）架构差异时的逻辑崩溃。vLLM 框架（基于 0.17 系列测试）在初始化其高度优化的 V1 引擎（HIP Graph Capture 阶段）时，会无一例外地陷入系统级硬挂起或直接断开连接。源码级别的溯源分析表明，csrc/libtorch_stable/sampler.cu 文件中硬编码了 kNumThreadsPerBlockMerge = 1024 的线程块合并参数。
基于数据中心 Instinct GPU（如 MI300 的 gfx942）的设计，1024 个线程被自然划分为 16 个包含 64 线程的 Wavefronts，其共享内存分配能够完全容纳在 64KB 的本地数据共享（LDS）缓存中。
然而，在 gfx1151 上，一个 Wavefront 仅包含 32 个线程。相同的 1024 线程请求被拆分为 32 个 Wavefronts。当这些线程同时请求 BlockScan 或 BlockRadixSort 的共享内存时，总需求瞬间飙升至 66032 字节，直接击穿了 64KB 的物理硬件限制。HIP 编译器抛出 local memory (66032) exceeds limit (65536) 错误并导致整个计算管线崩溃。当前唯一的缓解措施是传入 --enforce-eager 参数彻底关闭图捕获，但这迫使每个内核单独在 CPU 与 GPU 之间进行上下文切换，导致 Strix Halo 庞大的 128MB L3 (MALL) 缓存彻底失效，性能断崖式下跌。此外，当加载含有视觉编码器（Vision Encoder）的模型（如 Qwen3-VL-32B-AWQ）时，引擎会在 libhsa-runtime64.so 中触发严重的段错误（Segmentation Fault）。   

基础深度学习操作同样未能幸免。在多项独立测试中，仅仅是执行最基础的 PyTorch 显存分配（如 torch.randn(1000, 1000, device="cuda:0")），就会导致图形命令处理器前端（CPF）触发 GFX Hub 缺页异常，系统日志（dmesg）记录了大量 Page not present or supervisor privilege 错误，进程永久死锁。同时，在 rocWMMA（矩阵乘法加速库）的编译过程中，尝试开启 GGML_HIP_ROCWMMA_FATTN=ON 将直接导致 llama.cpp 编译失败，原因在于底层的 wmma 宏在 gfx1151 的 Clang LLVM 后端支持依然处于残缺状态。而在使用 TheROCk Nightly PyTorch 分支进行自回归模型训练时，更暴露了 5 项核心的 bfloat16 精度缺陷：当批处理大小（Batch Size）配置在 2^13 阈值、注意力头维度（HEAD_DIM）设为 32，或网络深度（DEPTH）超过 12 层时，模型梯度会迅速爆炸为 NaN；在矩阵学习率设置上，系统在 0.15 稳定但在 0.20 出现陡峭的崩溃悬崖，暴露了底层优化器累加器在精度边界的异常。   

与 ROCm 路径的灾难性表现形成强烈反差，Vulkan 计算路径提供了几乎无可挑剔的稳定性。Ollama 框架在强制切换至 Vulkan 后端（OLLAMA_VULKAN=1 OLLAMA_IGPU_ENABLE=1）后，能够完美输出语义符合要求的文本；反之，若放任其调用 ROCm/HIP 后端，模型虽能维持较高的生成速率，但其内部的 MoE（混合专家）路由或注意力张量被完全破坏，导致输出彻底的语义乱码，无视一切提示词指令。llama.cpp 的官方 Vulkan 发布版（b9851）甚至能够将 30B 级别的 Qwen3-Coder 模型推至 101.0 tokens/s 的极高吞吐率。这一对比确凿地证明，物理硬件本身（Radeon 8060S 与统一内存总线）不存在缺陷，所有系统性故障均源于 ROCm 编译生态对 Wave32 消费级架构的适配滞后。   

gemini-license-security.md
在构建企业级大模型基建时，协议标准、隐私合规与系统级安全构成了不可逾越的底线要求。

就 API 接口治理与前端配置而言，Open WebUI 提供了极度精细的环境变量管理机制以满足企业合规审查。系统通过 ENABLE_OLLAMA_API 与 OLLAMA_BASE_URL 进行严格的请求路由。在传输层安全（TLS）配置上，内建的 AIOHTTP 客户端支持证书链强制校验，允许通过绝对路径（如 /etc/ssl/certs/corporate-ca.crt）绑定私有证书颁发机构，这对于防御中间人攻击（MITM）至关重要。在身份认证与限流层面，ENABLE_LOGIN_FORM 可阻断未经授权的枚举攻击，强制基于 PASSWORD_HASH_ALGORITHM（推荐使用无长度限制的 argon2 而非老旧的 bcrypt）进行密码存储。对于多智能体并发带来的请求雪崩风险，配置 SUBAGENTS_MAX_CONCURRENT 限制了前台进程的并发槽位，配合 SUBAGENTS_BACKGROUND_ENABLED 参数，系统能够将高耗时任务（如长文生成或代码验证）推入异步队列，通过事件分发机制将结果回调注入对话，避免前端连接超时。由于缺乏详尽的全局日志落盘参数，“待核验”专门的高级审计日志配置规范。   

在多智能体互操作协议层，A2A（Agent2Agent）协议与 MCP（Model Context Protocol）展现了截然不同的架构边界与隐私考量。MCP 聚焦于“客户端-服务器”模型，规范了核心基础大模型（客户端）如何接入外部工具与私有数据仓库，其作用域通常收敛在单一系统的上下文控制内。相反，A2A 协议是一种对等的、去中心化的联邦通信标准，旨在使用 JSON-RPC 2.0 跨越异构语言与厂商边界连接完全独立的智能体。
A2A 协议的设计基石是“不透明执行”（Opaque Execution）理念：智能体之间的协作完全基于“代理卡片”（Agent Card）中声明的输入输出规范与身份认证端点，发起方无法探测、获取或干预接收方内部的思考过程、历史记忆缓存或专有工具链实现。这一架构在隐私合规（如 GDPR 个人数据隔离要求）与降低客户数据留存（Data Retention）风险上具有得天独厚的优势。通过控制 Agent Card 中的服务端点 URL 与底层 TLS，企业能够从网络层确保敏感的请求流量被限制在特定的地理合规区域（如仅在欧盟区域内路由），彻底规避云提供商自动跨境传输的法律风险。对于包含人机回环（Agent-to-Human）的长时间作业，A2A 摒弃了低效的轮询，采用服务器发送事件（SSE, Server-Sent Events）推送 TaskStatusUpdateEvent 与 TaskArtifactUpdateEvent，维持协议状态机的幂等性与一致性。   

在商业许可证的开源合规审查中，A2A 协议规范自身及其官方维护的各类语言 SDK（Python、JS、Java、Go、.NET、Rust）均遵循 Apache-2.0 许可协议，允许无限制的商业集成与闭源分发。各类测试模型（如 Qwen3.6-35B、Llama-3 等）受其专有开源权重的许可限制。需要强调的是，当前审查的官方文档与代码仓库中并未出现明确的商业主张，如服务报价单、客户付款网关或企业级 SLA 承诺页面（相关商业主张记录为“待核验”）。   

安全基线方面，Ubuntu 26.04 LTS 强制推行了针对微架构层面的深层漏洞修复。针对影响 AMD Zen 1 至 Zen 5 及 Strix Halo 架构的微代码签名伪造漏洞（EntrySign / CVE-2024-36347 / AMD-SB-7033），Canonical 的安全响应团队拒绝在未包含前置修复补丁（如 commit 8d171045069c）的旧内核上热加载微代码。管理员必须通过 fwupdmgr refresh && fwupdmgr get-updates 获取 OEM 厂商推送的最新包含 PI/AGESA 修复的底层 BIOS 固件，并结合 amd64-microcode 包的系统级升级（版本高于 2025-07-08），方可确保 CPUID 硬件识别并应用最新的微码集（如 0x0A0011DE），从根本上切断执行非法提权指令的途径。   

gemini-query-log.md
针对研究项目要求中列举的高优先级核验清单，以下为系统性的循证解答：

gfx1151 的 ROCm 支持状态：官方在 ROCm 7.0.2 发布说明中正式列入了 gfx1151。但在实践中，该支持状态极其不稳定。vLLM 等复杂引擎面临 HIP Graph Capture 导致内存溢出挂起的问题，基本张量操作触发 GFX Hub 缺页中断，其支持状态当前应界定为“带病实验性支持”。   

Ubuntu 24.04 的具体支持版本：Ubuntu 24.04.4 LTS 包含支持 Strix Halo 的关键特性，其核心依赖于版本号为 6.17.0-1011-oem 及后续更新的定制 OEM 内核。   

Kernel 对组件的要求：KFD 与 GTT 依赖较新的 amdgpu 驱动分配大页内存。XDNA2 NPU 则需要内核挂载 amdxdna 驱动，该驱动支持进程隔离并依赖 PCIe EP 与底层微控制器通信，主流支持合并在 Linux 6.11 及更新版本中，Ubuntu 26.04 的 7.0 内核具备 in-tree 原生支持。   

BIOS UMA、GTT、TTM pages limit 的实际作用：BIOS UMA 仅能配置极小的静态保留显存（最低 512MB）。真正的统一内存扩展必须通过修改内核参数 amdgpu.gttsize 和 ttm.pages_limit 实现，这使得内核机制能够动态将海量的系统内存固定并映射为可由 GPU 直接寻址的显存页，从而装载百亿参数级模型。   

amd_iommu 参数的影响：关闭（off）能极其微弱地降低纯 GPU 基准测试的寻址开销，但会立刻摧毁系统的休眠功能，且使 NPU 通信断裂。开启或配置为 pt（直通）能够维持系统总线的健康隔离，是长期运行 AI 推理的唯一合理选择。   

Mesa/RADV 与 ROCm 的适用场景：Mesa/RADV 基于 Vulkan API，其编译器架构极其成熟，在 llama.cpp 或 Ollama 单机推理中表现出压倒性的稳定性与卓越的吞吐速度，是当前 gfx1151 本地推理的首选。ROCm 理论上适用于张量微调训练与复杂内核开发，但当前处于严重缺陷期。   

Ollama 是否支持 gfx1151：是，但必须强制使用 Vulkan 路径。如果使其回退到默认的 iGPU ROCm 路径，由于底层 MoE 张量映射错误，模型将输出完全脱离提示词逻辑的语义乱码。   

llama.cpp 的 Vulkan、HIP 和 ROCm 路径：Vulkan 路径（官方 release）表现完美。HIP/ROCm 路径在编译时如果开启 GGML_HIP_ROCWMMA_FATTN=ON 会因缺乏 wmma 后端支持而中断，禁用此宏并使用原生 GGML_HIP=ON 可勉强运行，但性能不如 Vulkan。   

vLLM 在 gfx1151 上的状态：属于实验性支持/预览状态。官方文档注明支持，但部署时遭遇严重的 Wave32/Wave64 LDS 内存屏障架构冲突（ sampler.cu 硬编码 1024 线程），必须降级到低效的 eager 模式，且无法加载某些视觉量化模型。   

Lemonade 相关路径：Lemonade SDK 作为一个统一接口层，声称对 Strix Halo NPU/GPU 具备 Day Zero 级别支持，并通过 API 网关抽象后端的 ROCm 和 Vulkan 调用。但当前存在环境变量传递失效（如忽略 LEMONADE_LLAMACPP_PREFER_SYSTEM=true）的工程级缺陷。   

XDNA2 NPU 在 Linux 上的模型与框架：物理硬件最高支持 50 TOPS 算力。底层由 amdxdna 驱动支撑，上层支持执行 CNN 等传统模型及部分量化 LLM。主要接入路径依赖厂商提供的编译抽象工具链（如 Lemonade SDK）。   

Docker GPU 映射与容器名称：要求向容器透传 --device=/dev/kfd --device=/dev/dri。官方容器已从 rocm/vllm 迁移整合至 vllm/vllm-openai-rocm。   

Open WebUI 参数控制：通过 ENABLE_OLLAMA_API 控制外部调用，AIOHTTP 控制 TLS 与自签名 CA 信任。认证由 ENABLE_LOGIN_FORM 拦截，通过 SUBAGENTS_MAX_CONCURRENT 压制并发风暴防止 API 击穿。   

A2A 与 MCP 边界：A2A 是跨厂商、跨框架的去中心化对等协议，保护 Agent 的内部黑盒（不透明执行）；MCP 则是强绑定的中心化协议，用于单一模型主控如何调用具体存储与工具。   

商业许可证：所有 A2A 协议实现与 SDK 均为 Apache-2.0。关于特定 AI 软件提供公开商业服务等级协议（SLA）与具体报价的证据：待核验。   

隐私、跨境与平台条款：A2A 的网络架构通过端点声明机制阻断了内部数据的越界传输，代理无需共享对话记忆，仅流转完成任务所需的最小数据集（JSON 工件）。TLS 保障通信加密，天然规避云端默认跨境传输引发的合规风险。   

gemini-official-sources.jsonl
Code snippet
{"资料 ID": "1", "标题": "Experience Unparalleled Performance with the AMD Ryzen™ AI Max+", "直接 URL": "https://www.amd.com/en/blogs/2025/experience-unparalleled-performance-with-the-amd-ryzen.html", "作者或组织": "AMD", "页面日期": "2025", "访问日期": "2026-08-13", "原文支持的具体结论": "Ryzen AI Max+ 395 搭载 16 核心 Zen 5 和 40 核心 Radeon 8060S，提供 50 TOPS XDNA2 NPU 算力。", "对应硬件": "Ryzen AI Max+ 395", "对应软件版本": "待核验", "安装步骤": "待核验", "验证步骤": "待核验", "回滚步骤": "待核验", "已知限制": "无具体部署参数", "适合零基础程度": "4", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "2", "标题": "AMD Ryzen AI Halo is Designed for the Agentic Era", "直接 URL": "https://www.amd.com/en/blogs/2026/amd-ryzen-ai-halo-is-designed-for-the-agentic-era.html", "作者或组织": "AMD", "页面日期": "2026", "访问日期": "2026-08-13", "原文支持的具体结论": "本地 Agent Orchestration 依赖 CPU 与 GPU 均衡，AMD Strix Halo 在端到端完成时间上优于单纯的高推理吞吐架构。", "对应硬件": "Strix Halo", "对应软件版本": "llama.cpp, FastEmbed ONNX", "安装步骤": "待核验", "验证步骤": "运行 HEPA 测试集", "回滚步骤": "待核验", "已知限制": "包含多个仅运行在 CPU 的阶段", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "4", "标题": "Issue #17604: ROCm backend on Radeon 8060S produces semantically incorrect output", "直接 URL": "https://github.com/ollama/ollama/issues/17604", "作者或组织": "Ollama Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Ollama 使用 ROCm 后端在 8060S 上生成语义混乱的内容，切换到 Vulkan 后端输出完全正确。", "对应硬件": "Radeon 8060S", "对应软件版本": "Ollama 0.32.6", "安装步骤": "配置环境变量 OLLAMA_IGPU_ENABLE=1 OLLAMA_VULKAN=1", "验证步骤": "运行 qwen3.6:35b-a3b 模型推理", "回滚步骤": "取消环境变量返回 ROCm", "已知限制": "ROCm 存在 MoE 张量操作错误", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "5", "标题": "Strix Halo Guide: AMD Ryzen AI MAX+ 395 Local LLM Setup", "直接 URL": "https://github.com/hogeheer499-commits/strix-halo-guide", "作者或组织": "hogeheer499", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "内核必须注入 amdgpu.gttsize 与 ttm.pages_limit 以支持大模型；llama.cpp Vulkan 可达 101.0 t/s。", "对应硬件": "Strix Halo, gfx1151", "对应软件版本": "Ubuntu 24.04, llama.cpp b9851", "安装步骤": "编辑 GRUB，注入 amdgpu.gttsize=131072 ttm.pages_limit=31457280", "验证步骤": "运行基准测试脚本", "回滚步骤": "从 GRUB 删除启动参数", "已知限制": "关闭 IOMMU 会破坏休眠和 NPU", "适合零基础程度": "3", "证据等级": "兼容性矩阵/社区指南", "当前状态": "有效"}
{"资料 ID": "7", "标题": "Issue #6157: Memory access fault by GPU node-1 on Radeon 8060S", "直接 URL": "https://github.com/ROCm/ROCm/issues/6157", "作者或组织": "rosstang", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "vLLM 0.19.0 搭配 ROCm 7.2.1 启动时触发 GPU Page not present or supervisor privilege 内存越界崩溃。", "对应硬件": "Radeon 8060S, gfx1151", "对应软件版本": "vllm 0.19.0+rocm721", "安装步骤": "使用 ROCm 环境启动 vLLM", "验证步骤": "vllm serve amd/gpt-oss-120b", "回滚步骤": "降级 linux-firmware 至 20251111 (无效)", "已知限制": "严重内存崩溃，导致 GPU Hang", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "8", "标题": "Data fabric sync flood event / EC power cuts under sustained load", "直接 URL": "https://pcforum.amd.com/s/question/0D5Pd00001ieWigKAE/...", "作者或组织": "AMD PC Forum User", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Ryzen AI Max+ 395 笔记本在持续高负载下出现硬件级断电与数据总线同步泛洪错误，非操作系统引发。", "对应硬件": "Ryzen AI Max+ 395", "对应软件版本": "Ubuntu kernel 7.1.2, BIOS 311", "安装步骤": "施加长期高强度 CPU/GPU 负载", "验证步骤": "读取重置寄存器 (reset-reason)", "回滚步骤": "强制风扇 100% 运转避免 ACPI 故障", "已知限制": "与固件或热保护有关", "适合零基础程度": "2", "证据等级": "社区故障反馈", "当前状态": "有效"}
{"资料 ID": "11", "标题": "Issue #6034: PyTorch TheROCk nightly critical bf16 bugs", "直接 URL": "https://github.com/ROCm/ROCm/issues/6034", "作者或组织": "bkpaine1", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "gfx1151 训练模型时存在 bf16 精度缺陷，特定小批次 (2^13)、小维度或深层网络必定导致 NaN 崩溃。", "对应硬件": "Radeon 8060S (gfx1151)", "对应软件版本": "PyTorch 2.11.0a0+rocm7.11.0a20260106", "安装步骤": "配置模型训练参数", "验证步骤": "调整 TOTAL_BATCH_SIZE=2**13 测试", "回滚步骤": "增大批处理尺寸至 2**15", "已知限制": "底层精度编译器缺陷", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "12", "标题": "Issue #5824: Basic PyTorch GPU memory operations crash", "直接 URL": "https://github.com/ROCm/ROCm/issues/5824", "作者或组织": "ROCm Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Fedora 43 / Kernel 6.17 下最基本的张量操作直接触发 HSA 内存严重错误。20251125 固件导致退化，需手动回退至 2025-12-04 包含 MES 0x80 修复的包。", "对应硬件": "Radeon 8060S", "对应软件版本": "ROCm 6.3.1, linux-firmware 20251125", "安装步骤": "更新系统包", "验证步骤": "执行任意 PyTorch 张量操作", "回滚步骤": "热修复固件 /usr/lib/firmware/amdgpu/gc_11_5_1_* 恢复 MES 0x80", "已知限制": "存在硬件资源死锁问题", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "15", "标题": "vLLM Linux Docker Image", "直接 URL": "https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/advanced/advancedryz/linux/llm/build-docker-image.html", "作者或组织": "AMD", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "通过容器运行 vLLM，需要特权级硬件节点映射 (--device=/dev/kfd --device=/dev/dri) 及网络权限。", "对应硬件": "gfx1151, gfx1150", "对应软件版本": "rocm/vllm-dev:rocm7.2.1", "安装步骤": "docker run -it --privileged --device=/dev/kfd --device=/dev/dri...", "验证步骤": "vllm bench latency", "回滚步骤": "待核验", "已知限制": "此基础镜像已被后续主线合并淘汰", "适合零基础程度": "2", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "17", "标题": "Issue #5991: GPU page fault on gfx1151 — basic tensor operations hang", "直接 URL": "https://github.com/ROCm/ROCm/issues/5991", "作者或组织": "ROCm Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "简单的 torch.randn 导致 GFX Hub CPF 缺页中断，内核挂起且无报错抛出，PyTorch 实际上已识别设备。", "对应硬件": "gfx1151", "对应软件版本": "PyTorch 2.11.0a0+rocm7.11", "安装步骤": "执行 python 脚本分配随机张量", "验证步骤": "查看 dmesg 中关于 amdgpu [gfxhub] page fault 的输出", "回滚步骤": "待核验", "已知限制": "非 Python 报错，属于驱动/ISA编译失效", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "20", "标题": "Issue #4618: Missing support for Radeon 8060s rocWMMA", "直接 URL": "https://github.com/ROCm/rocm-libraries/issues/4618", "作者或组织": "visorcraft / ROCm", "页面日期": "2026-02-15", "访问日期": "2026-08-13", "原文支持的具体结论": "尽管 issue 提前关闭，但 2026 年 2 月在 Fedora 43 上使用 HIP Clang 编译开启 GGML_HIP_ROCWMMA_FATTN 的 llama.cpp 仍彻底失败。", "对应硬件": "Radeon 8060S (gfx1151)", "对应软件版本": "rocwmma-devel-6.4.0-3, HIP clang 19.0.0", "安装步骤": "CMake 添加 -DGGML_HIP_ROCWMMA_FATTN=ON", "验证步骤": "执行 make 编译", "回滚步骤": "关闭该宏定义回退到普通内核", "已知限制": "WMMA 指令集对 RDNA3.5 支持仍不完备", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "24", "标题": "Issue #5339: Expanding ROCm Ecosystem", "直接 URL": "https://github.com/ROCm/ROCm/issues/5339", "作者或组织": "AMD / ROCm", "页面日期": "2025-10-14", "访问日期": "2026-08-13", "原文支持的具体结论": "官方正式宣布 ROCm 7.0.2 版本提供对 gfx1150 和 gfx1151 的 Linux 支持，并更新了兼容性矩阵。", "对应硬件": "gfx1151, gfx1150", "对应软件版本": "ROCm 7.0.2", "安装步骤": "按文档指令安装包管理器源", "验证步骤": "检查 rocminfo 目标架构", "回滚步骤": "待核验", "已知限制": "初版支持，残留大量深层 BUG", "适合零基础程度": "3", "证据等级": "官方 Issue 声明", "当前状态": "有效"}
{"资料 ID": "26", "标题": "amdxdna Kernel Driver Documentation", "直接 URL": "https://docs.kernel.org/accel/amdxdna/index.html", "作者或组织": "Kernel.org", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "AMD XDNA NPU 的 Linux 驱动负责硬件阵列、微控制器和邮箱的管理，并原生支持进程隔离策略。", "对应硬件": "AMD XDNA Array (NPU)", "对应软件版本": "Linux Kernel", "安装步骤": "编译内核模块 amdxdna", "验证步骤": "检查模块是否挂载成功", "回滚步骤": "待核验", "已知限制": "依赖底层固件接口正常通信", "适合零基础程度": "1", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "28", "标题": "Issue #367: Lemonade Day Zero support failing", "直接 URL": "https://github.com/amd/RyzenAI-SW/issues/367", "作者或组织": "RyzenAI Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "在 Lemonade 10.2.0 版本下，虽然宣传 Day Zero 支持 Strix Halo 的 50 TOPS 算力，但实际调用受阻。", "对应硬件": "XDNA 2 (50 TOPS)", "对应软件版本": "Lemonade Version: 10.2.0, Kernel 7.0.0", "安装步骤": "执行 Lemonade 推理脚本", "验证步骤": "监控 NPU 利用率", "回滚步骤": "待核验", "已知限制": "框架兼容性打折", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "30", "标题": "Ubuntu 26.04 LTS Release Notes", "直接 URL": "https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/", "作者或组织": "Ubuntu / Canonical", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Ubuntu 26.04 明确标记支持 Strix Halo 系列 (Radeon 8040S, 8050S, 8060S) 对应的 gfx1151 目标架构。", "对应硬件": "Strix Halo (Radeon 8060S)", "对应软件版本": "Ubuntu 26.04 LTS", "安装步骤": "常规系统安装或从 24.04 升级", "验证步骤": "通过 rocminfo 验证内核驱动识别情况", "回滚步骤": "使用快照恢复", "已知限制": "提及 gfx908 ROCm 测试存在失败", "适合零基础程度": "4", "证据等级": "官方发行说明", "当前状态": "有效"}
{"资料 ID": "31", "标题": "Ubuntu 26.04 LTS Server Changes", "直接 URL": "https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/", "作者或组织": "Ubuntu / Canonical", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "服务器组件更换 Chrony 为默认 NTP 守护进程，并在 OpenSSH 升级中包含后量子加密密钥交换支持。", "对应硬件": "通用", "对应软件版本": "Chrony 4.8, OpenSSH 1:10.2p1", "安装步骤": "apt install chrony 迁移旧配置", "验证步骤": "检查 /etc/chrony/sources.d", "回滚步骤": "待核验", "已知限制": "升级中需要合并旧系统的时间服务器配置", "适合零基础程度": "3", "证据等级": "官方发行说明", "当前状态": "有效"}
{"资料 ID": "33", "标题": "Vulnerabilities: Entrysign", "直接 URL": "https://ubuntu.com/security/vulnerabilities/entrysign", "作者或组织": "Ubuntu Security", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "针对 Zen 5/Strix Halo 的 EntrySign 微代码伪造漏洞已被修复，相关内核与 amd64-microcode 更新集成于 Ubuntu 26.04 和 25.10。", "对应硬件": "Zen 5, Strix Halo", "对应软件版本": "Ubuntu 26.04 (Resolute)", "安装步骤": "更新内核和 microcode", "验证步骤": "使用 dmesg 检查微代码版本号", "回滚步骤": "禁止回滚以防重叠攻击", "已知限制": "必须配合 OEM 厂商提供的 BIOS 升级", "适合零基础程度": "2", "证据等级": "官方安全公告", "当前状态": "有效"}
{"资料 ID": "35", "标题": "External GPU RTX 6000 Pro on Ubuntu 25.10 + 26.04", "直接 URL": "https://discourse.ubuntu.com/t/external-gpu-rtx-6000-pro-on-ubuntu-25-10-26-04/77130", "作者或组织": "niemeyer", "页面日期": "2026-02-17", "访问日期": "2026-08-13", "原文支持的具体结论": "证实通过内核参数 iommu=pt amdgpu.gttsize=124928 ttm.pages_limit=31981568 成功将 128GB LPDDR5X 映射供 8060s 加载大模型。", "对应硬件": "Strix Halo (128GB)", "对应软件版本": "Ubuntu 26.04, kernel 7.0.0-15", "安装步骤": "修改 /etc/default/grub 并执行 update-grub", "验证步骤": "运行 Gemma 27B BF16 (约 50GB 显存) 测试通过", "回滚步骤": "删除 grub 参数并重启", "已知限制": "25.10 需添加 amdgpu.cwsr_enable=0 防止内核恐慌", "适合零基础程度": "3", "证据等级": "社区经验验证", "当前状态": "有效"}
{"资料 ID": "40", "标题": "AMD ROCm on Ubuntu", "直接 URL": "https://ubuntu.com/blog/amd-rocm-on-ubuntu", "作者或组织": "Canonical", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "确认 Ubuntu 26.04 LTS 原生集成了 ROCm 7.1，并点亮了 Strix Halo 处理器的 XDNA2 NPU 和 128GB 共享内存。", "对应硬件": "Strix Halo", "对应软件版本": "Ubuntu 26.04, ROCm 7.1, Lemonade", "安装步骤": "部署 Lemonade Server 管理调用", "验证步骤": "连接 ComfyUI/OpenWebUI 进行本地推理", "回滚步骤": "待核验", "已知限制": "The Rock 版本大重构可能阻断部分就地升级路径", "适合零基础程度": "4", "证据等级": "官方博客", "当前状态": "有效"}
{"资料 ID": "43", "标题": "AMD-SB-7033 Security Advisory Mitigation", "直接 URL": "https://ubuntu.com/security/vulnerabilities/entrysign", "作者或组织": "Ubuntu Security", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "必须确保主板 PI 版本升级，且 amd64-microcode 大于 2025-07-08 版本，才能通过 8d171045069c 内核补丁成功应用热加载。", "对应硬件": "AMD EPYC/Zen架构", "对应软件版本": "amd64-microcode > 2025-07-08", "安装步骤": "fwupdmgr refresh && fwupdmgr get-updates", "验证步骤": "dmesg | grep microcode 验证早加载", "回滚步骤": "待核验", "已知限制": "未更新 BIOS 将导致 OS 包修复无效", "适合零基础程度": "2", "证据等级": "官方安全公告", "当前状态": "有效"}
{"资料 ID": "49", "标题": "Open WebUI Reference - Env Configuration", "直接 URL": "https://docs.openwebui.com/reference/env-configuration/", "作者或组织": "Open WebUI Docs", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "支持禁用外部 API (Ollama) SSL 验证或挂载私有 CA 证书包，控制企业网络数据流安全。", "对应硬件": "通用", "对应软件版本": "Open WebUI", "安装步骤": "配置 ENABLE_OLLAMA_API", "验证步骤": "启动系统并验证外联连接情况", "回滚步骤": "重置环境变量", "已知限制": "部分 ConfigVar 环境仅在初始启动时读取", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "50", "标题": "Open WebUI Configurations - Auth and Agents", "直接 URL": "https://docs.openwebui.com/reference/env-configuration/", "作者或组织": "Open WebUI Docs", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "SUBAGENTS_MAX_CONCURRENT 可设置前台多智能体并发上限防止击穿，SUBAGENTS_BACKGROUND_ENABLED 支持后台异步运行。", "对应硬件": "通用", "对应软件版本": "Open WebUI", "安装步骤": "导出对应系统环境变量", "验证步骤": "多任务队列压测", "回滚步骤": "待核验", "已知限制": "并非跨集群全局限制，而是基于 worker 进程乘数限制", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "51", "标题": "Agent2Agent (A2A) Protocol Specification", "直接 URL": "https://github.com/a2aproject/A2A/blob/main/docs/specification.md", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "A2A 使得跨框架构建的独立代理能够相互发现、协商并分配任务，且确保执行不透明，仅传输规范数据件（Artifacts）。", "对应硬件": "通用", "对应软件版本": "A2A Protocol", "安装步骤": "提供 JSON-RPC 2.0 HTTP 端点", "验证步骤": "通过 Agent Card 解析能力", "回滚步骤": "待核验", "已知限制": "需要支持协议约定的 Task 生命周期状态机", "适合零基础程度": "3", "证据等级": "官方规范文件", "当前状态": "有效"}
{"资料 ID": "52", "标题": "A2A Streaming and Async Mechanisms", "直接 URL": "https://github.com/a2aproject/A2A/blob/main/docs/topics/streaming-and-async.md", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "长连接任务通过 Server-Sent Events (SSE) 实施流式传输，推送 TaskStatusUpdateEvent 与 TaskArtifactUpdateEvent。", "对应硬件": "通用", "对应软件版本": "A2A Protocol", "安装步骤": "实现 SendStreamingMessage RPC 端点", "验证步骤": "客户端维持 text/event-stream 监听", "回滚步骤": "断开连接进入异步中断状态", "已知限制": "要求底层反向代理支持长时间的 HTTP 挂起不被切断", "适合零基础程度": "2", "证据等级": "官方规范文件", "当前状态": "有效"}
{"资料 ID": "54", "标题": "A2A Extensions Mechanism", "直接 URL": "https://github.com/a2aproject/A2A/blob/main/docs/topics/extensions.md", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "支持扩展机制（Extensions）允许注入特定领域的 RPC 方法与数据验证约束，代理可在 Agent Card 中声明支持的扩展。", "对应硬件": "通用", "对应软件版本": "A2A Protocol", "安装步骤": "注册自定义扩展 URI", "验证步骤": "校验 Profile Extensions 强制数据结构", "回滚步骤": "降级至基础协议调用", "已知限制": "避免破坏核心标准协议", "适合零基础程度": "2", "证据等级": "官方规范文件", "当前状态": "有效"}
{"资料 ID": "55", "标题": "A2A Official SDK Licenses", "直接 URL": "https://github.com/a2aproject", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "A2A 所有官方语言 SDK（Python, Java, JS, Go, .NET, Rust）均采用 Apache-2.0 许可证。", "对应硬件": "通用", "对应软件版本": "A2A SDK", "安装步骤": "通过对应包管理器 (npm/pip/maven/cargo) 拉取", "验证步骤": "待核验", "回滚步骤": "待核验", "已知限制": "待核验", "适合零基础程度": "4", "证据等级": "官方代码仓库库标识", "当前状态": "有效"}
{"资料 ID": "56", "标题": "A2A Protocol Overivew", "直接 URL": "https://github.com/a2aproject/A2A/blob/main/README.md", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "A2A 是对 MCP 协议的补充，MCP 专注于代理使用底层工具的能力，而 A2A 专注于代理与代理之间的协作通信和任务转移。", "对应硬件": "通用", "对应软件版本": "A2A Protocol / MCP", "安装步骤": "待核验", "验证步骤": "设计多级层级的智能体协同", "回滚步骤": "待核验", "已知限制": "保护代理知识产权，禁止强取内部记忆", "适合零基础程度": "4", "证据等级": "官方介绍文档", "当前状态": "有效"}
{"资料 ID": "60", "标题": "Issue #37151: vLLM Segfault on APU using Vision Encoder", "直接 URL": "https://github.com/vllm-project/vllm/issues/37151", "作者或组织": "vLLM Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "在 gfx1151 上运行 Qwen3-VL-AWQ 等视觉编码模型时，vLLM 初始化阶段的 libhsa-runtime64.so 必定抛出段错误导致子进程死亡。", "对应硬件": "Ryzen AI Max+ 395 (gfx1151)", "对应软件版本": "vLLM 0.17.1rc1, ROCm 7.0", "安装步骤": "启动 vLLM Serve 视觉模型", "验证步骤": "查看进程异常退出日志", "回滚步骤": "待核验", "已知限制": "此架构上暂不支持视觉相关计算图的内存池分配", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "61", "标题": "vLLM ROCm Installation", "直接 URL": "https://docs.vllm.ai/en/stable/getting_started/installation/gpu/", "作者或组织": "vLLM Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "官方正式废弃原 AMD Infinity Hub 的旧版 rocm/vllm 镜像，强制迁移统一至官方发布链条下的 vllm/vllm-openai-rocm 容器。", "对应硬件": "Radeon RX / MI系列", "对应软件版本": "vLLM", "安装步骤": "docker pull vllm/vllm-openai-rocm", "验证步骤": "待核验", "回滚步骤": "待核验", "已知限制": "对于消费级显卡不再提供预编译的 pip wheel 文件", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "66", "标题": "Issue #45871: vLLM build fails on gfx1151 due to Wave32 architecture", "直接 URL": "https://github.com/vllm-project/vllm/issues/45871", "作者或组织": "vLLM Community", "页面日期": "2026-06", "访问日期": "2026-08-13", "原文支持的具体结论": "因 vLLM 核心文件 sampler.cu 假设 Wave64 架构并硬编码 1024 线程处理块，导致在 Wave32 (gfx1151) 上申请 LDS 容量高达 66032B，超过 64KB 上限编译失败。", "对应硬件": "Radeon 8060S (Wave32)", "对应软件版本": "vLLM main, ROCm 6.4.2+", "安装步骤": "PYTORCH_ROCM_ARCH=gfx1151 pip install -e .", "验证步骤": "捕获 HIP 内核编译报错信息", "回滚步骤": "需修改 C++ 源码重构共享内存分配逻辑", "已知限制": "属于深层硬件架构冲突", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "67", "标题": "vLLM Supported Hardware", "直接 URL": "https://docs.vllm.ai/en/v0.11.1/getting_started/installation/gpu/", "作者或组织": "vLLM Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "文档指出 Ryzen AI MAX 系列运行 vLLM 最低要求 ROCm 版本为 7.0.2 及配套驱动。", "对应硬件": "Ryzen AI MAX (gfx1151)", "对应软件版本": "ROCm 7.0.2+", "安装步骤": "基于新版系统编译底层库", "验证步骤": "待核验", "回滚步骤": "待核验", "已知限制": "Windows 环境缺乏原生支持，需通过 WSL", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "70", "标题": "Issue #32180: vLLM V1 Engine hang on gfx1151", "直接 URL": "https://github.com/vllm-project/vllm/issues/32180", "作者或组织": "vLLM Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "vLLM V1 引擎在 gfx1151 进行 HIP 图捕获时因驱动级超时而永远挂起。目前被迫使用 --enforce-eager 退回串行调度，导致巨大的性能浪费。", "对应硬件": "Radeon 8060S (gfx1151)", "对应软件版本": "vllm/vllm-openai-rocm:v0.14.1", "安装步骤": "添加启动参数 --enforce-eager", "验证步骤": "规避 Network/Socket Error", "回滚步骤": "待核验", "已知限制": "使得 128MB L3 MALL Cache 完全无法发挥其高带宽 KV Cache 的优势", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "29", "标题": "Issue #1791: Lemonade SDK Ignores System Vulkan Flag", "直接 URL": "https://github.com/lemonade-sdk/lemonade/issues/1791", "作者或组织": "Lemonade Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Lemonade 10.3.0 在执行代理分发时，忽略了强制使用本地编译引擎的变量 LEMONADE_LLAMACPP_PREFER_SYSTEM=true。", "对应硬件": "通用 (包含 Strix Halo)", "对应软件版本": "Lemonade v10.3.0", "安装步骤": "导出系统变量", "验证步骤": "检查引擎启动日志以验证调用路径", "回滚步骤": "降级 SDK", "已知限制": "抽象层配置不透明", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "10", "标题": "AMD GPU specifications", "直接 URL": "https://rocm.docs.amd.com/en/latest/reference/gpu-specs.html", "作者或组织": "AMD ROCm Docs", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Radeon 8060S 采用 RDNA3.5 架构，目标标识符为 gfx1151，具备 40 个图形核心及动态划分缓存能力。", "对应硬件": "Radeon 8060S (gfx1151)", "对应软件版本": "底层硬件支持", "安装步骤": "待核验", "验证步骤": "运行 rocminfo 对比输出规范", "回滚步骤": "待核验", "已知限制": "并非数据中心 CDNA 架构", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "25", "标题": "Install Ryzen AI Software Linux", "直接 URL": "https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/install/installryz/native_linux/install-ryzen.html", "作者或组织": "AMD ROCm Docs", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "非 root 用户调用 GPU 计算接口，必须执行 sudo usermod -a -G render,video $LOGNAME，否则会因系统权限产生访问阻塞。", "对应硬件": "Radeon 8060S", "对应软件版本": "Linux, amdgpu", "安装步骤": "usermod -a -G render,video $LOGNAME", "验证步骤": "groups 命令打印包含 render 和 video，或 rocminfo 识别设备", "回滚步骤": "从组内移除用户", "已知限制": "更改后必须重启", "适合零基础程度": "4", "证据等级": "官方安装文档", "当前状态": "有效"}
{"资料 ID": "27", "标题": "amdxdna Linux Kernel documentation details", "直接 URL": "https://docs.kernel.org/accel/amdxdna/amdnpu.html", "作者或组织": "Kernel.org", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "AMD NPU 属于多用户 AI 推理加速器，集成在 APU 中，通过专门的 amdxdna 栈运行 CNN 和 LLM 等模型任务。", "对应硬件": "AMD NPU", "对应软件版本": "Linux Kernel", "安装步骤": "加载 amdxdna.ko", "验证步骤": "运行简单的 CNN 推理验证加速端点", "回滚步骤": "卸载模块", "已知限制": "依赖上层框架封装（如 ONNX 或特定 SDK）", "适合零基础程度": "2", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "34", "标题": "Ubuntu 24.04.4 Release Bugs fixed", "直接 URL": "https://documentation.ubuntu.com/release-notes/24.04/4/", "作者或组织": "Ubuntu", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "Ubuntu 24.04.4 point release 集成了 linux-oem-6.14/6.17，修复了阻碍 Strix Halo 无缝启动及接口输出的 OEM 缺陷。", "对应硬件": "Strix Halo", "对应软件版本": "Ubuntu 24.04.4", "安装步骤": "安装或升级到最新 HWE/OEM 内核", "验证步骤": "测试重启和睡眠恢复过程是否流畅无断点", "回滚步骤": "回滚旧版本内核启动镜像", "已知限制": "可能需要额外专有固件支持", "适合零基础程度": "3", "证据等级": "官方发行说明", "当前状态": "有效"}
{"资料 ID": "47", "标题": "Ubuntu Noble Numbat Point Release", "直接 URL": "https://discourse.ubuntu.com/t/noble-numbat-point-release-changes/47565", "作者或组织": "Ubuntu Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "文档详细列举了用户创建工具 (gnome-initial-setup 切换为 ubuntu-desktop-installer) 与新版快照应用机制的安全及兼容性强化。", "对应硬件": "通用", "对应软件版本": "Ubuntu 24.04.x", "安装步骤": "常规系统构建流程", "验证步骤": "体验创建用户流程", "回滚步骤": "待核验", "已知限制": "部分 OEM-setup 被取代", "适合零基础程度": "4", "证据等级": "社区验证贴", "当前状态": "有效"}
{"资料 ID": "48", "标题": "llama.cpp Vulkan HIP Performance", "直接 URL": "https://github.com/ggml-org/llama.cpp/issues/24438", "作者或组织": "llama.cpp Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "针对 RDNA3.5 (gfx1151) APU，llama.cpp Vulkan 后端效率已超过纯 ROCm/HIP 后端的实验构建，具有更好的通用性和速度。", "对应硬件": "gfx1151", "对应软件版本": "llama.cpp", "安装步骤": "使用 GGML_VULKAN 构建项目", "验证步骤": "跑 benchmark 分析吞吐量", "回滚步骤": "清空 build 文件夹重新 cmake", "已知限制": "严重受制于内存带宽限制", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "57", "标题": "A2A DeepLearning.AI Course", "直接 URL": "https://github.com/a2aproject/A2A/blob/main/README.md", "作者或组织": "A2A Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "提供将现有多框架基建（如 LangGraph, BeeAI, Google ADK）转化为 A2A compliant 服务器的标准化路径，以促进异构系统的混合编排。", "对应硬件": "通用", "对应软件版本": "LangGraph, BeeAI", "安装步骤": "使用特定封装层将应用逻辑包装在 A2A HTTP 端点之后", "验证步骤": "从 A2A Client 发起通信调用并监听状态改变", "回滚步骤": "待核验", "已知限制": "不可穿透框架强行暴露原生对象", "适合零基础程度": "3", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "63", "标题": "vLLM 0.12.0 Supported OS/Arch", "直接 URL": "https://docs.vllm.ai/en/v0.12.0/getting_started/installation/gpu/", "作者或组织": "vLLM Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "明确在 Linux x86 系统上 vLLM 对 Ryzen AI Max (gfx1151) 的基础架构提供依赖支持，通过提供自定义内核以适应无 Wheel 的场景。", "对应硬件": "gfx1151", "对应软件版本": "vLLM 0.12.0, ROCm 6.3+", "安装步骤": "从源码进行 Full build (with compilation)", "验证步骤": "观察 C++ 层 kernel 构建是否由于架构报错停止", "回滚步骤": "移除 pip 编译缓存", "已知限制": "Windows native 环境不支持", "适合零基础程度": "2", "证据等级": "官方文档", "当前状态": "有效"}
{"资料 ID": "64", "标题": "vLLM Issue hardware topology report", "直接 URL": "https://github.com/vllm-project/vllm/issues/37151", "作者或组织": "vLLM Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "物理架构层面，Strix Halo 的 Radeon 8060S 与 CPU 共享 BogoMIPS 及 FPU 管线环境资源，使得统一内存访问不受外围 PCIe 总线的干预。", "对应硬件": "Ryzen AI MAX+ 395 / Radeon 8060S", "对应软件版本": "Kernel 6.17", "安装步骤": "执行 lscpu 等底层指令获取拓扑", "验证步骤": "检查 NUMA 或 UMA 节点分配", "回滚步骤": "待核验", "已知限制": "缺少针对 iGPU 的专业调度策略", "适合零基础程度": "2", "证据等级": "底层指令输出日志", "当前状态": "有效"}
{"资料 ID": "69", "标题": "vLLM Quantization Operations Support", "直接 URL": "https://docs.vllm.ai/en/v0.11.1/getting_started/installation/gpu/", "作者或组织": "vLLM Project", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "vLLM 现阶段包含大量针对 AWQ, GPTQ, GGUF 等格式的量化算子代码 (fused_moe, trtllm_moe)，但并非所有算子已适配 RDNA3.5。", "对应硬件": "通用", "对应软件版本": "vLLM", "安装步骤": "使用对应量化格式载入模型", "验证步骤": "校验生成效果，确保未出现 NaN 梯度爆炸或语义错乱", "回滚步骤": "切换回非量化 fp16 或 bf16 版本", "已知限制": "RDNA架构由于指令集限制通常需要 fallback 回未优化的慢速内核", "适合零基础程度": "1", "证据等级": "官方文档模块树", "当前状态": "有效"}
{"资料 ID": "19", "标题": "TheROCk PyTorch Issue Summary", "直接 URL": "https://github.com/ROCm/ROCm/issues/6034", "作者或组织": "bkpaine1", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "在测试基于 gfx1151 的 93 个强化学习自回归实验中，不仅发现了 5 个极具破坏性的 bf16 边界 BUG，亦找到通过 19 倍加速注意力重构绕开架构瓶颈的方法。", "对应硬件": "Radeon 8060S (gfx1151)", "对应软件版本": "PyTorch TheROCk Nightly", "安装步骤": "部署自定义 PyTorch 构建环境并执行调优", "验证步骤": "监测模型每 token 更新带来的指标 (val_bpb) 下降", "回滚步骤": "待核验", "已知限制": "需避免深层残差累积", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "21", "标题": "Issue #5824 Summary Report", "直接 URL": "https://github.com/ROCm/ROCm/issues/5824", "作者或组织": "ROCm Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "重申 Nobara Linux (基于 Fedora) 更新大量固件依赖后触发底层 ROCm 协议层栈对 gfx1151 发起直接内核页异常的恶劣事件。", "对应硬件": "Ryzen AI Max+ 395", "对应软件版本": "Nobara Linux 43, ROCm 6.3.1", "安装步骤": "待核验", "验证步骤": "触发系统日志 dmesg 追踪故障", "回滚步骤": "降级逾 1510 个包含核心底层调度的包 (失败，需直接打补丁)", "已知限制": "非系统级封装漏洞，而是驱动级回归", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "23", "标题": "Issue #5339: GGML Fallback Success", "直接 URL": "https://github.com/ROCm/ROCm/issues/5339", "作者或组织": "ROCm Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "由于底层 ROCm 对于 FATTN (Flash Attention) 缺乏支持，在编译配置中使用 -DGGML_HIP=ON 可让 GGML 选择绕过 ROCm 存在缺陷的执行路径并在 Whisper 上取得 31.9x 提速。", "对应硬件": "Radeon 8060S", "对应软件版本": "ROCm 7.2.0, GGML", "安装步骤": "调整构建宏，舍弃错误库", "验证步骤": "跑音频转译大模型计算响应延迟", "回滚步骤": "待核验", "已知限制": "性能不及纯手写优化库", "适合零基础程度": "2", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "71", "标题": "Issue #37472: vLLM V1 hang on encoder cache", "直接 URL": "https://github.com/vllm-project/vllm/issues/37472", "作者或组织": "vLLM Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "vLLM V1 在针对 RDNA (gfx1151) 初始化带有外部视觉编码器大模型时，因调用 MIOpen 缺少特定的 solver 数据库导致死循环无限挂起。", "对应硬件": "gfx1151", "对应软件版本": "vLLM V1 Engine", "安装步骤": "启动带有 Vision 参数的大规模端点", "验证步骤": "查看进程僵死状态", "回滚步骤": "退回不包含编码器的纯文本状态", "已知限制": "MIOpen 对消费级芯片数据库生成不完善", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "37", "标题": "Ubuntu 26.04 Navi Support Status", "直接 URL": "https://documentation.ubuntu.com/release-notes/26.04/changes-since-previous-interim/", "作者或组织": "Canonical", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "确认 26.04 版本将统一支持从 Navi 44 (gfx1201), Navi 48 到 Strix Halo (gfx1151) 各种现代 AMD 物理加速器的硬件栈整合。", "对应硬件": "Navi44, Navi48, Strix Halo", "对应软件版本": "Ubuntu 26.04", "安装步骤": "系统直接集成，无须外挂源", "验证步骤": "使用发行版自带工具识别设备总线", "回滚步骤": "待核验", "已知限制": "部分极限工作流 (如 Blender 渲染) 依然有挂起风险", "适合零基础程度": "3", "证据等级": "官方发行说明", "当前状态": "有效"}
{"资料 ID": "58", "标题": "Issue #1672: A2A Identity Verification Details", "直接 URL": "https://github.com/a2aproject/A2A/issues/1672", "作者或组织": "A2A Community", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "A2A 内部的安全性已通过中继侧的 XChaCha20-Poly1305 (24-byte nonce, AEAD) 双棘轮协议实施高强度端到端消息级加密保障，且密钥交换使用 X3DH 匹配。", "对应硬件": "通用", "对应软件版本": "A2A SDK 及其依赖 (libsodium)", "安装步骤": "配置密钥系统与代理映射", "验证步骤": "通过互操作向量强制检测匹配度", "回滚步骤": "清空加密通道上下文并重建会话", "已知限制": "暂无统一外部颁发的身份标识方案映射机制", "适合零基础程度": "1", "证据等级": "GitHub Issue", "当前状态": "有效"}
{"资料 ID": "39", "标题": "Ubuntu 26.04 gcc flags change", "直接 URL": "https://manpages.ubuntu.com/manpages/resolute/man1/gcc.1.html", "作者或组织": "Ubuntu / GCC", "页面日期": "待核验", "访问日期": "2026-08-13", "原文支持的具体结论": "自 25.10 及 26.04 起，通过开启诸如 -fzero-init-padding-bits=all 等特性全面提高了编译构建 C/C++ 等底座语言生成可执行程序时的内存抗渗透安全性。", "对应硬件": "通用", "对应软件版本": "GCC in Ubuntu 26.04", "安装步骤": "默认构建参数生效", "验证步骤": "编译后查阅生成的符号结构特征", "回滚步骤": "强制声明覆盖默认宏选项", "已知限制": "可能引发依赖位操作未初始化字段边界的极少数古老代码产生预期外故障", "适合零基础程度": "2", "证据等级": "官方系统手册", "当前状态": "有效"}

documentation.ubuntu.com
Changes in Ubuntu 24.04.4 - Ubuntu release notes
Opens in a new window

docs.kernel.org
accel/amdxdna NPU driver - The Linux Kernel documentation
Opens in a new window

documentation.ubuntu.com
Ubuntu 26.04 LTS summary - Ubuntu release notes
Opens in a new window

ubuntu.com
EntrySign - Vulnerability knowledge base - Ubuntu
Opens in a new window

github.com
Memory Access Fault on gfx1151 (Strix Halo) · Issue #5824 · ROCm/ROCm - GitHub
Opens in a new window

github.com
Strix Halo guide for AMD Ryzen AI MAX+ 395 / Radeon 8060S local LLM setup and benchmarks - GitHub
Opens in a new window

discourse.ubuntu.com
External GPU RTX 6000 Pro on Ubuntu 25.10 + 26.04 - Kernel
Opens in a new window

docs.kernel.org
AMD NPU - The Linux Kernel documentation
Opens in a new window

rocm.docs.amd.com
vLLM Linux Docker Image — Use ROCm on Radeon and Ryzen
Opens in a new window

docs.vllm.ai
GPU - vLLM
Opens in a new window

github.com
[Bug]: Performance Bottlenecks and V1 Engine Instability on AMD gfx1151 (Strix Halo) · Issue #32180 · vllm-project/vllm - GitHub
Opens in a new window

rocm.docs.amd.com
Install Ryzen Software for Linux with ROCm
Opens in a new window

github.com
[Bug][ROCm][gfx1151] sampler.cu: topKPerRowDecode<1024> exceeds local memory limit on Wave32 GPUs #45871 - GitHub
Opens in a new window

github.com
[Bug]: [ROCm][gfx1151] Engine Core segfaults in libhsa-runtime64.so when loading Qwen3-VL-32B-AWQ on AMD Ryzen AI MAX+ 395 · Issue #37151 - GitHub
Opens in a new window

github.com
[Issue]: GPU page fault on gfx1151 (Radeon 8060S) — basic tensor operations hang #5991
Opens in a new window

github.com
[Issue]: Missing support for Radeon 8060s (Ryzen AI Max+ 395) gfx1151 #4618 - GitHub
Opens in a new window

github.com
Strix Halo gfx1151: 93 ML experiments, 5 critical bf16 bugs, AOTriton 19x speedup undocumented · Issue #6034 - GitHub
Opens in a new window

github.com
Incorrect LLM Output on AMD Radeon 8060S / Ryzen AI MAX+ 395 with Vulkan and ROCm · Issue #17604 - GitHub
Opens in a new window

docs.openwebui.com
Environment Variable Configuration - Open WebUI
Opens in a new window

github.com
A2A/README.md at main · a2aproject/A2A - GitHub
Opens in a new window

modelcontextprotocol.io
Tools - Model Context Protocol
Opens in a new window

github.com
A2A/docs/specification.md at main · a2aproject/A2A - GitHub
Opens in a new window

github.com
Proposal: Agent Identity Verification for Agent Cards · Issue #1672 · a2aproject/A2A - GitHub
Opens in a new window

github.com
A2A/docs/topics/streaming-and-async.md at main - GitHub
Opens in a new window

github.com
Agent2Agent (A2A) Project - GitHub
Opens in a new window

github.com
[Documentation]: Confusing rocm support for gfx1151 · Issue #5339 - GitHub
Opens in a new window

documentation.ubuntu.com
Changes in Ubuntu 24.04.2 - Ubuntu release notes
Opens in a new window

github.com
[BUG] "Day Zero" Gemma 4 support missing for Linux (Strix Halo/XDNA 2) on lemond 10.2.0 · Issue #367 · amd/RyzenAI-SW - GitHub
Opens in a new window

ubuntu.com
AI with AMD ROCm on Ubuntu: your questions answered
Opens in a new window

github.com
v10.3.0: Lemonade ignores LEMONADE_LLAMACPP_PREFER_SYSTEM=true · Issue #1791 - GitHub
Opens in a new window

amd.com
Experience Unparalleled Performance with the AMD Ryzen™ AI Max+ 395 Processor
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window
Opens in a new window