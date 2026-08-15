#!/usr/bin/env bash
# 信息抓取日报体检：逐项检查这台机器上那条日报流程的地基是不是还在。
#
# 全部是只读检查，不改任何配置，不新建、不删除、不重启任何容器，
# 也不修改任何工作流。随时可以跑。
#
# 唯一会“动”的地方是第 3 项要在 n8n 容器里向 Ollama 的模型列表接口
# 发一次请求。那只是问一句“你在不在”，不加载任何模型，也不做推理。
#
# 它不打开任何日报文件，不读工作流内容，不打印任何凭据与环境变量的值。
#
# 用法：
#   ./check-n8n.sh
#
# 可以用环境变量改默认值：
#   CHECK_N8N_NAME       容器名，默认 n8n
#   CHECK_N8N_PORT       宿主机端口，默认 5678
#   CHECK_OLLAMA_URL     容器里去问的地址，默认 http://host.docker.internal:11434/v1/models
#   CHECK_N8N_DATA       n8n 数据卷在容器里的挂载点，默认 /home/node/.n8n
#   CHECK_WORK_MOUNT     工作目录在容器里的挂载点，默认 /data
#   CHECK_DAILY_DIR      宿主机上的日报目录，默认 $HOME/ai/data/daily
#   CHECK_TIMEOUT        等接口返回的秒数，默认 15
#
# 退出码：全部通过是 0，有任何一项不通过是 1。查不到的项报“跳过”，不算不通过。

set -uo pipefail

N8N_NAME="${CHECK_N8N_NAME:-n8n}"
N8N_PORT="${CHECK_N8N_PORT:-5678}"
OLLAMA_URL="${CHECK_OLLAMA_URL:-http://host.docker.internal:11434/v1/models}"
N8N_DATA="${CHECK_N8N_DATA:-/home/node/.n8n}"
WORK_MOUNT="${CHECK_WORK_MOUNT:-/data}"
DAILY_DIR="${CHECK_DAILY_DIR:-$HOME/ai/data/daily}"
API_TIMEOUT="${CHECK_TIMEOUT:-15}"

PASS=0
FAIL=0
SKIP=0

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }
note() { printf '  说明　%s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# 容器在不在（不管跑没跑）。在返回 0。
container_exists() {
  docker inspect "$N8N_NAME" >/dev/null 2>&1
}

# 问 docker 要某一项信息。拿不到就没有输出。
inspect_one() {
  docker inspect --format "$1" "$N8N_NAME" 2>/dev/null
}

printf '信息抓取日报体检\n'
printf '  时间          %s\n' "$(date '+%F %T')"
printf '  容器名        %s\n' "$N8N_NAME"
printf '  宿主机端口    %s\n' "$N8N_PORT"
printf '  日报目录      %s\n' "$DAILY_DIR"
printf '\n'

DOCKER_OK=""
if have docker && docker info >/dev/null 2>&1; then
  DOCKER_OK="yes"
fi

# ---------------------------------------------------------------- 1
printf '第 1 项　n8n 容器在不在跑，重启策略对不对\n'
if [ -z "$DOCKER_OK" ]; then
  skip "这台机器上没有 docker，或者当前用户使唤不动它（教材第 2 卷第 9 章）"
elif ! container_exists; then
  bad "找不到名叫 $N8N_NAME 的容器（教材第 9 卷第 2 章那条 docker run）"
  note "容器名不是 $N8N_NAME 的话，用 CHECK_N8N_NAME 指定。"
else
  RUNNING="$(inspect_one '{{.State.Running}}')"
  if [ "$RUNNING" = "true" ]; then
    ok "$N8N_NAME 在跑"
  else
    bad "$N8N_NAME 存在但没在跑（教材第 2 卷第 9 章：docker start $N8N_NAME）"
    note "先看它为什么停的：docker logs --tail=50 $N8N_NAME"
  fi

  POLICY="$(inspect_one '{{.HostConfig.RestartPolicy.Name}}')"
  case "$POLICY" in
    unless-stopped|always)
      ok "重启策略是 $POLICY，断电来电之后它会自己回来"
      ;;
    ""|no)
      bad "重启策略是“不重启”（教材第 2 卷第 9 章、第 9 卷第 2 章）"
      note "服务类容器要 --restart unless-stopped。改这一项要停掉删掉重建，不是 restart。"
      ;;
    *)
      bad "重启策略是 $POLICY，本教材一律用 unless-stopped（教材第 9 卷第 2 章）"
      ;;
  esac
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　端口有没有人在听\n'
if have ss; then
  if ss -tln 2>/dev/null | grep -q ":$N8N_PORT[[:space:]]"; then
    ok "$N8N_PORT 上有人在听"
    note "这一项只证明有进程占着这个口，不证明占着它的就是 n8n。"
  else
    bad "$N8N_PORT 上没有人在听（教材第 9 卷第 2 章）"
    note "容器没起来，或者当初 -p 映射到了别的端口。端口不一样用 CHECK_N8N_PORT 指定。"
  fi
elif [ -n "$DOCKER_OK" ] && container_exists; then
  MAPPED="$(docker port "$N8N_NAME" 2>/dev/null | head -n 5)"
  if [ -n "$MAPPED" ]; then
    skip "这台机器上没有 ss，改看容器自己报的映射"
    printf '%s\n' "$MAPPED" | while IFS= read -r 一行; do
      [ -n "$一行" ] && note "映射：$一行"
    done
  else
    skip "这台机器上没有 ss，容器也没报出端口映射，这一项查不了"
  fi
else
  skip "这台机器上没有 ss，也问不到 docker，这一项查不了"
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　容器里连不连得上 Ollama\n'
if [ -z "$DOCKER_OK" ]; then
  skip "问不到 docker，这一项查不了"
elif ! container_exists; then
  skip "第 1 项没过，容器都不在，这一项查不了"
elif [ "$(inspect_one '{{.State.Running}}')" != "true" ]; then
  skip "容器没在跑，这一项查不了"
else
  TOOL="$(docker exec "$N8N_NAME" sh -c 'command -v wget || command -v curl' 2>/dev/null | head -n 1)"
  if [ -z "$TOOL" ]; then
    skip "容器里既没有 wget 也没有 curl，这一项在容器内查不了"
    note "官方镜像基于 Alpine 且不带 curl，带不带 wget 随版本变化。"
    note "换个办法：在 n8n 里跑一次 HTTP Request 节点，效果一样（教材第 9 卷第 2、3 章）。"
  else
    case "$TOOL" in
      *wget)
        REPLY_HEAD="$(docker exec "$N8N_NAME" \
          wget -qO- --timeout="$API_TIMEOUT" "$OLLAMA_URL" 2>/dev/null | head -c 200)"
        ;;
      *)
        REPLY_HEAD="$(docker exec "$N8N_NAME" \
          curl -s -m "$API_TIMEOUT" "$OLLAMA_URL" 2>/dev/null | head -c 200)"
        ;;
    esac
    if [ -n "$REPLY_HEAD" ]; then
      ok "容器里用 $(basename "$TOOL") 问到了 $OLLAMA_URL，有返回"
      note "这一项只证明这条路通，不证明模型跑得动，也不证明模型名填对了。"
    else
      bad "容器里问不到 $OLLAMA_URL（教材第 9 卷第 2 章最后一节）"
      note "三种常见：Ollama 没起、没设成对外监听、这台机器上 host.docker.internal 不通。"
      note "第三种的退路是换成本机的固定地址（教材第 3 卷第 3 章）。"
    fi
  fi
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　两个数据卷挂对了没有\n'
if [ -z "$DOCKER_OK" ]; then
  skip "问不到 docker，这一项查不了"
elif ! container_exists; then
  skip "第 1 项没过，容器都不在，这一项查不了"
else
  MOUNTS="$(inspect_one '{{range .Mounts}}{{.Source}}=>{{.Destination}}{{println}}{{end}}')"
  if [ -z "$MOUNTS" ]; then
    bad "这个容器一个卷都没挂（教材第 9 卷第 2 章那条 docker run 有两个 -v）"
  else
    for 挂载点 in "$N8N_DATA" "$WORK_MOUNT"; do
      一行="$(printf '%s\n' "$MOUNTS" | grep -F "=>$挂载点" | head -n 1)"
      if [ -n "$一行" ]; then
        ok "$挂载点 挂着，来自 ${一行%%=>*}"
      else
        bad "容器里的 $挂载点 没有挂任何东西（教材第 9 卷第 2 章）"
        if [ "$挂载点" = "$N8N_DATA" ]; then
          note "这一项不挂，删掉容器之后你建的工作流和凭据全没了。"
        else
          note "这一项不挂，写文件那个节点会报找不到目录。"
        fi
      fi
    done
    note "这一项只看挂没挂，不看里面有什么，也不判断属主对不对。"
  fi
fi

# ---------------------------------------------------------------- 5
printf '\n第 5 项　日报目录里有没有东西\n'
if [ ! -d "$DAILY_DIR" ]; then
  skip "找不到 $DAILY_DIR。用 CHECK_DAILY_DIR 指定，或者按教材第 9 卷第 2 章建出来"
else
  ok "日报目录 $DAILY_DIR 在"
  N_MD="$(find "$DAILY_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  N_ALL="$(find "$DAILY_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
  note "根目录下有 $N_ALL 个文件，其中 $N_MD 个是 .md"
  if [ "$N_MD" -eq 0 ]; then
    note "一份日报都还没有。没跑过是正常的；跑过了还是空的，回教材第 9 卷第 6 章。"
  else
    NEWEST="$(find "$DAILY_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null \
      | sort | tail -n 1)"
    [ -n "$NEWEST" ] && note "最后一份的文件名是 $(basename "$NEWEST")"
    note "这一项只看文件名和份数，不打开任何一份，也不判断里面写得对不对。"
  fi
  OWNER="$(ls -ld "$DAILY_DIR" 2>/dev/null | awk '{print $3":"$4}')"
  [ -n "$OWNER" ] && note "目录属主是 $OWNER。容器里以 uid 1000 跑，写不进去看教材第 9 卷第 2 章。"
fi

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '体检没过。上面每一条“不通过”后面都写了回哪一章。\n'
  exit 1
fi

printf '体检通过。真正的验收是明天早上你邮箱或者日报目录里真的多出一份，而且读得下去。\n'
exit 0
