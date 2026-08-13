## 结论先行与证据口径

截至 **2026 年 8 月 13 日**，我按照你给出的 A1/A2/B/C/D 口径，把“卖得出去”与“技术上能跑”严格拆开。核心结论是：**Ryzen AI Max+ 395 / Strix Halo 已经存在真实付款、真实硬件交付和第一人称客户项目部署证据，但公开可验证的“用 Max395 给企业做本地 RAG/OCR/Agent，然后客户明确付款”的案例仍然很少。** 目前证据最强的商业链条分成三类：Framework 证明了终端客户确实为 Max395/128GB 机器完成付款；Beelink、GMKtec 的官方商品页客户评价证明 Max395 机器已经交付并被实际用作本地 AI 服务器；Altronis 则是目前我找到的最接近你目标商业模式的证据——服务商明确说自己把 **Framework Desktop 和 GMKtec EVO-X2 用于 client deployments，并在 Strix Halo 上跑真实客户 workload**。

在“邻近案例”中，证据反而更成熟。苏州银行采购“大模型训推一体机”的公开报道给出了 **1,788 万元人民币投标价格**；European Commission 与 deepset 已经把 self-hosted AI@EC 平台放到 Commission-managed infrastructure 上运行；deepset 还公开记录过客户要求在已有 NVIDIA GPU 上本地处理 **70 亿条 library records** 的项目；Hossted 的招聘页则直接称其咨询业务正在处理“real client cases”，客户把 Open WebUI 当成 self-hosted AI infrastructure 的关键组件。它们都不是 Max395，但证明客户确实会为“本地 AI 一体机、主权 AI 平台、本地知识处理、自托管 LLM 运维”这几类结果买单或形成商业交付。

按**最高证据等级去重**后，本报告纳入：

|口径|数量|含义|
|---|---|---|
|**A1**|**2**|有直接付款或采购金额/订单证据|
|**A2**|**6**|有真实客户使用、交付、上线或第一人称 commercial client deployment 证据|
|**B**|**5**|有购买/配置/商业服务页面，但没有客户成交证据|
|**C**|**2**|有公开采购/外包预算需求，但尚不能证明最终商业交付|
|**精确 Max395/Strix Halo 的 A1/A2**|**4**|Framework、Beelink、GMKtec、Altronis|
|**邻近 A1/A2**|**4**|苏州银行、European Commission/deepset、deepset 70 亿文档、Hossted|
|**精确硬件商业记录，含 B**|**7**|4 个 A 级 + 3 个 B 级|
|**另有精确 Strix Halo 实际生产力/降本旁证**|**1**|AMD/Ansys/HP Z2 Mini G1a，不计收入|

这里有一个特别重要的边界：**Framework 的付款案例只能证明“Max395 硬件卖掉了”，不能证明该客户靠这台机器出售 AI 服务赚钱。** Beelink 和 GMKtec 则进一步证明“买家收到机器后确实拿它跑本地 AI”；只有 Altronis 的公开记录把链条推进到“服务商使用 Strix Halo 为 clients 运行 workload”。

## 精确 Max395 / Strix Halo 的 A 级商业案例

### Framework Desktop Max395/128GB：客户完成付款并进入发货

**① 案例名称：** Framework Desktop Batch 11，Ryzen AI Max+ 395 / 128GB 客户付款。  
**② 完整直接链接：** [https://community.frame.work/t/framework-desktop-batch-11-guild/73886?page=2](https://community.frame.work/t/framework-desktop-batch-11-guild/73886?page=2)  
**③ 来源类型：** Framework 官方社区中的终端客户第一人称付款记录。  
**④ 发布时间：** 2025 年 9 月 23 日。  
**⑤ 卖方：** Framework Computer。  
**⑥ 客户或客户类型：** 社区用户 MSE-6、BNDKT；具体企业身份未公开。  
**⑦ 出售内容：** Framework Desktop / Max395 128GB 配置。  
**⑧ 最终交付物：** 实体 Desktop/Mainboard 系统；付款确认邮件提示即将发货。  
**⑨ 使用硬件：** AMD Ryzen AI Max+ 395，128GB 配置。  
**⑩ 是否明确 Max395/Strix Halo：** **是，明确写 Max 395/128GB。** 用户 Lincoln_Chen 也写明自己订购了 “395 128gb”。

**⑪ 收费方式：** 客户完成订单付款/银行卡扣款；页面还记录另一用户 “I was just charged”。  
**⑫ 公开价格或合同金额：** **实际付款金额未公开**，本研究不拿当时目录价替代真实成交价。  
**⑬ 付款/订单/交付证据：** BNDKT 明确表示已经完成付款，并收到确认邮件称 1–3 个工作日内发货；MSE-6 同日表示已被扣款。  
**⑭ 原文证据：** “**I just completed the payment … So my Max 395/128GB is almost on it’s way.**”  
**⑮ 证据等级：** **A1。** 这是目前最干净的 Max395 直接付款证据之一。

**⑯ 精确硬件还是邻近案例：** **精确 Max395。**  
**⑰ 能否复制到 Max395 商业模式：** **可以，但只直接证明硬件销售。** 可复制成“预装本地 AI 工作站 + 上门/远程部署”的产品，但后半部分的软件服务收入需要另外证明。  
**⑱ 复制所需能力：** 从硬件销售升级到 AI appliance，需要在 Max395/128GB 之上增加可维护的本地推理后端、Web UI/API、模型管理、数据备份、权限管理和售后支持；这些属于商业产品化推导，不是 Framework 此付款记录本身证明的内容。  
**⑲ 仍缺证据：** 发票金额、最终签收、客户具体 AI workload、客户是否借机器取得 AI 服务收入。  
**⑳ 白皮书位置：** **“Max395 已发生真实终端付款：硬件商品化证据”**。

### Beelink GTR9 Pro：机器已交付，并被客户实际作为本地 AI Server 使用

**① 案例名称：** Beelink GTR9 Pro Ryzen AI Max+ 395 本地 AI Server 客户使用。  
**② 完整直接链接：** [https://www.bee-link.com/products/beelink-gtr9-pro-amd-ryzen-ai-max-395](https://www.bee-link.com/products/beelink-gtr9-pro-amd-ryzen-ai-max-395)  
**③ 来源类型：** 制造商官方商品页 + 商品客户评价 + 厂商回复。  
**④ 发布时间：** 商品页当前可访问；可解析页面没有给出这些评论的绝对发布日期，因此写作 **评论日期未公开**。  
**⑤ 卖方：** Beelink。  
**⑥ 客户：** 页面可识别客户包括 Artur Wróblewski、Dejan 等个人购买者/本地 AI 用户。  
**⑦ 出售内容：** GTR9 Pro AI Mini PC。  
**⑧ 最终交付物：** 实体 Max395 工作站。客户描述了收到货物、软件配置和实际使用。  
**⑨ 硬件：** Ryzen AI Max+ 395；官方页面当前配置为高内存本地 AI PC。  
**⑩ 是否明确 Max395：** **是。**

**⑪ 收费方式：** 一次性硬件购买。  
**⑫ 公开价格：** 页面当前显示约 **US$4,349**；这是当前挂牌价，**不等于评论客户历史实付金额**。  
**⑬ 交付/客户使用证据：** Artur 描述等待发货和 DHL 交付，并报告 Ubuntu/Ollama 使用情况；Dejan 将机器直接描述为自己的 local AI server，Beelink 官方回复也针对其“local AI server”使用体验。  
**⑭ 原文证据：** “**the custom ‘yours only’ AI server produces excellent results!**”  
**⑮ 证据等级：** **A2**，因为有实际客户评价、到货和本地 AI 使用；没有公开付款凭证，所以不升 A1。

**⑯ 类型：** **精确 Max395。**  
**⑰ 能否复制：** **高度可复制。** 它直接证明“高内存 Max395 小型机作为本地 AI server”是实际买家在做的事情。  
**⑱ 复制能力：** 客户记录直接涉及 Ubuntu、Ollama，并有人建议 Lemonade AI Server；要卖给企业，还应补认证、稳定 API、备份、监控和远程支持。后四项是从消费级设备向企业 appliance 迁移的工程要求。  
**⑲ 缺证据：** 客户成交价、是否企业采购、是否用机器向第三方收费、每月创造收入。  
**⑳ 白皮书位置：** **“Max395 实机已经进入本地 LLM Server 使用场景”**。

### GMKtec EVO-X2：官方客户评价明确用于本地 MoE/LLM

**① 案例名称：** GMKtec EVO-X2 Max395 本地 AI 客户交付。  
**② 完整直接链接：** [https://de.gmktec.com/products/gmktec-evo-x2-amd-ryzen%E2%84%A2-ai-max-395-mini-pc-1](https://de.gmktec.com/products/gmktec-evo-x2-amd-ryzen%E2%84%A2-ai-max-395-mini-pc-1)  
**③ 来源类型：** GMKtec 官方商品页和客户评论。  
**④ 发布时间：** 商品页当前状态截至 2026-08-13；页面解析的客户评论没有显示绝对日期。  
**⑤ 卖方：** GMKtec。  
**⑥ 客户：** Anders Hansson、Dario、Roger Miranda Perez 等商品评价用户。  
**⑦ 出售内容：** EVO-X2 Ryzen AI Max+ 395 Mini PC。  
**⑧ 最终交付物：** Max395 实体 Mini PC。  
**⑨ 硬件：** Max+ 395，页面提供不同内存配置；当前页面价格从约 **€1,959.99** 起。  
**⑩ 是否明确 Max395：** **是。**

**⑪ 收费方式：** 一次性硬件购买。  
**⑫ 金额：** 当前商品页价格可见，但**客户真实历史支付金额未公开**。  
**⑬ 客户/交付证据：** 页面显示 **183 条 customer reviews**；Dario 明确称 EVO-X2 能运行通常需要强工作站的大模型，Roger 直接报告本地 MoE 模型实际运行结果。  
**⑭ 原文证据：** “**Increhible para IA MoE local. Qwen3.6-35B a 40 tokens/s**”  
**⑮ 等级：** **A2**。评价本身满足你的“客户评价/客户使用”条件，但没有付款金额证据。

**⑯ 类型：** **精确 Max395。**  
**⑰ 可复制：** **是。** 特别适合复制为“预装 local LLM + Web UI + RAG”的小型企业 AI appliance。  
**⑱ 所需能力：** 本地模型推理、量化模型管理、向量检索、Web/API 服务、磁盘和备份、系统监控；企业出售时还需要权限与审计。Max395 的高统一内存主要承担模型常驻和本地推理；这部分商业化架构属于基于实际 workload 的迁移推导。  
**⑲ 缺证据：** 企业客户身份、付款订单、由这台设备产生的服务收入。  
**⑳ 白皮书位置：** **“消费/Prosumer Max395 设备已被客户实际购买用于 local LLM”**。

### Altronis：目前最接近“拿 Strix Halo 给客户做项目并收费”的公开证据

**① 案例名称：** Altronis Strix Halo client deployments。  
**② 完整直接链接：**  
[https://altronis.sg/blog/local-ai-workstation-2026](https://altronis.sg/blog/local-ai-workstation-2026)  
[https://altronis.sg/services](https://altronis.sg/services)  
[https://altronis.sg/private-llm-sg](https://altronis.sg/private-llm-sg)  
**③ 来源类型：** 服务商第一人称生产部署记录 + 商业服务页。  
**④ 发布时间：** Local AI Workstation 文章发布于 **2026 年 5 月 3 日**，更新至 **2026 年 8 月 4 日**。  
**⑤ 卖方：** Altronis，Singapore AI/technology consultancy。  
**⑥ 客户：** **客户未公开**；服务商明确称为 clients / own clients。  
**⑦ 出售内容：** AI infrastructure & deployment、private/on-prem LLM、RAG、知识图谱/向量库、monitoring、updates、retraining，以及本地 AI workload 部署。  
**⑧ 交付物：** 在客户或受控基础设施上运行的模型、authenticated gateway、RAG/数据层、runbook，以及可选 managed-ops。

**⑨ 硬件：** 服务商明确说使用过 **Framework Desktop 和 GMKtec EVO-X2** 做 client deployments；其 private-LLM 页面明确列 Ryzen AI Max+ 395 128GB 一类平台。  
**⑩ 是否 Max395/Strix Halo：** **明确是。**  
**⑪ 收费方式：** 咨询/部署项目，之后可接 managed-ops retainer；公开页面未给固定报价。  
**⑫ 金额：** **金额未公开。**  
**⑬ 客户/交付证据：** Altronis 明确说两款 Strix Halo 系统已用于 client deployments，也明确称在其上“shipped real client workloads”，并称其生产 endpoint 是为 own clients 运行。  
**⑭ 原文证据：** “**We have used the Framework and the EVO-X2 in client deployments and would order either again.**”  
**⑮ 等级：** **A2。** 这是第一人称商业服务商的真实客户部署声明；由于没有客户名称、合同或发票，不能升 A1。

**⑯ 类型：** **精确 Strix Halo / Max395。**  
**⑰ 可复制：** **非常高。** 这是本报告中最直接证明“Max395 不只是卖电脑，而是可以作为咨询公司的客户交付基础设施”的案例。  
**⑱ 软件/硬件能力：** Altronis 披露的 workload 包括文本推理、视觉模型 OCR/抽取、embeddings、image generation、agent/news pipeline；服务页进一步涉及 RAG、vector database/knowledge graph、authenticated gateway、monitoring、updates 和 runbook。也就是说 Max395 的角色不是“AI 商品本身”，而是**本地模型推理与多模型 workload 的执行节点**；真正可收费的是上面的数据接入、RAG、Agent、权限、API、运维和业务流程。  
**⑲ 缺证据：** 客户名称、付款金额、合同、发票、具体项目对应哪一台 Framework/EVO-X2、每个 workload 的客户收费。  
**⑳ 白皮书位置：** **核心案例：“Strix Halo 从硬件进入客户项目交付链条”**。这应该放在白皮书最前面的商业可行性章节，而不是跑分章节。

上述四个案例应当区别对待。Framework 是**付款证据**，Beelink/GMKtec 是**客户到货并实际做 local AI 的证据**，Altronis 才是**服务商拿 Strix Halo 跑 client workload 的证据**。把四者串起来，可以证明“设备存在真实买家 → 买家确实拿来跑本地 AI → 已有服务商把它纳入客户交付”；但现有公开资料仍不能证明某个 Max395 RAG/OCR/Agent 项目具体收了多少钱。

## 邻近 A 级案例与 Max395 的迁移边界

### 苏州银行“大模型训推一体机”：公开 1,788 万元采购金额

**① 案例名称：** 苏州银行 2024 年大模型训推一体机货物采购。  
**② 直接链接：** [https://finance.sina.com.cn/wm/2025-01-15/doc-inefachx7123199.shtml](https://finance.sina.com.cn/wm/2025-01-15/doc-inefachx7123199.shtml)  
**③ 来源类型：** 零壹财经/零壹智库金融大模型中标项目统计，经新浪财经刊载；**属于二手行业数据来源，不是采购人原始公告**。  
**④ 发布时间：** 2025 年 1 月 15 日；所述采购发生于 2024 年。  
**⑤ 卖方：** 讯飞智元（科大讯飞子公司）。  
**⑥ 客户：** 苏州银行。  
**⑦ 出售内容：** 大模型**训推一体机货物**。  
**⑧ 交付物：** 大模型训练/推理一体机。  
**⑨ 硬件：** 报道没有公开 GPU/CPU/内存明细。  
**⑩ Max395：** **否。邻近案例。**

**⑪ 收费方式：** 企业采购/投标。  
**⑫ 公开金额：** **投标价格人民币 1,788 万元。**  
**⑬ 证据：** 报道明确列讯飞智元中标该大模型训推一体机货物采购项目，并给出投标价格。  
**⑭ 原文：** “**前者投标价格为1788万**”。  
**⑮ 等级：** **A1**，因为存在明确的中标采购及金额；但它不是付款到账凭证，实际结算情况未公开。

**⑯ 类型：** 邻近一体机商业采购。  
**⑰ 是否可复制到 Max395：** **只能复制低并发/部门级 inference appliance 商业模式，不能把 Max395 当作这套银行级训推系统的等价硬件。**  
**⑱ 迁移条件：** 若目标变为中小企业本地推理、RAG、OCR、Agent，可用单台/少量 Max395 节点；若需求包含大模型训练、高并发、HA 和银行级冗余，则通常需要服务器级多节点架构。这个判断是能力迁移推导，不是原案例硬件信息。  
**⑲ 缺证据：** 原始中标公告、最终合同额、付款、验收、实际服务器明细、是否完全离线。  
**⑳ 白皮书位置：** **“邻近市场的真实采购金额：企业愿意为大模型一体机付多少钱”**。

这是本轮研究中很重要的金额锚点，但绝不能写成“Max395 一体机卖了 1,788 万元”。正确写法只能是：**大模型训推一体机这一商业类别已经出现千万元级银行采购；Max395 能否切入其中的小型化/部门级子市场，需要另行论证。** 

### European Commission × deepset：self-hosted Sovereign AI 已正式上线

**① 案例名称：** AI@EC Sovereign AI Platform。  
**② 链接：** [https://www.deepset.ai/case-studies/european-commission-deepset](https://www.deepset.ai/case-studies/european-commission-deepset)  
**③ 来源类型：** deepset 官方客户案例；客户为 European Commission，且页面含 Commission 负责人评价。  
**④ 发布时间：** 页面当前未显示清晰的绝对发布日期，因此记为 **发布时间未公开**。  
**⑤ 卖方：** deepset。  
**⑥ 客户：** European Commission，具体共建单位 DG DIGIT。  
**⑦ 出售内容：** self-hosted sovereign GenAI application/agent platform，基于 Haystack Enterprise Platform。  
**⑧ 最终交付：** AI@EC 平台，供 Commission 部门构建、部署和治理 agents、knowledge management、summarisation、chatbots、multilingual policy analysis 等。  
**⑨ 硬件：** Commission-managed data-centre infrastructure，具体处理器/GPU 未公开。  
**⑩ Max395：** **否。邻近案例。**

**⑪ 收费方式：** 商业 enterprise platform + joint development；合同结构和价格未公开。  
**⑫ 金额：** **金额未公开。**  
**⑬ 交付证据：** 平台已经 live；公开指标包括 **68 builders、29 Directorates-General、316 条 production 或 ready-for-rollout pipelines**；页面明确说系统 entirely runs on Commission-managed infrastructure。  
**⑭ 原文：** “**the Commission partnered with deepset to jointly develop the self-hosted AI@EC Platform**”  
**⑮ 等级：** **A2。** 有可识别大型客户、明确 self-hosted 系统、共建、上线和生产指标，但没有公开付款金额。

**⑯ 类型：** 邻近 self-hosted/sovereign AI。  
**⑰ Max395 可复制程度：** **业务模式可以复制，规模不可直接复制。** Max395 适合做某个部门、办公室或 SME 的 sovereign AI node，而不是单机替代 Commission 的机构级平台。  
**⑱ 技术条件：** 本地 model gateway、RAG/agents、RBAC/SSO、审计、guardrails、日志、CI/CD、版本管理、备份和多用户 Web/API；企业级扩展还需高可用。AI@EC 的公开架构证明这些平台层是商业交付的一部分。  
**⑲ 缺证据：** deepset 合同金额、硬件采购清单和实际推理节点配置。  
**⑳ 白皮书位置：** **“从一台 AI workstation 向企业 sovereign AI platform 升级：真正卖的是治理与运维层”**。

### deepset × Quest1：客户要求在现有 GPU 上本地处理 70 亿文档记录

**① 名称：** Embedding 7 billion documents locally。  
**② 链接：** [https://www.deepset.ai/blog/ai-deployment-options-quest1](https://www.deepset.ai/blog/ai-deployment-options-quest1)  
**③ 来源：** deepset 第一人称客户项目记录。  
**④ 日期：** **2024 年 12 月 13 日**。  
**⑤ 卖方：** deepset + Quest1。  
**⑥ 客户：** knowledge-management customer，**客户名称未公开**。  
**⑦ 出售内容：** 本地 AI 架构/模型选择/硬件适配与 benchmarking 服务。  
**⑧ 最终交付：** 对客户现有 NVIDIA GPU 是否能够处理数十亿 documents 的评估，并帮助客户选定合适 embedding model。  
**⑨ 硬件：** 客户现有 NVIDIA GPUs，型号未公开。  
**⑩ Max395：** **否。**

**⑪ 收费方式：** 企业 AI implementation/consulting；金额未公开。  
**⑫ 金额：** **金额未公开。**  
**⑬ 交付证据：** deepset 说明其与 Quest1 为该 customer 实际执行 benchmarking exercise，并帮助客户识别最合适模型。  
**⑭ 原文：** “**They wanted to index their large knowledge base of seven billion library records using an embedding model.**”  
**⑮ 等级：** **A2**；有真实 customer problem 和已经执行的咨询/benchmarking deliverable，但无付款资料。

**⑯ 类型：** 邻近本地 RAG/embedding 服务。  
**⑰ 迁移到 Max395：** **可以复制“硬件评估 + 本地知识库部署”这一服务，但不能合理声称一台 Max395 能替代 70 亿记录项目的现有 GPU 基础设施。**  
**⑱ 所需能力：** document ingestion、embedding pipeline、batch processing、vector DB、benchmark/evaluation、model selection，以及对客户数据规模和 SLA 的 sizing。Max395 更现实的产品是中小规模知识库或边缘节点。  
**⑲ 缺证据：** 客户身份、项目金额、最终 production 配置以及项目是否持续运维。  
**⑳ 白皮书位置：** **“卖本地 AI 不一定卖模型：硬件 sizing、embedding 和数据迁移本身就是可收费服务”**。

### Hossted：self-hosted Open WebUI 已是“real client cases”的咨询业务

**① 名称：** Hossted Open WebUI self-hosted production support。  
**② 链接：** [https://www.upwork.com/freelance-jobs/apply/Open-WebUI-Engineer-Self-Hosted-LLM-Platform-Deployment-Production-Support_~022069931536353701997/](https://www.upwork.com/freelance-jobs/apply/Open-WebUI-Engineer-Self-Hosted-LLM-Platform-Deployment-Production-Support_~022069931536353701997/)  
**③ 来源：** Hossted 在 Upwork 发布的招聘/项目职位页；其中直接描述其现有 client consulting practice。  
**④ 日期：** 页面截至 2026-08-13 显示 “Posted 2 months ago”，没有精确绝对日期。  
**⑤ 卖方：** Hossted.com。  
**⑥ 客户：** 使用 self-hosted Open WebUI 的企业客户，名称未公开。  
**⑦ 出售内容：** Open WebUI self-hosted LLM deployment、故障排除、integration health、performance optimisation、RAG、authentication、数据库迁移、production support。  
**⑧ 交付物：** 修复/稳定后的 production Open WebUI stack 和持续咨询支持。  
**⑨ 硬件：** 未公开；后端可以连接 Ollama、vLLM、LiteLLM 等。  
**⑩ Max395：** **否。邻近服务。**

**⑪ 收费方式：** Hossted 对客户的收费未公开；其为扩充交付能力而招聘专家，Upwork 给工程师的预算是 **US$40–70/hour**，这个数字是**劳动力采购成本，不是 Hossted 客户价**。  
**⑫ 客户合同金额：** **金额未公开。**  
**⑬ 交付证据：** 招聘正文明确称工程师将处理 “real client cases through Hossted.com's open-source consulting practice”，并说这些客户正在把 Open WebUI 作为 self-hosted AI infrastructure 的关键组成部分。  
**⑭ 原文：** “**supporting clients who run Open WebUI as a critical component of their self-hosted AI infrastructure.**”  
**⑮ 等级：** **A2**，原因是服务商直接承认已存在真实 self-hosted 客户环境；但不能把招聘时薪当成客户收入。

**⑯ 类型：** 邻近 local/self-hosted AI managed support。  
**⑰ 可迁移到 Max395：** **非常容易。** Max395 只是 inference node，收费对象可以是“Open WebUI/Ollama/模型端点/RAG 不稳定，我替你维护”。  
**⑱ 技术条件：** Linux、Docker/Kubernetes、reverse proxy、WebSocket、TLS、Ollama/vLLM-compatible endpoints、RAG、PostgreSQL/vector DB、SSO/RBAC、monitoring。招聘页本身列出了这些生产问题。  
**⑲ 缺证据：** 客户名称、客户收费、Max395 使用情况。  
**⑳ 白皮书位置：** **“维护和 production support 本身是独立可售 SKU，不必只靠卖机器赚钱”**。

### AMD × Ansys × HP：真实 Max+ PRO 395 生产力降本，但不算收入

这条必须单列，因为它很强，却容易被错误包装成“商业收入”。

**① 名称：** AMD engineers / Ansys Discovery / HP Z2 Mini G1a。  
**② 链接：** [https://www.amd.com/en/resources/case-studies/ansys.html](https://www.amd.com/en/resources/case-studies/ansys.html)  
**③ 来源：** AMD 官方客户/技术案例。  
**④ 日期：** 对应 Ansys Discovery 2026 R1 工作流。  
**⑤ “卖方”：** Ansys/HP 是商业产品提供方，但页面**没有证明 AMD 为本案例采购付款**。  
**⑥ 使用方：** AMD thermal engineer Eurydice Kanimba。  
**⑦ 内容：** 本地高性能工程 simulation。  
**⑧ 交付：** 在本地 workstation 上快速完成高容量 thermal/fluid simulation。  
**⑨ 硬件：** HP Z2 Mini G1a，**Ryzen AI Max+ PRO 395**。  
**⑩ 是否 Strix Halo：** **是，Max+ PRO 395。**

**⑪ 收费方式：** 未披露。  
**⑫ 金额：** **金额未公开。**  
**⑬ 实际效果：** 过去 CPU workflow 需要数小时的 simulation，现在在 HP Z2 Mini G1a 上可在 **10–15 分钟**完成；这是明确、可量化的生产力提升。  
**⑭ 原文：** “**Simulations on her HP Z2 Mini G1a workstation now finish in just 10 to 15 minutes**”  
**⑮ 等级：** **不计 A1/A2 收入；计为“实际使用/降本旁证”。** 因为来源没有订单、付款或 HP→AMD 商业交付凭证。

**⑯ 类型：** 精确 Strix Halo PRO 变体，非 AI 服务收入案例。  
**⑰ 可复制：** 对工程咨询、CAE、设计服务来说可复制成“使用本地工作站完成客户委托”的生产工具，但不能把这一 AMD 内部案例写成已有外部服务收入。  
**⑱ 需要能力：** 专业 simulation 软件及对应 GPU/ROCm 支持；Max395 在这里承担的主要不是 LLM，而是**统一内存/iGPU 计算和大模型级内存容量的本地计算工作负载**。  
**⑲ 缺证据：** 设备采购价、采购合同、节省的人工成本货币值、对外客户收入。  
**⑳ 白皮书位置：** **“降本而非收入：Strix Halo 能把云/HPC 或高端 GPU 工作负载移到个人工作站”**。

## B 级收费产品、C 级需求和被排除的边界证据

下面的 B 级记录只能证明“有人已经把这种东西放到货架或服务目录里收费”，**不能证明有人购买**。这恰好是很多 Max395 宣传文章最容易跨越的证据鸿沟。

|案例|商业事实与直接链接|硬件与 Max395 角色|收费/证据|等级、复制条件与缺口|
|---|---|---|---|---|
|**AMD Ryzen AI Halo Developer Platform**|①名称：AMD Ryzen AI Halo Developer Platform；② [https://www.amd.com/en/products/processors/desktops/ryzen/ryzen-ai-halo.html](https://www.amd.com/en/products/processors/desktops/ryzen/ryzen-ai-halo.html)；③ AMD 官方产品页；④页面当前；⑤卖方 AMD/零售渠道；⑥客户未公开；⑦出售开发平台；⑧交付整机开发平台。|⑨ Max+ 395、128GB；⑩明确 Max395；它定位为本地 AI development/inference 平台。AMD 页面还明确给出 full ROCm support。|⑪一次性设备购买；⑫ AMD 页面列示 2026 年 5 月参考零售价约 **US$3,999**；⑬无客户付款；⑭原文：“**AMD Ryzen AI Halo Developer Platform with Ryzen AI Max+ 395 processor with full ROCm software support.**”|⑮**B**；⑯精确；⑰可包装成企业本地 AI appliance；⑱需加 UI/API/RAG/权限/运维；⑲缺客户订单；⑳白皮书“官方商业基准设备”。|
|**MINIX ER939-AI Pro**|①名称如左；② [https://www.minix.com.hk/products/minix-er939-ai-pro-mini-pc](https://www.minix.com.hk/products/minix-er939-ai-pro-mini-pc)；③厂商产品页；④页面当前；⑤MINIX；⑥客户未公开；⑦AI Mini PC；⑧实体整机。|⑨ Ryzen AI Max+ 395；⑩明确精确芯片。|⑪一次性购买/B2B 联系；⑫页面显示 **US$3,500**，同时显示 sold out，并提供 B2B 联系方式；⑬sold out 本身**不能被我当作付款证明**；⑭原文：“**MINIX ER939-AI Pro Mini PC**”。|⑮**B**；⑯精确；⑰可用于预装 AI appliance；⑱需要软件栈和售后；⑲没有客户或订单证据；⑳“Max395 现成整机价格带”。|
|**Corsair Max395 AI Workstation**|①名称：Corsair Ryzen AI Max+ 395 Radeon 8060S AI Workstation；② [https://www.pccasegear.com/products/73392/corsair-ryzen-ai-max-395-radeon-8060s-ai-workstation](https://www.pccasegear.com/products/73392/corsair-ryzen-ai-max-395-radeon-8060s-ai-workstation)；③澳洲零售商商品页；④当前；⑤Corsair/retailer；⑥客户未公开；⑦AI workstation；⑧预装整机。|⑨ Max+ 395、128GB/4TB 配置页面；⑩明确 Max395；页面将 Model HQ/本地 AI 类软件作为应用方向。|⑪整机零售；⑫本研究从已打开可解析正文中没有取得可安全引用的实际成交价，因此写 **金额未核实**；⑬无购买客户证据；⑭原文：“**Corsair Ryzen AI Max+ 395 Radeon 8060S AI Workstation**”。|⑮**B**；⑯精确；⑰适合“工作站+预装模型”的商品形式；⑱需追加企业软件和 SLA；⑲无客户成交/用途证明；⑳“商业整机供应侧”。|
|**Server Room Ryzen AI dedicated server**|①名称如左；② [https://serverroom.net/ryzenai](https://serverroom.net/ryzenai)；③托管/裸机服务器商业页面；④当前；⑤Server Room；⑥客户未公开；⑦dedicated AI server；⑧预配置环境和 expert support。|⑨页面写 Ryzen AI Max family、最高 128GB，但已打开正文具体处理器示例为 HX 370；⑩**没有足够证据把该页面认定为 Max+395**。|⑪服务器商业配置/托管；⑫公开页面引导配置，具体 Max395 月费没有在已打开正文中得到核实；⑬无客户实例；⑭“**Pre-configured with LLM Studio and Ollama for immediate AI development without custom setup.**”|⑮**B**；⑯邻近 Ryzen AI 商业托管；⑰商业模式可迁移；⑱需远程管理、网络、备份、SLA；⑲最关键缺口就是处理器精确型号和客户；⑳“AI workstation → dedicated hosting”。|
|**Primcast Ryzen AI LLM Hosting**|①名称如左；② [https://primcast.com/ryzenai](https://primcast.com/ryzenai)；③托管服务产品页；④当前；⑤Primcast；⑥客户未公开；⑦private LLM endpoint、RAG-ready API、internal copilots/agents；⑧dedicated environment。|⑨ Ryzen AI family，128GB 类配置；⑩已打开页面**没有明确 Max+395 型号**，所以不能列为精确案例。|⑪按月 dedicated-resource pricing + managed-service add-ons；⑫页面确认 straightforward monthly pricing，但具体 Max395 数字未公开于已打开正文；⑬无客户成交；⑭“**Host a private model endpoint, build internal copilots, or run agents with predictable latency.**”|⑮**B**；⑯邻近；⑰非常适合复制成 Max395 月租/private endpoint；⑱需 stable API、VPN/TLS、monitoring、storage、support；⑲客户/具体硬件/真实 MRR 均缺；⑳“Max395 订阅式算力和 private API”。|

这五个 B 级结果尤其说明一个问题：**卖“机器”已经非常成熟，卖“Max395 上的业务结果”公开证据明显更稀缺。** AMD、MINIX、Corsair 可以证明 Max395 被商品化；Server Room 和 Primcast 可以证明“private endpoint / Ollama / RAG-ready dedicated infrastructure + support”本身已经被包装成商业 SKU，但后两者的已打开页面不足以证明服务器一定使用 Max+395。

### 中国信达企业知识库项目：已经选出中标候选人，但我不升级成 A1/A2

**① 名称：** 中国信达 AI 大语言模型企业知识库试点建设项目。  
**② 链接：** [https://www.cinda.com.cn/home/wap/cn/xdjt/xdjtpd/cgxxgs/20240723/261878.shtml](https://www.cinda.com.cn/home/wap/cn/xdjt/xdjtpd/cgxxgs/20240723/261878.shtml)  
**③ 来源：** 中国信达官方采购信息。  
**④ 日期：** 2024 年 7 月 23 日。  
**⑤ 潜在卖方：** 第 1 包中标候选人科大讯飞；第 2 包上海道客网络。  
**⑥ 买方：** 中国信达资产管理股份有限公司。  
**⑦ 内容：** 第 1 包“大模型及知识库开发实施”，第 2 包“算力租赁服务”。  
**⑧ 预期交付：** 企业知识库开发实施 + 算力。  
**⑨ 硬件：** 未公开。  
**⑩ Max395：** 否。

**⑪ 收费：** 招投标/采购。  
**⑫ 金额：** **金额未公开。**  
**⑬ 证据：** 官方写的是“中标候选人”，而不是我可以验证的最终合同、付款或验收。  
**⑭ 原文：** “**中标内容：大模型及知识库开发实施**”。  
**⑮ 等级：** **C**，这里我采用比字面“中标”更保守的处理：由于本轮没找到最终合同/付款/验收，不能写成已完成商业交付。

**⑯ 类型：** 邻近需求。  
**⑰ 可复制到 Max395：** SME/部门级可以；大型资管机构正式生产环境需要进一步 sizing。  
**⑱ 条件：** 本地模型、RAG、权限、审计、知识 ingestion、API、算力管理。  
**⑲ 缺证据：** 最终中标结果、金额、合同、验收及部署架构。  
**⑳ 白皮书：** **“金融企业正在明确采购大模型+知识库开发实施”**。

### Upwork：本地/可本地部署 RAG 客服系统预算 US$15–35/小时

**① 名称：** Custom RAG Chatbot for Internal Team and Customer Support。  
**② 链接：** [https://www.upwork.com/freelance-jobs/apply/Custom-RAG-Chatbot-for-Internal-Team-and-Customer-Support_~022081494528025423474/](https://www.upwork.com/freelance-jobs/apply/Custom-RAG-Chatbot-for-Internal-Team-and-Customer-Support_~022081494528025423474/)  
**③ 来源：** Upwork 真实项目需求页。  
**④ 日期：** 页面截至 2026-08-13 显示 Posted 2 weeks ago。  
**⑤ 卖方：** 尚未确定的 freelancer/agency。  
**⑥ 买方：** 澳大利亚中型房地产企业类型客户。  
**⑦ 内容：** internal + customer-facing RAG chatbot。  
**⑧ 交付：** working chatbot、backend API、Web UI、document ingestion、vector DB、admin、RBAC、citations、human escalation、logging、QA、source code、Docker/local deployment setup、handover。  
**⑨ 硬件：** 未指定。  
**⑩ Max395：** 否。

**⑪ 收费：** **US$15–35/hour**，预计 1–3 个月。  
**⑫ 金额：** 没有固定总价。  
**⑬ 需求证据：** 50+ proposals，但页面只显示 interviewing 1，并没有证明项目已经 hire/付款。  
**⑭ 原文：** “**Docker or local deployment setup**”  
**⑮ 等级：** **C**。它证明客户愿意为完整 RAG 交付寻找供应商和支付小时费率，但不证明已成交。

**⑯ 类型：** 邻近需求；而且**不能写成已经决定采用 local LLM**，因为需求也接受 OpenAI、Claude 等模型。  
**⑰ Max395 可复制：** 很高，只要把云端模型选项替换为本地量化模型/embedding，并把 Docker stack 放到 Max395。  
**⑱ 条件：** FastAPI、Web UI、Qdrant/pgvector 类 vector store、document parser、RBAC、evaluation、Docker、local model endpoint。  
**⑲ 缺证据：** hire、付款、最终模型和实际硬件。  
**⑳ 白皮书：** **“RAG 成品的客户需求和小时收费锚点”**。

还有一个值得记录、但**没有计入本地 AI A1** 的边界证据：2026 年 7 月的 Upwork AML/CTF knowledge-assistant 项目公开 **US$1,500 fixed price**，页面已经显示 **Hires: 1**，因此“RAG assistant 有人实际雇人做”这点非常强；但项目描述并没有要求 local/offline model，所以按照你的“云端 API 案例不写成本地部署案例”规则，我没有把它计入本地 AI A1/A2 数量。它只能作为 RAG 服务的价格/成交旁证。

同理，我没有把单纯的开源教程、技术 demo、模型跑分或“支持商用”的产品宣传升级成 B/A，也没有因为商品页显示 sold out 就推断“已经卖出多少台”。这正是为什么最终 A 级数量远低于网上能搜索到的 Max395 内容数量。

## 最适合 Max395 用户出售的商业产品与服务

从现有证据看，Max395 真正容易赚钱的方向不是“向客户卖 395 的 TOPS、token/s 或 unified memory”，而是把这块硬件隐藏在一个**有验收标准的交付物**后面。Altronis、deepset、Hossted、Upwork RAG 需求以及一体机采购共同表明，企业买的是“本地可用、数据不出域、能接文档/业务系统、有 UI/API、出问题有人管”的结果。

|优先级|最适合出售的产品/服务|典型客户|最终交付物|最合理收费单位|证据性质|
|---|---|---|---|---|---|
|**高**|**预装本地 AI 工作站 / AI Appliance**|律所、会计师事务所、咨询公司、设计/工程公司、SME IT 部门|Max395 整机 + 本地模型 + Web UI + 基础 API + 文档|**每台设备 + 一次部署费**|Framework A1 证明有人付钱买硬件；Beelink/GMKtec A2 证明买家确实拿 Max395 做 local AI。|
|**高**|**企业私有知识库 / RAG**|法务、金融、工程、房地产、合规企业|文档 ingestion、向量索引、RAG chat、引用、权限、后台|**按项目 + 文档量/用户数 + 年维护**|deepset/EC A2；Upwork 有具体预算需求；中国信达有正式采购。|
|**高**|**企业内部本地 OpenAI-compatible API**|有内部软件开发团队、不能把数据发外网的企业|localhost/LAN model endpoint、auth、logging、model routing|**部署费 + 每月运维/SLA**|Altronis A2；Primcast B 明确把 private endpoint 当商品。|
|**高**|**本地 AI 运维、升级和故障支持**|已经买了 AI PC、Open WebUI、Ollama 的公司|模型升级、故障修复、备份、监控、SSO、performance tuning|**小时包 / 月度 retainer / 年度支持合同**|Hossted A2 最直接；Server Room、Primcast 都把 expert/managed support 商品化。|
|**中高**|**OCR + 文档抽取 + 结构化输出**|会计、保险、律所、工程、物流|PDF/扫描件 → JSON/Excel/DB + 可审阅 UI|**每千页 / 每批文件 / 项目费**|Altronis 明确在 Strix Halo workload 中运行 VLM OCR/extraction；但尚无公开的 Max395 OCR 单项收费案例，因此收费单位是商业设计推导。|
|**中高**|**Agent / RPA / MCP 工作流**|后台运营、客服、采购、研究、销售支持|Agent + tools + approval flow + logs + API/MCP endpoint|**每工作流实施费 + 月维护**|AI@EC 已有 agents/pipelines；Altronis 有 production agent workload；但 Max395 MCP 单项收入仍缺直接 A1。|
|**中**|**网页采集 + 竞争情报 + 自动报告**|投资、咨询、营销、贸易企业|定时采集、去重、local summarisation、日报/周报/PDF|**按数据源/月 / 月度 retainer**|Altronis 明确运行 news-pipeline agent，但没有公开证明其作为独立 Max395 SKU 收费，因此属于“真实 workload + 商业模式推导”。|
|**中**|**本地客服/内部 help-desk bot**|数据敏感 SME、专业服务公司|RAG chatbot + website/Teams/Slack + human escalation|**一次实施 + 渠道/用户/月维护**|Upwork 的完整客服 RAG 需求列出了实际交付物和 US$15–35/h 预算；Primcast 也把 customer-facing AI 列为 dedicated LLM use case，但尚无 Max395 A1。|
|**中**|**本地转录、翻译、字幕批处理**|视频工作室、研究团队、律所、会议服务商|audio/video → transcript/SRT/translated SRT|**每音频小时/分钟**|**本轮没有找到满足 A1/A2 的 Max395 公开收费案例。** 这是从本地多模态工作站能力延伸的商业推导，不能写成已有收入。|
|**中**|**本地内容/代码生产工作站服务**|agency、开发团队、研究/内容部门|文案、报告、代码、图片批量生产 pipeline|**按席位/月、项目、retainer**|Altronis 的 Strix Halo 生产 endpoint 明确会生成 blog drafts，并运行多个 agent workload，但“给客户卖内容生成”本身没有公开付款证据，因此只能算迁移推导。|

从“最容易拿到第一笔钱”的角度，排序并不是从最复杂的 Agent 开始。我认为证据支持的实际顺序更像是：**设备交付 → 私有 RAG → 本地 API → 维护支持 → OCR/文档自动化 → Agent/RPA**。原因是前四种已经分别有 Max395 硬件付款、Max395 local-AI 客户、self-hosted 企业客户和 maintenance consulting 的直接证据，而完整 Agent/MCP/A2A 在 Max395 上的公开付费证据还明显较弱。这个排序是对上述证据的商业推断，不是某一家公司的收入排名。

对 Max395 来说，最有价值的定位因此不是“便宜 GPU 服务器”，而是**一台可以同时承载模型、embedding、RAG、OCR/VLM、Agent orchestration 和内部 API 的单节点客户 appliance**。Altronis 已经提供了最接近这一形态的实证：同一 Strix Halo 节点承担 text inference、VLM/OCR/extraction、embeddings、image generation 和 agent/news workload；而 deepset、Hossted 的案例说明客户真正愿意付钱的上层价值在数据接入、治理、故障支持和 production reliability。

## 汇总统计、直接证据与能力推导

### 最终数量

采用“同一商业事实只按最高等级计算，不把 B 同时算 A，不把转载重复计数”的口径：

|项目|最终数量|构成|
|---|---|---|
|**A1 案例**|**2**|Framework Max395 客户明确付款；苏州银行大模型训推一体机中标且公开 1,788 万元投标价。|
|**A2 案例**|**6**|Beelink、GMKtec、Altronis、European Commission/deepset、deepset 70 亿记录项目、Hossted self-hosted OpenWebUI 客户支持。|
|**B 级收费/购买产品**|**5**|AMD Halo Developer Platform、MINIX、Corsair AI Workstation、Server Room、Primcast。|
|**C 级需求**|**2**|中国信达知识库项目按保守口径处理；Upwork custom RAG local-deployment 需求。|
|**精确 Max395/Strix Halo A1+A2**|**4**|Framework、Beelink、GMKtec、Altronis。|
|**邻近 A1+A2**|**4**|苏州银行、AI@EC、70 亿文档 local embedding、Hossted。|
|**精确 Max395 商业记录含 B**|**7**|上述 4 个 A 级，加 AMD Halo、MINIX、Corsair 三个 B。|
|**精确 Strix Halo 降本/实际工作流旁证**|**1**|AMD/Ansys/HP Z2 Mini G1a，Max+ PRO 395；不计收入。|

因此，如果白皮书标题写“**已有 Max395 付费案例**”，最安全的数字不是七个、八个或所有商品页数量，而是：

> **公开可核实的 Max395/Strix Halo A1/A2 商业案例，本轮找到 4 个；其中明确直接付款 1 个，商业交付/客户实际使用 3 个。**

其中真正涉及**“服务商拿 Strix Halo 为 clients 跑 workload”**的公开证据，目前最强的是 Altronis；Framework 的 A1 是硬件付款，Beelink/GMKtec 的 A2 是购买后的本地 AI 使用。

### 可以在白皮书中写成“有直接证据”的结论

**Max395 已经有人实际付钱购买。** Framework 社区用户明确说完成了 Max395/128GB 订单付款，另一用户明确说被扣款，并有即将发货信息。这是直接 A1，不是价格页推断。

**Max395 机器已经被实际交付并作为本地 AI server 使用。** Beelink 客户报告设备到货后使用 Ollama/Lemonade 类本地栈；GMKtec 官方商品页的用户明确报告 local MoE/Qwen workload。

**已经有咨询/集成服务商把 Strix Halo 纳入客户项目交付。** Altronis 明确说 Framework 和 EVO-X2 被用于 client deployments，并说自己已在该平台上 shipped real client workloads；其 private LLM 商业服务包括模型部署、gateway、RAG/数据层、handover 和 managed operations。

**企业确实会购买 self-hosted/sovereign RAG 与 AI platform。** European Commission 的 AI@EC 已经运行在 Commission-managed infrastructure 上，并有 316 条 production 或 ready-for-rollout pipelines；这不是技术 demo。

**企业会为“利用已有本地硬件完成知识处理”的集成与 sizing 服务找供应商。** deepset 公开记录的客户要求在已有 GPU 上本地处理 70 亿 library records，deepset/Quest1 实际执行了 benchmarking 和模型选择工作。

**self-hosted LLM 的部署、故障修复和长期维护本身已经形成咨询需求。** Hossted 明确称其专家会处理 real client cases，客户将 Open WebUI 作为 self-hosted AI infrastructure 的 critical component；其招聘的 delivery engineer 预算为 US$40–70/h，但该时薪只能作为交付人力成本，不应写成客户收费。

**大模型一体机已经有很高金额的邻近采购案例。** 二手行业统计公开报道苏州银行大模型训推一体机项目由讯飞智元中标，投标价 1,788 万元人民币；由于硬件不明，这只能证明“大模型一体机市场”，不能证明 Max395 的成交价。

**Max+ PRO 395 可以形成可量化的企业生产力收益，但不能把收益自动写成收入。** AMD/Ansys 案例中，HP Z2 Mini G1a 上的模拟从 CPU workflow 的数小时缩短到约 10–15 分钟；没有公开采购付款，所以本报告只记降本/效率，不记收入。

### 仍然只能写成“能力推导”的结论

目前**没有公开证据足以证明一个普遍命题：“普通 Max395 用户购买工作站后，通过出售 RAG/OCR/Agent 服务，已经稳定获得某个明确月收入。”** 已有案例能够证明硬件付款、实际 local-AI 使用和 client workload deployment，但不能填补“客户是谁—项目卖了什么—合同多少—回款多少—毛利多少”这一完整财务链条。

目前也**不能直接声称 Max395 已有公开的 OCR 按页收费、字幕按分钟收费、MCP 按月订阅、A2A Agent 合同、RPA 抓取月费等 A1 案例**。Altronis 证明 Max395 可以实际承担 OCR/VLM、embedding、agent/news pipeline 等 workload，但“workload 能跑”与“这个单独 SKU 已经有人付款”仍是两个不同命题。

同样，**不能把大型邻近案例的合同/采购金额线性迁移到 Max395。** 苏州银行的一体机采购属于银行级大模型基础设施，European Commission 是机构级 sovereign platform，70 亿文档的本地 embedding 也远超典型单机 SME workload。Max395 的合理迁移方向是把这些方案缩成 **1–几十用户、单部门、单办公室、边缘节点或专用 workflow appliance**，而不是声称一台 Max395 可以等价替代大型多 GPU 或数据中心系统。

因此，白皮书最稳健的商业论断可以写成：

> **Strix Halo 已跨过“纯 demo”阶段：Max395 设备已有真实付款、真实客户 local-AI 使用，也已有服务商公开称其被用于 client deployments。更成熟的邻近市场已经证明企业愿意采购本地大模型一体机、self-hosted RAG、sovereign AI platform 和 production support。当前仍缺的，不是“能不能做”，而是更多公开的 Max395 项目合同额、客户名称、回款与长期运维收入。** 

这也决定了 Max395 最可信的商业定位：**它不是收入来源本身，而是可部署在客户现场的低占地、高内存本地执行节点。真正能收费的对象，是整机交付、私有知识库、RAG、OCR/文档流、内部 API、Agent workflow、数据接入、安全治理、监控、模型升级和长期技术支持。** 其中前四类已经分别拥有硬件付款、客户使用、client deployment 或邻近企业采购的直接证据；字幕、翻译、独立 MCP/A2A、内容生产等方向，目前在 Max395 上仍应明确标注为**能力推导，而不是已有付费案例**。