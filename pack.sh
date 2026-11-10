#!/usr/bin/env bash
# 把一个模型目录打成 tar.gz、按 95MB 切块，写 manifest.json。用法见 docs/maintaining.md。
set -euo pipefail

MODEL=${1:?模型名，即 models/ 下的目录，如 zhiyi、hanzhang/tongbian、lm}
VERSION=${2:?版本号，主.次.修订，如 1.0.0}
SOURCE=${3:?模型目录}
PART_BYTES=$((95 * 1000 * 1000))

case "$MODEL" in
  zhiyi) FILES=(model.safetensors config.json tokenizer.json unified_vocab.json README.md) ;;
  zhiyi-onnx) FILES=(laya.int8g.onnx tokenizer.json unified_vocab.json rl_agent_config.json) ;;
  hanzhang/tongbian) FILES=(hanzhang-tongbian-small.qjm) ;;
  hanzhang/zhiwei) FILES=(hanzhang-zhiwei-small.qjm) ;;
  lm) FILES=(lm.qj) ;;
  *) echo "不认识的模型：$MODEL" >&2; exit 1 ;;
esac

ROOT=$(cd "$(dirname "$0")" && pwd)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "版本号要是 主.次.修订：$VERSION" >&2; exit 1; }
TAG="${MODEL//\//-}-v$VERSION"
OUT="$ROOT/dist/$TAG"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/$MODEL"
for f in "${FILES[@]}"; do
  [[ -f "$SOURCE/$f" ]] || { echo "缺少 $SOURCE/$f" >&2; exit 1; }
  cp "$SOURCE/$f" "$STAGE/$MODEL/$f"
done
[[ -f "$ROOT/models/$MODEL/LICENSE" ]] && cp "$ROOT/models/$MODEL/LICENSE" "$STAGE/$MODEL/LICENSE"

rm -rf "$OUT" && mkdir -p "$OUT"
COPYFILE_DISABLE=1 tar -czf "$STAGE/$TAG.tar.gz" -C "$STAGE" "$MODEL"
split -b "$PART_BYTES" -a 1 "$STAGE/$TAG.tar.gz" "$OUT/$TAG.tar.gz.part"
# split 的后缀是 a b c，改成 1 2 3
index=1
for part in "$OUT/$TAG.tar.gz.part"?; do
  mv "$part" "$OUT/$TAG.tar.gz.part$index"
  index=$((index + 1))
done

sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
size() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }
{
  printf '{\n  "model": "%s",\n  "version": "%s",\n  "tag": "%s",\n  "archive": {"bytes": %s, "sha256": "%s"},\n  "parts": [\n' \
    "$MODEL" "$VERSION" "$TAG" "$(size "$STAGE/$TAG.tar.gz")" "$(sha "$STAGE/$TAG.tar.gz")"
  first=1
  for ((i = 1; i < index; i++)); do
    part="$OUT/$TAG.tar.gz.part$i"
    [[ $first == 1 ]] || printf ',\n'
    printf '    {"name": "%s", "bytes": %s, "sha256": "%s"}' "$(basename "$part")" "$(size "$part")" "$(sha "$part")"
    first=0
  done
  printf '\n  ]\n}\n'
} > "$OUT/manifest.json"

cat "$OUT/$TAG.tar.gz.part"* | shasum -a 256 | cut -d' ' -f1 | grep -qx "$(sha "$STAGE/$TAG.tar.gz")" \
  || { echo "拼回来的压缩包对不上" >&2; exit 1; }
cat "$OUT/manifest.json"
