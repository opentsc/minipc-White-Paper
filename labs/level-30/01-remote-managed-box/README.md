# 案例 01　可远程管理、断电自恢复的机器

这份文档用于 Ubuntu Mini PC。完成以后，这台机器拔掉显示器和键盘也能用：你从别的电脑远程登录它，它的门只开该开的那几个，断电来电之后一切服务自己回来。附带一个体检脚本，一条命令逐项检查，每项当场给通过或者不通过，不通过的写清回教材哪一章。

对应教材[第 3 卷第 8 章](../../../book/03-服务器基础/08-自动启动与无人值守.md)、[第 9 章](../../../book/03-服务器基础/09-防火墙与密钥.md)和[第 10 章](../../../book/03-服务器基础/10-远程访问验收.md)。

体检脚本只读，不改任何配置，在没配置过的机器上跑也不会出事——查不到的项目它报“跳过”，不报错。

## 完成结果

- 远程能连：SSH 端口在监听，只认密钥不认密码。
- 门有人守：`ufw` 已启用，入站默认拒绝，每条放行规则说得出是给谁开的。
- 服务在跑：关键服务开机自启，容器的重启策略是自己回来那一种，定时任务还在。
- 断电能回：机器来电自己开机，两分钟内全部服务回到断电前的样子。
- 不会睡过去：四种睡眠方式全部封掉，机器不会自己断网。
- `check-remote-box.sh` 一条命令跑完全部检查，通过与否有明确的退出码。

## 准备条件

- 一台装了 Ubuntu 22.04 或 24.04 的 Mini PC，能远程登录。
- 一台笔记本，Windows 或者 macOS，用来远程操作和验收。
- 有 `sudo` 权限。
- **一台显示器和一把有线键盘。** 防火墙那一步万一做错，本地登录是唯一的退路；来电自启要进 BIOS 改，也得接上。
- 教材第 3 卷第 3、4 章做完（地址固定、密钥登录可用）。没做的话体检会有几项不通过，那是对的。

检查环境。

```bash
bash --version | head -1
systemctl --version | head -1
```

## 文件

```text
README.md                       就是这份
ufw.rules.example               防火墙规则清单，照抄执行
autostart.checklist.example     无人值守配置清单，照抄执行
scripts/check-remote-box.sh     体检脚本，只读
```

两个 `.example` 文件本身不会被执行，它们是给你照抄的清单，每条命令上面都写了作用。

## 操作步骤

### 1　复制到固定位置

```bash
mkdir -p "$HOME/apps"
cp -R labs/level-30/01-remote-managed-box "$HOME/apps/remote-managed-box"
cd "$HOME/apps/remote-managed-box"
chmod 755 scripts/check-remote-box.sh
```

只下载了这个案例，就把案例目录放到 `$HOME/apps/remote-managed-box`。

### 2　先跑一次体检，看现在差哪几项

**动手改之前先跑一次**，把不通过的那几项抄下来，改完再跑一次对照。

```bash
./scripts/check-remote-box.sh
```

不加 `sudo` 跑，防火墙那两项会降级成粗略判断。要查得全：

```bash
sudo ./scripts/check-remote-box.sh
```

### 3　按清单配防火墙

`ufw.rules.example` 里是可以直接抄的一组命令，**顺序不能调换**。

```bash
grep -n '' ufw.rules.example
```

**第一条是放行 SSH，第四条才是启用防火墙。** 反过来做，你会在执行 `ufw enable` 的那一刻被踢出来，而且连不回去。真出了这事，接上显示器和键盘在本地登录，执行 `sudo ufw disable`。

启用之后**新开一个窗口**验证还能连进去，再往下做。当前这个连着的窗口先别关。

### 4　按清单配自动启动

`autostart.checklist.example` 里是另一组命令，管的是“开机之后各项服务自己回来”。

```bash
grep -n '' autostart.checklist.example
```

里面第六条是 BIOS 里的来电自启，命令行改不了，要接显示器进 BIOS。**选项名各家不同，按功能找，别按名字硬对**，分品牌线索在教材第 3 卷第 8 章。

### 5　再跑一次体检

```bash
sudo ./scripts/check-remote-box.sh
echo $?
```

前八项应该全部通过，退出码是 0。

### 6　拔电，做真正的验收

**软件查不到来电自启，只能拔电试。**

先看一眼没有正在跑的备份、没有正在传的大文件。跑着数据库的，先进项目目录 `docker compose stop` 停干净。

然后：拔插座 → 等 30 秒 → 插回去 → **不按电源键** → 等两分钟。

回笔记本上，远程再跑一次体检：

```bash
ssh 你的账户名@192.168.1.50 "cd apps/remote-managed-box && sudo ./scripts/check-remote-box.sh"
```

**这一条能跑出来，本身就说明机器自己开机了、网络起来了、SSH 服务回来了。** 剩下的看输出。

### 7　把这次结果存一份

```bash
sudo ./scripts/check-remote-box.sh > "check-$(date +%F).txt" 2>&1
```

交付给客户的机器，这份输出就是验收单的附件。往外发之前按教材[第 0 卷第 8 章](../../../book/00-使用说明/08-文件保护.md)看一遍里面有没有不该外传的内容——输出里会带主机名和内网地址。

## 正常结果

一台配好的机器上，`sudo ./scripts/check-remote-box.sh` 的输出（机器名、地址、容器名会换成你自己的）：

```text
远程管理体检
  机器      minipc-01
  时间      2026-08-14 21:30:12
  身份      root，全部项目都能查

第 1 项　SSH 端口在监听
  通过　22 端口在等连接（0.0.0.0:22 [::]:22 ）

第 2 项　密码登录已关
  通过　配置里 PasswordAuthentication 是 no
  说明　这一项看的是配置文件。真正算数的是从别的机器用密码连一次，看它拒不拒（教材第 3 卷第 10 章第三条）。

第 3 项　防火墙已启用
  通过　ufw 已启用
  说明　规则 6 条。逐行念一遍，每一条都要说得出这个口是给谁开的。

第 4 项　入站默认拒绝
  通过　默认策略是入站拒绝

第 5 项　关键服务在跑并且开机自启
  通过　ssh 在跑，开机自启是 enabled
  通过　docker 在跑，开机自启是 enabled
  通过　cron 在跑，开机自启是 enabled

第 6 项　容器重启后自己回来
  通过　1 个容器都会在机器重启后自己回来

第 7 项　定时任务还在
  通过　有 2 条任务，其中有包含 backup 的那一条

第 8 项　睡眠和休眠已关
  通过　四种睡眠方式都封住了，机器不会自己睡过去

第 9 项　来电自启
  说明　这一项在 BIOS 里，脚本查不到。
  说明　验的办法只有一个：拔插座、等 30 秒、插回去、不按电源键，两分钟后从别的机器连一次（教材第 3 卷第 8 章）。

结果　通过 8 项，不通过 0 项，跳过 0 项
体检通过。来电自启那一项记得拔电试一次。
```

还没配的机器上，不通过的那几项后面会带着回哪一章，比如：

```text
第 3 项　防火墙已启用
  不通过　ufw 装了但没启用（教材第 3 卷第 9 章）
```

没装某样东西的项目报“跳过”，不算不通过。没装 Docker 的机器上第 6 项就是跳过，退出码仍然是 0。

## 验收标准

七条全部满足才算通过。

1. `sudo ./scripts/check-remote-box.sh` 输出“体检通过”，退出码是 0（`echo $?` 查）。
2. `sudo ufw status verbose` 输出里，`Status: active`、默认策略是 `deny (incoming)`，规则表里每一行你都说得出是给谁开的。
3. 从笔记本用密码去连被直接拒绝：
   `ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password 账户名@192.168.1.50` 返回 `Permission denied (publickey).`
4. `docker inspect -f '{{.Name}} {{.HostConfig.RestartPolicy.Name}}' $(docker ps -aq)` 输出的每一行，策略都是 `unless-stopped` 或者 `always`。
5. 拔电、来电、等两分钟，**不按电源键**，机器自己起来了。
6. 来电之后从笔记本远程跑一次体检，前八项仍然全部通过，容器名单和断电前一样。
7. 拔掉显示器、键盘、鼠标，只留电源线和网线，上面六条重跑一遍结果不变。

第 5 条做不到、BIOS 里确实没有来电自启这一项的机器，这一条记为“不支持”，其余六条照样要过。

## 可以出售的结果

- **远程管理交付**：给客户机器配好远程登录、防火墙、自动启动，交付时当场跑一次体检脚本，把输出存成文件放进验收单。客户拿到的是“这台机器我不用去现场也管得了”，不是几条命令。
- **断电恢复演练**：约定时间上门或远程做一次拔电测试，出一页结果说明，写清哪些服务几分钟内回来了、哪些没有、原因是什么。机房停电、工地断电这类客户吃这一套。
- **开放端口审计**：按 `ss -tln` 和 `ufw status` 清点这台机器上每一个开着的口，逐条写明给谁用、能不能关，出一份端口台账。多数客户机器上有一半的口没人说得清。
- **季度体检**：每季度远程跑一次体检脚本，出一页对照上一次的差异。配置会漂——有人临时关了防火墙没打开、新装的服务没设自启，这项服务卖的是定期确认。
- **交付前基线**：把体检脚本当成出厂检查的一道工序，不过不发货。这一项不单独收费，它降的是你自己的返工率。

## 常见问题

### 执行 `ufw enable` 之后连不上了

接上显示器和键盘，在机器本地登录：

```bash
sudo ufw disable
```

防火墙立刻关掉，SSH 马上回来。然后照 `ufw.rules.example` 从第一条重做，**放行 SSH 在前，启用在后**。

### 第 2 项说密码登录没关，但我明明关了

脚本读的是 `/etc/ssh/sshd_config` 和 `/etc/ssh/sshd_config.d/*.conf`。看一眼实际写了什么：

```bash
grep -riE '^[[:space:]]*PasswordAuthentication' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
sudo sshd -T | grep -i passwordauthentication
```

后一条是 SSH 服务自己算出来的最终结果，以它为准。两边对不上，多半是改完之后没重启服务：

```bash
sudo systemctl restart ssh
```

### 第 5 项说 ssh 不在跑，但我连得上

新版 Ubuntu 把 SSH 改成了按需启动，平时守着端口的是 `ssh.socket`，教材第 3 卷第 4 章说过。脚本会认这种情况，报的是“按需启动，22 端口在等连接”。真报了不通过，以 `ss -tln | grep :22` 和实际能不能连上为准。

### 第 6 项说连不上 Docker 服务

```bash
systemctl status docker
groups | grep docker
```

两种原因：Docker 服务没起来，或者当前账户不在 `docker` 组里（教材第 2 卷第 9 章）。加了组要注销重新登录才生效。

### 第 7 项说定时任务里找不到 backup

脚本默认找关键词 `backup`。你的任务叫别的名字，改一下再跑：

```bash
CHECK_CRON_PATTERN=你的关键词 ./scripts/check-remote-box.sh
```

`crontab -l` 里真的没有那一行，回教材第 2 卷第 12 章重建。

### 拔电之后机器没自己开机

BIOS 里那一项没设对，或者这台机器不支持。分品牌线索在教材第 3 卷第 8 章，`autostart.checklist.example` 里也抄了一份选项名。三个菜单翻遍还是找不到，去品牌官网下你这个型号的说明书，搜 “power loss”。

确实不支持的机器，接一个不间断电源可以绕过去。

### 想改脚本检查哪些服务

```bash
CHECK_SERVICES="ssh docker cron smbd tailscaled" ./scripts/check-remote-box.sh
CHECK_SSH_PORT=2222 ./scripts/check-remote-box.sh
```

三个环境变量都写在脚本开头的注释里。

## 停止和恢复

关掉防火墙：

```bash
sudo ufw disable
```

已经加的规则不会丢，`sudo ufw enable` 就回来了。

让机器重新能睡：

```bash
sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

把图形界面找回来：

```bash
sudo systemctl set-default graphical.target
sudo reboot
```

让某个容器不再自己启动：

```bash
docker update --restart no 容器名
```

体检脚本本身不用停也不用恢复，它只读，删掉就是了。

## 隐私边界

- 文档和示例里的地址一律是 `192.168.1.x` 这种示例地址，不含真实主机名、真实网段、密钥内容。
- **体检脚本的输出里有主机名、内网地址、容器名、开着的端口。** 这是教材[第 0 卷第 8 章](../../../book/00-使用说明/08-文件保护.md)点名的内网信息，往外发之前逐行看一遍。
- 存下来的体检结果文件按内部资料对待，交付给客户的那一份和留档的那一份分开放。
- 脚本不读私钥、不读密码、不发送任何数据到外部。它只调用系统自带的查询命令。
- 交付客户机器时，`authorized_keys` 里不要留你自己的公钥，做法见教材第 3 卷第 9 章。

## 当前范围

这个案例只做单机的远程管理和自启，没有做集中监控、没有做告警、没有做异地的远程访问网关。

下一步可以接三样：把体检脚本挂进定时任务每天跑一次、结果不通过时发一条通知（第 9 卷的内容）；把开放端口台账做成一份能交付的文档；给不支持来电自启的机器配不间断电源。多台机器一起管、集中看状态，属于第 14 卷。
