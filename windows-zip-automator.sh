#!/bin/zsh
set -e

if (( $# == 0 )); then
  exit 0
fi

/usr/bin/python3 - "$@" <<'PY'
import os, sys, zipfile

paths = sys.argv[1:]
if not paths:
    sys.exit(0)

out_dir = os.path.dirname(paths[0])
for p in paths:
    if os.path.dirname(p) != out_dir:
        print("同じフォルダ内の項目だけ選択してください。", file=sys.stderr)
        sys.exit(1)

base_name = os.path.splitext(os.path.basename(paths[0]))[0]
zip_path = os.path.join(out_dir, f"{base_name}.zip")

EXCLUDED_DIRS = {"__MACOSX", ".Spotlight-V100", ".Trashes"}
EXCLUDED_FILES = {".DS_Store"}

def should_skip(path):
    parts = path.split(os.sep)
    if any(part in EXCLUDED_DIRS for part in parts):
        return True
    name = os.path.basename(path)
    if name in EXCLUDED_FILES:
        return True
    if name == "._" or name.startswith("._"):
        return True
    return False

def add_path(zf, path):
    if should_skip(path):
        return
    if os.path.isdir(path):
        for root, dirs, files in os.walk(path):
            dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]
            for name in files:
                full = os.path.join(root, name)
                if should_skip(full):
                    continue
                rel = os.path.relpath(full, out_dir)
                zf.write(full, rel)
    else:
        rel = os.path.relpath(path, out_dir)
        zf.write(path, rel)

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for p in paths:
        add_path(zf, p)

print(zip_path)
PY
