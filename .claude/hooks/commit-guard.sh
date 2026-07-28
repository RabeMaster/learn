#!/bin/sh
# git commit 명령에 Co-Authored-By(공동작성자)가 있으면 차단한다.
if grep -qi 'co-authored-by:'; then
  echo 'Co-Authored-By 금지' >&2
  exit 2
fi
exit 0
