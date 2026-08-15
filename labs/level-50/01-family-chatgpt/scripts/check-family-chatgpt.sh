#!/usr/bin/env bash
# 全家 ChatGPT 体检：逐项检查这台机器上的本地模型服务是不是真的能给一屋子人用。
#
# 全部是只读检查，不改任何配置，随时可以跑。
# 唯一会“动”的地方是第 3 项和第 6 项要向模型发一句话，这会让模型被加载进内存。
# 那是模型服务本来就要做的事，不写任何文件、不改任何设置。
#
# 用法：
#   ./check-family-chatgpt.sh          普通用户跑就行
#   sudo ./check-family-chatgpt.sh     Docker 那一项没权限时加 sudo
#
# 可以用环境变量改默认值：
#   CHECK_OLLAMA_HOST      查接口时连哪个地址，默认 127.0.0.1
#   CHECK_OLLAMA_PORT      Ollama 端口，默认 11434
#   CHECK_WEBUI_PORT       Open WebUI 在宿主机上的端口，默认 3080
#   CHECK_WEBUI_CONTAINER  Open WebUI 的容器名，默认 open-webui
#   CHECK_MODEL            测试用哪个模型，默认自动取本地第一个
#   CHECK_TIMEOUT          等模型回答的秒数，默认 300
#
# 退出码：全部通过是 0，有任何一项不通过是 1。查不到的项报“跳过”，不算不通过。

set -uo pipefail

OLLAMA_ADDR="${CHECK_OLLAMA_HOST:-127.0.0.1}"
OLLAMA_PORT="${CHECK_OLLAMA_PORT:-11434}"
WEBUI_PORT="${CHECK_WEBUI_PORT:-3080}"
WEBUI_NAME="${CHECK_WEBUI_CONTAINER:-open-webui}"
MODEL="${CHECK_MODEL:-}"
API_TIMEOUT="${CHECK_TIMEOUT:-300}"

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

# 挑一个模型名出来用
pick_model() {
  [ -n "$MODEL" ] && return 0
  MODEL="$(list_models | head -1)"
  [ -n "$MODEL" ]
}

# 向模型发一句话，把它说的那句打印到标准输出。失败就没有输出。
ask_api() {
  have curl || return 1
  pick_model || return 1
  BODY="$(printf '{"model":"%s","messages":[{"role":"user","content":"用一句话说你在。"}],"stream":false}' "$MODEL")"
  RAW="$(curl -s -m "$API_TIMEOUT" "$API_BASE/chat/completions" \
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
choices = data.get("choices") or []
if not choices:
    sys.exit(1)
text = (choices[0].get("message") or {}).get("content") or ""
text = " ".join(text.split())
if not text:
    sys.exit(1)
print(text[:80])
' 2>/dev/null
  else
    printf '%s' "$RAW" | grep -q '"content"' && printf '%s' "（没有 python3，只确认返回里有 content 字段）"
  fi
}

# 某个端口是不是在监听，而且不是只绑在本机
port_open_to_lan() {
  have ss || return 2
  ADDRS="$(ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -E ":$1\$")"
  [ -n "$ADDRS" ] || return 1
  printf '%s\n' "$ADDRS" | grep -qvE '^(127\.|\[::1\])' || return 3
  printf '%s' "$(printf '%s' "$ADDRS" | tr '\n' ' ')"
  return 0
}

printf '全家 ChatGPT 体检\n'
printf '  时间      %s\n' "$(date '+%F %T')"
printf '  查的接口  %s\n' "$API_BASE"
printf '\n'

# ---------------------------------------------------------------- 1
printf '第 1 项　Ollama 服务在跑\n'
if have systemctl && systemctl list-unit-files 2>/dev/null | grep -q '^ollama\.service'; then
  SVC_ACTIVE="$(systemctl is-active ollama 2>/dev/null)"
  SVC_ENABLED="$(systemctl is-enabled ollama 2>/dev/null)"
  if [ "$SVC_ACTIVE" = "active" ]; then
    ok "ollama 服务在跑，开机自启是 ${SVC_ENABLED:-未知}"
    case "$SVC_ENABLED" in
      enabled|enabled-runtime) : ;;
      *) note "开机自启不是 enabled，机器重启之后这台家用 ChatGPT 不会自己回来（教材第 6 卷第 3 章）。" ;;
    esac
  else
    bad "ollama 服务现在是 ${SVC_ACTIVE:-未知}（教材第 6 卷第 3 章）"
  fi
elif have ss && ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -qE ":$OLLAMA_PORT\$"; then
  ok "没有 ollama 这个服务单元，但 $OLLAMA_PORT 端口在等连接，服务是起着的"
else
  skip "这台机器上查不到 ollama 服务，也没看到 $OLLAMA_PORT 端口在监听"
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　至少装了一个模型\n'
MODEL_LIST="$(list_models)"
MODEL_N="$(printf '%s\n' "$MODEL_LIST" | grep -c .)"
if [ -z "$MODEL_LIST" ]; then
  if have ollama; then
    bad "一个模型都没有，先拉一个（教材第 6 卷第 2 章、第 3 章）"
  elif have curl && curl -s -m 15 -o /dev/null "$API_BASE/models" 2>/dev/null; then
    bad "接口连得上，但一个模型都没有（教材第 6 卷第 2 章、第 3 章）"
  else
    skip "没有 ollama 命令，接口也连不上，查不了本地有哪些模型"
  fi
else
  ok "本地有 $MODEL_N 个模型：$(printf '%s' "$MODEL_LIST" | tr '\n' ' ')"
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　模型跑在 GPU 上，不是 CPU 上\n'
if ! have ollama; then
  skip "这台机器上没有 ollama 命令，查不了模型跑在哪儿"
else
  PS_OUT="$(ollama ps 2>/dev/null | awk 'NR>1 && NF>0')"
  if [ -z "$PS_OUT" ]; then
    note "内存里现在没有模型，先发一句话把它加载进来……"
    ask_api >/dev/null 2>&1
    PS_OUT="$(ollama ps 2>/dev/null | awk 'NR>1 && NF>0')"
  fi
  if [ -z "$PS_OUT" ]; then
    skip "内存里还是没有模型，判断不了跑在哪儿。手动跑一次对话之后再来一遍"
  elif printf '%s\n' "$PS_OUT" | grep -q '100% GPU'; then
    ok "ollama ps 显示 100% GPU"
  elif printf '%s\n' "$PS_OUT" | grep -qi 'cpu'; then
    bad "ollama ps 里出现了 CPU，模型没有全部跑在 GPU 上（教材第 6 卷第 3 章那一节的排查顺序）"
    printf '%s\n' "$PS_OUT" | sed 's/^/        /'
  else
    skip "ollama ps 的输出格式和预期不同，自己看一眼 PROCESSOR 那一列"
    printf '%s\n' "$PS_OUT" | sed 's/^/        /'
  fi
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　Open WebUI 容器在跑，而且会自己回来\n'
if ! have docker; then
  skip "这台机器上没装 Docker"
elif ! docker ps -a --format '{{.Names}}' >/dev/null 2>&1; then
  skip "连不上 Docker 服务，可能没起来或者当前账户没权限（加 sudo 再跑一次）"
else
  if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$WEBUI_NAME"; then
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
fi

# ---------------------------------------------------------------- 5
printf '\n第 5 项　局域网上的口开着，不是只对本机开\n'
if ! have ss; then
  skip "这台机器上没有 ss，查不了监听端口"
else
  for entry in "$WEBUI_PORT|Open WebUI，家里人进的那个门|第 6 卷第 4 章、第 5 章" \
               "$OLLAMA_PORT|Ollama 接口，程序连的那个门|第 6 卷第 8 章"; do
    P="${entry%%|*}"
    REST="${entry#*|}"
    WHAT="${REST%%|*}"
    WHERE="${REST##*|}"
    ADDRS="$(port_open_to_lan "$P")"
    case "$?" in
      0) ok "$P 在监听，$WHAT（$ADDRS）" ;;
      1) bad "$P 没在监听，$WHAT 连不上（教材$WHERE）" ;;
      3) bad "$P 只对本机开着，别的设备连不进来（教材$WHERE）" ;;
      *) skip "查不了 $P 这个口" ;;
    esac
  done
  note "开着不等于放行。ufw 那张表要自己念一遍，每一行说得出这个口是给谁开的（教材第 3 卷第 9 章）。"
fi

# ---------------------------------------------------------------- 6
printf '\n第 6 项　接口能返回一句话\n'
if ! have curl; then
  skip "这台机器上没有 curl，发不了请求"
elif ! pick_model; then
  skip "没挑出可用的模型名，接口这一项跳过。可以用 CHECK_MODEL 指定"
else
  ANSWER="$(ask_api)"
  if [ -n "$ANSWER" ]; then
    ok "模型 $MODEL 回了一句：$ANSWER"
  else
    bad "$API_BASE/chat/completions 没有返回可用的回答（教材第 6 卷第 8 章那三种报不出来）"
    note "常见三种：端口没开、防火墙挡着、模型名写错。也可能是加载超过了 $API_TIMEOUT 秒。"
  fi
fi

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '体检没过。上面每一条“不通过”后面都写了回哪一章。\n'
  exit 1
fi

printf '体检通过。手机上再打开一次网页界面，那才是这套东西真正的验收。\n'
exit 0
