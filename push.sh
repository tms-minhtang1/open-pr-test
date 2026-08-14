#!/usr/bin/env bash
# Push the current branch (or one you name) to one or more vendor remotes.
# Vendor is resolved by remote URL host, not remote name, so this works no
# matter what the remotes happen to be called in a given clone.
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
Usage: $(basename "$0") [github|gitlab|bitbucket|all] [git push args...]

Any argument after the vendor is passed straight through to 'git push',
so all normal git push syntax works: branch name, -f/--force,
--force-with-lease, -u, refspecs, etc.

Examples:
  $(basename "$0") github                    push current branch to github
  $(basename "$0") gitlab main                push 'main' to gitlab
  $(basename "$0") all -f                     force push current branch to all 3
  $(basename "$0") bitbucket -u HEAD:main     any git-push arg works, passed through

If vendor is omitted, you'll be prompted to pick one interactively.
EOF
}

remote_for_vendor() {
  local host
  host="$(host_of "$1")"
  git remote -v | awk -v h="$host" '$2 ~ h {print $1; exit}'
}

pick_vendor_interactively() {
  echo "Chọn vendor để push:" >&2
  select v in "${VENDORS[@]}" "all"; do
    if [[ -n "${v:-}" ]]; then
      echo "$v"
      return
    fi
    echo "Chọn số hợp lệ." >&2
  done
}

push_one() {
  local vendor="$1"; shift
  local remote
  remote="$(remote_for_vendor "$vendor")"
  if [[ -z "$remote" ]]; then
    echo "Không tìm thấy remote nào trỏ tới $(host_of "$vendor") (vendor: $vendor). Bỏ qua." >&2
    return 1
  fi
  echo "==> git push $remote $*" >&2
  git push "$remote" "$@"
}

if [[ $# -eq 0 ]]; then
  usage
  echo >&2
  vendor="$(pick_vendor_interactively)"
else
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    github|gitlab|bitbucket|all)
      vendor="$1"
      shift
      ;;
    *)
      # First arg isn't a known vendor: treat it as a git push arg and ask which vendor.
      vendor="$(pick_vendor_interactively)"
      ;;
  esac
fi

if [[ "$vendor" == "all" ]]; then
  status=0
  for v in "${VENDORS[@]}"; do
    push_one "$v" "$@" || status=1
  done
  exit "$status"
else
  push_one "$vendor" "$@"
fi
