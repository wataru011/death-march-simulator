#!/usr/bin/env bash
# Claude Code の Stop フックから呼ばれる自動コミット&プッシュスクリプト。
# 改修(作業ツリーの変更)があれば、現在のブランチに commit して push する。
# push を受けて GitHub Actions が PR 作成(auto-pr.yml)と Pages 公開(deploy-pages.yml)を行う。
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || exit 0
[ "$branch" = "HEAD" ] && exit 0            # detached HEAD は対象外

# 変更が無ければ何もしない
[ -z "$(git status --porcelain)" ] && exit 0

git add -A || exit 0
git commit -q -m "auto: 改修を反映 ($(date '+%Y-%m-%d %H:%M:%S'))" || exit 0

# ネットワークエラーに備えて指数バックオフで数回リトライ
for i in 1 2 3 4; do
  if git push -q origin "HEAD:${branch}"; then
    exit 0
  fi
  sleep $(( 2 ** i ))
done
exit 0
