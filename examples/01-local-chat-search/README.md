# 案例 01　本地聊天记录检索

这份文档用于 Ubuntu Mini PC。完成以后，可以把自己准备的 `txt` 文件导入本地 Meilisearch，并在终端中搜索。

公开版从普通文本文件开始，不包含微信数据库解密、密钥提取或客户端修改步骤。每个非空文本行会成为一条可搜索记录。

## 完成后的结果

- Meilisearch 在 Mini PC 上持续运行。
- 搜索端口只监听 `127.0.0.1`。
- 聊天文本保存在自己指定的目录。
- Python 脚本负责导入和搜索。
- systemd timer 可以每小时重建索引。

## 需要准备什么

- 一台安装 Ubuntu 22.04 或 24.04 的 Mini PC。
- 演示环境建议预留 2 GB 内存和 5 GB 磁盘。
- 当前用户可以执行 `sudo`。
- 准备导入的聊天记录已经保存为 UTF-8 编码的 `txt` 文件。

先检查系统。

```bash
uname -m
python3 --version
```

## 1　安装 Docker

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2 python3 curl openssl
sudo systemctl enable --now docker
sudo docker version
sudo docker compose version
```

后面的 Docker 命令使用 `sudo`。如果已经配置当前用户访问 Docker，可以去掉 `sudo`。

## 2　复制部署目录

把本目录复制到固定位置。

```bash
mkdir -p "$HOME/apps"
cp -R examples/01-local-chat-search "$HOME/apps/local-chat-search"
cd "$HOME/apps/local-chat-search"
```

如果只下载了这个案例，直接把案例目录放到 `$HOME/apps/local-chat-search`。

## 3　生成本地密钥

```bash
cp .env.example .env
sed -i "s/replace-with-a-random-key/$(openssl rand -hex 32)/" .env
chmod 600 .env
mkdir -p data private-data
chmod 700 data private-data
```

检查不含密钥的配置。不要把 `.env` 提交到 Git。

```bash
grep -E '^(MEILI_URL|MEILI_INDEX|CHAT_DATA_DIR)=' .env
```

## 4　先检查示例数据

```bash
python3 scripts/import.py --dry-run
```

示例内容使用虚构姓名和消息。可见结果应当包含下面两行。

```text
找到 4 行文字
检查完成，没有写入索引
```

## 5　启动本地搜索服务

```bash
sudo docker compose up -d
sudo docker compose ps
curl -fsS http://127.0.0.1:7700/health
```

健康检查应当返回下面的内容。

```json
{"status":"available"}
```

## 6　导入并搜索

第一次导入使用 `--reset`，保证索引内容和当前文件一致。

```bash
python3 scripts/import.py --reset
python3 scripts/search.py "预算"
```

搜索结果应当指向 `example-chat.txt` 中包含“预算”的一行。

再试一个词。

```bash
python3 scripts/search.py "Meilisearch"
```

## 7　换成自己的文件

把自己的 `txt` 文件复制到 `private-data`。这个目录已经被 `.gitignore` 排除。

```bash
cp "/你的文件路径/聊天记录.txt" private-data/
sed -i 's#CHAT_DATA_DIR=./sample-data#CHAT_DATA_DIR=./private-data#' .env
python3 scripts/import.py --dry-run
python3 scripts/import.py --reset
```

每次使用 `--reset` 都会清空旧索引，再按当前目录重建。原始 `txt` 文件不会被修改。

## 8　设置每小时更新

下面的服务文件假设案例放在 `$HOME/apps/local-chat-search`。

```bash
mkdir -p "$HOME/.config/systemd/user"
cp systemd/local-chat-index.service "$HOME/.config/systemd/user/"
cp systemd/local-chat-index.timer "$HOME/.config/systemd/user/"
systemctl --user daemon-reload
systemctl --user enable --now local-chat-index.timer
systemctl --user list-timers | grep local-chat-index
```

手动运行一次并查看结果。

```bash
systemctl --user start local-chat-index.service
journalctl --user -u local-chat-index.service -n 30
```

用户退出登录以后，user timer 可能停止。需要无人值守运行时再开启 linger。

```bash
sudo loginctl enable-linger "$USER"
```

## 9　停止和恢复

停止定时更新。

```bash
systemctl --user disable --now local-chat-index.timer
```

停止搜索服务。

```bash
sudo docker compose stop
```

重新启动。

```bash
sudo docker compose start
python3 scripts/search.py "预算"
```

移除容器和网络时，索引数据仍保留在 `data/meili`。

```bash
sudo docker compose down
```

需要重新开始时，先把旧索引改名保存。

```bash
sudo mv data/meili "data/meili.backup-$(date +%Y%m%d-%H%M%S)"
sudo docker compose up -d
python3 scripts/import.py --reset
```

## 10　常见问题

### 无法连接 Meilisearch

```bash
sudo docker compose ps
sudo docker compose logs --tail=50 meilisearch
curl -fsS http://127.0.0.1:7700/health
```

### 提示密钥不正确

确认 `.env` 没有保留示例值。修改密钥后需要重新创建容器。

```bash
sudo docker compose down
sudo docker compose up -d
```

### 找不到自己的文件

```bash
grep '^CHAT_DATA_DIR=' .env
find private-data -maxdepth 2 -type f -name '*.txt'
python3 scripts/import.py --dry-run
```

### 定时任务没有运行

```bash
systemctl --user status local-chat-index.timer
journalctl --user -u local-chat-index.service -n 50
loginctl show-user "$USER" -p Linger
```

## 隐私边界

- `private-data`、`.env` 和 `data/meili` 不进入 Git。
- 端口保持绑定在 `127.0.0.1`。
- 不要把群聊内容直接用于公开发布或模型训练。
- 备份聊天文件以前，先确认备份位置和访问权限。

## 当前范围

这个项目提供本地全文检索，没有接入本地模型。下一步可以让本地模型只读取搜索结果，再回答问题。模型接入前，先确认检索结果和权限范围正确。
