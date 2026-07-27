# terroir-onboarding

> Terroir를 처음 시작하는 사람을 위한 **온보딩 진입점 플러그인**.
> 사전 인증 없이 설치할 수 있다.

## 설치

```
/plugin marketplace add VntgCorp/terroir-claude-plugin-public
/plugin install terroir-onboarding@terroir-claude-plugin-public
```

## 사용

```
온보딩 시작해줘
```

또는 `/onboarding-start`.

## 제공 skill

| skill | 설명 |
| --- | --- |
| `onboarding-start` | 온보딩 진입점. 환경 셋팅 → 직무 확인 → 직무별 경로 안내 → 제공 기능 소개 |
| `env-setup` | 공통 업무 환경 셋팅 — 지라·컨플루언스 / 메일·캘린더·드라이브 연결 점검·안내 |
| `github-connect` | GitHub 계정 연결 → Git 연결 → 사내 플러그인 접근 확인·설치 (승인 후 이어받기 포함) |
| `org-access-request` | 조직 계정이 없는 경우 가입 안내와 접근 요청 전송, 대기 안내 |
