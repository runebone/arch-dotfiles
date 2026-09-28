#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
test_tmp="$(mktemp -d)"
trap 'rm -rf -- "$test_tmp"' EXIT
export NVIM_TEST_ROOT="$repo_root" NVIM_TEST_TMP="$test_tmp"
export NVIM_LOG_FILE="$test_tmp/nvim.log" XDG_STATE_HOME="$test_tmp/state" XDG_CACHE_HOME="$test_tmp/cache"
export GOCACHE="$test_tmp/go-cache" GOPROXY=off GOTOOLCHAIN=local
for test_file in project scoped_search interface_usages go_alternate go_tasks refactor; do
    nvim --headless -u NONE -i NONE -l "$repo_root/tests/$test_file.lua"
done
