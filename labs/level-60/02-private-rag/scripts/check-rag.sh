#!/usr/bin/env bash
# 私有知识库体检：逐项检查这台机器上的知识库是不是真的能演给客户看。
#
# 全部是只读检查，不改任何配置，随时可以跑。
# 唯一会“动”的地方是第 4 项要向 embedding 接口发一句话，这会让那个模型被加载进内存。
# 那是这套东西本来就要做的事，不写任何文件、不改任何设置。
#
# 它不读知识库里的内容，不读对话记录，不打印任何环境变量的值（里面可能有密钥），
# 第 5 项只打印变量名和它指向的主机名。
#
# 用法：
#   ./check-rag.sh          普通用户跑就行
#   sudo ./check-rag.sh     Docker 那一项或者数据卷没权限时加 sudo
#
# 可以用环境变量改默认值：
#   CHECK_OLLAMA_HOST      查接口时连哪个地址，默认 127.0.0.1
#   CHECK_OLLAMA_PORT      Ollama 端口，默认 11434
#   CHECK_EMBED_MODEL      向量模型名，默认 bge-m3
#   CHECK_WEBUI_CONTAINER  Open WebUI 的容器名，默认 open-webui
#   CHECK_DATA_DIR         Open WebUI 的数据目录，默认自己找
#   CHECK_TIMEOUT          等接口返回的秒数，默认 120
#
# 退出码：全部通过是 0，有任何一项不通过是 1。查不到的项报“跳过”，不算不通过。

set -uo pipefail

OLLAMA_ADDR="${CHECK_OLLAMA_HOST:-127.0.0.1}"
OLLAMA_PORT="${CHECK_OLLAMA_PORT:-11434}"
EMBED_MODEL="${CHECK_EMBED_MODEL:-bge-m3}"
WEBUI_NAME="${CHECK_WEBUI_CONTAINER:-open-webui}"
DATA_DIR="${CHECK_DATA_DIR:-}"
API_TIMEOUT="${CHECK_TIMEOUT:-120}"

API_BASE="http://${OLLAMA_ADDR}:${OLLAMA_PORT}/v1"

PASS=0
FAIL=0
SKIP=0

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }
note() { printf '  说明　%s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# 本地已经装了哪些模型，一行一个名字
list_models() {
  if have ollama; then
    ollama list 2>/dev/null | awk 'NR>1 && NF>0 {print $1}'
  elif have curl && have python3; then
    curl -s -m 15 "$API_BASE/models" 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for item in data.get("data") or []:
    name = item.get("id")
    if name:
        print(name)
' 2>/dev/null
  fi
}

# 名字对不对得上。ollama list 里是 bge-m3:latest，填的是 bge-m3，这两个算同一个
model_present() {
  printf '%s\n' "$1" | grep -qxE "$2(:.*)?"
}

# 向 embedding 接口发一句话，把向量的维度打印出来。失败就没有输出。
embed_dim() {
  have curl || return 1
  BODY="$(printf '{"model":"%s","input":"用一句话说你在。"}' "$EMBED_MODEL")"
  RAW="$(curl -s -m "$API_TIMEOUT" "$API_BASE/embeddings" \
    -H "Content-Type: application/json" \
    -d "$BODY" 2>/dev/null)"
  [ -n "$RAW" ] || return 1
  if have python3; then
    printf '%s' "$RAW" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
items = data.get("data") or []
if not items:
    sys.exit(1)
vec = items[0].get("embedding") or []
if not vec:
    sys.exit(1)
print(len(vec))
' 2>/dev/null
  else
    printf '%s' "$RAW" | grep -q '"embedding"' && printf '%s' "?"
  fi
}

# Open WebUI 的数据目录在哪儿
find_data_dir() {
  [ -n "$DATA_DIR" ] && { printf '%s' "$DATA_DIR"; return 0; }
  if have docker; then
    FROM_MOUNT="$(docker inspect -f \
      '{{range .Mounts}}{{if eq .Destination "/app/backend/data"}}{{.Source}}{{end}}{{end}}' \
      "$WEBUI_NAME" 2>/dev/null)"
    [ -n "$FROM_MOUNT" ] && { printf '%s' "$FROM_MOUNT"; return 0; }
  fi
  for guess in "$HOME/ai/projects/open-webui/data" "$HOME/open-webui/data"; do
    [ -d "$guess" ] && { printf '%s' "$guess"; return 0; }
  done
  return 1
}

# 这个主机名是不是本机或者内网
is_local_host() {
  case "$1" in
    localhost|127.*|0.0.0.0|::1|\[::1\]|host.docker.internal|*.local) return 0 ;;
    10.*|192.168.*) return 0 ;;
    172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
    *) return 1 ;;
  esac
}

printf '私有知识库体检\n'
printf '  时间          %s\n' "$(date '+%F %T')"
printf '  查的接口      %s\n' "$API_BASE"
printf '  向量模型      %s\n' "$EMBED_MODEL"
printf '\n'

# ---------------------------------------------------------------- 1
printf '第 1 项　embedding 模型装了没有\n'
MODEL_LIST="$(list_models)"
if [ -z "$MODEL_LIST" ]; then
  if have ollama || (have curl && curl -s -m 15 -o /dev/null "$API_BASE/models" 2>/dev/null); then
    bad "一个模型都没有，先拉一个（教材第 6 卷第 12 章）"
  else
    skip "没有 ollama 命令，接口也连不上，查不了本地有哪些模型"
  fi
elif model_present "$MODEL_LIST" "$EMBED_MODEL"; then
  ok "本地有 $EMBED_MODEL"
else
  MAYBE="$(printf '%s\n' "$MODEL_LIST" | grep -iE 'embed|bge|gte|e5|nomic' | tr '\n' ' ')"
  bad "本地没有 $EMBED_MODEL（教材第 6 卷第 12 章：ollama pull bge-m3）"
  if [ -n "$MAYBE" ]; then
    note "看着像 embedding 类的有：$MAYBE 。用别的就 CHECK_EMBED_MODEL=模型名 再跑一次。"
  else
    note "本地这几个模型里没看到 embedding 类的。对话模型不能拿来算向量（教材第 6 卷第 12 章）。"
  fi
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　Open WebUI 容器在跑，而且会自己回来\n'
if ! have docker; then
  skip "这台机器上没装 Docker"
elif ! docker ps -a --format '{{.Names}}' >/dev/null 2>&1; then
  skip "连不上 Docker 服务，可能没起来或者当前账户没权限（加 sudo 再跑一次）"
elif ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$WEBUI_NAME"; then
  skip "没有叫 $WEBUI_NAME 的容器。名字不一样的话用 CHECK_WEBUI_CONTAINER 指定"
else
  WEBUI_STATE="$(docker inspect -f '{{.State.Running}}|{{.HostConfig.RestartPolicy.Name}}' "$WEBUI_NAME" 2>/dev/null)"
  WEBUI_RUNNING="${WEBUI_STATE%%|*}"
  WEBUI_POLICY="${WEBUI_STATE##*|}"
  if [ "$WEBUI_RUNNING" != "true" ]; then
    bad "$WEBUI_NAME 容器没在跑（教材第 6 卷第 4 章）"
  else
    case "$WEBUI_POLICY" in
      always|unless-stopped)
        ok "$WEBUI_NAME 在跑，重启策略是 $WEBUI_POLICY，机器重启后自己回来"
        ;;
      *)
        bad "$WEBUI_NAME 在跑，但重启策略是 ${WEBUI_POLICY:-无}，机器重启后不会自己回来（用 docker update --restart unless-stopped $WEBUI_NAME 改）"
        ;;
    esac
  fi
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　知识库里有没有东西\n'
KB_DIR="$(find_data_dir)"
if [ -z "$KB_DIR" ]; then
  skip "找不到 Open WebUI 的数据目录。用 CHECK_DATA_DIR=/你的路径 指定"
elif [ ! -d "$KB_DIR" ]; then
  bad "$KB_DIR 这个目录不存在（教材第 7 卷第 3 章那一节说了数据在哪）"
elif [ ! -r "$KB_DIR" ]; then
  skip "$KB_DIR 没有权限读，加 sudo 再跑一次"
else
  KB_N="$(find "$KB_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${KB_N:-0}" -gt 0 ] 2>/dev/null; then
    ok "数据目录 $KB_DIR 里有 $KB_N 个文件"
  else
    bad "数据目录 $KB_DIR 是空的，库还没建（教材第 7 卷第 3 章）"
  fi
  for sub in uploads vector_db; do
    if [ -d "$KB_DIR/$sub" ]; then
      SUB_N="$(find "$KB_DIR/$sub" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
      note "$sub/ 里有 $SUB_N 项"
    fi
  done
  note "这一项只看数据目录里有没有东西，不判断库建对没有。份数要自己在界面上对（教材第 7 卷第 3 章第五步）。"
  note "数据目录里的子目录名随 Open WebUI 版本变化，需要核验。"
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　embedding 接口能返回一串数字\n'
if ! have curl; then
  skip "这台机器上没有 curl，发不了请求"
elif ! curl -s -m 10 -o /dev/null "$API_BASE/models" 2>/dev/null; then
  skip "$API_BASE 连不上，这一项查不了（教材第 6 卷第 8 章）"
else
  DIM="$(embed_dim)"
  if [ -n "$DIM" ]; then
    if [ "$DIM" = "?" ]; then
      ok "$EMBED_MODEL 返回了向量（没有 python3，只确认返回里有 embedding 字段）"
    else
      ok "$EMBED_MODEL 返回了一个 $DIM 维的向量"
    fi
  else
    bad "$API_BASE/embeddings 没有返回可用的向量（教材第 6 卷第 12 章那三种报不出来）"
    note "常见三种：模型名写错、填的是对话模型、接口没通。也可能是加载超过了 $API_TIMEOUT 秒。"
  fi
fi

# ---------------------------------------------------------------- 5
printf '\n第 5 项　断网演示前的联网依赖自检\n'
if ! have docker; then
  skip "没装 Docker，查不了容器的配置"
elif ! docker inspect "$WEBUI_NAME" >/dev/null 2>&1; then
  skip "看不到 $WEBUI_NAME 这个容器，查不了它连的是哪儿"
else
  ENV_LINES="$(docker inspect -f '{{range .Config.Env}}{{println .}}' "$WEBUI_NAME" 2>/dev/null)"
  EXTERNAL=""
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      *http://*|*https://*) : ;;
      *) continue ;;
    esac
    VAR="${line%%=*}"
    for url in $(printf '%s' "$line" | grep -oE 'https?://[^ ,;"]+' 2>/dev/null); do
      HOST="$(printf '%s' "$url" | sed -E 's#^https?://##; s#/.*##; s#^[^@]*@##; s#:[0-9]+$##')"
      [ -n "$HOST" ] || continue
      if ! is_local_host "$HOST"; then
        EXTERNAL="$EXTERNAL
  $VAR → $HOST"
      fi
    done
  done <<EOF
$ENV_LINES
EOF

  if [ -n "$EXTERNAL" ]; then
    bad "容器环境变量里有指向外网的地址，断网之后这些地方可能挂住（教材第 7 卷第 9 章那四个翻车点）"
    printf '%s\n' "$EXTERNAL" | sed '/^[[:space:]]*$/d; s/^/    /'
    note "只打印了变量名和主机名，没打印变量的值。每一行都要说得出它是干什么的。"
  else
    ok "容器环境变量里没有指向外网的地址"
  fi

  if printf '%s' "$ENV_LINES" | grep -qE '^(OFFLINE_MODE|HF_HUB_OFFLINE)='; then
    note "OFFLINE_MODE 或者 HF_HUB_OFFLINE 设了，容器不再尝试去外面下东西（教材第 7 卷第 9 章那道可选保险）。"
  else
    note "OFFLINE_MODE 和 HF_HUB_OFFLINE 没有设。这是可选的保险，不设也能断网跑（教材第 7 卷第 9 章那一节）。"
  fi

  note "这一项查不到界面上选的向量模型是哪个。管理员面板那一页要自己看一眼，是本机的模型才算数（教材第 7 卷第 3 章第一步）。"
fi

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '体检没过。上面每一条“不通过”后面都写了回哪一章。\n'
  exit 1
fi

printf '体检通过。真正的验收是拔掉网线再问三道题，还有那张填完的评测表。\n'
exit 0
