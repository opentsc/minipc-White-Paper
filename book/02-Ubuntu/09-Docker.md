# 09　Docker

## 这一章的任务

装好 Docker，跑起第一个容器应用，从浏览器打开它。

跑起来的是一个服务监控面板：你把要盯的地址填进去，它每隔一分钟去看一眼通不通，断了就在页面上标红。第 6 卷跑起本地模型服务之后，用它盯着那个服务，就是它最实在的用途。

做完之后你手上有一套通用的动作：拿到别人给的一行 `docker run`，你知道每个参数在干什么、数据落在你硬盘的哪里、怎么看它的日志、怎么删了重来。**后面第 6 卷的模型服务、第 7 卷的知识库、第 9 卷的自动化工具，全部是这一章的重复。**

## 开始前

- 第 3 章装的 `ca-certificates` 和 `gnupg` 已经在了，这一章要用；
- 网络能连通，装 Docker 要下载几百 MB；
- 第 6 章的 `systemctl status` 和第 7 章的 `journalctl` 会用了；
- 40 分钟，下载慢的话久一点。

## 新词

**容器**（Container）：把一个程序和它需要的全部东西打包在一起，跑起来之后和系统里其他程序互不干扰。装它不会往系统里散落文件，删它也不会留下残渣。

**镜像**（Image）：容器的出厂状态，一个只读的打包文件。镜像是模子，容器是照模子做出来跑着的那一个。同一个镜像可以同时跑起好几个容器。

**Docker Hub**：放镜像的公开仓库。`docker run` 后面写的那个名字，比如 `louislam/uptime-kuma`，就是去这里取。

**标签**（Tag）：镜像名后面冒号跟着的那段，例如 `louislam/uptime-kuma:1` 里的 `1`。它指的是版本。不写标签默认取 `latest`，`latest` 会跟着上游变，**本教材一律写明标签**。

**端口映射**：容器有自己独立的一套网络，里面的程序开在哪个端口，外面默认访问不到。端口映射就是在宿主机上开一个门，通到容器里的某个端口。

**目录映射**（挂载卷）：把宿主机上的一个目录接到容器里面去。容器往那个位置写的文件，实际落在你的硬盘上。**这是容器里唯一不会随容器删除而消失的东西。**

**宿主机**（Host）：跑着 Docker 的这台机器本身，也就是你的 Mini PC。和“容器里面”相对。

## 装 Docker

Docker 不在 Ubuntu 自带的软件源里，要先把它的官方源加进来。下面四步照抄，中间不要跳。

**第一步，把 Docker 的签名密钥存下来**：

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

作用：建一个放密钥的目录，把 Docker 的公钥下载进去，再让所有账户能读它。系统靠这个密钥验证下载到的软件包是不是 Docker 官方发的。三条命令都没有输出。

**第二步，把软件源写进系统**：

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

这条很长，**整条复制过去，不要手打**。里面两处 `$(...)` 会自动换成你这台机器的架构和 Ubuntu 版本代号，不用自己填。

**第三步，刷新清单并安装**：

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

`apt update` 的输出里应该出现一行 `download.docker.com`，说明新源认上了。没出现的话回第二步重来。

最后那个 `docker-compose-plugin` 是第 10 章要用的，一起装上。

**第四步，确认装上了**：

```bash
sudo docker version
```

输出分 `Client` 和 `Server` 两段，两段都有版本号就对了。只有 `Client` 那段、`Server` 那段报错，说明 Docker 服务没起来：

```bash
sudo systemctl enable --now docker
```

第 6 章那条命令，让它现在起来、以后开机自己起来。

> 国内网络下 `download.docker.com` 可能很慢或者连不上。等太久就改用 Ubuntu 自带源里的版本：`sudo apt install docker.io docker-compose-v2`。这个版本旧一些，本教材后面全部步骤都能跑，两条路选一条，不要两边都装。

## 让自己不用每次都打 sudo

刚装好时，`docker` 命令必须加 `sudo`。把你的账户加进 `docker` 组就不用了：

```bash
sudo usermod -aG docker $USER
```

`-aG` 里的 `a` 不能漏，原因见第 4 章。

**加完要注销重新登录才生效。** 不想现在注销，可以在当前终端里执行 `newgrp docker` 临时生效，但新开的终端窗口还是老样子，最终还是要注销一次。

> **加进 `docker` 组等于给了这个账户管理员权限。** 有 Docker 权限的人可以把系统盘的任何目录挂进容器，然后以 root 身份改里面的文件。所以只把你自己加进去，第 4 章建的那个受限账户不要加。

重新登录之后验证：

```bash
docker run hello-world
```

作用：下载一个只有几百 KB 的测试镜像并跑起来，跑完就退出。正常输出里有这么一句：

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

看到这句，Docker 就装好了。前面不用加 `sudo` 也能跑通，说明组也加对了。

## 跑起第一个容器

先建好要给容器用的目录：

```bash
mkdir -p ~/ai/projects/uptime-kuma/data
```

按第 1 章的约定，一个项目一个目录，放在 `~/ai/projects` 下面。

然后是这一章的主命令：

```bash
docker run -d \
  --name uptime-kuma \
  --restart unless-stopped \
  -p 3001:3001 \
  -v "$HOME/ai/projects/uptime-kuma/data:/app/data" \
  louislam/uptime-kuma:1
```

一行写不下时用反斜杠 `\` 换行，行末的反斜杠后面不能有空格。整段复制粘贴进终端，最后回车。

第一次执行要下载镜像，输出是一堆滚动的进度条，几百 MB，看网速。下完之后打印一长串十六进制字符，那是容器的编号，跑起来了。

五个参数一个个说，**后面每一卷的部署命令都是这几个参数的组合**：

**`-d` 后台跑。** 不加的话容器占着你的终端窗口，关掉窗口它就停了。服务类的容器一律加 `-d`。

**`--name uptime-kuma` 给容器起名字。** 不起名字 Docker 会随机给一个，像 `nervous_hopper` 这种，下次要停它还得先去查。起了名字之后，停它、看日志、删它都用这个名字。

**`--restart unless-stopped` 决定它什么时候自己起来。** 这个值的意思是：机器重启后自动起来，容器自己崩了也自动起来，但你手动 `docker stop` 停掉的就一直停着，不跟你对着干。服务类容器就用这个值。

**`-p 3001:3001` 端口映射。** 冒号前面是宿主机上的端口，后面是容器里的端口。**这两个数字不必相同，前面那个才是你在浏览器里输的。** 3001 已经被别的程序占了，就把前面改成 `3080:3001`，浏览器里输 3080，容器里面的程序毫不知情。

**`-v 宿主机目录:容器内目录` 目录映射。** 这里把 `~/ai/projects/uptime-kuma/data` 接到容器里的 `/app/data`。容器往 `/app/data` 写的东西，实际落在你硬盘上那个目录里。冒号前面必须是完整路径，所以写 `$HOME` 不写 `~`，`$HOME` 就是你的家目录。

最后一行 `louislam/uptime-kuma:1` 是镜像名和标签，本地没有就自动去 Docker Hub 下。

## 从浏览器打开

看看它起来没有：

```bash
docker ps
```

正常输出（宽度关系，这里省掉了几列）：

```
CONTAINER ID   IMAGE                    STATUS         PORTS                    NAMES
a1b2c3d4e5f6   louislam/uptime-kuma:1   Up 2 minutes   0.0.0.0:3001->3001/tcp   uptime-kuma
```

`STATUS` 那列是 `Up` 加上跑了多久，就是正常的。

打开浏览器，地址栏输入：

```
http://localhost:3001
```

`localhost` 就是这台机器自己。第一次打开是一个设置页面，选语言、填一个管理员用户名和密码，提交之后进主界面。

**这个密码是你自己设的，和系统账户没关系，记在密码管理器里。**

进去之后点“添加监控项”，类型选 HTTP(s)，地址随便填一个你常用的网址，保存。过一会儿页面上会出现一条绿色的心跳条，那是它每隔几十秒去访问一次的结果。

同一个局域网里的其他电脑要访问，把 `localhost` 换成这台机器的 IP 地址。查 IP 用 `ip a`，具体在第 3 卷讲。

## 看一眼目录映射真的生效了

回到终端：

```bash
ls -lh ~/ai/projects/uptime-kuma/data
```

里面出现了几个文件，其中一个是 `kuma.db`，那是它的数据库。这些文件是容器里的程序写出来的，落在你自己的硬盘上，你能看到、能复制、能备份（第 12 章）。

**这就是目录映射的意义。** 没有 `-v` 的容器，数据只存在容器内部，容器一删数据跟着没。有了 `-v`，容器变成一个随时能扔掉重建的壳子，值钱的东西在你的目录里。

后面各卷的部署命令里，凡是有 `-v` 的位置，都要想一下这一句。

## 四个日常命令

### `docker ps` 看有哪些容器

```bash
docker ps
```

只列正在跑的。

```bash
docker ps -a
```

`-a` 把停掉的也列出来。刚才那个 `hello-world` 就在这里面，`STATUS` 是 `Exited (0)`，括号里的 0 表示它正常跑完退出了，不是出错。

### `docker logs` 看容器的日志

```bash
docker logs uptime-kuma
```

作用：打印这个容器从启动到现在的全部输出。

**容器出问题时第一条就用它。** 容器起不来、页面打不开、功能不对，原因基本都在这里面。

两个常用选项，和第 7 章 `journalctl` 是一个意思：

```bash
docker logs --tail 50 uptime-kuma
```

只看最后 50 行。

```bash
docker logs -f uptime-kuma
```

盯着新出来的日志，`Ctrl+C` 退出。开两个窗口，一个盯日志，另一个去浏览器里点，能看到每次操作对应的输出。

### `docker stop` 和 `docker start` 停和起

```bash
docker stop uptime-kuma
```

作用：停掉容器。会打印一遍容器名，等几秒，因为它先礼貌地通知程序退出，程序自己收尾。这时候刷新浏览器打不开了。

```bash
docker start uptime-kuma
```

起回来。刷新浏览器，页面和数据都在。

```bash
docker restart uptime-kuma
```

停了再起，改完配置让它重新读一遍时用。

### `docker rm` 删掉容器

```bash
docker stop uptime-kuma
docker rm uptime-kuma
```

**要先停再删**，跑着的容器删不掉，会报 `container is running`。

删完 `docker ps -a` 里就没有它了。

现在把上面那条完整的 `docker run` 原样再执行一次——容器回来了，浏览器打开，你设的管理员账号、加的监控项，全都还在。**因为数据在 `~/ai/projects/uptime-kuma/data`，不在容器里。**

> **删容器不会删你用 `-v` 映射出来的目录，但会删容器内部的其他一切。** 一个容器如果没有 `-v`，`docker rm` 之后里面的数据就没了，没有回收站。删之前先想一下：这个容器的数据在哪个目录？答不上来就先别删。

顺手把 `hello-world` 那个也清掉。先 `docker ps -a` 找到 `IMAGE` 那列是 `hello-world` 的行，看它 `NAMES` 那列的随机名字，然后：

```bash
docker rm 那个随机名字
```

要为一个随机名字回头查一次列表，这就是 `--name` 存在的理由。

## 镜像占地方，也要管

```bash
docker images
```

列出本地已经下载的镜像和各自的大小。

```bash
docker system df
```

作用：一眼看清镜像、容器、卷各占了多少磁盘。第 5 章讲过系统盘不能撑满，镜像是后面最容易吃掉空间的东西之一——一个模型相关的镜像动辄好几 GB。

删掉不用的镜像：

```bash
docker rmi hello-world
```

被容器用着的镜像删不掉，会报错，那是保护，不是故障。

清理所有停着的容器和没被任何容器使用的镜像：

```bash
docker system prune -a
```

**这条会把当前没在跑的容器和它们的镜像全删掉**，下次要用得重新下载。空间紧张的时候再用，平时不用。用 `-v` 映射出来的目录不受影响。

## 开机之后自己回来

```bash
systemctl status docker
```

`Loaded` 那行末尾是 `enabled`，说明 Docker 本身开机自启（第 6 章的读法）。加上容器那个 `--restart unless-stopped`，机器重启之后容器会自己回来。

真的重启一次验证：

```bash
sudo reboot
```

开机后不用做任何事，直接打开浏览器访问 `http://localhost:3001`，页面在，就说明这一整套自启是通的。第 6 卷的模型服务要求的就是这个效果——你不在的时候它也在。

有哪一步做不出来，到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

## 事实来源和版本日期

- Docker 官方软件源的四步安装命令，来自 Docker 官方文档的 Ubuntu 安装说明。命令随文档更新可能微调，以你安装当天的官方页面为准；
- `louislam/uptime-kuma:1` 是这个镜像的大版本标签，跟着 1.x 系列走。镜像的最新标签和端口在它的项目页面上，改版后以那里为准；
- 本章核验日期：2026-08-14。

## 完成检查

- `docker version` 的 `Client` 和 `Server` 两段都有版本号吗？
- 不加 `sudo` 执行 `docker ps`，能列出容器吗？
- 浏览器打开 `http://localhost:3001`，看到监控面板了吗？
- `ls ~/ai/projects/uptime-kuma/data` 里有文件吗？这些文件是谁写的？
- `-p 3001:3001` 里的两个数字，哪个是你在浏览器里输的？
- 把容器删掉再用同一条命令建回来，数据还在吗？为什么？
- `--restart unless-stopped` 是什么意思？你手动停掉的容器，机器重启后会自己起来吗？
- 重启机器之后，不做任何操作，页面还能打开吗？

## 下一步

进入[第 10 章：Docker Compose](10-Docker-Compose.md)。
