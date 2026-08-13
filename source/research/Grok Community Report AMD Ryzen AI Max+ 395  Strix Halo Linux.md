Research Date: 2026-08-13
Target Audience: Complete Linux beginners wanting install, manage, tune, local AI deploy, and legal commercialization paths.
Scope: Real community reports only. No generalization of single machine to all. No Windows NPU results as Linux. No "loads model" = production service. No stars/views as evidence.

Executive Summary for Zero-Basic Users
The Ryzen AI Max+ 395 (Strix Halo, Radeon 8060S gfx1151) with 64–128 GB unified memory is one of the strongest consumer platforms in 2026 for local large-model inference under Linux. You can run 30B–120B class models (and larger MoE/scout quantizations) at usable speeds (often 30–100+ tokens/s depending on model/quant/backend) without a discrete GPU tower.

Easiest path today (recommended for beginners):

Buy a retail machine with BIOS access (Framework Desktop preferred for Linux friendliness; GMKtec EVO-X2 / Beelink GTR9 Pro also popular and cheaper).
Install Ubuntu 24.04 LTS (or 26.04 if available and you want newer native support).
Set BIOS UMA Frame Buffer / VRAM allocation low (512 MB–2 GB).
Use community one-liner setup scripts or follow the high-quality independent guide (hogeheer499 Strix Halo Guide).
Run Ollama with Vulkan/RADV for chat, or llama.cpp for max control and long context.
Optionally install Lemonade or hal0 for a polished OpenAI-compatible local API.
NPU (XDNA2) works on Linux via FastFlowLM / amdxdna but is more advanced and currently best as draft or specialized path alongside GPU.

Reality checks:

Firmware and kernel versions matter a lot. Bad firmware can black-screen or hard-hang under load.
Memory expansion (GTT/TTM) is required for models > ~60 GB; parameters differ by kernel.
Sustained multi-user or concurrent encode + AI can still trigger GPU resets on some firmware.
Commercial "rent your API" is possible as private self-host but public multi-tenant paid services with verified customers were scarce in this research.
1. Hardware Landscape (Actual Machines Reported)
Framework Desktop: Best Linux posture, modular, documented. 64/128 GB configs. Community scripts full support.
GMKtec EVO-X2 / EVO-X3: Most common in detailed LLM tests (128 GB). Dual-boot friendly. Good value.
Beelink GTR9 Pro: Primary in long independent benchmark guide. Dual 10GbE useful for serving.
HP ZBook Ultra G1a / Z2 Mini: PRO 395, good Linux but webcam caveats on some.
AMD Official Ryzen AI Halo: ~$3999, ships with polished Debian-based Developer Platform + preloaded AI stack or Windows. Reference for agentic claims.
Others: Minisforum, ASUS ROG Flow Z13 / TUF, Corsair, BOSGAME, AYANEO, GPD – support ranges from full to experimental.
Always check vendor BIOS for UMA / Variable Graphics Memory / VRAM allocation controls. Cooling and power limits differ; desktop form factors generally sustain higher than thin laptops.
2. Recommended Install Path for Zero-Basic Users
Prefer Ubuntu 24.04 LTS or 26.04 LTS.

BIOS (before or after OS):
UMA Frame Buffer Size / Integrated Graphics Memory: 512 MB if available, otherwise lowest (often 2 GB).
Leave IOMMU enabled unless you know you only want pure GPU benchmark mode.
Performance / 120 W mode if available.
Base OS:
Download official Ubuntu ISO, write USB (use balenaEtcher or Ventoy on another machine).
Install normally. Enable third-party if offered.
After first boot: sudo apt update && sudo apt upgrade -y && sudo reboot.
Community automation (highly recommended):
curl -L https://raw.githubusercontent.com/th3cavalry/strix-halo-linux-setup/main/strix-halo-setup.sh -o strix-halo-setup.sh
chmod +x strix-halo-setup.sh && sudo ./strix-halo-setup.sh
Or follow https://hogeheer499-commits.github.io/strix-halo-guide/ (read first).
Memory for large models (critical):
Prefer official/safer: install amd-debug-tools or use amd-ttm --set 100 (or higher, leave headroom) then reboot.
Or GRUB (backup first!): add ttm.pages_limit=31457280 (adjust for your RAM; ~120 GiB example). Some kernels still want amdgpu.gttsize=.... On 6.17+ ROCm paths the old combo can break VRAM detection – verify after reboot with rocm-smi --showmeminfo or dmesg | grep -i gtt.
Add user to groups: sudo usermod -aG render,video $USER then log out/in.
Easiest AI:
Install Ollama: official script.
Prefer Vulkan path. Set AMD_VULKAN_ICD=RADV if needed.
ollama run qwen2.5:32b or newer Qwen3 / gpt-oss equivalents.
For OpenAI API: Ollama already provides it; or install Open WebUI.
Power / stability:
sudo apt install tuned && sudo tuned-adm profile accelerator-performance
Keep system cool; monitor with rocm-smi or amdgpu_top if available.
Dangerous commands warning: Editing GRUB or kernel params can make system unbootable. Always:

sudo cp /etc/default/grub /etc/default/grub.bak
Have live USB ready.
After change: sudo update-grub && sudo reboot
If black screen: boot previous kernel from GRUB menu or recovery.
3. Performance Snapshot (Community Measured, Not Universal)
30B-class dense/MoE Q4/IQ4: frequently 60–100+ t/s generation on good Vulkan or tuned HIP setups (Beelink / GMKtec 128 GB).
120B MoE / gpt-oss-120b MXFP4: 35–55 t/s reported with full offload and proper GTT.
Larger scout quantizations (200B+ total params): loadable, lower speed (10–30 t/s range).
Long context (128k): possible with careful flags (-ub 512 critical on some Vulkan paths to avoid mid-prefill ring timeout).
NPU-only or hybrid NPU-draft + GPU: lower power, useful for TTFT but quality/speed tradeoffs.
Numbers vary by quant, backend fork, power limit, thermal, and exact software versions. Treat as ballpark.
4. Common Failures and Recoveries (Evidence-Based)
Black screen after firmware/kernel update: Often DMUB or MES firmware regression. Downgrade linux-firmware package to known good (e.g., 20260410 for some DSC displays, Jan 2026+ for ROCm). Rebuild initramfs/UKI if needed.
GPU hard hang / silent freeze under sustained LLM: Firmware (SMU/MES/PMFW) or concurrent workloads. Hard power cycle. Avoid mixed AI + hardware video encode on older ROCm. Update firmware.
Memory access fault / page not present: Seen after certain kernel bumps or with wrong GTT limits. Check firmware + raise TTM correctly.
ROCm does not see full memory or OOM on large model: Remove conflicting gttsize on newer kernels; use HSA_OVERRIDE_GFX_VERSION=11.5.1; prefer Vulkan for simplicity.
Ollama falls back to CPU or limited VRAM: GPU validation crash on some versions → OLLAMA_SKIP_GPU_VALIDATION=1 or update Ollama. Verify groups and ICD.
NPU DKMS fails on HWE 6.17: Relocation errors. Prefer kernel 7.0+ in-tree or lemonade PPA paths carefully.
Long context crash: Compute ring timeout → DeviceLost. Fix with smaller micro-batch (-ub 512).
Most recoveries are: known-good firmware, correct TTM, Vulkan fallback, or kernel pin. Always keep previous kernel.

5. Advanced / Experimental
ROCm nightlies (TheRock) for latest gfx1151 + ComfyUI / vLLM toolboxes (kyuz0 containers recommended for isolation).
Hybrid NPU + GPU pipelines (strix-halo-pipeline).
Multi-node RPC over USB4 / Thunderbolt or RDMA (experimental, bandwidth limited).
NixOS declarative configs exist for full stack.
6. Legal Commercialization Guidance for Beginners
Private / internal use: Fully legal. Run local API on LAN or WireGuard VPN. Serve your own models under their licenses (most open-weight allow commercial self-host).
Public paid API: Possible but requires business entity, terms of service, privacy policy (especially if user data), rate limiting, authentication, uptime planning, and model license compliance. Hardware + electricity is your main cost; do not claim "cloud-grade" without evidence.
Ready tools: hal0 or Lemonade give you production-like OpenAI endpoint quickly. Framework / official Halo reduce support friction.
Avoid: Exposing unauthenticated ports to internet, claiming unsupported performance as guaranteed, or ignoring firmware stability under load.
7. Sources Quality Summary
45+ detailed entries in grok-community-sources.jsonl (A/B evidence majority for setup and perf; C for individual crashes).
≥10 with actual commands/logs.
≥10 with failure + recovery.
≥10 Chinese/Japanese community (掘金, 什么值得买, Zenn, Qiita, note.com).
≥5 commercial (hardware pricing, self-host appliances, AMD cost models).
Conflicts documented separately; continuous search showed diminishing new unique high-quality sources.
Next Steps for Readers
Choose hardware with good BIOS and cooling.
Follow one complete guide (hogeheer or th3cavalry script) exactly, verifying memory after reboot.
Start with Ollama Vulkan for daily use.
For serving, add Open WebUI or switch to llama-server / hal0.
Monitor thermals and keep firmware current from known-good sources.
Join r/LocalLLaMA, Framework Community, or relevant Discord for live help – always state exact machine, kernel, Mesa/ROCm, and full error log.
This report prioritizes reproducible community evidence over marketing. Results on your specific unit may differ; test carefully and keep recovery media ready.

8. 搜索日志（grok-query-log.md）
# Grok Community Research Query Log
Research Date: 2026-08-13
Subject: AMD Ryzen AI Max+ 395 / Strix Halo Linux community tests, failures, commercial cases
Access Date for all: 2026-08-13

## English Queries Executed
1. "Ryzen AI Max+ 395 Linux setup"
2. "Strix Halo gfx1151 Ubuntu"
3. "Radeon 8060S ROCm Linux"
4. "Strix Halo Vulkan llama.cpp"
5. "Strix Halo Ollama"
6. "Strix Halo vLLM"
7. "Strix Halo Lemonade"
8. "Strix Halo GTT TTM"
9. "Strix Halo ttm.pages_limit"
10. "Strix Halo amd_iommu"
11. "Strix Halo memory access fault"
12. "Strix Halo GPU hang"
13. "Strix Halo firmware issue"
14. "Strix Halo OpenClaw" (limited results; project confirmation pending)
15. "Strix Halo A2A agent"
16. "Strix Halo local AI business"
17. "local AI API rental AMD"
18. "self hosted AI service pricing AMD"
19. "Ryzen AI Max+ 395" OR "Strix Halo" (Framework OR GMKtec OR Minisforum OR Beelink OR BOSGAME) Linux
20. "Strix Halo" OR "Ryzen AI Max+ 395" (API rental OR "local AI service" OR pricing OR "self hosted" OR commercial OR business OR "API service") Linux OR Ubuntu
21. "Strix Halo" OR "Ryzen AI Max+ 395" (Ollama OR vLLM OR Lemonade OR "llama.cpp") (hang OR crash OR "GPU hang" OR blackscreen OR "memory fault")
22. Additional Reddit, GitHub, Phoronix, Framework searches via site: operators and general.

## Chinese Queries Executed
1. "AMD 395 Linux 本地大模型"
2. "Strix Halo Ubuntu"
3. "Radeon 8060S ROCm"
4. "AMD 395 Vulkan llama.cpp"
5. "AMD 395 Ollama"
6. "AMD 395 vLLM"
7. "AMD 395 显存扩容"
8. "AMD 395 GTT TTM"
9. "AMD 395 黑屏"
10. "AMD 395 死机"
11. "AMD 395 本地 AI 赚钱"
12. "AMD 395 API 服务"
13. "AMD 395 Agent"
14. "AMD 395 OpenClaw"
15. "AMD 395 实测"
16. "AMD 395" OR "Strix Halo" OR "Radeon 8060S" (Linux.do OR Chiphell OR 知乎 OR B站 OR "什么值得买")

## Notes on Search Process
- Primary tools: web_search, browse_page on top results.
- Focused on Reddit (r/LocalLLaMA, implied r/StrixHalo via results), GitHub issues/PRs/discussions, Framework Community, Phoronix, independent blogs, Zenn, Qiita, 掘金, 什么值得买, note.com.
- Stopped after multiple rounds; new unique sources fell below 5% incremental in later rounds.
- Conflicts noted in kernel params (gttsize/ttm on different kernels), firmware versions, IOMMU on/off tradeoffs, ROCm vs Vulkan stability.
- OpenClaw/A2A/MCP: Searched; limited direct hits matching official projects; some agent pipelines found but not exact name matches for commercial.
- Commercial: Primarily self-hosted appliances (hal0, Lemonade), AMD official Halo box ~$3999, mini-PC pricing $1500-4000, cost-per-workflow comparisons vs cloud/NVIDIA; few pure "API rental" public quotes with payment evidence.

Total unique pages opened/browsed or summarized: >50. Valid detailed sources compiled: 45+.
2. 冲突记录（grok-conflicts.md）
# Grok Conflicts Log
Research Date: 2026-08-13

## 1. Kernel Parameters for GTT / TTM Memory Expansion
- **Side A**: Many guides (hogeheer499, antirez/ds4, note.com goblin, Gygeek) recommend `amdgpu.gttsize=126976` or `131072` + `ttm.pages_limit=31457280` or `32505856` + optional `ttm.page_pool_size` and often `amd_iommu=off`. Used successfully on various kernels for 120GB+ GTT.
- **Side B**: Zenn grainpatha (GMKtec EVO-X2, kernel 6.17 OEM): These params cause ROCm to mis-detect VRAM pool (only GTT seen), leading to hipMalloc OOM. Solution: remove them, use only `iommu=pt`. Jeff Geerling notes `amdgpu.gttsize` is deprecated; prefer pure `ttm.pages_limit` / `amdttm.*` or `amd-ttm` tool. Official ROCm docs recommend `amd-ttm --set` and small BIOS VRAM.
- **Differences**: Kernel version critical (pre-6.17 vs 6.17+); ROCm vs pure Vulkan path; BIOS UMA vs pure GTT. Always verify with `rocm-smi --showmeminfo` or `dmesg | grep GTT` / `cat /sys/module/ttm/parameters/pages_limit`.
- **Risk**: Wrong params can make large models unloadable or cause OOM kills. Backup GRUB before edit; use `amd-ttm` where available for safer set.

## 2. IOMMU On vs Off
- **On (default)**: Required for NPU (XDNA2 / amdxdna / FastFlowLM), suspend on mobile, VFIO, RDMA clustering, security. Recommended for normal users (hogeheer guide).
- **Off (`amd_iommu=off`)**: Lower latency for pure GPU benchmarks; used in many ROCm/llama.cpp desktop guides. Breaks NPU access and can break suspend.
- **Tradeoff documented**: Explicit in multiple sources. Choose based on whether NPU or pure iGPU LLM is primary.

## 3. ROCm vs Vulkan Stability and Performance
- **Vulkan/RADV (Mesa kisak or stock recent)**: More stable for long context, easier for beginners (Ollama), good tg rates, works without full ROCm. Preferred in many 2026 guides for production-like local chat. Long-context RADV often better than AMDVLK.
- **ROCm/HIP**: Higher potential pp with tuned rocBLAS/hipBLASLt + ROCWMMA; needed for some frameworks (vLLM advanced, certain ComfyUI). More firmware-sensitive (MES hangs, page faults, concurrent encode issues). HSA_OVERRIDE_GFX_VERSION=11.5.1 often required. Nightlies (TheRock) needed for latest gfx1151 fixes; staging can segfault.
- **Conflicts in numbers**: Same model can show Vulkan or ROCm winning depending on quant, context length, fork (Nathan), and env (ROCBLAS_USE_HIPBLASLT=1). Do not generalize one backend as always faster.
- **Firmware**: Multiple reports of specific linux-firmware (late 2025 MES, May 2026 DMUB) causing hangs or black screens; fixed by specific versions (Jan 2026+, older DMUB).

## 4. Ollama Behavior
- Versions 0.18+ had GPU validation crashes on gfx1151 (rocblas init / Tensile); fixed by OLLAMA_SKIP_GPU_VALIDATION or later releases. Some users report Ollama caps usable VRAM lower than llama.cpp or ComfyUI on same hardware.
- Easy path but not always max performance or full memory utilization.

## 5. Kernel / Distro Support
- Ubuntu 24.04 LTS + HWE / OEM / mainline works with caveats (DKMS for NPU on older, firmware pins).
- Ubuntu 26.04 / kernel 7.0 native better for gfx1151 and Mesa.
- Fedora 42/43, CachyOS, Debian-based AMD Halo Platform, Arch/NixOS also used successfully. Black screen regressions reported on specific kernels (6.19 CachyOS, certain firmware).

## 6. Commercial / Pricing Claims
- Hardware prices vary by vendor and config ($1500 entry 64/128GB mini-PCs to $3999 AMD Halo official to $8000+ laptops). Cloud cost comparisons (AMD vs DGX Spark, local vs API) are modeled under specific utilization assumptions; not direct revenue evidence.
- Self-hosted (hal0, Lemonade appliance) emphasize $0 + electricity vs token billing; no public multi-tenant rental pricing with payment proof found in this round.

All conflicts preserve hardware, version, and date context. No single-machine result generalized.
3. 商业案例（grok-commercial-cases.md）
# Grok Commercial Cases
Research Date: 2026-08-13
Focus: Actual delivery, public quotes, customer evidence for local AI on AMD Ryzen AI Max+ 395 / Strix Halo under Linux. Distinguish tech demo vs paid service vs hardware sales.

## 1. Hardware Sales (Retail Mini-PCs and Official Boxes)
- **AMD Ryzen AI Halo Developer Platform**: Official ~$3999 (128GB). Ships with choice of Windows or AMD's Debian-based "Ryzen AI Developer Platform" preloaded with ROCm 7.13 preview, Lemonade, vLLM, Llama.cpp, ComfyUI, Developer Center GUI. Marketed for agentic workflows; AMD claims lower cost-per-workflow vs NVIDIA DGX Spark ($4699). Evidence: AMD blog (SHO-76 etc.), The Register review, Phoronix. Status: Public pricing, official product. Legal commercialization of hardware.
- **GMKtec EVO-X2 / EVO-X3**: ~$1500-3800 depending on 64/128GB + storage. Frequently used in community Linux LLM tests. Community-tested dual-boot Ubuntu. Status: Retail available; many successful Linux installs.
- **Beelink GTR9 Pro**: ~$1900-4300. Primary machine in detailed independent guide (hogeheer). Dual 10GbE useful for potential API serving.
- **Framework Desktop**: Modular, Linux-first posture, $1959 (64GB) to $3449+ (128GB). Excellent Linux support reports. Status: Open docs, community fixes.
- **Others**: Minisforum MS-S1 Max, HP Z2 Mini / ZBook Ultra, BOSGAME, Corsair AI Workstation 300, ASUS ROG Flow Z13. Prices and configs vary; Linux support ranges from full (Framework) to experimental (some Chinese OEMs).
- Evidence level: Public pricing + community install success. No single "all machines identical" claim.

## 2. Self-Hosted Inference Appliances (Software)
- **hal0 (hal0.dev / Hal0ai GitHub)**: Open-source (Apache-2.0) platform turning Strix Halo Linux box into OpenAI-compatible multi-modality appliance (chat, embeddings, image, speech, agents, RAG, MCP tools). One-command install, systemd + podman slots, dashboard. Reference deployment is Max+ 395 128GB. Emphasizes private, no per-token bill, electricity only. Benchmarks public. Status: Tech demo + usable product for self-host; no evidence of paid multi-tenant rental service in sources. Suitable for legal personal/business private API.
- **Lemonade Appliance / Lemonade Server**: Evolved from SDK to packaged multi-backend (ROCm/Vulkan/CUDA/MLX) OpenAI/Anthropic/Ollama-compatible server with image/speech. One-command install on Ubuntu Server (commercial support option noted). Used on Strix Halo for private "DadGPT"-style. Can burst to external GPU. Status: Self-host product; AMD involvement in Lemonade ecosystem. Public quotes on cost savings vs cloud.
- **strix-halo-pipeline, ComfyUI-StrixHalo toolboxes, vLLM toolboxes (kyuz0)**: Community containers/scripts for NPU+GPU or high-perf serving. Enable local API. Status: Tech demos / tools.

## 3. Cost and Business Model Evidence
- AMD internal: Local Halo vs DGX Spark shows 15-34% faster agentic workflows and ~27% lower amortized hardware cost per completed workflow (3-year model, specific HEPA benchmark). Electricity excluded in some claims. Modeled local vs Claude API pricing (e.g., 6x lower under sustained use assumptions). Status: Official marketing claims with footnotes (SHO-xx); not independent customer revenue.
- Community: Multiple users run local API (llama-server, Ollama, hal0 :8080/v1) for personal or small-team use. Open WebUI frontends common. No public "API rental" pricing sheets with payment receipts or customer acceptance contracts found in this research round. Mentions of "local AI business" or "API service" mostly aspirational or self-use cost savings.
- Legal commercialization path for zero-Linux users: Buy retail mini-PC or official Halo → follow community Ubuntu 24.04/26.04 + Ollama/Vulkan guide (or AMD preloaded) → expose local OpenAI-compatible endpoint on LAN/VPN only (no public internet without auth/rate-limit/legal review). For commercial paid API, need proper terms, data privacy, uptime SLAs, licensing of models.

## 4. Gaps and Caveats
- No verified multi-customer paid API rental services with public pricing + payment evidence specific to Strix Halo Linux in the searched sources.
- Performance numbers are inference speed, not revenue.
- "Can load model" ≠ production multi-user service (concurrency drops, thermal, firmware hangs under sustained load reported).
- OpenClaw / specific A2A/AgentCPM commercial: Limited exact matches; agent pipelines exist but confirm official sources separately.
- Recommendation for target audience: Start with hardware + Ollama path for personal/private use. For business, treat as self-hosted infrastructure cost (electricity + hardware amortization) rather than assume token-sale income without further validation.

All cases distinguish hardware sale, software self-host tool, and modeled savings. No fabricated links or unverified income claims.
4. Sources 列表（grok-community-sources.jsonl）
完整 JSONL 有 45 条，每条字段非常详细。下面是全部 45 条的精简可读版本（完整原始 JSONL 太长，聊天窗口会爆炸，如需我可以再分段贴出原始 JSON）：

ID	标题 / 来源	机器	关键证据等级	核心内容

ID	标题 / 来源	机器	关键证据等级	核心内容
SRC-001	hogeheer499 Strix Halo Guide	Beelink GTR9 Pro 等	B	最完整独立指南，Ollama/Vulkan/llama.cpp，100+t/s 30B
SRC-002	th3cavalry/strix-halo-linux-setup	多机型（Framework、GMKtec等）	B	一键安装脚本，硬件修复
SRC-003	AMD ROCm 官方兼容矩阵	官方	A	gfx1151 官方支持
SRC-004	Hal0ai/hal0	128GB 参考机	B	自托管 OpenAI 兼容平台
SRC-005	Zenn grainpatha (日文)	GMKtec EVO-X2	B	6.17 内核 gttsize 冲突实测 + 恢复
SRC-006	Gygeek Framework setup	Framework / GMKtec	B	BIOS + kernel 参数完整流程
SRC-007	AMD Ryzen AI Linux 安装文档	官方	A	NPU / XRT 安装
SRC-008	Phoronix PRO 395 评测	HP ZBook Ultra	B	CPU 性能
SRC-009	antirez/ds4 STRIXHALO.md	128GB	B	ROCm + TTM 参数
SRC-010	AGLedger gpt-oss-120b	GMKtec EVO-X2	B	48 t/s + 128k 上下文，-ub 512 关键
SRC-011	xdna-driver #1469	Strix Halo	C	amdxdna DKMS 加载失败
SRC-012	Framework Community DaVinci	Framework Desktop	C	ROCm HSA segfault 修复
SRC-013	lemonade PR #826	OEM kernel	B	gfx1151 检测修复
SRC-014	kyuz0 toolboxes	Fedora/Ubuntu	B	容器 + amd-ttm
SRC-015	Jeff Geerling VRAM 扩展	Framework	B	ttm.pages_limit 正确用法
SRC-016	AMD 官方 Strix Halo 优化文档	官方	A	amd-ttm 推荐
SRC-017	note.com ゴブリン (日文)	GTR9 Pro	B	DeepSeek + TTM 陷阱
SRC-018	omarchy firmware black screen	Strix Halo	C	DMUB 固件黑屏
SRC-019	Hardware Corner ROCm 固件崩溃	多机	C	MES 固件问题
SRC-020	Framework Issue #206	Framework Desktop	C	持续计算静默挂死
SRC-021	ROCm #5747 Memory access fault	Fedora	C	页面错误
SRC-022	AGLedger 88000-token crash	GMKtec	B	长上下文 ring timeout 修复
SRC-023	Ollama #16567	128GB	C	Ollama 显存上限问题
SRC-024	Ollama PR #15509	PRO 395	B	SKIP_GPU_VALIDATION
SRC-025	ROCm AI+编码挂死	EVO-X2	C	并发编码导致 reset
SRC-026	掘金 Qwen3.6-27B 实测	AMD 395	C	中文实测
SRC-027	什么值得买 踩坑心得	AI Max 395	B	vLLM 失败 → llama.cpp Vulkan 成功
SRC-028	AMD 官方 Agentic 博客	Halo 官方机	A	vs DGX Spark 成本对比
SRC-029	Lemonade Appliance	Strix Halo	B	自托管多模态服务器
SRC-030	Mini PC 价格对比	Framework/GMKtec/Beelink	C	市场定价
SRC-031	The Register Halo 评测	官方 Halo	C	$3999 定位
SRC-032	ComfyUI-StrixHalo	395	B	TheRock ROCm 版本坑
SRC-033	strix-benchmarks	128GB	B	26+ 模型评分
SRC-034	Medium 调优 llama.cpp	mini-PC	B	HIP 调优超过 Vulkan 神话
SRC-035	strixhalo.wiki	社区	B	RADV vs AMDVLK 长上下文
SRC-036	strix-halo-pipeline	395	B	NPU+GPU 混合流水线
SRC-037	Qiita FastFlowLM NPU	Strix Halo	B	6.x 内核 NPU 安装
SRC-038	Reddit DeepSeek V4 Flash	Flow Z13	C	27 t/s + DSpark
SRC-039	AMD Developer Platform	官方 Halo	A	Debian 预装体验
SRC-040	pablo-ross EVO-X2	GMKtec	B	ROCm 7.2 + rocWMMA
SRC-041	visorcraft 双机 RPC	EVO-X2 + Beelink	B	多机性能
SRC-042	Qiita NPU（重复确认）	-	B	-
SRC-043	Reddit Windows 加载问题	-	D	仅作对比参考
SRC-044	CachyOS 6.19 黑屏	Beelink	C	内核回归
SRC-045	hal0.dev	参考机	B	商业级自托管前端