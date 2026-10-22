#!/system/bin/sh
# 合并启用中的源，生成 GitHub 加速 hosts
# 用法：update.sh          执行更新
#       update.sh --test   仅测试 github.com 连通性，输出 OK / FAIL

MODDIR=${0%/*}
DATA=/data/adb/github_hosts
SOURCES=$DATA/sources.json
DISABLED=$DATA/disabled.list
LOG=$DATA/log.txt
BACKUP=$DATA/backup
HOSTS=$MODDIR/system/etc/hosts
MERGED=$DATA/.merged
TMP=$DATA/.hosts.new
DL=$DATA/.download
MAX_BACKUP=10
MIN_LINES=5

BUSYBOX=$(command -v busybox 2>/dev/null)
[ -n "$BUSYBOX" ] || BUSYBOX=/data/adb/ksu/bin/busybox
[ -n "$BUSYBOX" ] || BUSYBOX=/data/adb/magisk/busybox
CURL=$(command -v curl 2>/dev/null)

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

if [ "$1" = "--test" ]; then
  if "$BUSYBOX" nc -z -w 3 github.com 443 2>/dev/null; then
    echo "OK"
  else
    echo "FAIL"
  fi
  exit 0
fi

mkdir -p "$BACKUP"
[ -d "$(dirname "$HOSTS")" ] || "$BUSYBOX" mkdir -p "$(dirname "$HOSTS")"
[ -f "$SOURCES" ] || cp -f "$MODDIR/sources.json" "$SOURCES" 2>/dev/null
[ -f "$DISABLED" ] || : > "$DISABLED"

fetch() {
  if [ -n "$CURL" ]; then
    "$CURL" -fsSL --connect-timeout 10 --max-time 30 -o "$2" "$1" 2>/dev/null && return 0
  fi
  "$BUSYBOX" wget -q -T 15 -O "$2" "$1" 2>/dev/null && return 0
  rm -f "$2"
  return 1
}

: > "$MERGED"
total=0
ok=0

for url in $("$BUSYBOX" grep -o '"url"[^"]*"[^"]*"' "$SOURCES" | "$BUSYBOX" sed 's/^"url"[^"]*"//; s/"$//'); do
  total=$((total + 1))
  "$BUSYBOX" grep -qxF "$url" "$DISABLED" 2>/dev/null && continue

  if fetch "$url" "$DL"; then
    "$BUSYBOX" awk '$1 !~ /^#/ && NF >= 2 && ($1 ~ /^[0-9]/ || $1 ~ /:/) { print $1, $2 }' "$DL" >> "$MERGED"
    ok=$((ok + 1))
  else
    log "下载失败: $url"
  fi
  rm -f "$DL"
done

# 按域名去重：同一域名保留最先出现的源给的 IP（越靠前的源优先级越高），
# 否则一个域名会写入多个不同 IP，实际命中哪个不确定
"$BUSYBOX" awk '!seen[$2]++' "$MERGED" > "$MERGED.uniq"
mv -f "$MERGED.uniq" "$MERGED"
count=$("$BUSYBOX" wc -l < "$MERGED")

if [ "$ok" -eq 0 ]; then
  log "全部源下载失败，保留现有 hosts"
  echo "FAIL: 全部源下载失败"
  exit 1
fi

if [ "$count" -lt "$MIN_LINES" ] || ! "$BUSYBOX" grep -q 'github\.com' "$MERGED"; then
  log "新内容异常（$count 行），放弃写入"
  echo "FAIL: 新内容异常（$count 行）"
  exit 1
fi

{
  echo "# GitHub Hosts 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')"
  echo "127.0.0.1 localhost"
  echo "::1 localhost"
  cat "$MERGED"
} > "$TMP"

[ -f "$HOSTS" ] && cp -f "$HOSTS" "$BACKUP/hosts.$(date +%s)"

# 用重定向覆盖而非 mv，保持 inode 不变，否则已挂载的 /system/etc/hosts 仍指向旧文件
cat "$TMP" > "$HOSTS" || { log "写入失败: $HOSTS"; echo "FAIL: 写入失败"; exit 1; }

"$BUSYBOX" ls -1t "$BACKUP" 2>/dev/null | "$BUSYBOX" tail -n +$((MAX_BACKUP + 1)) | while IFS= read -r f; do
  rm -f "$BACKUP/$f"
done

rm -f "$MERGED" "$TMP"
log "更新完成：源 $ok/$total 成功，合并 $count 行"
echo "OK: 源 $ok/$total 成功，合并 $count 行"
