#!/usr/bin/env bash
# 打包 KernelSU 模块 zip
set -euo pipefail
cd "$(dirname "$0")"

VER=$(sed -n 's/^version=//p' module.prop)
OUT=dist
NAME="github-hosts-${VER}.zip"

mkdir -p "$OUT"
rm -f "$OUT/$NAME"

python3 - "$OUT/$NAME" <<'PY'
import os, sys, zipfile

dst = sys.argv[1]
files = ["module.prop", "customize.sh", "service.sh", "update.sh", "sources.json"]
for top in ("system", "webroot"):
    for root, _, fs in os.walk(top):
        for f in sorted(fs):
            files.append(os.path.join(root, f))

with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    for p in files:
        zi = zipfile.ZipInfo(p, date_time=(1980, 1, 1, 0, 0, 0))
        zi.external_attr = (0o100755 if p.endswith(".sh") else 0o100644) << 16
        zi.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(zi, open(p, "rb").read())

print("打包 %d 个文件" % len(files))
PY

echo "已生成 $OUT/$NAME ($(du -h "$OUT/$NAME" | cut -f1))"
python3 -c "import zipfile;print(zipfile.ZipFile('$OUT/$NAME').namelist())"
