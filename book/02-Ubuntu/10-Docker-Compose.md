# 10　Docker Compose

## 这一章的任务

用一个文件、一条命令，起一套两个容器的服务。

起的是一个自己的代码仓库服务 Gitea，加上它要用的数据库。跑起来之后，浏览器打开就是一个和 GitHub 长得差不多的界面，代码和资料存在你自己这台机器上，不上传到任何地方。

做完之后你手上多一份可以照着改的 `compose.yaml`。**后面各卷凡是要同时起两个以上容器的部署，都是这个文件换个内容。**

## 开始前

- 第 9 章的 Docker 装好了，`docker ps` 不加 `sudo` 能跑；
- 第 9 章装的 `docker-compose-plugin` 在（用 Ubuntu 自带源的话是 `docker-compose-v2`）；
- 40 分钟，第一次下载镜像慢一些。

## 新词

**Docker Compose**：把一套服务的全部参数写进一个文件，用一条命令起停的工具。第 9 章那条 `docker run` 后面跟的五个参数，在这里变成文件里的几行。

**`compose.yaml`**：Compose 读的那个文件，固定叫这个名字，放在项目目录里。老一点的教程里叫 `docker-compose.yml`，同一个东西，两个名字都认。

**YAML**：这个文件用的格式。它靠缩进表示层级关系，**只能用空格缩进，不能用 Tab 键**，同一层的项目缩进必须一样多。这是新手在这一章唯一会栽的跟头。

**服务**（service）：`compose.yaml` 里定义的每一个容器叫一个服务。一套里有两个容器，就写两段。

## 为什么不接着用 `docker run`

第 9 章那条命令已经有五个参数了。现在要起两个容器，还多出三件事：

- 两个容器要能互相找到，Gitea 得知道数据库在哪；
- 起的顺序有讲究，数据库先起来；
- 这一堆参数下次还要用，写在纸上、记在脑子里都不牢靠。

Compose 解决的就是这三件。参数全写进文件，文件跟着项目目录走，下次换台机器把这个文件拷过去，一条命令原样起回来。**这个文件本身就是这套服务的说明书**，半年后你想知道当初端口设了多少，打开它看一眼就行。

## 第一步，建项目目录

```bash
mkdir -p ~/ai/projects/gitea
cd ~/ai/projects/gitea
```

一个项目一个目录，第 1 章的约定。这一章后面的命令都在这个目录里执行——**Compose 认的是当前目录下的 `compose.yaml`，走错目录就找不到文件。**

## 第二步，写 compose.yaml

```bash
nano compose.yaml
```

把下面这些原样抄进去。抄的时候注意缩进，每一级两个空格：

```yaml
services:
  gitea:
    image: gitea/gitea:1
    container_name: gitea
    restart: unless-stopped
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432
      - GITEA__database__NAME=gitea
      - GITEA__database__USER=gitea
      - GITEA__database__PASSWD=change-this-password
    ports:
      - "3000:3000"
    volumes:
      - ./data:/data
    depends_on:
      - db

  db:
    image: postgres:16
    container_name: gitea-db
    restart: unless-stopped
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=change-this-password
      - POSTGRES_DB=gitea
    volumes:
      - ./postgres:/var/lib/postgresql/data
```

`Ctrl+O` 回车保存，`Ctrl+X` 退出。

**抄完先改两处**：

1. 两个 `change-this-password` 改成同一个你自己定的密码，两处必须一致，不然 Gitea 连不上数据库。这个密码只有这两个容器之间用，你不需要记；
2. `USER_UID` 和 `USER_GID` 这两个数字，用 `id -u` 和 `id -g` 查出你自己的填进去。多数机器上第一个账户就是 1000。它的作用是让容器写出来的文件属主是你，不然你在宿主机上改不动那些文件。

## 这个文件在说什么

**最外层的 `services:`** 底下是这一套里的每个容器。这里有两个：`gitea` 和 `db`。这两个名字你自己起，但它们同时是容器在这套网络里的主机名——所以 Gitea 那段里写 `GITEA__database__HOST=db:5432`，`db` 指的就是下面那个数据库容器。**同一个 `compose.yaml` 里的容器，用服务名互相找。**

**`image`** 是用哪个镜像，和第 9 章 `docker run` 最后那一行是同一个东西。

**`container_name`** 是容器名，等于第 9 章的 `--name`。

**`restart: unless-stopped`** 等于第 9 章的 `--restart`，含义一样。

**`ports`** 等于 `-p`，写法也一样，冒号前是宿主机端口，后是容器里的端口。**注意 `db` 那段没有 `ports`**，这是故意的：数据库不需要从外面访问，同一套里的 Gitea 能连上它就够了。不映射端口，局域网里的其他机器就碰不到这个数据库。用不着的端口不要往外开。

**`volumes`** 等于 `-v`。这里写的 `./data` 是相对路径，`.` 表示 `compose.yaml` 所在的这个目录，所以实际位置是 `~/ai/projects/gitea/data`。目录不用提前建，Compose 会建。

**`environment`** 是传给容器里程序的配置，一项一行。第 9 章没用到它，这里两个容器都要用：数据库靠这几项知道该建哪个库、账号密码是什么；Gitea 靠这几项知道去哪儿连数据库。这些名字是各个镜像自己定的，抄它的官方说明，不用自己想。

**`depends_on`** 表示先起 `db` 再起 `gitea`。它只管启动顺序，不保证数据库那一刻已经能接受连接，所以第一次启动时 Gitea 可能先报几条连不上数据库的错，过几秒自己就好了，这不是故障。

## 第三步，四个动作

### 一、`up -d` 起来

```bash
docker compose up -d
```

作用：按 `compose.yaml` 把这一套全部起来，`-d` 和第 9 章一样是后台跑。

第一次执行要下载两个镜像，输出是一堆进度条，最后几行类似：

```
[+] Running 3/3
 ✔ Network gitea_default     Created
 ✔ Container gitea-db        Started
 ✔ Container gitea           Started
```

三行都是 `Started` 或 `Created` 就成了。中间那个 `Network` 是 Compose 自动建的一个网络，两个容器接在上面，它们才能用服务名互相找到。

**注意命令是 `docker compose`，中间一个空格。** 老教程里的 `docker-compose`（带横杠）是上一代的独立程序，参数大同小异，本教材一律用带空格的新写法。

### 二、`ps` 看状态

```bash
docker compose ps
```

作用：只列出这一套里的容器，不像 `docker ps` 那样把机器上所有容器都列出来。

```
NAME        IMAGE            STATUS         PORTS
gitea       gitea/gitea:1    Up 30 seconds  0.0.0.0:3000->3000/tcp
gitea-db    postgres:16      Up 31 seconds  5432/tcp
```

两行都是 `Up` 就对了。`gitea-db` 那行的端口没有 `0.0.0.0->` 这一段，因为没往外映射。

### 三、`logs` 看日志

```bash
docker compose logs
```

作用：把这一套里所有容器的日志混在一起显示，每行前面标着是哪个容器写的。

只看一个：

```bash
docker compose logs gitea
```

只看最后几行、盯着新的，和第 9 章一样：

```bash
docker compose logs --tail 50 -f gitea
```

**页面打不开、功能不对，先看这里。** 两个容器的场景里，一半的问题是数据库那边报出来的，所以要会分别看。

### 四、`down` 停掉

```bash
docker compose down
```

作用：把这一套的容器停掉并删除，连同 Compose 建的那个网络一起。

**`down` 不会动 `./data` 和 `./postgres` 这两个目录**，数据都在你自己的目录里。再执行一次 `docker compose up -d`，容器重新建出来，网站和数据原样回来。

只想停一会儿、不删容器：

```bash
docker compose stop
docker compose start
```

## 第四步，浏览器里完成安装

打开 `http://localhost:3000`。

第一次打开是 Gitea 的初始配置页：

1. **数据库那几项已经按 `compose.yaml` 里的设置填好了，不要改**；
2. 往下拉，找到“管理员账号设置”，把它展开，填一个管理员用户名、密码和邮箱。**这一步不要跳过**——跳过的话第一个注册的人自动成为管理员；
3. 其他项保持默认，点“立即安装”；
4. 等十几秒，页面跳到首页，右上角是你刚建的账户。

进去点“＋”新建一个仓库，随便起个名字，建出来就说明这一套两个容器配合正常——网页是 Gitea 给的，仓库信息存在数据库容器里。

**密钥、`.env` 这类文件不要传进这个仓库**，哪些内容不能进 Git 见[第 0 卷第 8 章](../00-使用说明/08-文件保护.md)。虽然这个服务在你自己机器上，习惯要一样。

## 改了配置怎么重新生效

改 `compose.yaml` 之后，**不是 `restart`，是再执行一次 `up -d`**：

```bash
docker compose up -d
```

Compose 会对比文件和正在跑的容器，只重建有变化的那个，没变的不动。输出里会看到类似 `Recreated` 的字样。

`docker compose restart` 只是把容器停了再起，用的还是旧参数，改完文件用它等于白改。这是这一章最容易踩的坑。**改文件用 `up -d`，没改文件只想让程序重读自己的配置才用 `restart`。**

下一章要改的端口就走这条路。

## 数据在哪，哪些能直接看

```bash
ls ~/ai/projects/gitea
```

三样东西：`compose.yaml` 是说明书，`data` 是 Gitea 的仓库和配置，`postgres` 是数据库的文件。

`data` 里面你能随便看，属主是你。`postgres` 那个目录进不去，`ls` 会报权限不足——里面的文件属主是容器里的数据库账户，宿主机上显示成一串数字编号。这是数据库镜像的正常行为，不是故障。这类目录怎么备份，第 12 章单说。

有哪一步做不出来，到[第 15 卷：故障排查](../15-故障排查/README.md)按症状查。

## 事实来源和版本日期

- `compose.yaml` 里 Gitea 那几个 `GITEA__database__` 开头的配置项名字，来自 Gitea 官方的 Docker 安装说明，随版本可能增减；
- `gitea/gitea:1` 和 `postgres:16` 是两个镜像的大版本标签，各自跟着 1.x 和 16.x 走；
- 本章核验日期：2026-08-14。

## 完成检查

- `docker compose up -d` 之后，`docker compose ps` 里两行都是 `Up` 吗？
- 浏览器打开 `http://localhost:3000`，装完之后能新建一个仓库吗？
- `compose.yaml` 里 `db` 那段为什么没有 `ports`？
- Gitea 那段里的 `HOST=db:5432`，这个 `db` 是从哪儿来的？
- YAML 缩进能用 Tab 键吗？
- 改完 `compose.yaml` 该执行哪条命令让它生效，为什么不是 `restart`？
- `docker compose down` 之后，`~/ai/projects/gitea/data` 还在吗？

## 下一步

进入[第 11 章：环境变量与配置文件](11-环境变量与配置文件.md)。
