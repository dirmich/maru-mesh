# MaruMesh 새 세션 온보딩

이 문서는 새로운 기기나 새로운 AI/개발 세션에서 MaruMesh를 수정하기 전에 먼저 확인해야 할 작업 기준을 정리합니다.

## 1. 저장소 경계

- 원본 소스와 실제 개발 이력은 private source repo인 이 프로젝트에서 관리합니다.
- public 배포 repo는 `../marumesh-pub`이며 GitHub repository는 `dirmich/maru-mesh`입니다.
- public repo에는 공개 README, `docs/`, GitHub Release client asset만 동기화합니다.
- source repo의 `.env`, `.gocache`, `bin/`, `dist/`, 로컬 로그/홈 디렉터리는 public repo에 넣지 않습니다.
- 실제 `.env`는 로컬 운영 파일입니다. commit하지 말고 `.env.example`만 문서화된 기본값으로 유지합니다.

## 2. public repo 준비

새 기기나 새 세션에서 source repo만 있고 `../marumesh-pub`가 없으면, 먼저 public repo를 같은 상위 디렉터리에 clone합니다.

```bash
cd ..
git clone https://github.com/dirmich/maru-mesh.git marumesh-pub
cd marumesh
```

정상 배치는 다음과 같습니다.

```text
<workdir>/marumesh      # private source repo
<workdir>/marumesh-pub  # public docs/release repo
```

`publish.sh`도 `../marumesh-pub`가 없으면 자동으로 public repo를 clone합니다. 그래도 온보딩 시점에는 먼저 public repo를 준비해 두면 문서 동기화 diff를 바로 확인할 수 있습니다.

## 3. 처음 읽을 문서

작업을 시작하면 다음 순서로 읽습니다.

1. `docs/SESSION_CONTEXT.md`: 현재 기능 상태와 최근 구현 이력.
2. `docs/commands.md`: `marumesh up/down`, service, publish 명령 사용법.
3. `docs/DISTRIBUTION.md`: public repo와 release 배포 방식.
4. `docs/install_guide.md`: server/client 설치와 Docker/PostgreSQL/SSO 설정.
5. `CHANGELOG.md`: 버전별 변경 기록.

## 4. 기본 제품 결정사항

- 사용자는 기본적으로 `marumesh up`과 `marumesh down`만 알면 됩니다.
- `marumesh up`의 기본 control plane은 `https://marumesh.lab.highmaru.com`입니다.
- `--control`은 기본 서버가 아닌 다른 control plane을 사용할 때만 지정합니다.
- 로그인 정보가 없으면 CLI가 기기 이름을 포함한 SSO URL을 출력하고, 브라우저 로그인 후 token을 저장합니다.
- 로그인 정보가 있으면 저장 token으로 인증하고 보안 채널을 백그라운드로 시작한 뒤 명령은 종료됩니다.
- device owner는 Google SSO로 로그인한 사용자입니다.
- 같은 `device_id`가 다시 등록되면 새 row를 만들지 않고 기존 device의 이름, public key, 최종 로그인 시간을 갱신합니다.
- dashboard에서 device가 삭제되면 해당 device의 저장 token은 더 이상 신뢰하지 않고 다음 `up`에서 SSO 등록 flow를 다시 진행해야 합니다.

## 5. 단일 실행파일 원칙

- client 설치 산출물은 `marumesh` 단일 실행파일입니다.
- server 설치 산출물은 `marumesh-server` 단일 실행파일이며 React dashboard를 embed합니다.
- WireGuard는 Go userspace 의존성으로 포함합니다. 사용자가 별도 `wg`, `wireguard-tools`, `wireguard-go` CLI를 설치해야 하는 구조로 되돌리지 않습니다.
- OS TUN 장치 생성 권한은 필요합니다.
- 현재 실제 mesh mode는 `tun`입니다. `userspace` mode는 향후 TUN 없는 fallback을 위한 예약 값입니다.

## 6. 플랫폼별 주의사항

- 빌드 산출물은 root가 아니라 `bin/<os>-<arch>/` 아래에 생성합니다.
- release upload asset은 `dist/marumesh-*` 이름을 사용합니다.
- Linux asset: `marumesh-linux-amd64`, `marumesh-linux-arm64`
- Windows asset: `marumesh-windows-amd64.exe`
- macOS Intel asset: `marumesh-darwin-amd64`
- macOS Apple Silicon asset: `marumesh-darwin-arm64`
- macOS systray 의존성 때문에 macOS target은 target arch의 macOS native build가 필요합니다. Intel Mac에서는 `darwin-amd64`, Apple Silicon(M1/M2/M3/M4)에서는 `darwin-arm64`를 만듭니다.
- macOS `marumesh up`은 기본적으로 menubar tray를 표시합니다. tray 없이 실행하려면 `--headless`를 사용합니다.
- Linux는 기본 headless입니다.
- Windows는 desktop service/session에서 tray menu를 사용합니다.

## 7. 로컬 개발 환경

일반 검증:

```bash
make test
make build
```

release asset 생성:

```bash
make release-assets
```

Docker control plane:

```bash
cp .env.example .env
docker network connect backend_default postgresql
docker compose up --build
```

기본 Docker 매핑은 `HOST_PORT=8000`, `PORT=8080`입니다. HAProxy가 Docker의 `cp-server:8080`으로 연결되면 공식 테스트 URL은 `https://marumesh.lab.highmaru.com`입니다.

PostgreSQL 컨테이너는 같은 Docker network에 있어야 합니다. 비밀번호에 `#`, `$`, `!`, `@`, 공백 같은 특수문자가 있으면 keyword DSN에서 `password='...'`처럼 password 값만 작은따옴표로 감싸거나 URL DSN의 password를 percent-encoding합니다.

## 8. 작업 규칙

- 문서와 커밋 메시지는 한국어를 기본으로 작성합니다.
- 작업 단위가 끝나면 관련 문서를 즉시 갱신합니다.
- source repo에서 commit/push를 수행합니다.
- public 문서와 release는 `publish.sh`로 갱신합니다.
- `.env` 같은 로컬 민감 파일은 삭제하지 말고, Git 추적에서도 제외합니다.
- 사용자가 만든 미커밋 변경은 되돌리지 않습니다. 충돌하면 먼저 상태를 확인하고 그 변경 위에서 작업합니다.

## 9. Publish 절차

source repo에서 수정, 검증, commit이 끝나면 다음을 실행합니다.

```bash
./publish.sh
```

`publish.sh` 기본 동작:

- `Makefile`의 `VERSION`을 읽어 `v<VERSION>` release tag를 사용합니다.
- `make test`와 `make release-assets`를 실행합니다.
- source branch에 push되지 않은 commit이 있으면 push합니다.
- 최상위 `README*.md`와 `docs/`를 `../marumesh-pub`에 동기화하고 public repo에 commit/push합니다.
- `dirmich/maru-mesh` GitHub Release를 생성하거나 기존 asset을 덮어씁니다.
- `README-ja.md`, `README-zh.md` 같은 다국어 README는 `README*.md` 패턴으로 자동 동기화됩니다.

빠른 문서 동기화만 필요할 때:

```bash
./publish.sh --skip-tests --skip-build
```

실행 전 확인:

```bash
./publish.sh --dry-run
```

## 10. 배포 URL

Client install URL:

```bash
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
```

Windows:

```powershell
iwr https://marumesh.lab.highmaru.com/install.ps1 -UseB | iex
```

설치 스크립트는 public GitHub Releases에서 client binary를 다운로드합니다.

```text
https://github.com/dirmich/maru-mesh/releases/latest/download
```

## 11. 자주 깨지는 경계

- 기본 control URL이 다시 `localhost:8080`으로 돌아가면 안 됩니다.
- license verify endpoint는 `/api/v1/license/verify`와 legacy `/v1/license/verify` 호환을 유지합니다.
- `marumesh up` 기본 실행에서 내부 JSON 로그를 쏟지 않습니다. 상세 로그는 `--debug`에서만 출력합니다.
- `up`은 foreground daemon처럼 붙잡고 있지 않고, mesh 준비 후 반환해야 합니다.
- macOS TUN 이름은 `utun` 계열이어야 하며, 정상 연결 후 `ifconfig`에 VIP가 보여야 합니다.
- Windows `up`은 로그인 token이 저장된 config 경로를 서비스 실행에 명시해야 합니다.
- frontend는 시작 시 SSO 세션을 확인하고 미로그인 상태에서는 login screen만 보여야 합니다.
- 일반 사용자는 자기 device와 공유받은 device 중심으로 보고, superuser만 전체 사용자/device와 전역 정책을 관리합니다.

## 12. 현재 남은 큰 과제

- ICE/WireGuard E2E 실제 패킷 통신 안정화.
- TUN 없는 userspace netstack fallback 구현 여부 결정.
- 조직/팀 단위 device 및 policy 그룹화.
- Apple Silicon macOS native release asset 자동화.
