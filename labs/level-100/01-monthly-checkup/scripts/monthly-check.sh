#!/usr/bin/env bash
# 月度巡检汇总：一次跑完月底出报告要看的那几项，输出可以直接抄进月度报告。
#
# 全部是只读检查。它不改任何配置、不新建不删除不重启任何容器、不动任何定时任务，
# 也不往这台机器上写任何文件。随时可以跑。
# 查不到的项目报“跳过”，不报错——没配置过的机器上跑也不会出事。
#
# 用法：
#   ./monthly-check.sh                              直接跑
#   sudo ./monthly-check.sh                         温度和防火墙那几项查得更全
#   ./monthly-check.sh > 月度巡检-2026-11.txt 2>&1   存一份，留档用
#
# 环境变量，全部有默认值，按你自己那台机器改：
#   MC_MONTH              要汇总哪个月，形如 2026-11，默认当月
#   MC_SERVICES           要查的服务，空格隔开，默认 "ssh docker cron"
#   MC_DISKS              要查的挂载点，空格隔开，默认 "/"
#   MC_BACKUP_LOG         备份日志路径，默认 "$HOME/ai/backup/backup.log"
#   MC_BACKUP_MAX_AGE_H   备份日志最后一次超过多少小时算不通过，默认 48
#                         这不是建议值，按你自己的备份周期改
#   MC_DAILY_DIR          每日巡检输出目录，用来数这个月跑了几次，默认不数
#   MC_LOG_SINCE          日志看多久以内，默认 "30 days ago"
#   MC_LOG_TOP            日志里出现最多的前几条，默认 5
#   MC_KNOWN_NOISE        已知背景噪声清单，默认脚本上一级的 known-noise.txt
#   MC_DISK_MIN_FREE_PCT  系统盘剩余低于百分之多少算不通过，默认不判断，只报数
#
# 退出码：有任何一项不通过是 1，否则是 0。

set -uo pipefail

MONTH="${MC_MONTH:-$(date '+%Y-%m')}"
SERVICES="${MC_SERVICES:-ssh docker cron}"
DISKS="${MC_DISKS:-/}"
BACKUP_LOG="${MC_BACKUP_LOG:-$HOME/ai/backup/backup.log}"
BACKUP_MAX_AGE_H="${MC_BACKUP_MAX_AGE_H:-48}"
DAILY_DIR="${MC_DAILY_DIR:-}"
LOG_SINCE="${MC_LOG_SINCE:-30 days ago}"
LOG_TOP="${MC_LOG_TOP:-5}"
DISK_MIN_FREE_PCT="${MC_DISK_MIN_FREE_PCT:-}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KNOWN_NOISE="${MC_KNOWN_NOISE:-$SCRIPT_DIR/../known-noise.txt}"

PASS=0
FAIL=0
SKIP=0

# 下面几个变量是给最后那段“可以直接抄进月度报告”用的
R_CHECKS="未统计"
R_BACKUP="未测"
R_DISK=""
R_TEMP="未测"
R_SERVICES="未测"
R_PORTS="未测"
R_CONTAINERS="未测"

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }
note() { printf '  说明　%s\n' "$1"; }
line() { printf '  %s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

printf '月度巡检汇总\n'
printf '  机器      %s\n' "$(hostname 2>/dev/null || echo 未知)"
printf '  跑的时间  %s\n' "$(date '+%F %T')"
printf '  汇总月份  %s\n' "$MONTH"
if [ "$(id -u)" = "0" ]; then
  printf '  身份      root，全部项目都能查\n'
else
  printf '  身份      普通用户，温度和防火墙那几项可能查不全\n'
fi
printf '  这个脚本只读，不改这台机器上任何东西。\n'
printf '\n'

# ---------------------------------------------------------------- 1
printf '第 1 项　服务在不在\n'
if have systemctl; then
  SVC_TOTAL=0
  SVC_OK=0
  SVC_BAD=""
  for s in $SERVICES; do
    SVC_ENABLED="$(systemctl is-enabled "$s" 2>/dev/null)"
    SVC_ACTIVE="$(systemctl is-active "$s" 2>/dev/null)"
    if [ -z "$SVC_ENABLED" ] && [ -z "$SVC_ACTIVE" ]; then
      line "$s 没装，跳过这一个"
      continue
    fi
    SVC_TOTAL=$((SVC_TOTAL + 1))
    case "$SVC_ENABLED" in
      enabled|enabled-runtime|static|alias|indirect|generated) EN_OK=1 ;;
      *)                                                      EN_OK=0 ;;
    esac
    if [ "$SVC_ACTIVE" = "active" ] && [ "$EN_OK" = "1" ]; then
      SVC_OK=$((SVC_OK + 1))
      line "$s 在跑，开机自启是 $SVC_ENABLED"
    elif [ "$s" = "ssh" ] && have ss && ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -qE ':22$'; then
      SVC_OK=$((SVC_OK + 1))
      line "$s 是按需启动，22 端口在等连接（教材第 3 卷第 4 章说过这种情况）"
    else
      SVC_BAD="$SVC_BAD $s(现在 ${SVC_ACTIVE:-未知}，自启 ${SVC_ENABLED:-未知})"
    fi
  done
  if [ "$SVC_TOTAL" = "0" ]; then
    skip "要查的服务这台机器上一个都没装"
  elif [ -z "$SVC_BAD" ]; then
    ok "$SVC_OK 项服务都在跑，而且都设了开机自启"
    R_SERVICES="$SVC_OK 项，全部正常"
  else
    bad "这几项不对：$SVC_BAD（教材第 3 卷第 8 章）"
    R_SERVICES="$SVC_TOTAL 项，其中 $((SVC_TOTAL - SVC_OK)) 项有问题"
  fi
else
  skip "这台机器上没有 systemctl"
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　容器重启策略\n'
if have docker; then
  if ! CONTAINER_IDS="$(docker ps -aq 2>/dev/null)"; then
    skip "连不上 Docker 服务，可能没起来或者当前账户没权限"
  elif [ -z "$CONTAINER_IDS" ]; then
    skip "这台机器上还没有容器"
  else
    # shellcheck disable=SC2086
    POLICIES="$(docker inspect -f '{{.Name}}|{{.HostConfig.RestartPolicy.Name}}' $CONTAINER_IDS 2>/dev/null)"
    C_BAD=""
    C_OK=0
    while IFS='|' read -r cname cpol; do
      [ -z "$cname" ] && continue
      cname="${cname#/}"
      case "$cpol" in
        always|unless-stopped) C_OK=$((C_OK + 1)) ;;
        *)                     C_BAD="$C_BAD $cname(${cpol:-无})" ;;
      esac
    done <<EOF
$POLICIES
EOF
    if [ -z "$C_BAD" ]; then
      ok "$C_OK 个容器都会在断电来电之后自己回来"
      R_CONTAINERS="$C_OK 个，都会自己回来"
    else
      bad "这些容器不会自己回来：$C_BAD（教材第 3 卷第 8 章）"
      note "第 14 卷第 7 章那次故障就是这一项漂掉引起的：重建过的容器没带上重启策略，停一次电才发现。"
      R_CONTAINERS="有 $(printf '%s' "$C_BAD" | wc -w) 个不会自己回来"
    fi
  fi
else
  skip "这台机器上没装 Docker"
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　磁盘还剩多少\n'
if have df; then
  D_ANY=0
  D_BAD=""
  for m in $DISKS; do
    if [ ! -d "$m" ]; then
      line "$m 这个挂载点不在，跳过这一个"
      continue
    fi
    D_INFO="$(df -Pk "$m" 2>/dev/null | awk 'NR==2 {printf "%s|%s", $2, $4}')"
    if [ -z "$D_INFO" ]; then
      line "$m 读不到，跳过这一个"
      continue
    fi
    D_ANY=1
    D_TOTAL_K="${D_INFO%%|*}"
    D_AVAIL_K="${D_INFO##*|}"
    if [ "$D_TOTAL_K" -gt 0 ] 2>/dev/null; then
      D_FREEPCT=$(( D_AVAIL_K * 100 / D_TOTAL_K ))
    else
      D_FREEPCT=0
    fi
    D_AVAIL_H="$(awk -v k="$D_AVAIL_K" 'BEGIN {
      if (k >= 1073741824) printf "%.1f TB", k/1073741824;
      else printf "%.0f GB", k/1048576;
    }')"
    D_TOTAL_H="$(awk -v k="$D_TOTAL_K" 'BEGIN {
      if (k >= 1073741824) printf "%.1f TB", k/1073741824;
      else printf "%.0f GB", k/1048576;
    }')"
    line "$m 剩 $D_AVAIL_H（总共 $D_TOTAL_H，还剩 ${D_FREEPCT}%）"
    R_DISK="$R_DISK$m 剩余　$D_AVAIL_H（上月　　　　　）
"
    if [ -n "$DISK_MIN_FREE_PCT" ] && [ "$D_FREEPCT" -lt "$DISK_MIN_FREE_PCT" ]; then
      D_BAD="$D_BAD $m(${D_FREEPCT}%)"
    fi
  done
  if [ "$D_ANY" = "0" ]; then
    skip "要查的挂载点一个都读不到"
  elif [ -z "$DISK_MIN_FREE_PCT" ]; then
    ok "剩余空间已列出（没设 MC_DISK_MIN_FREE_PCT，这一项只报数不判断）"
    note "判断要和上个月比，不是看绝对值。做法见教材第 14 卷第 2 章：一个月降多少才是要看的那个数。"
  elif [ -z "$D_BAD" ]; then
    ok "各挂载点剩余都在 ${DISK_MIN_FREE_PCT}% 以上"
  else
    bad "这几个挂载点剩余低于 ${DISK_MIN_FREE_PCT}%：$D_BAD（教材第 15 卷“磁盘已满”那一条）"
  fi
else
  skip "这台机器上没有 df"
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　温度\n'
if have sensors; then
  T_OUT="$(sensors 2>/dev/null | grep -E '^[A-Za-z].*[+-][0-9]+\.[0-9]+°C' | head -8)"
  if [ -z "$T_OUT" ]; then
    skip "sensors 装了但没读到温度项"
  else
    printf '%s\n' "$T_OUT" | while IFS= read -r l; do printf '  %s\n' "$l"; done
    ok "温度读数已列出（这一项只报数不判断）"
    note "本教材不给 Max395 的温度参考区间。判断要和教材第 4 卷第 16 章那份基线第七组比，而且要先确认条件没变（第 4 卷第 17 章）。"
    R_TEMP="见本次输出第 4 项（和基线第七组比：　　　　）"
  fi
else
  skip "这台机器上没有 sensors，读不到温度（装法见教材第 4 卷第 12 章）"
fi

# ---------------------------------------------------------------- 5
printf '\n第 5 项　备份最近一次跑的时间\n'
if [ ! -e "$BACKUP_LOG" ]; then
  bad "找不到备份日志 $BACKUP_LOG（教材第 2 卷第 12 章、level-20／01）"
  note "日志文件不见了，通常不是备份没跑，是目录被移走了或者盘没挂上。这一条比“超期没跑”更急。"
elif [ ! -r "$BACKUP_LOG" ]; then
  skip "备份日志在，但当前账户读不了，加 sudo 再跑一次"
else
  B_MTIME="$(date -r "$BACKUP_LOG" '+%s' 2>/dev/null)"
  B_SHOW="$(date -r "$BACKUP_LOG" '+%F %H:%M' 2>/dev/null)"
  if [ -z "$B_MTIME" ]; then
    skip "读不到备份日志的时间"
  else
    NOW="$(date '+%s')"
    AGE_H=$(( (NOW - B_MTIME) / 3600 ))
    line "最后一次写日志：$B_SHOW（距今 $AGE_H 小时）"
    B_LAST="$(tail -3 "$BACKUP_LOG" 2>/dev/null)"
    if [ -n "$B_LAST" ]; then
      line "日志最后三行："
      printf '%s\n' "$B_LAST" | while IFS= read -r l; do printf '    %s\n' "$l"; done
    fi
    R_BACKUP="最近一次 $B_SHOW"
    if [ "$AGE_H" -gt "$BACKUP_MAX_AGE_H" ]; then
      bad "备份已经 $AGE_H 小时没跑了（上限设的是 $BACKUP_MAX_AGE_H 小时）"
      note "备份失效通常很安静（level-20／01）。先看移动硬盘插没插，再看定时任务和脚本权限。"
    else
      ok "备份在 $BACKUP_MAX_AGE_H 小时内跑过"
      note "跑了不等于还得回来。还原演练每季度一次，做法见教材第 14 卷第 3 章。"
    fi
  fi
fi

# ---------------------------------------------------------------- 6
printf '\n第 6 项　日志里有没有反复出现的错误\n'
if ! have journalctl; then
  skip "这台机器上没有 journalctl"
else
  L_RAW="$(journalctl --since "$LOG_SINCE" -p err --no-pager 2>/dev/null)"
  if [ -z "$L_RAW" ]; then
    ok "$LOG_SINCE 到现在，日志里没有 err 及以上的条目"
    note "没有报错也不等于没事。这一项看的是变化，不是有没有。"
  else
    L_TOP="$(printf '%s\n' "$L_RAW" \
      | sed -E 's/^[A-Z][a-z]{2} +[0-9]+ [0-9:]+ [^ ]+ //' \
      | sed -E 's/\[[0-9]+\]//g' \
      | sed -E 's/[0-9]+/#/g' \
      | sort | uniq -c | sort -rn | head -"$LOG_TOP")"
    line "$LOG_SINCE 到现在，出现最多的前 $LOG_TOP 条（数字已归并成 #）："
    printf '%s\n' "$L_TOP" | while IFS= read -r l; do printf '    %s\n' "$l"; done

    KNOWN_N=0
    KNOWN_PATTERNS=()
    if [ -r "$KNOWN_NOISE" ]; then
      while IFS= read -r kl; do
        case "$kl" in ''|'#'*) continue ;; esac
        KNOWN_PATTERNS+=("$kl")
        KNOWN_N=$((KNOWN_N + 1))
      done < "$KNOWN_NOISE"
    fi

    if [ "$KNOWN_N" = "0" ]; then
      skip "没有已知背景噪声清单，这一项只列出来给你自己看"
      note "把上面确认无害的那几条抄进 $KNOWN_NOISE，一条一行，以后这一项才判断得了。教材第 14 卷第 2 章讲了这份清单怎么建。"
      note "第 4 卷第 17 章第八条写过：系统日志里有几条红色报错是正常的，那几条属于背景噪声，不要每次重查一遍。"
    else
      UNKNOWN=""
      while IFS= read -r l; do
        [ -z "$l" ] && continue
        MSG="$(printf '%s' "$l" | sed -E 's/^ *[0-9]+ //')"
        HIT=0
        for p in "${KNOWN_PATTERNS[@]}"; do
          case "$MSG" in *"$p"*) HIT=1; break ;; esac
        done
        [ "$HIT" = "0" ] && UNKNOWN="$UNKNOWN
$MSG"
      done <<EOF
$L_TOP
EOF
      if [ -z "$UNKNOWN" ]; then
        ok "前 $LOG_TOP 条都在已知背景噪声清单上（清单里有 $KNOWN_N 条）"
      else
        bad "有清单上没有的条目在反复出现："
        printf '%s\n' "$UNKNOWN" | while IFS= read -r l; do
          [ -n "$l" ] && printf '    %s\n' "$l"
        done
        note "确认无害的抄进 $KNOWN_NOISE；确认要处理的按教材第 15 卷对应的症状查。"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------- 另外两行，只报数
printf '\n另外两行（只报数，抄进报告用）\n'

if [ -n "$DAILY_DIR" ] && [ -d "$DAILY_DIR" ]; then
  N_DAILY="$(find "$DAILY_DIR" -maxdepth 1 -type f -name "*$MONTH*" 2>/dev/null | wc -l | tr -d ' ')"
  line "这个月的每日巡检输出：$N_DAILY 份"
  R_CHECKS="$N_DAILY 次"
else
  line "每日巡检输出：没设 MC_DAILY_DIR，这一行没数"
fi

if have ss; then
  N_PORTS="$(ss -tln 2>/dev/null | awk 'NR>1 {print $4}' | grep -vE '^(127\.|\[::1\])' | sort -u | wc -l | tr -d ' ')"
  line "对外在监听的口：$N_PORTS 个"
  R_PORTS="$N_PORTS 个"
  if have ufw; then
    U_OUT="$(ufw status 2>/dev/null)"
    if [ -n "$U_OUT" ]; then
      N_RULES="$(printf '%s\n' "$U_OUT" | grep -ciE 'ALLOW|允许')"
      line "防火墙放行规则：$N_RULES 条（逐条要说得出给谁开的）"
      R_PORTS="$N_PORTS 个在监听，防火墙放行 $N_RULES 条"
    fi
  fi
else
  line "对外在监听的口：这台机器上没有 ss，查不了"
fi

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

printf '\n'
printf '============ 下面这段可以直接抄进月度报告第二栏 ============\n'
printf '巡检　　　　　　%s\n' "$R_CHECKS"
printf '备份　　　　　　%s\n' "$R_BACKUP"
if [ -n "$R_DISK" ]; then
  printf '%s' "$R_DISK"
else
  printf '磁盘剩余　　　　未测\n'
fi
printf '温度稳态　　　　%s\n' "$R_TEMP"
printf '服务开机自启　　%s\n' "$R_SERVICES"
printf '容器自恢复　　　%s\n' "$R_CONTAINERS"
printf '对外开的口　　　%s\n' "$R_PORTS"
printf '\n'
printf '还要自己补三行，这个脚本查不到：\n'
printf '　还原演练　　　最近一次是哪一天、结果、下一次约在什么时候（第 14 卷第 3 章）\n'
printf '　这个月出过的事　从故障记录表上抄（第 14 卷第 7 章）\n'
printf '　下个月要注意的　每条要有一个数或者一个日期（第 14 卷第 6 章）\n'
printf '\n'
printf '往外发之前逐行看一遍：这份输出里有主机名、内网地址、容器名和开着的端口。\n'
printf '（教材第 0 卷第 8 章。给客户的那一份只抄上面那一段，不要整份贴进去。）\n'
printf '===========================================================\n'

if [ "$FAIL" -gt 0 ]; then
  printf '\n这次有不通过的项。上面每一条后面都写了回哪一章。\n'
  exit 1
fi

printf '\n这次全部通过或跳过。\n'
exit 0
