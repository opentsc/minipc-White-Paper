#!/usr/bin/env bash
# 远程管理体检：逐项检查这台机器能不能被远程管、断电之后服务能不能自己回来。
#
# 全部是只读检查，不改任何配置，随时可以跑。
#
# 用法：
#   ./check-remote-box.sh          普通用户跑，防火墙那两项降级成粗略判断
#   sudo ./check-remote-box.sh     查得最全
#
# 可以用环境变量改默认值：
#   CHECK_SSH_PORT      SSH 端口，默认 22
#   CHECK_SERVICES      要检查的服务，空格隔开，默认 "ssh docker cron"
#   CHECK_CRON_PATTERN  定时任务里要找的关键词，默认 backup
#
# 退出码：全部通过是 0，有任何一项不通过是 1。

set -uo pipefail

SSH_PORT="${CHECK_SSH_PORT:-22}"
SERVICES="${CHECK_SERVICES:-ssh docker cron}"
CRON_PATTERN="${CHECK_CRON_PATTERN:-backup}"

PASS=0
FAIL=0
SKIP=0
UFW_OUT=""

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }
note() { printf '  说明　%s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

read_ufw() {
  have ufw || return 1
  if [ "$(id -u)" = "0" ]; then
    UFW_OUT="$(ufw status verbose 2>/dev/null)"
  else
    UFW_OUT="$(sudo -n ufw status verbose 2>/dev/null)"
  fi
  [ -n "$UFW_OUT" ]
}

printf '远程管理体检\n'
printf '  机器      %s\n' "$(hostname 2>/dev/null || echo 未知)"
printf '  时间      %s\n' "$(date '+%F %T')"
if [ "$(id -u)" = "0" ]; then
  printf '  身份      root，全部项目都能查\n'
else
  printf '  身份      普通用户，防火墙两项降级成粗略判断\n'
fi
printf '\n'

# ---------------------------------------------------------------- 1
printf '第 1 项　SSH 端口在监听\n'
if have ss; then
  LISTEN_ADDRS="$(ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -E ":$SSH_PORT\$")"
  if [ -z "$LISTEN_ADDRS" ]; then
    bad "没看到 $SSH_PORT 端口在等连接，远程登录进不来（教材第 3 卷第 4 章）"
  elif printf '%s\n' "$LISTEN_ADDRS" | grep -qvE '^(127\.|\[::1\])'; then
    ok "$SSH_PORT 端口在等连接（$(printf '%s' "$LISTEN_ADDRS" | tr '\n' ' ')）"
  else
    bad "$SSH_PORT 端口只对本机开着，别的机器连不进来（教材第 3 卷第 4 章）"
  fi
else
  skip "这台机器上没有 ss，查不了监听端口"
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　密码登录已关\n'
if [ -r /etc/ssh/sshd_config ]; then
  SSHD_FILES="/etc/ssh/sshd_config"
  for f in /etc/ssh/sshd_config.d/*.conf; do
    [ -r "$f" ] && SSHD_FILES="$SSHD_FILES $f"
  done
  # shellcheck disable=SC2086
  PWAUTH="$(grep -h -iE '^[[:space:]]*PasswordAuthentication[[:space:]]+' $SSHD_FILES 2>/dev/null | tail -1 | awk '{print tolower($2)}')"
  if [ "$PWAUTH" = "no" ]; then
    ok "配置里 PasswordAuthentication 是 no"
  elif [ -z "$PWAUTH" ]; then
    bad "配置里没写 PasswordAuthentication，等于允许密码登录（教材第 3 卷第 4 章）"
  else
    bad "配置里 PasswordAuthentication 是 $PWAUTH，密码那条路还开着（教材第 3 卷第 4 章）"
  fi
  note "这一项看的是配置文件。真正算数的是从别的机器用密码连一次，看它拒不拒（教材第 3 卷第 10 章第三条）。"
else
  skip "读不到 /etc/ssh/sshd_config"
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　防火墙已启用\n'
if read_ufw; then
  if printf '%s\n' "$UFW_OUT" | head -1 | grep -qiE 'active|激活'; then
    ok "ufw 已启用"
    RULE_COUNT="$(printf '%s\n' "$UFW_OUT" | grep -viE '^(Default|默认)' | grep -ciE 'ALLOW|DENY|REJECT|LIMIT|允许|拒绝')"
    note "规则 $RULE_COUNT 条。逐行念一遍，每一条都要说得出这个口是给谁开的。"
  else
    bad "ufw 装了但没启用（教材第 3 卷第 9 章）"
  fi
elif have ufw; then
  if [ -r /etc/ufw/ufw.conf ] && grep -qi '^ENABLED=yes' /etc/ufw/ufw.conf; then
    ok "ufw 配置里是启用状态（粗略判断，加 sudo 跑能查得更准）"
  else
    bad "ufw 看起来没启用（教材第 3 卷第 9 章）"
  fi
else
  skip "这台机器上没装 ufw"
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　入站默认拒绝\n'
if [ -n "$UFW_OUT" ] && printf '%s\n' "$UFW_OUT" | grep -qiE '^(Default|默认)'; then
  if printf '%s\n' "$UFW_OUT" | grep -iE '^(Default|默认)' | grep -qiE 'deny \(incoming\)|拒绝 ?\(传入\)|拒绝 ?\(incoming\)'; then
    ok "默认策略是入站拒绝"
  else
    bad "默认入站策略不是拒绝（教材第 3 卷第 9 章）"
  fi
elif [ -r /etc/default/ufw ]; then
  POL="$(grep -i '^DEFAULT_INPUT_POLICY' /etc/default/ufw 2>/dev/null | head -1 | cut -d= -f2 | tr -d '"' | tr -d ' ')"
  case "$POL" in
    DROP|REJECT|drop|reject) ok "默认入站策略是 $POL（粗略判断）" ;;
    "")                      skip "读不到默认入站策略" ;;
    *)                       bad "默认入站策略是 $POL，服务器上应该是 DROP（教材第 3 卷第 9 章）" ;;
  esac
else
  skip "读不到 ufw 的默认策略"
fi

# ---------------------------------------------------------------- 5
printf '\n第 5 项　关键服务在跑并且开机自启\n'
if have systemctl; then
  for s in $SERVICES; do
    SVC_ENABLED="$(systemctl is-enabled "$s" 2>/dev/null)"
    SVC_ACTIVE="$(systemctl is-active "$s" 2>/dev/null)"
    if [ -z "$SVC_ENABLED" ] && [ -z "$SVC_ACTIVE" ]; then
      skip "$s 没装"
      continue
    fi
    case "$SVC_ENABLED" in
      enabled|enabled-runtime|static|alias|indirect|generated) EN_OK=1 ;;
      *)                                                      EN_OK=0 ;;
    esac
    if [ "$SVC_ACTIVE" = "active" ] && [ "$EN_OK" = "1" ]; then
      ok "$s 在跑，开机自启是 $SVC_ENABLED"
    elif [ "$s" = "ssh" ] && have ss && ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -qE ":$SSH_PORT\$"; then
      ok "$s 是按需启动，$SSH_PORT 端口在等连接（教材第 3 卷第 4 章说过这种情况）"
    else
      bad "$s 现在是 ${SVC_ACTIVE:-未知}，开机自启是 ${SVC_ENABLED:-未知}（教材第 3 卷第 8 章）"
    fi
  done
else
  skip "这台机器上没有 systemctl"
fi

# ---------------------------------------------------------------- 6
printf '\n第 6 项　容器重启后自己回来\n'
if have docker; then
  if ! CONTAINER_IDS="$(docker ps -aq 2>/dev/null)"; then
    skip "连不上 Docker 服务，可能没起来或者当前账户没权限"
  elif [ -z "$CONTAINER_IDS" ]; then
    skip "这台机器上还没有容器"
  else
    # shellcheck disable=SC2086
    POLICIES="$(docker inspect -f '{{.Name}}|{{.HostConfig.RestartPolicy.Name}}' $CONTAINER_IDS 2>/dev/null)"
    BAD_LIST=""
    GOOD_N=0
    while IFS='|' read -r cname cpol; do
      [ -z "$cname" ] && continue
      cname="${cname#/}"
      case "$cpol" in
        always|unless-stopped) GOOD_N=$((GOOD_N + 1)) ;;
        *)                     BAD_LIST="$BAD_LIST $cname(${cpol:-无})" ;;
      esac
    done <<EOF
$POLICIES
EOF
    if [ -z "$BAD_LIST" ]; then
      ok "$GOOD_N 个容器都会在机器重启后自己回来"
    else
      bad "这些容器不会自己回来：$BAD_LIST（教材第 3 卷第 8 章，用 docker update --restart unless-stopped 改）"
    fi
  fi
else
  skip "这台机器上没装 Docker"
fi

# ---------------------------------------------------------------- 7
printf '\n第 7 项　定时任务还在\n'
if have crontab; then
  CRON_OUT="$(crontab -l 2>/dev/null)"
  CRON_JOBS="$(printf '%s\n' "$CRON_OUT" | grep -vE '^[[:space:]]*(#|$)')"
  CRON_N="$(printf '%s\n' "$CRON_JOBS" | grep -c . )"
  if [ "$CRON_N" = "0" ]; then
    bad "当前账户的 crontab 里一条任务都没有（教材第 2 卷第 12 章）"
  elif printf '%s\n' "$CRON_JOBS" | grep -qi "$CRON_PATTERN"; then
    ok "有 $CRON_N 条任务，其中有包含 $CRON_PATTERN 的那一条"
  else
    bad "有 $CRON_N 条任务，但没有一条包含 $CRON_PATTERN，备份可能被注释掉了（教材第 2 卷第 12 章）"
  fi
else
  skip "这台机器上没有 crontab"
fi

# ---------------------------------------------------------------- 8
printf '\n第 8 项　睡眠和休眠已关\n'
if have systemctl; then
  SLEEPY=""
  for t in sleep.target suspend.target hibernate.target hybrid-sleep.target; do
    T_STATE="$(systemctl is-enabled "$t" 2>/dev/null)"
    [ "$T_STATE" = "masked" ] || SLEEPY="$SLEEPY $t"
  done
  if [ -z "$SLEEPY" ]; then
    ok "四种睡眠方式都封住了，机器不会自己睡过去"
  else
    bad "这几项还能让机器睡着：$SLEEPY（教材第 3 卷第 8 章）"
  fi
else
  skip "这台机器上没有 systemctl"
fi

# ---------------------------------------------------------------- 9
printf '\n第 9 项　来电自启\n'
note "这一项在 BIOS 里，脚本查不到。"
note "验的办法只有一个：拔插座、等 30 秒、插回去、不按电源键，两分钟后从别的机器连一次（教材第 3 卷第 8 章）。"

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '体检没过。上面每一条“不通过”后面都写了回哪一章。\n'
  exit 1
fi

printf '体检通过。来电自启那一项记得拔电试一次。\n'
exit 0
