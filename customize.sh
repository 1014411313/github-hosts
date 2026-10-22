#!/system/bin/sh
# KernelSU / Magisk 安装时 source 本脚本

ui_print "- GitHub Hosts 加速模块"
ui_print "- 多源合并，默认每 12 小时自动更新"

DATA=/data/adb/github_hosts
mkdir -p "$DATA/backup"

[ -f "$DATA/sources.json" ] || cp -f "$MODPATH/sources.json" "$DATA/sources.json"
[ -f "$DATA/config.conf" ] || printf 'INTERVAL=43200\n' > "$DATA/config.conf"
[ -f "$DATA/disabled.list" ] || : > "$DATA/disabled.list"

metamodule_ok=0
if [ -e /data/adb/metamodule ]; then metamodule_ok=1; fi
if [ "$metamodule_ok" -eq 0 ]; then
  # 标准标记是 module.prop 里的 metamodule=1，目录名各实现不同（meta-overlay 等）
  for f in /data/adb/modules/*/module.prop; do
    [ -f "$f" ] || continue
    if grep -q '^metamodule=' "$f" 2>/dev/null; then
      metamodule_ok=1
      break
    fi
  done
fi

if [ "$metamodule_ok" -eq 0 ]; then
  ui_print " "
  ui_print "!! 未检测到 metamodule（如 meta-overlayfs）"
  ui_print "!! KernelSU / SterSU 需要它才能把 system/etc/hosts 挂载生效"
  ui_print "!! 请安装 metamodule 后重启"
  ui_print " "
fi

if command -v set_perm_recursive >/dev/null 2>&1; then
  set_perm_recursive "$MODPATH" 0 0 0755 0644
  set_perm "$MODPATH/update.sh" 0 0 0755
  set_perm "$MODPATH/service.sh" 0 0 0755
  set_perm "$MODPATH/customize.sh" 0 0 0755
else
  chmod 0755 "$MODPATH"/*.sh 2>/dev/null
fi
