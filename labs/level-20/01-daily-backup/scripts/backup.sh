#!/usr/bin/env bash
# 日常备份：先同步到本机的一份，再同步到移动硬盘上的一份。
#
# 用法：
#   ./backup.sh                      只做本机那一份
#   ./backup.sh /移动硬盘上的目录     本机一份，移动硬盘一份
#
# 可以用环境变量改默认值：
#   BACKUP_SOURCES       要备份的目录，多个用冒号隔开
#   BACKUP_LOCAL_DEST    本机备份目录
#   BACKUP_EXCLUDE_FILE  排除清单
#   BACKUP_LOG           日志文件

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCES_RAW="${BACKUP_SOURCES:-$HOME/ai/data:$HOME/ai/projects:$HOME/ai/scripts}"
LOCAL_DEST="${BACKUP_LOCAL_DEST:-$HOME/ai/backup/latest}"
EXCLUDE_FILE="${BACKUP_EXCLUDE_FILE:-$SCRIPT_DIR/../backup-exclude.txt}"
LOG="${BACKUP_LOG:-$(dirname "$LOCAL_DEST")/backup.log}"
EXTERNAL_DEST="${1:-}"

mkdir -p "$LOCAL_DEST/config"
mkdir -p "$(dirname "$LOG")"

log() {
  echo "$(date '+%F %T') $*" | tee -a "$LOG"
}

if [ ! -f "$EXCLUDE_FILE" ]; then
  log "找不到排除清单 $EXCLUDE_FILE，停下"
  exit 1
fi

log "开始备份"

OLD_IFS="$IFS"
IFS=':'
# shellcheck disable=SC2206
SOURCES=($SOURCES_RAW)
IFS="$OLD_IFS"

for src in "${SOURCES[@]}"; do
  if [ ! -d "$src" ]; then
    log "跳过 $src，目录不存在"
    continue
  fi
  rsync -a --delete --exclude-from="$EXCLUDE_FILE" "$src" "$LOCAL_DEST/" >> "$LOG" 2>&1
  log "已同步 $src"
done

for f in "$HOME/.bashrc" "/etc/fstab"; do
  if [ -f "$f" ]; then
    cp -a "$f" "$LOCAL_DEST/config/" 2>/dev/null || log "复制 $f 失败，跳过"
  fi
done
log "配置文件已复制"

if [ -z "$EXTERNAL_DEST" ]; then
  log "没有给移动硬盘路径，这次只做了本机这一份"
elif [ ! -d "$EXTERNAL_DEST" ]; then
  log "找不到 $EXTERNAL_DEST，移动硬盘可能没插，这次只做了本机这一份"
else
  rsync -a --delete "$LOCAL_DEST/" "$EXTERNAL_DEST/" >> "$LOG" 2>&1
  log "已同步到 $EXTERNAL_DEST"
fi

log "备份结束"
