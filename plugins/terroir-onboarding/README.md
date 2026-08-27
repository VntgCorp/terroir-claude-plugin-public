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

또는 `/onboarding`.

## 제공 skill

| skill | 설명 |
| --- | --- |
| `onboarding` | 온보딩 진입점. 직무 확인 → 환경 셋팅 → 직무별 경로 안내 → 시작 안내·커넥터 상태 출력 |
| `env-setup` | 공통 업무 환경 셋팅 — 지라·컨플루언스 / 메일·캘린더·드라이브 연결 점검·안내 |
| `github-connect` | GitHub 계정 연결 → Git 연결 → 사내 플러그인 접근 확인·설치 (승인 후 이어받기 포함) |
| `org-access-request` | 조직 계정이 없는 경우 가입 안내와 접근 요청 폼 안내(사용자가 직접 제출), 대기 안내 |

## 온보딩 플로우

스킬 간 분기 수준의 전체 흐름이다. 각 스킬의 내부 절차는 해당 SKILL.md가 유일한 진실이다. 온보딩을 완주한 경로의 종착점은 `onboarding`의 공통 종료 출력이다. 조직 접근 승인이 필요한 경로는 종료 출력 없이 대기 상태로 멈췄다가, 승인 후 재개 문구를 받아 `github-connect`로 이어진다.

종료 출력은 두 블록의 조합이다 — 시작 안내(세션에 로드된 스타트 포인트 `terroir-*-guide:*` 스킬 나열, 없으면 설치 여부와 직무에 따라 자리를 비우거나 안내 한 줄로 대체) + 커넥터 상태별 "할 수 있는 일"(연결/미연결 런타임 확인). 스타트 포인트는 private 플러그인이 제공하므로, 추가돼도 이 플러그인의 문서는 바뀌지 않는다. 시작 단계(프로젝트 시작·개발 진행 안내)는 온보딩 범위 밖이다.

```mermaid
flowchart TD
    START(["온보딩 시작<br/>&quot;온보딩 시작해줘&quot; · /onboarding"])

    Q1{"직무 확인"}
    Q2{"업무 도구 연결을<br/>지금 진행할까요?<br/>(화법은 직무에 맞춤)"}
    ENV["env-setup<br/>지라·컨플루언스 / 메일·캘린더·드라이브"]
    BR{"§1의 답으로 분기<br/>(다시 묻지 않음)"}
    Q3{"GitHub 계정 보유?"}

    GH["github-connect<br/>계정·Git 연결 → 접근 확인<br/>→ private 플러그인 설치<br/>→ 개발 런타임 셋팅 위임(private 스킬)"]
    OA["org-access-request<br/>가입 안내 → 접근 요청 폼 제출"]
    WAIT(["플랫폼개발팀 승인 대기"])

    END(["공통 종료 출력<br/>시작 안내(로드된 스타트 포인트 나열)<br/>+ 커넥터 상태별 &quot;할 수 있는 일&quot;<br/>+ &quot;필요한 것이 있으면 입력하세요&quot;"])
    SP["시작 단계 — 스타트 포인트<br/>terroir-*-guide:* 스킬 (private 플러그인 제공)<br/>프로젝트 시작·개발 진행 안내"]

    START --> Q1
    Q1 --> Q2
    Q2 -->|연결하기| ENV
    Q2 -->|건너뛰기| BR
    ENV --> BR

    BR -->|프로덕트 관련 직군| Q3
    BR -->|비 프로덕트 직군| END

    Q3 -->|있음| GH
    Q3 -->|없음| OA
    GH -->|조직·레포 접근 불가| OA
    OA --> WAIT
    WAIT -.->|재개 문구 입력| GH

    GH --> END
    END -.->|시작 안내의 지시 실행<br/>（온보딩 범위 밖）| SP

    classDef skill fill:#dbeafe,stroke:#2563eb,color:#0b1b3a
    classDef gate fill:#fef3c7,stroke:#d97706,color:#3a2a05
    classDef term fill:#dcfce7,stroke:#16a34a,color:#0a2612
    classDef branch fill:#fef3c7,stroke:#d97706,color:#3a2a05,stroke-dasharray:5 4
    classDef ext fill:#f3f4f6,stroke:#6b7280,color:#1f2937,stroke-dasharray:5 4
    class ENV,GH,OA skill
    class Q1,Q2,Q3 gate
    class BR branch
    class START,END,WAIT term
    class SP ext
```
