#!/bin/sh
# git push 정책: Claude가 혼자 push하지 못하게 한다.
#  - force push (--force / -f / --force-with-lease / +refspec)  -> 차단(deny)
#  - 일반 push                                                   -> 사용자 확인(ask)
in=$(cat)
if printf '%s' "$in" | grep -qiE 'push[^"]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|")|[[:space:]]\+[^[:space:]])'; then
  dec=deny
  reason="force push는 Claude가 직접 하지 않습니다. 사용자에게 설명하고 직접 실행하도록 요청하세요."
else
  dec=ask
  reason="push 전 사용자 확인이 필요합니다."
fi
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$dec" "$reason"
