#!/usr/bin/env bash
# Create a pull/merge request on one or more vendor remotes.
# github -> gh pr create, gitlab -> glab mr create, bitbucket -> Bitbucket REST API v2.0
# (needs BITBUCKET_EMAIL + BITBUCKET_API_TOKEN in the environment).
set -euo pipefail

VENDORS=(github gitlab bitbucket)

# bash 3.2 (macOS default) has no associative arrays; use a function instead.
host_of() {
  case "$1" in
    github) echo "github.com" ;;
    gitlab) echo "gitlab.com" ;;
    bitbucket) echo "bitbucket.org" ;;
  esac
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [github|gitlab|bitbucket|all] [options]

Options (mirror common git/gh/glab flags):
  -t, --title TITLE      PR/MR title
  -b, --body TEXT        PR/MR body/description (alias: -d/--description)
  -B, --base BRANCH      target branch (default: repo default branch)
  -H, --head BRANCH      source branch (default: current branch)
  --draft                mark as draft (github/gitlab only; ignored on bitbucket)
  --fill                 autofill title/body from the last commit if not given
  --web                  open the created PR/MR in the browser
  -h, --help             show this help

Examples:
  $(basename "$0") github --fill
  $(basename "$0") gitlab -t "Add cart module" -b "Implements cart CRUD" -B main
  $(basename "$0") all --fill --web

If vendor is omitted, you'll be prompted to pick one interactively.
EOF
}

remote_for_vendor() {
  local host
  host="$(host_of "$1")"
  git remote -v | awk -v h="$host" '$2 ~ h {print $1; exit}'
}

pick_vendor_interactively() {
  echo "Chọn vendor để tạo PR:" >&2
  select v in "${VENDORS[@]}" "all"; do
    if [[ -n "${v:-}" ]]; then
      echo "$v"
      return
    fi
    echo "Chọn số hợp lệ." >&2
  done
}

title=""
body=""
base=""
head=""
draft=false
fill=false
web=false

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--title) title="$2"; shift 2 ;;
      -b|-d|--body|--description) body="$2"; shift 2 ;;
      -B|--base) base="$2"; shift 2 ;;
      -H|--head) head="$2"; shift 2 ;;
      --draft) draft=true; shift ;;
      --fill) fill=true; shift ;;
      --web) web=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
  done
}

current_branch() { git rev-parse --abbrev-ref HEAD; }

autofill_from_last_commit() {
  [[ -n "$title" ]] || title="$(git log -1 --pretty=%s)"
  [[ -n "$body" ]] || body="$(git log -1 --pretty=%b)"
}

create_github() {
  local args=(pr create)
  [[ -n "$title" ]] && args+=(--title "$title")
  [[ -n "$body" ]] && args+=(--body "$body")
  [[ -n "$base" ]] && args+=(--base "$base")
  [[ -n "$head" ]] && args+=(--head "$head")
  $draft && args+=(--draft)
  $web && args+=(--web)
  echo "==> gh ${args[*]}" >&2
  gh "${args[@]}"
}

create_gitlab() {
  local args=(mr create)
  [[ -n "$title" ]] && args+=(--title "$title")
  [[ -n "$body" ]] && args+=(--description "$body")
  [[ -n "$base" ]] && args+=(--target-branch "$base")
  [[ -n "$head" ]] && args+=(--head "$head")
  $draft && args+=(--draft)
  $web && args+=(--web)
  echo "==> glab ${args[*]}" >&2
  glab "${args[@]}"
}

create_bitbucket() {
  : "${BITBUCKET_EMAIL:?BITBUCKET_EMAIL chưa set trong env}"
  : "${BITBUCKET_API_TOKEN:?BITBUCKET_API_TOKEN chưa set trong env}"

  local remote workspace_repo source dest pr_title pr_body
  remote="$(remote_for_vendor bitbucket)"
  [[ -n "$remote" ]] || { echo "Không tìm thấy remote bitbucket.org" >&2; return 1; }

  # git@bitbucket.org:workspace/repo.git  or  https://bitbucket.org/workspace/repo.git
  local url
  url="$(git remote get-url "$remote")"
  workspace_repo="$(echo "$url" | sed -E 's#.*bitbucket\.org[:/]##; s#\.git$##')"

  source="${head:-$(current_branch)}"
  dest="$base"
  if [[ -z "$dest" ]]; then
    dest="$(curl -sf -u "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN" \
      "https://api.bitbucket.org/2.0/repositories/${workspace_repo}" \
      | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("mainbranch",{}).get("name",""))' 2>/dev/null)"
    dest="${dest:-main}"
  fi

  pr_title="$title"
  pr_body="$body"
  [[ -n "$pr_title" ]] || { echo "Cần --title (hoặc --fill) cho bitbucket PR" >&2; return 1; }

  local payload
  payload="$(python3 -c '
import json, sys
title, body, source, dest = sys.argv[1:5]
print(json.dumps({
    "title": title,
    "description": body,
    "source": {"branch": {"name": source}},
    "destination": {"branch": {"name": dest}},
}))
' "$pr_title" "$pr_body" "$source" "$dest")"

  echo "==> POST bitbucket pullrequests ($workspace_repo: $source -> $dest)" >&2
  local resp
  resp="$(curl -sf -u "$BITBUCKET_EMAIL:$BITBUCKET_API_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "https://api.bitbucket.org/2.0/repositories/${workspace_repo}/pullrequests" \
    -d "$payload")"

  local pr_url
  pr_url="$(echo "$resp" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["links"]["html"]["href"])' 2>/dev/null || true)"
  if [[ -z "$pr_url" ]]; then
    echo "Tạo PR thất bại. Response:" >&2
    echo "$resp" >&2
    return 1
  fi
  echo "$pr_url"
  $web && command -v open >/dev/null && open "$pr_url"
}

vendor=""
if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help) usage; exit 0 ;;
    github|gitlab|bitbucket|all) vendor="$1"; shift ;;
  esac
fi
[[ -n "$vendor" ]] || vendor="$(pick_vendor_interactively)"

parse_args "$@"
$fill && autofill_from_last_commit

case "$vendor" in
  github) create_github ;;
  gitlab) create_gitlab ;;
  bitbucket) create_bitbucket ;;
  all)
    status=0
    for v in "${VENDORS[@]}"; do
      if [[ -n "$(remote_for_vendor "$v")" ]]; then
        case "$v" in
          github) create_github || status=1 ;;
          gitlab) create_gitlab || status=1 ;;
          bitbucket) create_bitbucket || status=1 ;;
        esac
      fi
    done
    exit "$status"
    ;;
  *)
    echo "Vendor không hợp lệ: $vendor" >&2
    usage
    exit 1
    ;;
esac
