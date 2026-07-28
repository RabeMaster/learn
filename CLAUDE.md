# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 안내서입니다.

## 저장소 개요

개인 공부용 저장소. 주제별로 공부 노트·블로그 글(Markdown)·실습 코드를 모은다. Obsidian 볼트이며(`.obsidian/`은 git 제외), 글은 한국어·플레인 Markdown으로 쓴다(`[[위키링크]]` 금지). 저장소 공통 빌드/테스트 도구는 없음 — 실습 프로젝트는 각자의 도구를 먼저 확인할 것.

## 폴더/이름 규칙

- 주제 폴더: `NNN_주제/` (세 자리, 0으로 채움) — 예: `001_java/`, `002_gc/`.
- 글: `NNN_제목.md`. 이미지: 폴더별 `images/`.
- 실습 프로젝트는 주제 폴더 안에 둔다. 커밋 전 빌드 산출물(`target/`, `build/`, `.gradle/`, `bin/`)을 `.gitignore`에 추가.

## 커밋/PR 규칙

- 커밋·PR에 `Co-Authored-By:`(누구든)와 AI 귀속 문구(`Generated with Claude Code`, `Claude-Session`)를 넣지 않는다. `.githooks/commit-msg`가 거부하며 `.claude/settings.json`이 attribution을 끈다.
- 커밋 제목은 `type(scope): 설명` 형식. type = feat/fix/docs/refactor/style/test/chore, scope는 주제 폴더 이름(생략 가능). merge 커밋은 예외. `.githooks/commit-msg`가 강제.
- 새로 클론하면 한 번: `git config core.hooksPath .githooks`.
- 커밋·푸시는 요청받을 때만. 공개 푸시는 먼저 확인.

## 비밀정보

공개 저장소. 비밀번호·API 키·`.env` 등 민감정보는 커밋하지 않는다.

## 코드 스타일 (`.editorconfig`)

- UTF-8, LF, 파일 끝 개행. `*.md`는 줄 끝 공백 유지, 그 외는 제거.
- Java: 2칸 들여쓰기 (Google Java Style — 4칸으로 바꾸지 말 것).
- Obsidian은 `.editorconfig`를 적용하지 않음(IDE·Claude 편집에만 적용).

## 작업 방식

- 사용자 글은 문체를 유지하며 가볍게 교정한다(틀림·어색·위험만 짚기). 요청 없이 전면 재작성 금지.

## 소통

항상 한국어·쉬운 말. 문서도 한국어. 어려운 용어는 풀어서 설명.
