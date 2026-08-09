# 공통서비스 — 공통 사항

`@vntgcorp/*` 공통서비스(auth·file 등)를 쓰기 위해 **모든 서비스에 공통으로 필요한 것**을 담는다.

> **이 문서의 범위**: 서비스 공통 사항만. 서비스별 설치·진입 패키지는 각 서비스 문서(`auth.md`·`file.md`), 사용법은 설치된 패키지(`node_modules`의 README·`dist/*.d.ts`)에 있다.

## 레지스트리 인증 (최초 1회 셋업)

`@vntgcorp/*`는 npmjs가 아니라 **GitHub Packages**(private)에서 받는다. 아래 두 가지가 준비돼 있어야 `pnpm add @vntgcorp/...`가 성공한다. 없으면 **401/404**로 실패한다.

### 1) `.npmrc`에 레지스트리 매핑 (프로젝트)

프로젝트 루트 `.npmrc`에 아래 두 줄이 있어야 한다.

```ini
@vntgcorp:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}
```

- 첫 줄: `@vntgcorp` 스코프는 GitHub Packages에서 받으라는 지정.
- 둘째 줄: 토큰을 **파일이 아니라 `NODE_AUTH_TOKEN` 환경변수에서** 읽는다(시크릿을 커밋하지 않기 위함).

### 2) `NODE_AUTH_TOKEN` 토큰 준비 (개발자 셸)

`read:packages` 권한을 가진 토큰을 셸 환경변수로 export한다. 두 경로 중 하나:

```bash
# 경로 A — gh CLI 재사용 (권장, 시크릿을 파일에 남기지 않음)
gh auth status || gh auth login -h github.com    # gh 로그인이 안 돼 있으면 먼저 로그인
gh auth refresh -h github.com -s read:packages   # 최초 1회 스코프 추가
export NODE_AUTH_TOKEN=$(gh auth token)

# 경로 B — PAT 발급 (CI/서비스 계정과 동일 방식)
# github.com → Settings → Developer settings → Personal access tokens (classic)
# → read:packages 체크 후 발급
export NODE_AUTH_TOKEN=ghp_xxxxxxxxxxxx
```

매번 export가 번거로우면 `~/.zshrc`(또는 `~/.bashrc`)에 `export` 줄을 넣어 둔다.

> 설치만 하는 개발자는 `read:packages`면 충분하다. `write:packages`는 SDK를 **배포**하는 사람만 필요하다.

## 설치 실패 시 (증상 → 원인)

| 증상 | 원인 | 조치 |
|------|------|------|
| `404 Not Found` | `.npmrc`에 `@vntgcorp` 레지스트리 매핑 없음 | 위 1) 추가 |
| `401 Unauthorized` | 토큰 없음/만료/스코프 부족 | 위 2) — `NODE_AUTH_TOKEN` export + `read:packages` 확인 |
| `Failed to replace env in config: ${NODE_AUTH_TOKEN}` | `.npmrc`는 있으나 env 미설정 | 위 2) export |
