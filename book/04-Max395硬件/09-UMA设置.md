# 09　UMA 设置

## 完成结果

这台机器的 GPU 能用到 120 GiB 内存。做法是两步：BIOS 里把 UMA Frame Buffer Size 设成最低档，Ubuntu 里给内核加三个参数。做完之后，你能用三条命令确认它真的生效了，也知道万一改坏了怎么把系统救回来。

这是本卷最关键的一章。第 6 卷跑模型的所有前提都在这里。

## 开始前需要准备什么

- **读过第 6 章。** 那一章讲了为什么这么设，本章只讲怎么设。不理解“BIOS 设小反而 GPU 能用更多”这件事的话，先回去读一遍；
- 能进 BIOS（第 7 章）；
- 一台已经装好 Ubuntu、能登录桌面的设备（[第 1 卷第 7 章](../01-开箱与安装/07-安装Ubuntu.md)）；
- 知道这台机器的内存容量是 128 GB、96 GB 还是 64 GB（`free -h` 能看，或看订单）；
- 手边有[第 1 卷第 10 章](../01-开箱与安装/10-恢复介质.md)做的恢复 U 盘；
- 大约 30 分钟，中间要重启两次。不要在给客户演示前十分钟做这件事。

> **⚠️ 这一章要改两个会影响开机的地方：BIOS 设置和引导配置。**
>
> **改 BIOS 之前**：先用手机把要改的那一屏拍下来。改坏了的恢复办法是重新进 BIOS 选 `Load Optimized Defaults` 或 `Restore Defaults` 再按 `F10` 保存（分品牌做法见[第 1 卷第 12 章](../01-开箱与安装/12-硬件问题处理.md)）。
>
> **改引导配置之前**：本章第三步会先做一份备份文件。**这一步不能跳过。** 引导配置写错最常见的后果是参数不生效，严重时是开不了机。开不了机的恢复办法在本章“改坏了开不了机怎么办”那一节，做之前先把那一节读一遍，知道有路可走再动手。

## 新词

**终端**（Terminal）：输入命令的那个黑窗口。在 Ubuntu 桌面按 `Ctrl+Alt+T` 打开，也可以在“显示应用程序”里搜“终端”。本章的所有命令都在这里输，输完按回车执行。

**sudo**：命令前面加上它表示“用管理员身份执行这一条”。系统会要你输入登录密码。**输密码的时候屏幕上不会显示任何字符，光标也不动，这是正常的**，照常输完按回车。

**nano**：一个在终端里用的文本编辑器，Ubuntu 自带。它把可用按键列在窗口底部，`^O` 表示 `Ctrl+O`（保存），`^X` 表示 `Ctrl+X`（退出）。本章用它来改一个配置文件。

**引导**（Boot）：开机时从硬盘上把操作系统装载起来、交出控制权的那个过程。

**引导程序**（GRUB）：Ubuntu 用的引导程序。开机时它先跑，决定启动哪个系统、哪个内核版本，并把内核参数传给内核。

**GRUB 菜单**：开机时 GRUB 显示的那个黑底白字的选择列表。机器上只装了 Ubuntu 时它默认不显示，开机按住 `Shift` 或反复按 `Esc` 能把它调出来。系统改坏之后主要靠它救回来。

**内核参数**：开机时传给内核的一串设置，写在 GRUB 的配置里。本章要加的三个就是内核参数。

**`/etc/default/grub`**：GRUB 的配置文件，你要改的就是它。改它不会立刻生效，还要执行一条命令重新生成真正被开机读取的配置。

**`update-grub`**：读 `/etc/default/grub`，生成开机时实际读取的那份配置。**不跑这一条，你改的东西不算数。**

**恢复模式**（Recovery mode）：GRUB 菜单里的一个启动项，用最小的方式把系统起到命令行，专门用来修系统。开机改坏了主要靠它。

**备份文件**：本章会把原配置复制一份，文件名后面加 `.bak`。改坏了就用它覆盖回去。

## 这一章要做的三件事

```text
一、BIOS 里把 UMA Frame Buffer Size 设成最低档（512 MB，最低只有 2 GB 就设 2 GB）
二、Ubuntu 里给内核加三个参数，把 GTT 上限设成 120 GiB
三、重启，用三条命令验证
```

第一件事如果你在装系统时按[第 1 卷第 7 章](../01-开箱与安装/07-安装Ubuntu.md)做过了，本章第二步只需要进去确认一眼。

## 第一步：确认起点

三条只读命令，先弄清楚这台机器现在是什么状态。

**看内核版本**

```bash
uname -r
```

输出形如 `6.17.0-14-generic`。**前面的 `6.17` 是关键**，按下面这张表对号入座。

| 你看到的版本 | 怎么办 |
| --- | --- |
| 6.16.9 到 6.17.x | 本教材的基准，直接按本章往下做 |
| 6.18.4 及以上 | 参数和本章完全一样，直接往下做。AMD 官方另给了一个叫 `amd-ttm` 的命令行工具可以代替手改配置，**二选一，不要两边都设**。本教材主线仍然手改，因为改了什么一目了然，方便回滚和审计 |
| 6.11 到 6.15 | 走 Vulkan 的话本章参数照样有效；走 ROCm 的话这些内核上有硬伤，不管怎么设参数 ROCm 只看得到约 15.5 GB，没有任何参数能绕过。**先升内核**（见下面） |
| 6.8 | 这是 Ubuntu 24.04 出厂的旧内核，不支持这颗芯片的正常图形与 NPU 调度。**必须先升内核** |

**要升内核的话**（`6.15` 及以下）：

```bash
sudo apt update
sudo apt install --install-recommends linux-generic-hwe-24.04
sudo reboot
```

重启后再跑一次 `uname -r`，预期看到 `6.17` 开头。升完再回来做本章。

**看内存容量**

```bash
free -h
```

`Mem` 那一行的 `total` 就是系统看到的总内存。128 GB 的机器上这个数字通常显示为 120 多 Gi（因为 BIOS 已经切走了一部分，加上换算口径的差别），不用对齐到整数。

**看现在有没有已经加过的参数**

```bash
cat /proc/cmdline
```

输出的是本次开机传给内核的完整参数行。没改过的机器上看不到 `ttm.` 开头的东西，属正常。

> **如果你之前按别的教程加过参数**：这一行里出现 `amdgpu.gttsize`、`amd_iommu=off`、`apparmor=0`、或者 `amdttm.` 开头的东西，本章第四步要**先把它们删干净再加新的，不要叠加**。理由在第 6 章的“不要用的写法”。

## 第二步：在 BIOS 里把 UMA 设成最低档

> **⚠️ 进 BIOS 之前先用手机把要改的那一屏拍下来。** 改坏了的恢复办法：重新进 BIOS 选 `Load Optimized Defaults` 或 `Restore Defaults`，按 `F10` 保存退出（[第 1 卷第 12 章](../01-开箱与安装/12-硬件问题处理.md)）。恢复默认之后要回到这一步重新设一次。

1. 关机，按第 7 章的方式进 BIOS；
2. 找到显存分配那一项。分品牌的常见路径（来自[第 1 卷第 7 章](../01-开箱与安装/07-安装Ubuntu.md)，**随固件版本变化，需要核验**）：

| 品牌 | 常见路径 |
| --- | --- |
| GMKtec EVO-X2 / EVO-X3 | Advanced → GFX Configuration → UMA Frame Buffer Size |
| Beelink GTR9 Pro | Advanced → GFX Configuration → UMA Frame Buffer Size |
| Framework Desktop | Advanced → AMD CBS → NBIO → GFX Configuration → UMA Frame Buffer Size |
| HP ZBook Ultra G1a | Advanced → Video Configuration → UMA Frame Buffer |
| 其他品牌 | 在 Advanced 或 Chipset 下找含 UMA、iGPU Memory、Integrated Graphics Memory、Graphics Memory Allocation、Variable Graphics Memory 或 VRAM 字样的项 |

3. 把它设成**最低可选档**。常见是 `512 MB`；这台机器上最低只有 `2 GB` 就设 `2 GB`；只有 `Auto` 没有具体档位的，先保持 `Auto`，装完之后按第六步看日志里实际是多少，记进第 16 章的设备基线；
4. 按 `F10` 保存退出（或在 Save & Exit 菜单里选保存退出）。机器重启。

**这一项做过就不用再动**，除非刷过固件或恢复过默认值（第 8 章）。

## 第三步：备份引导配置

登录 Ubuntu 桌面，按 `Ctrl+Alt+T` 打开终端。

```bash
sudo cp /etc/default/grub /etc/default/grub.bak
```

`cp` 是复制，前面是源文件，后面是目标文件。这条命令把原配置原样复制一份，文件名后面加了 `.bak`。

确认备份真的在：

```bash
ls -l /etc/default/grub*
```

输出里应当同时看到 `grub` 和 `grub.bak` 两个文件，两者的大小一样。

> **看不到 `grub.bak` 就不要往下做。** 后面每一步都以这份备份为退路。

## 第四步：改 `/etc/default/grub`

```bash
sudo nano /etc/default/grub
```

文件打开后，用方向键找到以 `GRUB_CMDLINE_LINUX_DEFAULT=` 开头的那一行。Ubuntu 默认长这样：

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
```

把它改成（128 GB 的机器）：

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ttm.pages_limit=31457280 ttm.page_pool_size=31457280 amdgpu.gpu_recovery=1"
```

也就是在原来的 `quiet splash` 后面，空一格，把三个参数接上去。

**三个参数各管什么**（完整理由见第 6 章）：

- `ttm.pages_limit=31457280`：GTT 上限，单位是 4 KiB 的内存页，31457280 页等于 120 GiB；
- `ttm.page_pool_size=31457280`：与上一条配套，同一个数值；
- `amdgpu.gpu_recovery=1`：GPU 硬挂之后尝试复位。和显存无关，是给长期挂机的机器用的兜底。复位成功的代价是当时在跑的任务全部失败，所以要配套服务自动拉起（第 14 卷）。

**改的时候注意这几条**：

1. **只改这一行**，文件里其他行一律不动；
2. **引号必须是英文半角的 `"`**，一头一尾各一个。中文输入法打出来的弯引号会让配置坏掉——这是最常见的翻车原因，改之前先把输入法切到英文；
3. 参数之间用**一个半角空格**隔开，等号两边不留空格；
4. 原来的 `quiet splash` 保留。你的这一行本来就没有它们的话，也不用补；
5. 第一步查到有 `amdgpu.gttsize`、`amd_iommu=off`、`apparmor=0`、`amdttm.` 开头的东西，**先删掉再加新的**。

改完保存退出：

- 按 `Ctrl+O`（字母 O，保存），底部提示文件名，直接按 `Enter` 确认；
- 按 `Ctrl+X` 退出。

**保存后先核对一遍再往下走**：

```bash
grep GRUB_CMDLINE_LINUX_DEFAULT /etc/default/grub
```

`grep` 是从文件里挑出含指定字样的行。把输出和上面那一行**逐个字符**对一遍，重点看引号是不是两个半角引号、参数有没有拼错、数字有没有少一位。

## 第五步：让改动生效

```bash
sudo update-grub
```

这条命令读你刚改的文件，生成开机时实际读取的那份配置。**不跑它，前面白改。**

正常输出大致是这样（版本号随你的机器变）：

```text
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.17.0-14-generic
Found initrd image: /boot/initrd.img-6.17.0-14-generic
done
```

看到最后的 `done`，这一步就成了。

> **⚠️ 输出里出现 `syntax error`、`unexpected EOF`、`error:` 这类字样，不要重启。** 这说明配置文件有语法问题，多半是引号没配对。回到第四步重新检查那一行；实在改不对就用备份覆盖回去，从头再来一次：
>
> ```bash
> sudo cp /etc/default/grub.bak /etc/default/grub
> sudo update-grub
> ```

**不需要执行 `grub-install`。** UEFI 机器上改完 `/etc/default/grub` 只要 `update-grub` 就够了，网上有些教程顺手带的那条不带目标盘的 `grub-install` 是多余的。

然后重启：

```bash
sudo reboot
```

## 第六步：重启并验证

三条只读命令，一条一条来。

**一、内核有没有收到参数**

```bash
cat /proc/cmdline
```

输出里应当能看到你加的三个参数。看不到就是没写进去，回到第四步和第五步检查。

**二、内核认到了多少显存**

```bash
sudo dmesg | grep -i "amdgpu.*memory"
```

`dmesg` 是内核自己的消息记录，后面那半截是从里面挑出含 amdgpu 和 memory 字样的行。预期两行（数值随你的设置变）：

```text
[drm] amdgpu: 512M of VRAM memory ready
[drm] amdgpu: 122880M of GTT memory ready.
```

- 第一行的 `512M` 对应 BIOS 里设的最低档。你设的是 2 GB 就会显示 `2048M`；
- 第二行的 `122880M` 就是 120 GiB，对应你设的 GTT 上限。

**这两行是判断配置有没有生效的主要依据**，比任何监控工具可靠。

**三、参数文件里的值**

```bash
cat /sys/module/ttm/parameters/pages_limit
```

预期输出 `31457280`。这是内核当前实际生效的页数。

**四、看它真的被借出去（可选，等第 6 卷装好模型再做）**

```bash
sudo apt install radeontop
radeontop
```

看 `gtt` 那一栏：空载时接近 0；用 llama.cpp 或 Ollama 加载一个 40 GB 量级的模型，这一栏应当从 0 爬到模型体积上下。这是动态分配真的在工作的直接证据。按 `q` 退出。

同时另开一个终端跑 `free -h`，看宿主还剩多少内存。

装好 ROCm 之后（第 5 卷）还可以再查一层：

```bash
rocm-smi --showmeminfo vram gtt
```

`GTT Total Memory` 应在 120 GiB 量级。gfx1151 上 ROCm 对静态和动态两个池的汇报口径反复过几次，**以日志和 `/sys` 下的参数文件为准**。

## 不同内存容量的数值对照表

换算公式：

```text
页数 = 目标 GiB × 262144
```

| 整机内存 | 目标 GTT 上限 | 两个参数都填这个值 | 说明 |
| --- | --- | --- | --- |
| 128 GB | 120 GiB | `31457280` | **本教材默认**，留 8 GiB 给系统 |
| 128 GB | 124 GiB | `32505856` | 激进档，只留 4 GiB。跑 120B 级模型加长上下文时才考虑，这台机器上就不要再跑别的服务了 |
| 96 GB | 88 GiB | `23068672` | 按公式推算，**本项目未在实机验证** |
| 64 GB | 56 GiB | `14680064` | 按公式推算，**本项目未在实机验证** |

96 GB 和 64 GB 那两行是照同一个公式算出来的，本项目手上没有这两种容量的机器，**没有实测过**。按这两行设完之后，一定要跑第六步的验证命令，看日志里的 GTT 数值对不对得上。

**这是上限，不是占用。** 不加载模型的时候，这块内存照常归系统用，`free -h` 不会因为设了参数就少一块。

## 三种被否决的做法

材料里流传着另外几条路，本教材都不走。理由在第 6 章有完整版，这里各给一句。

**一、不要把 BIOS 设成 96 GB 静态。** 96 GB 是 BIOS 菜单和 Windows 的上限，比本章这套动态方案的 120 GiB 还低，而且静态切走的那块内存宿主再也拿不回来。

**二、不要加 `amdgpu.gttsize`（任何数值）。** 内核文档已经把它标为废弃并将在未来移除，只设它不设 TTM、或者两边数值不一致时，日志会报不一致，HIP 按小的一边汇报，128 GB 的机器照样报内存不足。

**三、不要加 `amd_iommu=off`。** 换来的是没有第三方复测的 5% 到 12% 内存带宽，代价是 NPU 直接消失、待机失效、虚拟化与设备直通失效、DMA 防护失效。**大 GTT 不需要关 IOMMU**，本章这套参数在 IOMMU 默认开启的状态下照样能到 120 GiB。

另外三条顺带说明：`amdttm.` 开头的参数属于另一条产品线的驱动栈，Ubuntu 主线内核不认；`apparmor=0` 和显存没有任何关系，纯粹降低系统安全基线；`iommu=pt` 是折中档，本教材默认配置不写，少一个变量。

## 改坏了开不了机怎么办

先说实际概率：改内核参数最常见的后果是**参数没生效**，机器照常开机。真会开不了机的是引号没配对导致生成了坏的配置——所以第五步看到报错就不要重启。

万一真的起不来，按下面的顺序试。

**办法一：临时删掉参数开一次机（最快）**

1. 开机时按住 `Shift`，或者反复按 `Esc`，把 GRUB 菜单调出来；
2. 用方向键选中第一项 Ubuntu，**按 `e`**（不是回车），进入这一次开机的编辑界面；
3. 找到以 `linux` 开头的那一行，用方向键把光标移到你加的那几个参数上，用 `Delete` 或退格删掉；
4. 按 `Ctrl+X` 启动。

这种改法**只对这一次开机有效，不写硬盘**，重启就恢复原样。进系统之后用备份覆盖回去：

```bash
sudo cp /etc/default/grub.bak /etc/default/grub
sudo update-grub
sudo reboot
```

**办法二：恢复模式**

1. 调出 GRUB 菜单，选 `Advanced options for Ubuntu`；
2. 选带 `(recovery mode)` 字样的那一项；
3. 出现恢复菜单后选 `root`（Drop to root shell prompt），回车，看到命令行提示符；
4. 恢复模式下根分区是**只读**的，先让它可写：

```bash
mount -o remount,rw /
```

5. 用备份覆盖，重新生成配置，重启：

```bash
cp /etc/default/grub.bak /etc/default/grub
update-grub
reboot
```

恢复模式下已经是管理员身份，这几条前面不用加 `sudo`。

**办法三：连 GRUB 菜单都出不来**

用[第 1 卷第 10 章](../01-开箱与安装/10-恢复介质.md)做的恢复 U 盘启动，进 Live 模式。这条路要先把硬盘上的系统分区挂载起来才能改文件，步骤比前两条复杂，按[第 15 卷](../15-故障排查/README.md)处理。

**BIOS 那一半改坏了**：进 BIOS 选 `Load Optimized Defaults` 或 `Restore Defaults`，按 `F10` 保存（[第 1 卷第 12 章](../01-开箱与安装/12-硬件问题处理.md)）。恢复之后回到本章第二步重新设一次 UMA。

## 这一章涉及的可改设置

**一、BIOS 里的 UMA Frame Buffer Size**

- **默认状态**：随整机厂而定，常见是 `Auto`、`512 MB` 或 `2 GB`。进 BIOS 读出你这台的当前值并记下来；
- **什么情况才需要改**：装系统前设成最低可选档，设过一次就不用再动。刷过固件或恢复过 BIOS 默认值之后要重设；
- **改完怎么验证**：开机后 `sudo dmesg | grep -i "amdgpu.*memory"`，第一行 VRAM 的数值和你在 BIOS 里选的档一致；
- **怎么恢复**：进 BIOS 改回原值，或用 `Load Optimized Defaults`（[第 1 卷第 12 章](../01-开箱与安装/12-硬件问题处理.md)）。

**二、`ttm.pages_limit` 与 `ttm.page_pool_size`**

- **默认状态**：不设。内核默认的 GTT 上限约为系统内存的 50%（AMD 官方文档口径）；
- **什么情况才需要改**：要跑的模型加上下文超过内存一半时。只跑小模型的机器可以不改；
- **改完怎么验证**：`cat /proc/cmdline` 能看到参数；`cat /sys/module/ttm/parameters/pages_limit` 输出你设的页数；日志里 GTT 那一行显示对应容量；加载大模型时 `radeontop` 的 `gtt` 一栏爬上去；
- **怎么恢复**：`sudo cp /etc/default/grub.bak /etc/default/grub`，再 `sudo update-grub`，重启。

**三、`amdgpu.gpu_recovery=1`**

- **默认状态**：不设。内核文档写默认值为 `-1`（自动）；
- **什么情况才需要改**：无人值守、长期挂机跑推理的机器显式写成 `1`，把行为钉死，不依赖各内核版本对“自动”的判断。桌面上手动用的机器可以不加；
- **改完怎么验证**：`cat /proc/cmdline` 里能看到这个参数；
- **怎么恢复**：从配置里删掉，`sudo update-grub`，重启；
- **界限**：复位不是每次都成功，社区有固件级挂死、复位无效只能断电的案例。长期稳定性的大头在固件版本，出现整机级问题先查固件（第 8 章），再考虑参数。

**四、IOMMU**

- **默认状态**：内核默认开启，引导配置里不写任何相关参数。**本教材保持默认**；
- **什么情况才需要改**：本教材没有推荐改动的场景。收益与代价见第 2 章和第 6 章；
- **改完怎么验证**：`cat /proc/cmdline` 看有没有相关参数；
- **怎么恢复**：把参数删掉，`sudo update-grub`，重启。

## 正常结果

BIOS 里的 UMA Frame Buffer Size 是最低档；`cat /proc/cmdline` 里能看到三个新参数；日志里两行分别显示 `512M of VRAM` 和 `122880M of GTT`；`cat /sys/module/ttm/parameters/pages_limit` 输出 `31457280`；`free -h` 显示的可用内存和改之前差不多，没有因为设了上限就少一块。

到这里，这台机器已经具备跑大模型的内存条件。

## 看到不同结果怎么办

**BIOS 里根本找不到显存分配这一项**：先在 Advanced 下面逐级往里翻，特别是 AMD CBS 这类层级很深的菜单（第 7 章）。确实没有的话，说明这个固件没开放这一项，那就跳过第二步，只做内核参数那一半——**GTT 那部分照样生效**，只是 BIOS 静态预留是多少你说了不算。装完按第六步看日志里 VRAM 那一行实际是多少，记进第 16 章的设备基线。

**BIOS 里最低档不是 512 MB，只有 2 GB**：设 2 GB，这是拍板结论里写明的。

**BIOS 里只有 `Auto`，没有具体档位**：保持 `Auto`，按第六步看日志里 VRAM 实际是多少，记下来。

**`sudo dmesg | grep -i "amdgpu.*memory"` 什么都没输出**：可能是关键词不匹配（不同内核版本的日志措辞略有差异），去掉过滤看全量输出里有没有 amdgpu 相关行；也可能是日志被后面的内容冲掉了，重启后立刻再查一次。这条命令只读日志，多跑几次没有风险。

**日志里 GTT 的数值大约是内存的一半（比如 62 GB 左右）**：这是**没改参数时的默认状态**，AMD 官方文档写明默认上限约为系统内存的 50%。说明参数没生效，回到第六步第一条看 `/proc/cmdline` 里有没有你加的参数。

**`/proc/cmdline` 里看不到你加的参数**：三种可能——`nano` 里没保存成功（回第四步用 `grep` 核对）、忘了跑 `sudo update-grub`（回第五步）、改的不是 `GRUB_CMDLINE_LINUX_DEFAULT` 那一行而是另一行。

**日志里报 GTT 和 TTM 数值不一致**：说明同时设了两套管同一件事的参数。查 `/proc/cmdline` 里有没有 `amdgpu.gttsize`，有就删掉，只留本章这三个。

**`cat /sys/module/ttm/parameters/pages_limit` 提示没有这个文件**：说明用的前缀不对（比如写成了 `amdttm.`），或者内核版本太旧。先确认 `uname -r` 的结果，再回第四步核对参数拼写。

**ROCm 只看到约 15.5 GB**：查内核版本。6.15 及更早的内核上这是已知缺陷，任何参数都绕不过去，唯一出路是按第一步升级内核。

**监控工具（`nvtop`、`btop`）一直显示 512 MB 显存**：这是显示问题，不是配置失败——这类工具没有适配动态显存。判断标准永远是日志里的 GTT 那一行和 `radeontop` 里 `gtt` 那一栏的实际占用曲线。

**LM Studio 拒绝把模型交给 GPU**：它按静态显存数判断能不能卸载，BIOS 设成 512 MB 之后可能直接拒绝。本教材主线用 llama.cpp、Ollama、vLLM，没有这个问题（**这条来自项目补充材料引用的口径，本项目未上网核对原始页面，需要核验**）。

**这台机器不是 128 GB**：按“不同内存容量的数值对照表”换算。96 GB 和 64 GB 那两行是推算值，**未在实机验证**，设完一定要跑第六步的验证。

**`sudo update-grub` 报错**：不要重启。回第四步检查引号，或者直接用备份覆盖回去重来。

**重启之后开不了机**：按“改坏了开不了机怎么办”那一节，从办法一开始。

**你要跑 120B 级别的模型，120 GiB 不够**：先确认是不是真的不够——量化档和上下文长度都影响占用（第 6 卷）。确实需要再考虑 124 GiB 那一档，代价是系统只剩 4 GiB。

**这台机器要用 NPU**：那就必须保持 IOMMU 开启。本章这套配置正好满足，什么都不用额外做（第 2 章）。

## 完成检查

- 这一章要做的三件事分别是什么？
- BIOS 里那一项设成多少？最低只有 2 GB 的机器怎么办？
- 三个内核参数分别是什么？各管什么？
- 改 `/etc/default/grub` 之前必须先做哪一步？不做会怎样？
- 引号必须用哪一种？为什么这一条要单独强调？
- 改完配置之后为什么还要跑 `sudo update-grub`？
- 验证配置有没有生效，看哪三条命令？哪一条是主要依据？
- 页数和 GiB 怎么换算？128 GB 的机器填哪个数字？
- 开机起不来的时候，最快的那条恢复办法是什么？它会不会写硬盘？
- 本章否决的三种做法分别是什么？各自的理由是什么？

## 事实来源和版本日期

- BIOS 显存保留设成最低（原文例值 0.5 GB）、扩容走 TTM／GTT、默认 GTT 上限约为系统内存的 50%、ROCm 路线要求内核不低于 6.18.4、`amd-ttm` 工具可代替手改配置：[AMD Strix Halo system optimization](https://rocm.docs.amd.com/en/docs-7.2.0/how-to/system-optimization/strixhalo.html)，AMD 官方文档，访问日期 2026-08-13。面向 ROCm 7.2，不覆盖 Vulkan 路径，也不代表 Ubuntu 24.04 上的行为，事实状态 `official_source`；
- 96 GB 是 BIOS 菜单与 Windows 的上限而非 Linux 的上限、`amdgpu.gttsize` 已被内核日志标为废弃：[Increasing the VRAM allocation on AMD AI APUs under Linux](https://www.jeffgeerling.com/blog/2025/increasing-vram-allocation-on-amd-ai-apus-under-linux)，Jeff Geerling，2025-08-08，访问日期 2026-08-13，个人实测单机结果，属 2025 年 8 月的固件与内核环境，事实状态 `candidate`；
- 31457280 × 4 KiB = 120 GiB 的换算与留 8 GB 余量：[Strix Halo Wiki：AI Capabilities Overview](https://strixhalo.wiki/AI/AI_Capabilities_Overview)，访问日期 2026-08-13，社区维基汇编，混合了多台设备与多个版本的口径，事实状态 `candidate`；
- BIOS 设 512 MB（厂商最低 2 GB 就设 2 GB）、IOMMU 保持默认开启的完整流程：[Strix Halo Guide](https://hogeheer499-commits.github.io/strix-halo-guide/)，hogeheer499，访问日期 2026-08-13，单一作者的机器与软件版本，其旧版本曾建议 `amdgpu.gttsize=131072`，与新内核的显存检测冲突，事实状态 `candidate`；
- 124 GiB 激进档：[amd-strix-halo-toolboxes](https://github.com/kyuz0/amd-strix-halo-toolboxes)，访问日期 2026-08-13，跑分场景口径，其 README 仍写 `amdgpu.gttsize=126976`，属存量写法，事实状态 `candidate`；
- `gttsize` 已废弃并将在未来移除、`gpu_recovery` 默认值为 `-1`：[amdgpu 内核模块参数文档](https://docs.kernel.org/gpu/amdgpu/module-parameters.html)，kernel.org，访问日期 2026-08-13。只给参数定义，不给某代硬件上的实际行为，也不给复位成功率，事实状态 `official_source`；
- 参数与 TTM 数值不一致导致 HIP 只见 62.2 GB（该数值恰为可用内存的一半）：[ROCm issue #5595](https://github.com/ROCm/ROCm/issues/5595)，访问日期 2026-08-13，单一参数组合的报告，事实状态 `candidate`；
- 内核 6.15 及更早版本上 ROCm 在 gfx1151 只看到约 15.5 GB、6.16.9 起修复：[ROCm issue #5444](https://github.com/ROCm/ROCm/issues/5444)，2026-08-13 核对已关闭并标记已解决，事实状态 `official_source`。修复在内核侧，不覆盖 ROCm 其他版本的显存汇报问题；
- `amdttm.` 前缀在 Ubuntu 主线内核上不生效：[Setting up unified memory for Strix Halo correctly on Ubuntu 25.04 or 25.10](https://dev.webonomic.nl/setting-up-unified-memory-for-strix-halo-correctly-on-ubuntu-25-04-or-25-10)，webonomic，访问日期 2026-08-13。只覆盖 Ubuntu 25.04 与 25.10，未验证 24.04 HWE 与 26.04，事实状态 `candidate`；
- 关闭 IOMMU 的收益（约 6% 与 5% 到 12% 两家口径）与代价（NPU、待机、虚拟化、DMA 防护）：[Strix Halo Wiki：AI Capabilities Overview](https://strixhalo.wiki/AI/AI_Capabilities_Overview) 与 [amd-strix-halo-toolboxes](https://github.com/kyuz0/amd-strix-halo-toolboxes)，访问日期 2026-08-13，均为个人实测，**无第三方复测，需要核验**；
- Ubuntu 24.04.4 的 HWE 内核为 6.17：本项目补充材料引用 Phoronix 报道，访问日期 2026-08-13，事实状态 `candidate`；
- BIOS 里 UMA 选项的分品牌菜单路径：[第 1 卷第 7 章](../01-开箱与安装/07-安装Ubuntu.md)已记录，选项名称随品牌与固件版本变化，本项目未逐机型实测，事实状态 `candidate`，**需要核验**；
- 96 GB 与 64 GB 机型的推荐数值：按公式推算，**本项目未在实机验证**，事实状态 `candidate`；
- LM Studio 按静态显存数判断能否交给 GPU：来自项目补充材料引用的 lmstudio-ai/lms issue #589 口径，本项目未上网核对原始页面，事实状态 `candidate`，**需要核验**；
- 本章方案的适用范围：Ubuntu 24.04.4 LTS 加 HWE 内核 6.17、128 GB 统一内存的 Ryzen AI Max+ 395 整机，核验日期 2026-08-13。其他内核版本按第一步的分组处理，其他内存容量按对照表换算；
- 内核参数这一层在各整机厂之间没有差别，BIOS 那一层有差别，本章用分品牌路径表和三条“找不到这一项”的分支处理，不用任一机型的界面代表全部 Max395 整机；
- 事实状态标记的含义见[证据与发布规则](../../reference/证据与发布规则.md)；
- 本章核验日期：2026-08-14。

## 下一步

进入[第 10 章：功耗模式](10-功耗模式.md)。
