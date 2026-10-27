# terroir-context 변경 이력

실제 배포 버전은 [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)을 따른다.

## 1.1.0 - 2026-10-27

### 추가

- CHANGELOG 항목을 쓰거나 고칠 때 Claude 가 먼저 읽는 작성 기준 문서와, 그 문서대로 쓰는 `changelog-write` 스킬을 더했습니다.

## 1.0.0 - 2026-10-20

최초 배포.

### 추가

- 세션 시작 시 `docs/index.md` 목차를 메인 세션에 올리는 훅. 목차 항목이 없으면 아무것도 올리지 않는다 [RDDP-2188].
