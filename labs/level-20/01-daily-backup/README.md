# 案例 01　每周自动备份到移动硬盘

这份文档用于 Ubuntu Mini PC。完成以后，机器每周自己把重要目录备份两份：一份留在本机，一份写到移动硬盘。附带一个验收脚本，它会造一个测试文件、跑一次备份、删掉原件、再从备份里还原回来，把每一步的结果打出来。

案例自带演示数据，先用演示数据跑通，再换成自己的目录。对应教材[第 2 卷第 12 章](../../../book/02-Ubuntu/12-日常备份.md)。

## 完成结果

- `backup.sh` 能手动跑，也能交给定时任务跑。
- 本机一份在 `~/ai/backup/latest`，移动硬盘一份在你指定的目录。
- 模型文件、依赖目录、数据库数据目录按清单排除，不进备份。
- 移动硬盘没插的时候，脚本记一行日志正常退出，不报错、不中断。
- `verify-restore.sh` 能一条命令验收整套备份，通过与否有明确的退出码。
- 每次运行都写进日志文件，能查什么时候跑过、同步了哪些目录。

## 准备条件

- 一台装了 Ubuntu 22.04 或 24.04 的 Mini PC，`rsync` 可用（`rsync --version` 有输出，没有就 `sudo apt install rsync`）。
- 一块移动硬盘，可用空间大于要备份的目录总和。只想先看效果的话，这一项可以先不要。
- 按教材第 1 章建好的 `~/ai` 目录结构（`data`、`projects`、`scripts`、`backup`、`models`）。
- 演示部分只用案例自带的 `sample-data`，不需要真实资料。

检查环境。

```bash
rsync --version | head -1
bash --version | head -1
```

## 文件

```text
backup-exclude.txt        排除清单，哪些目录和文件不进备份
crontab.example           定时任务示例行
scripts/backup.sh         备份脚本
scripts/verify-restore.sh 验收脚本
sample-data/              演示数据，含两个故意不该被备份的文件
```

`sample-data/projects/demo-report` 里放了 `node_modules/` 和 `model.gguf` 两样东西，用来验证排除清单确实生效。

## 操作步骤

### 1　复制到固定位置

```bash
mkdir -p "$HOME/apps"
cp -R labs/level-20/01-daily-backup "$HOME/apps/daily-backup"
cd "$HOME/apps/daily-backup"
chmod 755 scripts/backup.sh scripts/verify-restore.sh
```

只下载了这个案例，就把案例目录放到 `$HOME/apps/daily-backup`。

### 2　先用演示数据跑一遍验收

不带任何参数，它只动案例自己的 `sample-data` 和 `demo-backup` 两个目录，碰不到你的真实资料。

```bash
./scripts/verify-restore.sh
```

### 3　看看备份出来的结构

```bash
find demo-backup -maxdepth 3
```

`node_modules` 和 `model.gguf` 不应该出现在这里面。

### 4　换成自己的目录

把脚本和清单放进教材约定的位置。

```bash
cp scripts/backup.sh "$HOME/ai/scripts/"
cp backup-exclude.txt "$HOME/ai/scripts/"
chmod 755 "$HOME/ai/scripts/backup.sh"
```

先看移动硬盘挂在哪，在上面建一个专用目录。

```bash
ls /media/$USER/
mkdir -p /media/$USER/换成你的卷标/minipc-backup
```

第一次跑之前先试运行，看它打算做什么。输出里出现以 `*deleting` 开头的行就停下来，说明目标目录写错了。

```bash
rsync -a --delete --dry-run --itemize-changes \
  --exclude-from="$HOME/ai/scripts/backup-exclude.txt" \
  "$HOME/ai/data" "$HOME/ai/backup/latest/"
```

真跑一次。

```bash
"$HOME/ai/scripts/backup.sh" "/media/$USER/换成你的卷标/minipc-backup"
```

### 5　对真实目录做一次验收

```bash
BACKUP_SOURCES="$HOME/ai/data:$HOME/ai/projects:$HOME/ai/scripts" \
BACKUP_LOCAL_DEST="$HOME/ai/backup/latest" \
BACKUP_EXCLUDE_FILE="$HOME/ai/scripts/backup-exclude.txt" \
  ./scripts/verify-restore.sh "/media/$USER/换成你的卷标/minipc-backup"
```

验收脚本造的测试文件叫 `restore-check-日期时间.txt`，跑完自己删掉，不会动你已有的文件。

### 6　交给定时任务

`crontab.example` 里是可以直接抄的一行。

```bash
crontab -e
```

把示例行抄进去，账户名和卷标换成你自己的，路径写全。

```bash
crontab -l
```

## 正常结果

`./scripts/verify-restore.sh` 的输出（路径会换成你机器上的）：

```text
备份验收
  源目录      .../sample-data/notes:.../sample-data/projects
  本机备份    .../demo-backup/latest
  移动硬盘    .../demo-backup/external

第 1 步　造一个测试文件
第 2 步　跑一次备份
第 3 步　检查备份里有没有这个文件
  通过　本机备份里有它，内容一致
  通过　移动硬盘那份里有它，内容一致

第 4 步　检查排除清单有没有生效
  通过　该排除的目录和大文件都没进备份

第 5 步　删掉原件，再从备份还原
  通过　从本机备份还原成功，内容和删之前一致

第 6 步　清理测试文件
  通过　源里删掉的文件，备份里也跟着删了

结果　通过 5 项，不通过 0 项，跳过 0 项
验收通过。
```

`backup.sh` 单独跑的输出：

```text
2026-08-14 16:20:01 开始备份
2026-08-14 16:20:38 已同步 /home/账户名/ai/data
2026-08-14 16:21:02 已同步 /home/账户名/ai/projects
2026-08-14 16:21:02 已同步 /home/账户名/ai/scripts
2026-08-14 16:21:02 配置文件已复制
2026-08-14 16:23:47 已同步到 /media/账户名/卷标/minipc-backup
2026-08-14 16:23:47 备份结束
```

移动硬盘没插的时候，最后两行换成一句“找不到……移动硬盘可能没插，这次只做了本机这一份”，退出码仍然是 0。

## 验收标准

六条全部满足才算通过。

1. `./scripts/verify-restore.sh` 输出“验收通过”，退出码是 0（`echo $?` 查）。
2. 本机备份目录下有 `data`、`projects`、`scripts`、`config` 四项，内容和源目录对得上。
3. 移动硬盘那份和本机那份内容一致。
4. 备份目录里搜不到 `node_modules`、`__pycache__`、`*.gguf`、`*.safetensors`：
   `find 备份目录 \( -name node_modules -o -name '*.gguf' \) | wc -l` 输出 0。
5. 给一个不存在的移动硬盘路径跑一次，脚本记一行日志并正常结束，退出码是 0。
6. 定时任务到点后，日志文件里出现新的一组带时间的行。

## 可以出售的结果

- **备份配置交付**：给客户机器装好这套脚本、排除清单和定时任务，交付时当场跑一次验收脚本，把输出截图放进验收单。客户拿到的是“删了能找回来”这件事，不是一个脚本文件。
- **还原演练**：每季度上门或远程跑一次验收脚本，出一页结果说明。备份失效通常很安静，这项服务卖的是定期确认。
- **备份策略评估**：按客户的目录清点哪些要备份、哪些能重新生成、丢多久的数据可以接受，出一份排除清单和备份频率建议。
- **整盘镜像加文件备份的组合方案**：镜像用于系统崩了重装（教材第 1 卷第 10 章），文件备份用于误删找回，两条线一起交付，说明各自的恢复时间。

## 常见问题

### 提示找不到排除清单

```bash
ls -l backup-exclude.txt
BACKUP_EXCLUDE_FILE="$HOME/ai/scripts/backup-exclude.txt" ./scripts/backup.sh
```

脚本默认在自己上一级目录找 `backup-exclude.txt`。把 `backup.sh` 单独复制到 `~/ai/scripts` 时，清单要一起复制过去。

### 备份目录里少了东西

先看是不是被清单排掉的。

```bash
grep -n '' backup-exclude.txt
tail -30 "$HOME/ai/backup/backup.log"
```

### 移动硬盘那份没更新

```bash
ls /media/$USER/
tail -5 "$HOME/ai/backup/backup.log"
```

日志里是“找不到……”，说明跑的时候硬盘没挂上。卷标变了的话，定时任务里的路径要跟着改。

### 数据库目录报权限不足

容器里的数据库写出来的文件，属主不是你的账户，普通账户读不了，所以清单里排除了 `postgres/`。要备份它，先停服务再用管理员权限复制：

```bash
cd "$HOME/ai/projects/gitea"
docker compose stop
sudo rsync -a "$HOME/ai/projects/gitea/postgres" "/media/$USER/卷标/minipc-backup/gitea-postgres/"
docker compose start
```

### 定时任务没跑

```bash
crontab -l
ls -l "$HOME/ai/scripts/backup.sh"
journalctl -u cron --since today | tail -20
```

三项依次看：任务行在不在、脚本有没有 `x` 权限、cron 有没有把命令发出去。

## 停止和恢复

停掉自动备份：

```bash
crontab -e
```

在那一行前面加一个 `#` 注释掉，保存退出。已经备好的文件不受影响。

恢复自动备份：把 `#` 去掉。

删掉演示产生的文件：

```bash
rm -rf demo-backup
```

从备份里还原一个文件：

```bash
cp "$HOME/ai/backup/latest/data/文件名" "$HOME/ai/data/"
```

整台机器要恢复，先用整盘镜像把系统写回去（教材第 1 卷第 10 章），再把这份备份复制回 `~/ai`。

## 隐私边界

- `sample-data` 里全部是虚构内容，不含真实客户资料。
- 备份日志会记下目录路径，往外发之前按教材第 0 卷第 8 章检查一遍。
- 移动硬盘上的备份等于把资料带出机房，存放位置和借出规则要和客户讲清楚。
- 排除清单里没有密钥类文件——`.env` 这类是要备份的，但备份介质本身要按密钥同等对待，不要随手插到别的机器上。

## 当前范围

这个案例只做文件级备份，没有做异地副本和加密。下一步可以把移动硬盘那份改成同步到另一台机器或者对象存储，加密之后再传。数据库的一致备份要用数据库自己的导出命令，属于第 3 卷的内容。
