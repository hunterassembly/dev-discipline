#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

for test_file in "$REPO_ROOT/tests/"*_test.sh; do
  if [ -x "$test_file" ]; then
    "$test_file"
  else
    bash "$test_file"
  fi
done
