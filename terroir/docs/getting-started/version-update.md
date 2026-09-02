# terroir 버전 업데이트

이 repo의 표준 파일(CI wrapper 등 managed 파일)은 사내 `terroir-greenfield` 버전과 연동됩니다.
PR을 열면 `terroir-greenfield-version-check`가 이 repo의 **버전 스탬프**(`.terroir-greenfield/version`)를
사내 최신과 비교해 뒤처짐 여부를 알려줍니다. 이 문서는 **체크 신호를 읽는 법과 뒤처졌을 때의 대응**을 다룹니다.

## 버전 체크 신호

PR 체크는 스탬프와 사내 최신의 차이를 semver 기준으로 판단해 세 가지 신호를 냅니다.

| PR 체크 | 의미 | 해야 할 일 |
|---------|------|-----------|
| 🟢 통과 | 최신 | 없음 |
| 🟢 + ⚠️ 코멘트 | **patch** 뒤처짐 (버그·문서·안정성) | CI는 통과. 여유 있을 때 업데이트 |
| 🔴 실패 + 🛑 코멘트 | **minor/major** 뒤처짐 (새 기능·input·구조) | **업데이트 필요** (아래 절차) |

> 🔴가 머지를 **강제로 막지는 않습니다.** (실제 차단 여부는 이 repo의 branch protection이 해당 체크를
> required status check로 등록했는지에 달려 있습니다.) 다만 갱신하지 않으면 배포 값 누락이나 빌드 실패로 이어질 수 있습니다.

## 심각도 기준 (semver)

버전은 `MAJOR.MINOR.PATCH` 형식이며, 어느 자리가 올랐는지로 신호가 갈립니다.

| 종류 | 변경 성격 | 체크 동작 |
|------|-----------|-----------|
| **PATCH** | 버그 수정 · 문서 · 동작 변화 없는 개선 | ⚠️ 경고 (CI 통과) |
| **MINOR** | 새 기능·파일·input 추가 (기존 호환) | 🔴 실패 + 업데이트 필요 |
| **MAJOR** | 수동 마이그레이션이 필요한 변경 | 🔴 실패 + 업데이트 필요 (+ 수동 액션) |

**왜 minor도 빨간불인가.** reusable workflow에 새 input(예: probe 경로)이 추가되는 시점이 보통 MINOR입니다.
wrapper를 갱신하지 않으면 그 input이 forward되지 않아 배포 값이 **조용히 누락(silent drop)**됩니다.
빌드가 실패하기 *전에* 갱신을 유도하기 위해 minor를 실패로 처리합니다.

## 빨간불 대응 (실 예시)

managed 파일과 스탬프를 손으로 고치지 말고, extension을 최신화한 뒤 재실행하면 자동으로 갱신됩니다.

```bash
# 1) main/develop 이 아닌 chore 브랜치에서 시작
#    (bootstrap 은 main/develop 직접 실행을 거부합니다 — 브랜치 보호와 정합)
git switch develop && git pull
git switch -c chore/greenfield-upgrade

# 2) extension 최신화 + 이 repo 에서 재실행
gh extension upgrade terroir-greenfield
gh terroir-greenfield
```

`gh terroir-greenfield`(업그레이드 모드)가 자동으로 처리하는 것:

- **managed 파일(CI wrapper 등)을 사내 최신으로 갱신** — 새 input forward가 여기서 반영됨 (= silent drop 원인 제거)
- **버전 스탬프**(`.terroir-greenfield/version`)를 최신으로 갱신
- 변경을 `commit` + `push`한 뒤, PR 생성 명령을 안내

```bash
gh pr create --base develop --head chore/greenfield-upgrade \
  --title "chore(greenfield): upgrade to <버전>"
```

이 PR이 머지되면 스탬프가 최신이 되어 **🔴 체크와 🛑 코멘트가 자동으로 사라집니다.**
이어서 `develop` → `main` PR을 한 번 더 올리면 `main`까지 동기화됩니다.

**MAJOR일 때는 자동 갱신만으로 부족할 수 있습니다.** 대부분의 minor/patch는 위 절차로 전자동 해소되지만,
MAJOR는 코멘트 또는 사내 `MIGRATIONS` 안내에 명시된 수동 액션(파일 정리·설정 이전 등)을 **함께** 적용해야 합니다.

## Do / Don't

```bash
# ✅ Do: chore 브랜치에서 업그레이드 실행 후 PR
git switch -c chore/greenfield-upgrade && gh terroir-greenfield

# ✅ Do: 뒤처짐 해소는 gh terroir-greenfield 재실행에 맡김 (managed 파일 + 스탬프 자동 갱신)
gh extension upgrade terroir-greenfield && gh terroir-greenfield

# ❌ Don't: main/develop 에서 직접 실행 (bootstrap 이 거부함 — 정상 동작)
git switch develop && gh terroir-greenfield

# ❌ Don't: 빨간불을 무시하고 넘어감 (새 input silent drop → 배포 값 누락/빌드 실패)

# ❌ Don't: managed 파일이나 스탬프를 손으로 편집
vi .terroir-greenfield/version              # 다음 업그레이드가 덮어씀 + 검증 신뢰성 훼손
```

## 자주 묻는 것

- **`main`/`develop`에서 `gh terroir-greenfield`가 거부돼요.** 정상입니다 — 표준은 chore/feature 브랜치에서
  실행 후 PR로 머지하는 흐름입니다. 브랜치 보호 정책과 정합을 맞추기 위한 의도된 거부입니다.
- **빨간불이 머지를 막나요?** 기본은 아닙니다(경고 신호). 단 이 repo가 해당 체크를 required status check로
  등록했다면 막힙니다.
- **스탬프는 어디 있나요?** `.terroir-greenfield/version` (한 줄, 현재 적용된 버전).
  `gh terroir-greenfield` 재실행 시 자동 갱신됩니다.

## 근거

- **스탬프 비교 방식**: managed 파일 자체를 diff하지 않고 한 줄 버전 스탬프만 비교하는 이유는, 사용자가 만질 수 없는
  파일의 정합성 검증을 가볍고 결정적으로 유지하기 위함입니다. 스탬프가 곧 "이 repo가 어느 표준 버전 위에 서 있는가"입니다.
- **minor를 실패로 처리하는 이유**: reusable workflow의 새 input은 wrapper가 forward하지 않으면 silent drop됩니다.
  실패는 경고보다 강한 신호로, 배포 사고가 나기 전에 갱신을 강제 유도합니다.
- **main/develop 직접 실행 거부**: 표준 파일 변경도 반드시 PR 리뷰를 거치게 하여, 보호 브랜치에 검증되지 않은
  자동 변경이 바로 들어가는 것을 막습니다. (브랜치 전략과 정합)
- **MAJOR 수동 병행**: 자동 갱신은 파일 forward는 처리하지만 데이터·설정 마이그레이션은 판단이 필요하므로,
  MAJOR에 한해 사내 `MIGRATIONS` 안내를 병행하도록 설계되었습니다.
