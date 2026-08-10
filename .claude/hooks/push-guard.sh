#!/bin/sh
# git push 정책: Claude가 혼자 push하지 못하게 한다.
#  - force push (--force / -f / --force-with-lease / +refspec)  -> 차단(deny)
#  - 일반 push                                                   -> 사용자 확인(ask)
#  - push가 아닌 명령                                             -> 판단하지 않고 통과
#
# settings.json의 if 필터에만 안전을 맡기지 않는다.
# 필터가 넓게 걸리거나 동작하지 않아도 여기서 한 번 더 걸러내야
# 무관한 명령까지 확인창이 뜨는 일이 없다.
in=$(cat)

# 실제로 git push인지 먼저 확인한다. 아니면 아무 결정도 내리지 않고 빠진다.
#   git 과 push 사이에 옵션이 몇 개 끼어도 잡는다 (git -c user.name=x push)
#   push 가 단어로 끝나야 한다 (git pushup-branch 같은 건 제외)
#   --grep=push 처럼 값에 섞인 push 는 잡지 않는다
if ! printf '%s' "$in" | grep -qE 'git[[:space:]]+([^[:space:]]+[[:space:]]+)*push([[:space:]]|\\|"|$)'; then
  exit 0
fi

if printf '%s' "$in" | grep -qiE 'push[^"]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|")|[[:space:]]\+[^[:space:]])'; then
  dec=deny
  reason="force push는 Claude가 직접 하지 않습니다. 사용자에게 설명하고 직접 실행하도록 요청하세요."
else
  dec=ask
  reason="push 전 사용자 확인이 필요합니다."
fi
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$dec" "$reason"
