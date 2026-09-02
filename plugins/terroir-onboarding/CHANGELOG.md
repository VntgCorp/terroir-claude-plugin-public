# terroir-onboarding 변경 이력

실제 배포 버전은 [`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)을 따른다.

## 1.0.1 - 2026-09-02

### 추가

- `/onboarding` 시작 시 public `terroir-claude-plugin-public` 마켓플레이스의 사용자 전역 자동 업데이트를 활성화한다.
- 프로덕트 직군이 private 플러그인 설치까지 진행하면 private `terroir-claude-plugin` 마켓플레이스의 자동 업데이트도 활성화한다.
- 설정을 변경했는지, 이미 활성화되어 있는지, 수동 설정이 필요한지를 사용자에게 안내한다.

### 변경

- 기존 설정과 마켓플레이스 채널을 보존하며, 자동 업데이트 설정에 실패해도 나머지 온보딩을 계속한다.

## 1.0.0 - 2026-08-28

- 온보딩 진입 스킬 이름을 `/onboarding-start`에서 `/onboarding`으로 변경했다.
- 직무와 업무 도구 연결 상태에 따라 온보딩을 분기하고, 설치된 private 플러그인의 시작점을 안내한다.
