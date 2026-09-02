# 공통서비스 · File (파일 업로드/다운로드)

file-service를 호출하는 BFF SDK(`@vntgcorp/file-sdk-*`).

## 목차

- [설치](#설치)
- [설치 후](#설치-후)

## 설치

| 대상 | 명령 |
|------|------|
| NestJS 백엔드 | `pnpm --filter <be-app> add @vntgcorp/file-sdk-nestjs` |
| React 프론트엔드 | `pnpm --filter <fe-app> add @vntgcorp/file-sdk-react @vntgcorp/file-sdk-client-core` |

- ⚠️ **FE는 `file-sdk-client-core`도 함께 설치**한다 (앱이 직접 import하는 패키지 — 이유·사용법은 설치 후 README 참고).
- **버전**: 프로젝트에 없으면 최신, **이미 있으면 기존 버전 유지**(임의 업그레이드 금지 — 미지의 호환성 에러 방지).
- **진입 패키지만** 설치한다 — `file-sdk-server-core`·`file-sdk-types`·`file-sdk-token`은 transitive로 자동 설치되므로 직접 설치하지 않는다.
- 설치가 401/404로 실패하면 레지스트리 인증(`.npmrc` + `NODE_AUTH_TOKEN`)을 확인한다 → [README.md](./README.md#레지스트리-인증-최초-1회-셋업)

## 설치 후

설치된 패키지의 **README를 읽고** 통합한다. 정확한 타입·시그니처는 같은 패키지의 `dist/index.d.ts`에서 확인하고, **추측하지 않는다.**

- BE: `node_modules/@vntgcorp/file-sdk-nestjs/README.md`
- FE: `node_modules/@vntgcorp/file-sdk-react/README.md`
