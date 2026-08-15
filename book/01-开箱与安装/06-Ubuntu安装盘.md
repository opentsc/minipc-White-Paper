# 06　Ubuntu 安装盘

## 完成结果

在另一台电脑上下载好 Ubuntu 镜像，制作好 USB 启动盘，确认可以用来安装系统。

## 开始前需要准备什么

- **另一台可以正常使用的电脑**（Windows、Mac 或已有 Linux 系统均可）；
- 一个容量 8 GB 或以上的 USB 闪存盘（U 盘）；
- 网络连接（需要下载约 5 GB 的镜像文件）。

> 这一步在另一台电脑上完成，不需要操作 Mini PC。

**注意**：制作安装盘会清空 U 盘上的所有内容。在开始前，把 U 盘里需要保留的文件转移到其他地方。

## 选择 Ubuntu 版本

本教材使用 **Ubuntu 24.04 LTS**（Long Term Support，长期支持版）。

如果你的另一台电脑或相关资料推荐 Ubuntu 26.04 LTS，也可以选择 26.04。两个版本都支持 Max395 的硬件，操作步骤相同。

不要选择非 LTS 版本（例如 23.10、25.04、25.10），这些版本的维护周期短，不适合作为长期使用的系统基础。

## 在哪里下载

访问 Ubuntu 官网下载页面：

```
https://ubuntu.com/download/desktop
```

选择 Ubuntu 24.04.x LTS 或 Ubuntu 26.04 LTS，点击下载。文件名类似：

```
ubuntu-24.04.4-desktop-amd64.iso
```

或：

```
ubuntu-26.04-desktop-amd64.iso
```

文件大小约 4-6 GB，下载时间取决于网络速度。

下载完成后，页面通常会提供 SHA256 校验码。建议核对校验码确认文件完整：

**Windows 下校验（PowerShell）**：

```powershell
Get-FileHash ubuntu-24.04.4-desktop-amd64.iso -Algorithm SHA256
```

输出的 Hash 值应当和官网提供的一致。

**Mac 下校验（终端）**：

```bash
shasum -a 256 ubuntu-24.04.4-desktop-amd64.iso
```

**Linux 下校验（终端）**：

```bash
sha256sum ubuntu-24.04.4-desktop-amd64.iso
```

## 制作 USB 启动盘

推荐使用 **balenaEtcher** 或 **Ventoy**。

### 方法 A：balenaEtcher（推荐初次操作者）

1. 在另一台电脑的浏览器里搜索 “balenaEtcher” 并下载安装；
2. 插入 U 盘；
3. 打开 balenaEtcher；
4. 点击“Flash from file”，选择下载好的 `.iso` 文件；
5. 点击“Select target”，选择你的 U 盘（仔细确认是 U 盘，不是其他磁盘）；
6. 点击“Flash”，等待完成。

> **⚠️ 会清空 U 盘所有内容**。确认目标是 U 盘，不是你电脑的系统盘。

完成后 balenaEtcher 会自动校验。校验通过后，U 盘制作完成。

### 方法 B：Ventoy

1. 下载 Ventoy 并安装到 U 盘（Ventoy 会格式化 U 盘）；
2. 把 `.iso` 文件复制到 U 盘根目录；
3. 完成，无需其他操作。

Ventoy 的好处是同一个 U 盘可以放多个 ISO，下次可以直接替换文件，不用重新制作启动盘。

### 在 Linux 下制作（命令行方式）

```bash
# 确认 U 盘设备名，通常是 /dev/sdb 或 /dev/sdc
lsblk

# 写入镜像（将 /dev/sdX 替换为你的 U 盘设备名）
# ⚠️ 确认设备名正确，否则会覆盖错误磁盘
sudo dd if=ubuntu-24.04.4-desktop-amd64.iso of=/dev/sdX bs=4M status=progress && sync
```

## 确认启动盘制作成功

制作完成后，U 盘中应当出现以下情况之一：

- balenaEtcher 显示“Flash Complete!”且校验通过；
- Ventoy 方式：能在文件管理器里看到 U 盘中有 .iso 文件；
- dd 方式：命令正常结束，无报错。

如果 balenaEtcher 校验失败，重新制作一次。如果连续失败，尝试换一个 U 盘。

## 正常结果

U 盘制作成功，启动盘校验通过，可以用于安装 Ubuntu。

## 看到不同结果怎么办

**校验码和官网给的对不上**：文件在下载途中损坏了。删掉重新下载，不要用这个文件制作启动盘。用损坏的镜像装系统，会在安装到一半时报错。

**balenaEtcher 找不到 U 盘**：换一个 USB 口重插，优先用机身上直接的口，不要用扩展坞或 USB 集线器。仍然看不到就换一个 U 盘。

**写入过程中报错或中途失败**：先换 USB 口重试一次。第二次仍然失败，多半是 U 盘本身有问题，换一个 U 盘。U 盘容量虚标的情况也会导致写入失败。

**写完后电脑提示“需要格式化才能使用”**：这是正常现象。写入镜像后的 U 盘用的是 Windows 不认识的格式，**不要点格式化**，点取消，直接拔下来拿去装系统。

**下载速度极慢**：官网下载慢时可以换国内的镜像站下载同一个版本，下载完照样核对校验码，校验码一致就可以用。

## 完成检查

- Ubuntu ISO 文件已下载，校验码与官网一致吗？
- U 盘容量 8 GB 以上，U 盘上原有文件已备份？
- 启动盘制作完成，balenaEtcher 显示 Flash Complete 或命令正常结束？

## 下一步

进入[第 7 章：安装 Ubuntu](07-安装Ubuntu.md)。
