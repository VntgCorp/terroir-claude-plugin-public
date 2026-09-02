# 코드 컨벤션

이름 짓기와 포맷의 규칙입니다. **포맷은 도구가 강제**(ESLint + Prettier, 커밋 시 자동 적용)하므로
외울 필요 없고, 이 문서는 도구가 잡아주지 못하는 **이름 짓기와 판단 기준**을 다룹니다.

## 규칙 요약

1. 포맷(들여쓰기·따옴표·세미콜론)은 논쟁하지 않는다 — Prettier 결과가 곧 표준.
2. 이름은 **발음 가능하고 검색 가능한 완전한 단어**로. 축약어 지양.
3. TypeScript 네이밍: 변수/함수 `camelCase`, 클래스/타입 `PascalCase`, 상수 `UPPER_SNAKE_CASE`.
4. 파일명: 서버는 `이름.역할.ts`(역할 접미사는 [server-structure.md](server-structure.md) 표), 클라이언트는 대표 export 표기를 따른다.
5. 주석은 "무엇을"이 아니라 **"왜"**를 쓴다. 코드를 다시 말하는 주석은 쓰지 않는다.

## 적용 범위 — 파일 경로로 판단한다

규칙마다 적용 범위가 표기됩니다. 범위는 편집 중인 **파일의 경로**로 판단합니다 —
`apps/be-*`·`(terroir/)libs/server`는 **서버**, `apps/fe-*`·`(terroir/)libs/client`는 **클라이언트**. 범위 표기가 없는 규칙은 **공통**입니다.
풀스택으로 양쪽을 오가더라도 규칙은 사람이 아니라 파일 기준입니다.
**경계**는 코드 파일이 아니라 시스템 인터페이스(DB·Kafka·URL)의 이름을 뜻합니다 — 어느 쪽 코드에서 다루든 동일합니다.

## 네이밍

| 대상 | 범위 | 규칙 | 예 |
|------|------|------|-----|
| 변수, 함수, 메서드 | 공통 | camelCase, 동사로 시작(함수) | `calculateTotalPrice()`, `orderCount` |
| 클래스, 타입, enum 타입 | 공통 | PascalCase | `OrderService`, `OrderStatus` |
| enum 값, 상수 | 공통 | UPPER_SNAKE_CASE | `PENDING_REVIEW`, `MAX_RETRY_COUNT` |
| boolean | 공통 | `is/has/can/should` 접두 | `isGift`, `hasStock`, `canCancel` |
| 파일명 | 서버 | kebab-case + 역할 접미사 | `orders.service.ts`, `gcs-storage.adapter.ts` |
| 파일명 | 클라이언트 | 대표 export 표기 그대로 — 컴포넌트 PascalCase, hook·store camelCase | `OrderList.tsx`, `useDebounce.ts`, `authStore.ts` |
| DB 테이블/컬럼 | 경계 | snake_case (data/db-naming-and-ids.md *(후속 PR)*) | `order_items.created_at` |
| Kafka 토픽 | 경계 | dot 계층 + kebab (api/kafka-events.md *(후속 PR)*) | `prod.vntg.order.event.payment-completed` |
| URL 경로 | 경계 | kebab-case 복수형 (api/rest-conventions.md *(후속 PR)*) | `/user-profiles` |

파일명 규칙이 서버·클라이언트에서 다른 이유: **파일명은 그 파일의 대표 export를 따르기 때문**입니다.
NestJS는 kebab-case 파일 + 역할 접미사가 생태계 관례이고, React는 컴포넌트(PascalCase)·hook(camelCase)
심볼 표기를 파일명에 그대로 씁니다. "클라이언트 파일인데 kebab-case인가?" 같은 혼동이 생기면 이 원칙으로 돌아오세요.

이름 짓기 판단 기준:

- **검색 가능하게** — `d`, `tmp`, `data2` 같은 이름은 grep이 불가능하다. `daysUntilExpiry`처럼.
- **단위와 의미를 이름에** — `timeout`(뭐의? 단위는?)보다 `requestTimeoutMs`.
- **부정형 boolean 금지** — `isNotReady`는 `!isNotReady`가 되는 순간 재앙. `isReady`로.
- **대칭을 지켜라** — `open/close`, `create/delete`, `begin/end`. `open/destroy` 같은 짝 금지.
- **상태 이름에는 시점을 담아라** — 동사원형은 명령이지 상태가 아니다. `CANCEL`은 취소하라는 건지
  취소됐다는 건지 알 수 없다. 진행 중이면 `-ING`(`COOKING`), 완료면 `-ED`(`COOKED`, `CANCELLED`),
  대기면 `PENDING_*`(`PENDING_PAYMENT`). 상태 값만 보고 "지금 어느 시점인가"에 답할 수 있어야 한다.
  서버·클라이언트·DB enum 모두 동일.

```ts
// ❌
const d = new Date(); const list2 = users.filter(u => u.a > 30);
function proc(x: any) { ... }
type OrderStatus = 'COOK' | 'CANCEL' | 'DELIVERY';   // 시점이 안 보이는 상태

// ✅
const now = new Date();
const seniorUsers = users.filter(user => user.age > MINIMUM_SENIOR_AGE);
function calculateShippingFee(order: Order): Money { ... }
type OrderStatus = 'COOKING' | 'COOKED' | 'CANCELLED' | 'DELIVERING' | 'DELIVERED';   // 시점이 보이는 상태
```

## 주석

```ts
// ❌ 코드를 다시 말하는 주석 — 노이즈
// 사용자를 조회한다
const user = await this.usersRepo.findById(id);

// ✅ "왜"를 말하는 주석 — 코드로 표현 못 하는 맥락
// 결제 게이트웨이가 5xx여도 실제 결제는 성공했을 수 있어 (타임아웃 케이스),
// 취소가 아니라 '확인 대기'로 두고 배치가 재조회한다
await this.markPaymentUnconfirmed(orderId);
```

- 공개 API·복잡한 함수에는 JSDoc(목적/파라미터/반환/예외)을 답니다. Swagger 문서화는 별도 데코레이터로.
- `TODO:`에는 **무엇을 왜 미뤘는지**를 함께 — `// TODO: 대량건 최적화 (현재 N+1, 주문 1만건부터 체감)`.
- 죽은 코드는 주석 처리로 남기지 않고 지웁니다. 필요하면 git 히스토리에 있습니다.

## 타입 사용

- `any` 금지가 기본값입니다(lint가 잡음). 정말 불가피하면 `unknown`으로 받고 좁혀서 사용.
- 함수의 공개 시그니처(파라미터·반환)에는 타입을 명시합니다. 지역 변수는 추론에 맡겨도 됩니다.
- 값의 종류가 정해져 있으면 union 리터럴 또는 enum: `type Env = 'local' | 'dev' | 'prod'`.

### 인터페이스 이름 — `I` 접두사 쓰지 않음

인터페이스에 `I` 접두사를 붙이지 않습니다 (`ApiResponse`, `Storage` — `IApiResponse` ❌).
TypeScript 커뮤니티 표준을 따릅니다 — TS에서는 클래스도 타입으로 쓰여 `I` 구분의 실익이 적고,
AI 생성 코드와의 마찰도 줄어듭니다. 추상/구현 구분은 이름이 아니라 설계(인터페이스 vs adapter 파일)로 드러냅니다.

## 포맷 — 도구에 맡긴다

- 커밋하면 lint-staged가 변경 파일에 `eslint --fix` + `prettier --write`를 자동 실행합니다.
- 포맷 관련 PR 코멘트는 하지 않습니다 — 도구가 통과시켰으면 끝난 문제입니다.
- 룰 상세와 트러블슈팅: [greenfield lint 가이드(04-lint)](https://github.com/VntgCorp/gh-terroir-greenfield/tree/main/templates/terroir/docs/guide/04-lint) (managed 문서).

## 근거

- 강제 구현: `eslint.config.mjs` + `.prettierrc` + lint-staged (greenfield managed)
- 네이밍 원칙: 검색 가능성·발음 가능성 — Clean Code(Meaningful Names), [Google TS Style Guide](https://google.github.io/styleguide/tsguide.html)
- `I` 접두사: TypeScript 커뮤니티 표준(공식 핸드북·MS 가이드라인)이 비권장 — 신규 코드부터 접두사 없이(본문 참조)
