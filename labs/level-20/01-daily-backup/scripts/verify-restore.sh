#!/usr/bin/env bash
# 备份验收：造一个测试文件、跑一次备份、删掉原件、再从备份里还原回来。
#
# 不带参数时用案例自带的 sample-data 演示，不碰你的真实目录。
# 要验收真实备份，设好 BACKUP_SOURCES 和 BACKUP_LOCAL_DEST 再跑，
# 移动硬盘上的目录作为第一个参数传进来。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -n "${BACKUP_SOURCES:-}" ]; then
  DEMO=0
else
  DEMO=1
fi

SOURCES_RAW="${BACKUP_SOURCES:-$LAB_DIR/sample-data/notes:$LAB_DIR/sample-data/projects}"
LOCAL_DEST="${BACKUP_LOCAL_DEST:-$LAB_DIR/demo-backup/latest}"
EXCLUDE_FILE="${BACKUP_EXCLUDE_FILE:-$LAB_DIR/backup-exclude.txt}"
LOG="${BACKUP_LOG:-$(dirname "$LOCAL_DEST")/backup.log}"

EXTERNAL_DEST="${1:-}"
if [ -z "$EXTERNAL_DEST" ] && [ "$DEMO" = "1" ]; then
  EXTERNAL_DEST="$LAB_DIR/demo-backup/external"
  mkdir -p "$EXTERNAL_DEST"
fi

OLD_IFS="$IFS"
IFS=':'
# shellcheck disable=SC2206
SOURCES=($SOURCES_RAW)
IFS="$OLD_IFS"

SRC1="${SOURCES[0]}"
SRC1_NAME="$(basename "$SRC1")"

PASS=0
FAIL=0
SKIP=0

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }

printf '备份验收\n'
printf '  源目录      %s\n' "$SOURCES_RAW"
printf '  本机备份    %s\n' "$LOCAL_DEST"
printf '  移动硬盘    %s\n' "${EXTERNAL_DEST:-（这次不查）}"
printf '\n'

if [ ! -d "$SRC1" ]; then
  printf '找不到源目录 %s，停下\n' "$SRC1"
  exit 1
fi

STAMP="$(date '+%Y%m%d-%H%M%S')"
CANARY_NAME="restore-check-$STAMP.txt"
CANARY="$SRC1/$CANARY_NAME"
CONTENT="restore check $STAMP $$"

printf '第 1 步　造一个测试文件\n'
echo "$CONTENT" > "$CANARY"
printf '  %s\n\n' "$CANARY"

printf '第 2 步　跑一次备份\n'
BACKUP_SOURCES="$SOURCES_RAW" \
BACKUP_LOCAL_DEST="$LOCAL_DEST" \
BACKUP_EXCLUDE_FILE="$EXCLUDE_FILE" \
BACKUP_LOG="$LOG" \
  "$SCRIPT_DIR/backup.sh" "$EXTERNAL_DEST" | sed 's/^/  /'
printf '\n'

LOCAL_COPY="$LOCAL_DEST/$SRC1_NAME/$CANARY_NAME"
EXT_COPY="$EXTERNAL_DEST/$SRC1_NAME/$CANARY_NAME"

printf '第 3 步　检查备份里有没有这个文件\n'
if [ -f "$LOCAL_COPY" ] && cmp -s "$CANARY" "$LOCAL_COPY"; then
  ok "本机备份里有它，内容一致"
else
  bad "本机备份里没有它，或者内容对不上：$LOCAL_COPY"
fi

if [ -n "$EXTERNAL_DEST" ] && [ -d "$EXTERNAL_DEST" ]; then
  if [ -f "$EXT_COPY" ] && cmp -s "$CANARY" "$EXT_COPY"; then
    ok "移动硬盘那份里有它，内容一致"
  else
    bad "移动硬盘那份里没有它，或者内容对不上：$EXT_COPY"
  fi
else
  skip "没给移动硬盘目录，这一项不查"
fi

printf '\n第 4 步　检查排除清单有没有生效\n'
LEAKED="$(find "$LOCAL_DEST" \( -name node_modules -o -name __pycache__ -o -name '*.gguf' -o -name '*.safetensors' \) -print 2>/dev/null | head -5)"
if [ -z "$LEAKED" ]; then
  ok "该排除的目录和大文件都没进备份"
else
  bad "这些不该出现在备份里：$(echo "$LEAKED" | tr '\n' ' ')"
fi

printf '\n第 5 步　删掉原件，再从备份还原\n'
rm -f "$CANARY"
if [ -f "$CANARY" ]; then
  bad "原件没删掉，后面的还原不算数"
else
  cp "$LOCAL_COPY" "$CANARY" 2>/dev/null
  if [ -f "$CANARY" ] && [ "$(cat "$CANARY")" = "$CONTENT" ]; then
    ok "从本机备份还原成功，内容和删之前一致"
  else
    bad "还原失败，或者内容和删之前不一致"
  fi
fi

printf '\n第 6 步　清理测试文件\n'
rm -f "$CANARY"
BACKUP_SOURCES="$SOURCES_RAW" \
BACKUP_LOCAL_DEST="$LOCAL_DEST" \
BACKUP_EXCLUDE_FILE="$EXCLUDE_FILE" \
BACKUP_LOG="$LOG" \
  "$SCRIPT_DIR/backup.sh" "$EXTERNAL_DEST" > /dev/null 2>&1
if [ ! -f "$LOCAL_COPY" ]; then
  ok "源里删掉的文件，备份里也跟着删了"
else
  bad "备份里还留着已经删掉的文件：$LOCAL_COPY"
fi

printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '验收没过。日志在 %s\n' "$LOG"
  exit 1
fi

printf '验收通过。\n'
exit 0
