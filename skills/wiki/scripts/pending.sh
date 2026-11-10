#!/usr/bin/env bash
# pending.sh — 列出知识库 raw/ 中尚未消化的资料（幂等检查）
# 原理：对每个 raw/*.md 算 SHA256，与 wiki/sources/*.md frontmatter 中的
# digest_sha256 比对；没有匹配即 PENDING。
# 用法: pending.sh <知识库根目录>    （缺省为当前目录；位置无关，可在任何地方调用）
ROOT="${1:-.}"
cd "$ROOT" || { echo "cannot cd: $ROOT" >&2; exit 1; }
[ -f AGENTS.md ] || echo "warn: $ROOT 下没有 AGENTS.md，可能不是 LLM Wiki 知识库" >&2
shopt -s nullglob
pending=0
for f in raw/*.md; do
  h=$(sha256sum "$f" | cut -d" " -f1)
  if grep -rqsF -- "digest_sha256: $h" wiki/sources/; then
    printf 'DONE    %s\n' "$f"
  else
    printf 'PENDING %s\n' "$f"
    pending=$((pending + 1))
  fi
done
echo "---"
echo "pending: $pending"
