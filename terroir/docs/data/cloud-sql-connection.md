# Cloud SQL 접속

배포 환경의 DB는 **공용 Cloud SQL 인스턴스 하나를 여러 프로젝트가 나눠 쓰는** 형태입니다. 그 안에서
프로젝트마다 하나씩 발급받는 데이터베이스를 **논리 DB**라고 부릅니다. 로컬 개발은 docker compose의
postgres를 그대로 씁니다 — 이 문서는 그 둘을 **한 코드로** 처리하는 규칙입니다.

> **어디부터 읽을지** — 앱이 `@terroir/server/prisma`의 `PrismaModule`을 import하고 있다면
> **고칠 코드가 없습니다.** §앱에서 할 일만 보세요. 단 사내 표준 셋업을 재실행해 갱신한 직후라면
> §기존 앱 옮기기의 0번을 먼저 보세요 — 커넥션 코드만 갱신되고 의존성은 따라오지 않습니다. `PrismaClient`를 직접 만드는 레포라면
> §커넥션을 직접 만드는 레포를, 이미 `DATABASE_URL`로 붙던 앱을 옮기는 중이라면 §기존 앱 옮기기를
> 함께 보세요.

> ⚠️ **이 문서의 코드 예시는 Prisma 기준입니다. Prisma 를 새로 도입하라는 뜻이 아닙니다.**
> 접속 규칙 자체는 클라이언트와 무관하고, 아래 §접속 계약이 그 규칙을 클라이언트·**언어** 중립으로 적어
> 둔 부분입니다. `pg` 직접 사용·TypeORM·Drizzle 은 물론 **Node 가 아닌 언어**(Python·Go·Java)도
> **계약만 지켜 각자 방식으로 배선하면 됩니다** — Cloud SQL Connector 는 언어별 라이브러리가 따로
> 있습니다. Prisma 예시는 참조 구현으로 보세요. 관계형 DB 를 아예 안 쓰는 앱은 이 문서가 필요 없습니다.
>
> **Node 가 아니라면 §접속 계약과 문서 끝의 §언어별 Connector 라이브러리, 이 둘만 읽으면 됩니다.**
> 그 사이의 §앱에서 할 일 · §기존 앱 옮기기는 전부 Node/Prisma 전용입니다.

## 목차

- [규칙 요약](#규칙-요약)
- [환경변수](#환경변수)
- [접속 계약](#접속-계약)
- [앱에서 할 일](#앱에서-할-일)
- [기존 앱 옮기기](#기존-앱-옮기기)
- [검증](#검증)
- [Do / Don't](#do--dont)
- [자주 막히는 곳](#자주-막히는-곳)
- [근거](#근거)
- [언어별 Connector 라이브러리](#언어별-connector-라이브러리)

## 규칙 요약

1. 배포 환경 접속은 **Cloud SQL Connector 라이브러리 직결 + IAM DB 인증**이다. **비밀번호를 쓰지 않는다.**
2. 로컬/배포 분기는 **`CLOUD_SQL_INSTANCE` 환경변수의 유무**로 판단한다. 있으면 Connector 경로,
   없으면 `DATABASE_URL` 경로(로컬 compose postgres)다. `NODE_ENV`로 분기하지 않는다.
3. 접속 정보는 앱이 만들지 않는다. **플랫폼이 환경변수로 주입**하는 `CLOUD_SQL_*` 세 개를 읽기만 한다.
4. 로컬용 `DATABASE_URL`·`DATABASE_DB`는 **Cloud SQL 값으로 바꾸지 않는다.** 로컬 개발용 값이다
   (`DATABASE_DB`는 compose가, `DATABASE_URL`은 앱이 읽는다).
   배포 환경에서는 이 키들을 쓰지 않는다(옮기는 중이라면 §기존 앱 옮기기).
5. 논리 DB는 **프로젝트 단위로 발급**받는다. 같은 프로젝트의 앱들은 같은 신원(GCP 서비스 계정)으로 붙으므로,
   앱마다 계정을 따로 만들지 않는다.
6. 접속이 되었다는 판단은 **실제 쿼리**가 통과할 때만 한다(아래 §검증). 기동 로그·`$connect()` 성공은
   증거가 아니다.

## 환경변수

플랫폼이 주입합니다. 앱은 읽기만 하세요.

| 키 | 예시 | 설명 |
|----|------|------|
| `CLOUD_SQL_INSTANCE` | `vntg-nfw-services-dev:asia-northeast3:dev-service-pg` | 인스턴스 연결 이름. **이 값의 존재가 분기 스위치** |
| `CLOUD_SQL_IAM_USER` | `my-project@vntg-nfw-services-dev.iam` | IAM DB 사용자. GSA 이메일에서 `.gserviceaccount.com`을 뗀 형태 |
| `CLOUD_SQL_DATABASE` | `my-project-db` | 논리 DB 이름. 발급 때 정해지며 플랫폼이 주입합니다 |

**세 값 모두 플랫폼이 환경변수로 주입합니다 — 앱이 이름을 알아내거나 어딘가에 적어 둘 필요가
없습니다.** 이름 규칙은 `{프로젝트}-{발급 때 입력한 이름}` 이고(포털에서 `＋ DB 추가` 할 때
"DB 이름" 에 `db` 를 넣었다면 `my-project-db`), **논리 DB는 프로젝트당 하나**입니다.

값을 눈으로 확인하고 싶다면 **Terroir 포털의 프로젝트 화면**에서 발급된 DB로 볼 수 있습니다.
다만 **앱 코드나 매니페스트에 그 이름을 적어 넣지는 마세요** — 주입된 환경변수만 읽습니다.
이름을 직접 넣으면 오타가 접속 단계가 아니라 첫 쿼리에서 `database ... does not exist` 로 터져,
발급 자체가 안 된 것처럼 읽힙니다.

로컬에는 이 셋이 없습니다. 그래서 Connector 경로를 타지 않습니다 — `.env`의 `DATABASE_URL`이 있으면
로컬 compose postgres로 붙고, 그것도 없으면 연결을 건너뛴 채 부팅합니다. 사내 표준 스켈레톤으로 새로
만든 프로젝트는 **`.env.example`의 `DATABASE_URL`이 주석 상태가 기본**이므로, 로컬에서 DB를 쓰려면
주석을 해제하세요.

## 접속 계약

**클라이언트와 무관한 규칙입니다.** 아래 여섯 가지를 지키면 어떤 DB 클라이언트로 배선하든 됩니다 —
**언어가 달라도 마찬가지입니다.** 이후 절의 Prisma 코드는 이 계약의 **참조 구현**일 뿐입니다.

1. **분기 기준은 `CLOUD_SQL_INSTANCE` 의 존재 여부.** 환경 이름(`NODE_ENV` 등)으로 분기하지 않는다.
2. **소켓·TLS 는 Connector 라이브러리를 거치고, IAM 인증과 private IP 를 명시한다.** 인스턴스는 private
   IP 전용이라 IP 종류를 빠뜨리면 공인 IP 로 붙으려다 실패한다. **넘기는 방식은 라이브러리마다 다르다** —
   커넥션 옵션을 돌려받아 클라이언트 설정에 합치는 형태(Node: `getOptions({ instanceConnectionName,
   authType: IAM, ipType: PRIVATE })`)일 수도 있고, 커넥터가 커넥션을 직접 만들어 돌려주는 형태(Python:
   `connector.connect(instance, driver, enable_iam_auth=True, ip_type=PRIVATE)`)일 수도 있고, 드라이버
   확장점에 커넥터를 등록하고 설정을 문자열로만 넘기는 형태(JDBC: `socketFactory` · `cloudSqlInstance`
   · `enableIamAuth=true` · `ipTypes=PRIVATE`)일 수도 있다.
   **어느 쪽이든 IAM 인증과 private IP 지정을 빠뜨리지 않는 것이 계약이다.** 옵션 이름은 라이브러리를
   따른다 — Node·Python 은 `ipType`(단수)이지만 JDBC 는 `ipTypes`(복수, 콤마 구분 선호도 목록)다.
   **드라이버가 자체 TLS 를 거는 클라이언트라면 그쪽 TLS 는 꺼야 한다**(JDBC 는 `sslmode=disable`).
   암호화를 포기하는 게 아니라 **암호화 책임을 Connector 로 넘기는** 설정이다 — 켜 둔 채로 두면 이중
   협상으로 접속이 깨진다.
3. **`user`(=`CLOUD_SQL_IAM_USER`)와 `database`(=`CLOUD_SQL_DATABASE`)는 주입값 그대로 쓰고, `password`
   는 넣지 않는다** — IAM 인증에서는 생략이 정답이고, 빈 문자열도 넣지 않는다. 인자 이름은 라이브러리를
   따른다(Python 은 `db=`).
   단 드라이버에 따라 **비어 있지 않은 `password` 를 형식 검증 용도로 요구**하기도 한다(pgjdbc). 그
   경우에만 자격증명이 아님이 드러나는 더미 값을 쓰되, **접속 문자열이 아니라 클라이언트 설정으로**
   전달한다 — IAM 인증에서 이 값은 서버에 전달돼도 무시된다.
4. **주입 상태를 세 가지로 구분한다.** 셋 다 없음 → 아직 발급 전이므로 **연결을 건너뛰고 부팅**시킨다(죽이지
   않는다). `CLOUD_SQL_INSTANCE` 만 있고 나머지가 없거나 그 반대 → **설정 오류이므로 기동 시점에 죽인다**
   (빠진 키 이름을 메시지에 넣는다). 셋 다 있음 → Connector 경로.
   **"죽인다" 는 프로세스 종료(0 이 아닌 exit code)를 뜻하며 요청 시점 예외가 아니다.** 워커를 fork 하는
   서버(gunicorn·`uvicorn --workers`·PM2 cluster)라면 이 판정이 **fork 이전 마스터 프로세스에서** 일어나야
   한다. 아니면 워커만 죽고 슈퍼바이저가 무한 재시작해, CrashLoop 대신 **"뜬 것처럼"** 보인다.
   반대로 **셋 다 있는데 접속에 실패하는 것은 설정 오류가 아니다** — 죽이지 말고 부팅시킨 뒤 §검증
   경로에서만 실패로 보고한다. "첫 커넥션 실패 시 생성자에서 예외" 를 기본값으로 갖는 풀(HikariCP 등)은
   그 기본값을 꺼야 한다. 안 그러면 설정 오류와 일시적 장애가 같은 증상(CrashLoop)으로 보인다.
5. **커넥션은 풀로 재사용한다.** Connector 경유 연결은 매번 TLS 핸드셰이크와 IAM 토큰 교환을 수반하므로
   요청마다 새로 만들면 레이턴시와 인스턴스 커넥션 수 양쪽에서 문제가 된다. **IAM 액세스 토큰은 약 1시간
   후 만료**되므로 풀 커넥션의 최대 수명을 그보다 짧게(예: 30분) 잡아 재활용시킨다 — 이 값은 성능 튜닝
   손잡이가 아니라 **건드리면 안 되는 상한**이다. 늘리면 1시간 뒤부터 조용히 깨진다. 공용 인스턴스라
   커넥션 수는 전 테넌트가 나눠 쓰므로 앱당 작게(5 내외) 잡고, 유휴 상태에서도 최소치를 붙들고 있는
   기본값(HikariCP `minimumIdle`)이 있는지 확인한다. Prisma·TypeORM 처럼 풀이 내장인 클라이언트는 이
   결정이 보이지 않지만, 드라이버를 직접 쓰면 직접 정해야 한다.
6. **Connector 수명은 만든 주체가 소유한다.** 종료 시 클라이언트를 먼저 끊고 그다음 `connector.close()`.

> **Node 한정 —** `@google-cloud/cloud-sql-connector` 에서는 **`getOptions()` 가 실패한 경우 닫지
> 않는다.** 그 상황에서 닫으면 라이브러리 내부의 처리되지 않은 rejection 이 원래 에러를 덮고 프로세스를
> 죽인다(정리할 자원도 없다). 다른 언어 바인딩에는 해당하지 않는다.

> **런타임 TLS 요건 —** IAM 인증은 **TLS 1.3** 을 요구하므로 런타임의 TLS 구현이 그걸 지원해야 한다.
> LibreSSL 기반이나 구버전 OpenSSL 을 쓰는 런타임(macOS 시스템 Python 등)에서는 접속 단계부터
> 실패한다. 즉 **컨테이너 베이스 이미지 선택이 기능 요건**이다 — 로컬에서는 되는데 이미지에서 안
> 되거나 그 반대면 여기부터 본다. (JVM 은 OpenSSL 이 아니라 JSSE 를 쓰므로 이 제약을 받지 않는다.
> JDK 11+ 면 된다.)

배선 후 자가 점검: 접속 문자열 어디에도 비밀번호가 없는가 · 접속 정보가 하나도 없는 상태로 기동해도
서버가 뜨는가 · 일부만 주입한 상태로 기동하면 빠진 키 이름과 함께 **프로세스가** 즉시 죽는가 · 요청마다
커넥션을 새로 만들지는 않는가 · 종료 시 프로세스가 남지 않는가. 다섯 가지가 모두 예여야 계약을 지킨
것이고, 그다음이 §검증입니다.

## 앱에서 할 일

### 표준 커넥션을 쓰는 경우 — 없습니다

커넥션은 `@terroir/server/prisma`(= `terroir/libs/server/prisma`)가 소유합니다. 앱은 `PrismaModule`만
import하면 되고, 위 환경변수가 주입되면 알아서 Connector 경로로 붙습니다.

```ts
// 루트 모듈(예: app.module.ts) — 이대로 두면 됩니다
import { PrismaModule } from '@terroir/server/prisma';
```

DB가 필요하면 **논리 DB를 발급**받으세요 — Terroir 포털의 프로젝트 화면에서 `＋ DB 추가`입니다.
발급은 검토 후 처리되며, 완료되면 플랫폼이 위 환경변수를 주입합니다.

**발급 전에도 앱은 정상 배포됩니다**(아래 3분기가 배선돼 있을 때. 표준 커넥션에는 이미 들어 있습니다).
접속 정보가 하나도 없으면 연결을 시도하지 않고 경고만 남긴 채 부팅합니다. 서버는 뜨고 `/api/health`도 응답하며, DB를 실제로 쓰는 요청만 실패합니다. 발급 후 환경변수가
주입되면 **재시작만으로** 연결됩니다.

> 기본 구성에는 **클러스터 안 DB(`type: "DB"` 워크로드)가 없습니다.** 배포 환경의 DB는 공용 Cloud SQL의
> 논리 DB를 씁니다. `terroir.json`에 DB 워크로드를 선언하면 클러스터에 PostgreSQL이 직접 뜨고 접속 URL에
> 비밀번호가 평문으로 들어가므로, 신규 프로젝트는 선언하지 않는 것을 권장합니다.

### 커넥션을 직접 만드는 레포 — 한 곳만 고칩니다

`@terroir/server/prisma`가 없고 `PrismaClient`를 직접 만드는 레포(기존 프로젝트를 가져온 경우)는
그 생성 지점에 아래를 적용합니다.

의존성:

```bash
pnpm add @google-cloud/cloud-sql-connector pg
pnpm add -D @types/pg          # pg 는 자체 타입을 배포하지 않는다. 없으면 typecheck 가 TS7016 으로 깨진다
#   ↑ 설치 후 **버전이 하나인지 확인**한다: pnpm ls @types/pg
#     @prisma/adapter-pg 가 자기 트리에 @types/pg 를 들고 있어, 루트에 최신(8.20+)이 깔리면
#     PoolConfig 가 서로 다른 타입이 되어 typecheck 가 TS2345 로 깨진다
#     (8.20 에서 Client.connect() 반환형이 Promise<void> → Promise<ClientBase> 로 바뀌었다).
#     두 버전이 보이면 adapter 쪽 버전으로 **캐럿 없이** 고정한다.
pnpm add @prisma/adapter-pg@$(node -p "require('@prisma/client/package.json').version")
#   ↑ @prisma/client 와 **정확히 같은 버전**. 메이저만 맞추면 안 된다 — adapter 는
#     @prisma/driver-adapter-utils 를 자기 버전으로 정확 고정하므로, 캐럿이나 @6 으로 두면
#     client 6.15 에 adapter 6.19 가 깔려 런타임에서 갈린다. typecheck 는 그대로 통과한다.
```

> **컨테이너 이미지를 직접 만드는 레포라면** — 여기서 추가한 Prisma 의존성은 이미지 빌드에도 영향을
> 줍니다. `prisma generate` 를 빌드 스테이지에서 실행해야 하고, 그 스테이지의 openssl 버전이 쿼리
> 엔진 바이너리 타깃을 결정하므로 `-slim`·alpine 베이스에서는 엔진이 어긋나 런타임에만 터집니다.
> 이미지 쪽 규칙은 이 문서의 범위가 아니며, 사내 `dockerize` 스킬과 그 레퍼런스가 담당합니다.

커넥션:

```ts
import { AuthTypes, Connector, IpAddressTypes } from '@google-cloud/cloud-sql-connector';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import type { PoolConfig } from 'pg';

type Resolved =
  | { source: 'cloud-sql'; config: PoolConfig; connector: Connector }
  | { source: 'database-url'; config: PoolConfig }
  | { source: 'none' };

async function resolveAdapterConfig(): Promise<Resolved> {
  // 공백만 든 값은 없는 것으로 친다 — YAML 인용부호 사고나 복붙 잔여 공백이 truthy 로
  // 새어 들어가면 EBADCONNECTIONNAME 으로 엉뚱한 곳에서 터진다.
  const instance = process.env.CLOUD_SQL_INSTANCE?.trim();
  const user = process.env.CLOUD_SQL_IAM_USER?.trim();
  const database = process.env.CLOUD_SQL_DATABASE?.trim();

  // ── 배포 경로 — CLOUD_SQL_* 세 개가 함께 주입됐을 때 ──
  if (instance) {
    // "없음" 과 "잘못됨" 은 다르다. 일부만 주입된 건 설정 오류이므로 기동 시점에 죽인다.
    // 어느 키가 빠졌는지 함께 알린다 — 메시지만 보고 진단할 수 있어야 한다.
    if (!user || !database) {
      const missing = [
        !user && 'CLOUD_SQL_IAM_USER',
        !database && 'CLOUD_SQL_DATABASE',
      ].filter(Boolean);
      throw new Error(`CLOUD_SQL_INSTANCE 는 주입됐으나 ${missing.join(', ')} 가 없습니다.`);
    }

    // connector 를 전역에 두지 않고 만든 자리에서 반환한다 — 수명은 호출자가 소유한다
    const connector = new Connector();
    // ★ getOptions() 가 실패해도 connector.close() 를 부르지 않는다. 부르면 더 나빠진다 — 아래 설명 참조.
    const opts = await connector.getOptions({
      instanceConnectionName: instance,
      authType: AuthTypes.IAM,       // 비밀번호 없음
      ipType: IpAddressTypes.PRIVATE, // 인스턴스는 private IP 전용
    });
    // password 를 넣지 않는다 — IAM 인증에서는 생략한다
    return { source: 'cloud-sql', config: { ...opts, user, database }, connector };
  }

  // 위 가드의 **반대 방향** — INSTANCE 만 없고 나머지가 있는 것도 설정 오류다.
  // 여기서 막지 않으면 낡은 DATABASE_URL 이 남아 있을 때 아래 로컬 경로로 흘러가
  // **비밀번호 인증으로 조용히** 붙는다. 쓰기가 섞이면 조용한 데이터 사고가 된다.
  if (user || database) {
    const present = [user && 'CLOUD_SQL_IAM_USER', database && 'CLOUD_SQL_DATABASE'].filter(Boolean);
    throw new Error(`${present.join(', ')} 는 주입됐으나 CLOUD_SQL_INSTANCE 가 없습니다.`);
  }

  // ── 로컬 경로 — docker compose postgres ──
  const url = process.env.DATABASE_URL?.trim();
  // PrismaPg 는 문자열 URL 을 받지 않으므로 connectionString 으로 감싼다
  if (url) return { source: 'database-url', config: { connectionString: url } };

  // ── 아직 발급 전 — 오류가 아니다 ──
  // 여기서 throw 하면 발급을 기다리는 동안 배포 자체가 막힌다.
  return { source: 'none' };
}

export async function createPrismaClient() {
  const r = await resolveAdapterConfig();

  if (r.source === 'none') {
    // 부팅은 시키고 연결만 건너뛴다. 생성자는 던지지 않지만 $connect() 는 던지므로,
    // 호출자가 configured 를 보고 연결을 건너뛰어야 한다 (아래 §부팅 설명 참조).
    console.warn('DB 접속 정보가 없어 연결을 건너뜁니다.');
    return { client: new PrismaClient(), configured: false, close: async () => {} };
  }

  const client = new PrismaClient({ adapter: new PrismaPg(r.config) });
  return {
    client,
    configured: true,
    // 종료 시 client 를 먼저 끊고 connector 를 닫는다 (NestJS 라면 onModuleDestroy).
    // $disconnect() 를 빠뜨리면 pg.Pool 소켓이 남아 프로세스가 종료되지 않는다.
    close: async () => {
      await client.$disconnect();
      if (r.source === 'cloud-sql') r.connector.close();
    },
  };
}
```

기동 시에는 `configured` 를 보고 연결을 건너뜁니다. **`new PrismaClient()` 자체는 던지지 않지만
`$connect()` 는 던집니다** — 이 가드를 빼면 접속 정보가 없을 때 부팅에서 죽습니다.

```ts
// NestJS 라면 onModuleInit — 기존 레포에 이미 await this.$connect() 가 있다면 반드시 감쌀 것
if (configured) await client.$connect();
```

이 세 분기는 표준 커넥션(`@terroir/server/prisma`)과 **같은 규칙**입니다. 접속 정보가 없을 때 죽지
않게 하는 부분을 빼면, DB 발급을 기다리는 동안 배포가 막힙니다.

`PrismaPg`는 `pg.PoolConfig`를 그대로 받으므로 `pg.Pool`을 직접 만들 필요가 없습니다.

`connector`를 모듈 전역 변수로 두지 마세요. Connector는 자기 인스턴스 캐시와 소켓을 들고 있고
`close()`가 그것들을 전부 정리하므로, 전역으로 공유하면 **한쪽 종료가 아직 살아있는 다른 쪽의 연결을
깨뜨립니다**(한 프로세스에서 모듈을 여러 번 띄우는 통합테스트가 대표적). 클라이언트를 만든 주체가
connector를 함께 들고 있다가 자기 종료 시점에 닫는 형태로 두세요.

### ⚠️ `previewFeatures`는 빠뜨리면 조용히 통과합니다

`@prisma/client`가 6.16.0 미만이면 `schema.prisma`에 아래 한 줄이 **반드시** 있어야 합니다.

```prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}
```

**`prisma generate`는 이것이 빠져도 경고 없이 성공합니다.** 타입 검사도 통과합니다. 실패는 오직
`new PrismaClient({ adapter })`를 **실행하는 순간**에만 드러납니다.

```
PrismaClientConstructorValidationError: "adapter" property can only be provided to
PrismaClient constructor when "driverAdapters" preview feature is enabled.
```

즉 빌드가 전부 초록불이어도 배포 후 부팅에서 처음 터집니다. 배선한 뒤 **반드시 한 번 실행**해서
클라이언트가 만들어지는지 확인하세요.

## 기존 앱 옮기기

이미 `DATABASE_URL`로 붙던 앱을 논리 DB로 옮길 때만 해당합니다. **새로 만든 프로젝트는 이미 이
상태이므로 건너뛰세요.**

**0. 표준 커넥션을 쓰는 레포도 손댈 것이 있습니다.** 위 §앱에서 할 일의 "고칠 코드가 없습니다"는
*이미 배선이 끝난 상태*를 말합니다. 사내 표준 셋업을 재실행해 갱신하는 경우, 커넥션 코드
(`terroir/libs/…`)는 덮어써지지만 **그 코드가 요구하는 아래 세 가지는 덮어써지지 않습니다** — 모두
사용자 소유 파일이라 직접 맞춰야 합니다:

| 파일 | 무엇을 | 빠뜨리면 |
|---|---|---|
| `package.json` | 위 §의존성 블록의 패키지 | 빌드가 깨진다 |
| `schema.prisma` | `previewFeatures = ["driverAdapters"]` | 빌드는 초록불, **부팅에서** `PrismaClientConstructorValidationError` |
| `Dockerfile` | **`COPY terroir/libs ./terroir/libs`** | **로컬 빌드는 통과하고 이미지 빌드에서만** `Can't resolve '@terroir/…'` |

세 번째가 가장 늦게 발견됩니다. `@terroir/*` 는 `tsconfig.base.json` 의 paths 로 해석돼 번들에
포함되므로 **빌드 컨텍스트에 실제 파일이 있어야** 하는데, 로컬에는 소스 트리가 통째로 있으니
`pnpm build`·`typecheck` 가 모두 통과합니다. 컨텍스트가 좁은 이미지 빌드에서만 깨집니다.
새로 만든 프로젝트의 Dockerfile 에는 이 `COPY` 가 이미 들어 있습니다 — **기존 레포를 갱신하는
경우에만** 해당합니다.

(레포 관리자용 상세 절차는 사내 표준 셋업 레포의 `MIGRATIONS.md`에 있습니다.)

**1. 로컬 전용 DB 키를 배포 필수 목록에서 뺍니다.** — *앱 디렉토리의 `.env.example`에서 배포 필수 키를
뽑아 올리는 CI(사내 표준 BE 배달 워크플로)를 쓰는 레포에만 해당합니다. 배포 환경설정 화면에 `DATABASE_*`가
"입력 필요"로 떠 있으면 그 레포입니다.* 그 CI는 `.env.example`의 주석 아닌 키 이름을 뽑아 배포 환경의
**필수 입력 항목**으로 올립니다. 배정되지 않은 키가 하나라도 남으면 배포가 막히므로,
배포에서 쓰지 않는 `DATABASE_*`는 `.env.example`에서 **주석 처리**하고 실제 값은 `.env`(git 미추적)에만
둡니다. 빈 값은 미입력으로 걸러져 통과하지 못하는데, **값을 지어내 채우면 안 됩니다** — driver adapter
경로의 `$connect()`는 lazy라 파드는 정상 기동한 것처럼 보이고 DB를 쓰는 요청마다 실패합니다. 그 값이
닿는 주소라면 더 나쁩니다 — 비밀번호 인증으로 엉뚱한 DB에 붙습니다.

**2. 이미 주입된 값을 삭제합니다.** 필수 목록에서 빠진 키는 ConfigMap/Secret에서 지워지지 않고 **추가
항목으로 재분류될 뿐**입니다. ⚠️ **1번을 커밋한다고 곧바로 내려오지 않습니다** — 배포 파이프라인이
한 번 돌아야 필수 목록이 갱신됩니다. 그전에 포털을 열면 그 키는 여전히 **필수 항목**에 있고 삭제
버튼이 없습니다(정상입니다). 파이프라인이 돈 뒤 **추가 항목**에서 삭제하면 파드 주입이 멈춥니다.

**3. 논리 DB를 발급받습니다.** 포털의 `＋ DB 추가`입니다. 기존 데이터 이전은 별도 트랙입니다.
DDL(스키마) 반영 경로는 아직 정리 중입니다 — 사내 표준 마이그레이션 가이드의 "DBeaver + VPN으로 운영
DB 직접 실행"은 private IP + 비밀번호 없는 IAM 인증인 공용 인스턴스에는 그대로 적용되지 않습니다.
플랫폼개발팀에 문의하세요.

## 검증

배선했다고 끝이 아닙니다. **실제 쿼리가 통과해야** 접속이 된 것입니다.

### 1) 실제 쿼리 한 번

임시 엔드포인트에 아래 쿼리를 태우고 호출해 보세요. **이게 통과하면 끝입니다.**

```sql
SELECT NOW() AS now, current_database()::text AS database, current_user::text AS "user"
```

응답의 `user` 가 `<프로젝트>@<GCP 프로젝트>.iam` 형태면 **의도한 신원으로 붙은 것**이고, `database` 가
발급받은 논리 DB 이름이면 **의도한 DB 에 붙은 것**입니다. 접속 여부만이 아니라 *어디에 무엇으로*
붙었는지까지 한 번에 확인됩니다.

> `::text` 를 빼지 마세요. `current_user`·`current_database()` 는 PostgreSQL 의 `name` 타입이라
> ORM 에 따라 역직렬화에 실패합니다(Prisma `$queryRaw` 는 `Failed to deserialize column of type
> 'name'`). 쿼리는 DB 를 왕복해 **성공한 뒤** 매핑에서 터지므로 접속 실패로 오인하기 쉽습니다.

헬스 체크(`/api/health`)에는 넣지 마세요 — liveness 가 DB 에 의존하면 DB 가 흔들릴 때 파드가
재시작 루프에 빠집니다.

반드시 **실제 쿼리**여야 합니다. driver adapter 경로에서 `$connect()`는 lazy라 아무도 듣지 않는
주소로도 성공하므로, **기동 로그나 `$connect()` 성공은 접속의 증거가 아닙니다.**

로그는 IDP 배포 관리 화면의 **Grafana 링크**에서 봅니다.
클러스터에 직접 붙을 필요는 없습니다.

### 2) 안 되면 — 로그로 어디 문제인지 가릅니다

| 로그·증상 | 어디 문제인가 |
|---|---|
| `DB 접속 정보가 없어 연결을 건너뜁니다` | 아직 발급 전. 논리 DB를 발급받으세요 |
| `CLOUD_SQL_INSTANCE 는 주입됐으나 … 가 없습니다` | 주입 설정 오류 → **문의** |
| 인증은 되는 것 같은데 DB 접속만 거부된다 | 위 쿼리의 `user` 를 보세요. 의도한 GSA 가 아니면 신원 배선 문제 → **문의**. 맞다면 권한(GRANT) 문제 → **문의** |
| 그 밖의 접속 오류 | §자주 막히는 곳을 먼저 보세요 |

**"인프라 쪽 작업은 끝났다" 는 말은 검증이 아닙니다** — 권한 설정은 실제로 동작하지 않는 상태도
조용히 받아들여지고, 앱이 붙는 순간에만 거부됩니다. 반드시 쿼리를 한 번 태워 보세요.

문의할 때는 **프로젝트 이름과 위 로그**를 함께 주세요. 신원(어느 GSA로 붙고 있는지) 확인은 클러스터
접근이 필요해 플랫폼개발팀이 합니다 — 접근 권한을 따로 받으실 필요는 없습니다.

## Do / Don't

| ❌ Don't | ✅ Do |
|---------|------|
| `DATABASE_URL`에 Cloud SQL 비밀번호를 넣는다 | 비밀번호 없이 IAM 인증을 쓴다 |
| 로컬 `DATABASE_DB`를 Cloud SQL 논리 DB 이름으로 바꾼다 | `CLOUD_SQL_DATABASE`를 따로 쓴다. `DATABASE_DB`는 로컬 compose 소유 |
| 종료 시 connector만 닫는다 | `$disconnect()` 먼저, 그다음 `connector.close()` — 빠뜨리면 프로세스가 안 죽는다 |
| `NODE_ENV === 'production'` 으로 분기한다 | `CLOUD_SQL_INSTANCE` 유무로 분기한다 |
| 앱에서 인스턴스 이름·계정을 하드코딩한다 | 주입된 환경변수만 읽는다 |
| 앱마다 DB 계정을 따로 요청한다 | 프로젝트 단위 신원을 공유한다 |
| 앱 전용 DB를 K8s에 직접 띄운다(StatefulSet 등) | 공용 Cloud SQL의 논리 DB를 발급받는다 |
| "인프라 작업 끝났다" 를 접속 성공으로 본다 | 실제 쿼리가 도는지로 확인한다 |
| 검증하려고 클러스터 접근 권한을 요청한다 | 쿼리·로그로 판단하고, 신원 문제로 좁혀지면 플랫폼팀에 문의한다 |

## 자주 막히는 곳

| 증상 | 원인 | 조치 |
|------|------|------|
| 기동 로그에 `DB 접속 정보가 없어 연결을 건너뜁니다` | 접속 정보가 하나도 없음 = 아직 발급 안 됨 | 배포 환경이면 논리 DB 발급. 로컬이면 `.env`에서 `DATABASE_URL` 주석을 해제한다 — 새 프로젝트는 주석 상태가 기본이다 |
| 쿼리 시 `Environment variable not found: DATABASE_URL` | 위와 **같은 원인**. 접속 정보 없이 뜬 상태에서 DB를 쓰는 요청이 들어옴 | `DATABASE_URL`을 넣으라는 뜻이 아니다 — 배포 환경이면 `CLOUD_SQL_*` 주입(= 논리 DB 발급) 여부를 본다. 기동 로그의 경고를 함께 확인 |
| 배포 환경설정 화면이 `DATABASE_URL`·`DATABASE_PASSWORD` 등을 **입력 필요**로 요구한다 | 앱 `.env.example`에 그 키들이 주석 없이 남아 있음 — CI가 배포 필수 키로 올린다 | `.env.example`에서 주석 처리하고 값은 `.env`에만 둔다. **값을 지어내 채우면 안 된다** — driver adapter 경로의 `$connect()`는 lazy라 파드는 정상 기동한 것처럼 보이고, DB를 쓰는 요청이 들어올 때마다 실패한다. 그 값이 닿는 주소라면 더 나쁘다(비밀번호 인증으로 엉뚱한 DB에 붙는다) |
| `.env.example`을 고쳤는데도 파드에 `DATABASE_URL`이 계속 주입된다 | 필수 목록에서 빠진 키는 ConfigMap/Secret에서 지워지지 않고 **추가 항목으로 재분류**될 뿐이다 | 배포 환경설정의 **추가 항목**에서 그 키를 직접 삭제한다 — 필수 항목과 달리 삭제할 수 있다 |
| 기동 시 `CLOUD_SQL_INSTANCE 는 주입됐으나 … 가 없습니다` | 세 키 중 일부만 주입됨 (설정 오류) | 플랫폼개발팀에 문의 — 세 값은 함께 주입되어야 한다 |
| 인증은 되는 것 같은데 DB 접속만 거부된다 | 앱이 **의도와 다른 신원(GSA)** 으로 붙고 있을 수 있다. 이 경우에도 토큰 발급 자체는 성공하므로, 증상만으로는 권한(GRANT) 문제와 구분되지 않는다 | §검증의 쿼리로 `current_user` 를 먼저 확인한다 — 의도한 GSA 가 아니면 신원 배선, 맞으면 권한 문제다. 어느 쪽이든 앱에서 고칠 수 없으므로 그 값을 들고 플랫폼개발팀에 문의 |
| 배포는 되는데 파드가 SIGTERM 후 강제 종료(SIGKILL)된다 | 종료 시 `$disconnect()`를 하지 않아 `pg.Pool` 소켓이 남음 | `close()`에서 `await client.$disconnect()`를 먼저 호출한다 |
| typecheck가 `TS7016: Could not find a declaration file for module 'pg'` | `pg`는 자체 타입을 배포하지 않는다 | `pnpm add -D @types/pg` |
| typecheck가 `TS2345: Argument of type 'PoolConfig' is not assignable…` — 같은 이름의 타입인데 안 맞는다 | `@types/pg` 가 **두 버전** 깔렸다. 루트에 최신(8.20+)이, `@prisma/adapter-pg` 트리에 그보다 낮은 버전이 있다. 8.20 에서 `Client.connect()` 반환형이 바뀌어 `PoolConfig` 가 서로 다른 타입이 됐다 | `pnpm ls @types/pg` 로 버전이 몇 개인지 본다. 둘이면 adapter 쪽 버전으로 **캐럿 없이** 고정한다 |
| 로컬 `pnpm build`·`typecheck` 는 통과하는데 **이미지 빌드만** `Can't resolve '@terroir/…'` | Dockerfile 이 `terroir/libs` 를 빌드 컨텍스트에 복사하지 않는다. 로컬에는 소스 트리가 통째로 있어 안 걸린다 | Dockerfile 에 `COPY terroir/libs ./terroir/libs` 를 추가한다(§기존 앱 옮기기 0번). 새로 만든 프로젝트에는 이미 있다 |
| 인증까지 통과했는데 쿼리가 `database "…" does not exist` | 파드에 들어간 `CLOUD_SQL_DATABASE` 가 실제 논리 DB 이름과 다름. 주입값을 **손으로 덮어썼을** 가능성이 높다(배포 환경설정의 추가 항목에 같은 키를 넣으면 주입값을 가린다) | 손으로 넣은 `CLOUD_SQL_DATABASE` 를 지워 주입값이 그대로 쓰이게 한다. 지운 뒤에도 같으면 포털에서 발급된 DB 이름과 대조하고 문의한다 — 발급 자체가 안 된 것은 아니다 |
| 접속은 된 것 같은데 `$queryRaw` 가 `Failed to deserialize column of type 'name'` | **접속 문제가 아니다.** `current_user`·`current_database()` 는 PostgreSQL의 `name` 타입을 반환하는데 Prisma가 그 타입을 매핑하지 못한다 — 쿼리는 DB를 왕복해 **성공한 뒤 결과 매핑에서** 터진다 | `::text` 로 캐스팅한다 (`current_user::text`). 접속 확인용으로 이 두 함수를 찍어보는 건 흔한 패턴이라 자주 밟는다. 기동 로그가 `DB 접속 경로: cloud-sql` 이면 배선은 이미 정상이다 |
| 인증은 되는데 DB 접속 거부 | 논리 DB에 GRANT 미완료 | 발급이 끝났는지 확인 후 문의 |
| 로컬인데 Cloud SQL로 붙으려 함 | `.env`에 `CLOUD_SQL_INSTANCE`가 들어감 | 로컬 `.env`에서 제거 |
| 어댑터 관련 런타임 오류인데 typecheck 는 통과한다 | `@prisma/adapter-pg`와 `@prisma/client` 버전이 갈림. 메이저만 같아도 갈린다(adapter 가 `driver-adapter-utils` 를 정확 고정) | 두 패키지를 **정확히 같은 버전**으로 고정한다. `pnpm ls @prisma/client @prisma/adapter-pg @prisma/driver-adapter-utils` 로 셋이 같은지 확인 |

## 근거

- 앱 DB는 앱별 K8s DB가 아니라 **공용 Cloud SQL + 논리 DB**이며, 연결은 Connector 라이브러리 직결 +
  IAM 인증(비밀번호 없음)입니다. 인스턴스는 private IP 전용입니다.
- 논리 DB의 소유·격리 단위는 **프로젝트**이고, 접속 신원은 **프로젝트당 GSA 1개**입니다. 같은 프로젝트
  안에서는 앱 간 DB 접근을 열고, 프로젝트 간에는 격리합니다. 그래서 앱↔DB 연결은 접근제어가 아니라
  **설정** 문제로 다룹니다.
- 접속 정보를 앱이 만들지 않고 주입받는 이유도 같습니다 — 인스턴스·계정·DB 이름은 플랫폼이 발급 시점에
  결정하며, 앱은 그 결과만 소비합니다.

## 언어별 Connector 라이브러리

**계약이 우선입니다.** 아래는 API 형태를 확인할 때만 참고하세요 — 라이브러리 문서에는 사내 규약
(무비번 · private IP 전용 · 주입 상태 3분기 · 풀 수명)이 없습니다.

| 언어 | 라이브러리 |
|---|---|
| Node.js | [cloud-sql-nodejs-connector](https://github.com/GoogleCloudPlatform/cloud-sql-nodejs-connector) |
| Python | [cloud-sql-python-connector](https://github.com/GoogleCloudPlatform/cloud-sql-python-connector) |
| Go | [cloud-sql-go-connector](https://github.com/GoogleCloudPlatform/cloud-sql-go-connector) |
| Java | [cloud-sql-jdbc-socket-factory](https://github.com/GoogleCloudPlatform/cloud-sql-jdbc-socket-factory) |

**표에 없는 언어도 계약은 같습니다** — [Cloud SQL 커넥터 개요](https://cloud.google.com/sql/docs/postgres/language-connectors)
