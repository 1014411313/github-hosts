#!/system/bin/sh
# 开机后先更新一次，之后按 config.conf 的 INTERVAL 循环更新

MODDIR=${0%/*}
DATA=/data/adb/github_hosts
CONF=$DATA/config.conf
LOG=$DATA/log.txt

mkdir -p "$DATA/backup"
[ -f "$CONF" ] || printf 'INTERVAL=43200\n' > "$CONF"
[ -f "$DATA/sources.json" ] || cp -f "$MODDIR/sources.json" "$DATA/sources.json" 2>/dev/null
[ -f "$DATA/disabled.list" ] || : > "$DATA/disabled.list"

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 5
  i=$((i + 1))
done
sleep 30

(
  while :; do
    sh "$MODDIR/update.sh"
    interval=$(sed -n 's/^INTERVAL=\([0-9][0-9]*\).*/\1/p' "$CONF" 2>/dev/null | head -n 1)
    case "$interval" in
      '' | *[!0-9]*) interval=43200 ;;
    esac
    [ "$interval" -lt 600 ] && interval=600
    sleep "$interval"
  done
) >> "$LOG" 2>&1 &
