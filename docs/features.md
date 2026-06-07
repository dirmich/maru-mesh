# MaruMesh 구현 이력

## 2026-06-06

### 네트워크 데이터 경로 보강
- **ICE 연결 시작 로직 구현**: P2P initiator는 `Dial`, responder는 `Accept`로 실제 ICE connectivity check를 시작하도록 수정했습니다.
- **PacketConn 어댑터 구현**: Pion ICE `Conn`을 WireGuard `ICEBind`가 사용할 수 있는 `net.PacketConn` 형태로 연결하고 `ReadFrom`/`WriteTo`를 실제 I/O로 교체했습니다.
- **ICE payload 테스트 추가**: 외부 STUN 없이 host candidate만으로 두 peer를 연결하고 payload 전송을 검증하는 단위 테스트를 추가했습니다.
- **Mesh degrade 상태 노출**: WireGuard/TUN 초기화 실패 시 로컬 API가 `mesh_enabled=false`, `mesh_error`를 반환하도록 보강했습니다.
- **외부 WireGuard CLI 의존성 제거**: Docker 런타임 이미지에서 `wireguard-tools`와 `iproute2`를 제거하고 Go 내장 WireGuard 장치로 동작하도록 설치 경계를 정리했습니다.
- **설치 사전 점검 명령 추가**: `marumesh check`로 TUN 생성 권한을 확인하고 OS별 해결 힌트를 출력하도록 했습니다.
- **Mesh 모드 설정 추가**: 설정 파일의 `mesh_mode`와 CLI `--mesh-mode`를 추가해 현재 `tun` 모드와 향후 `userspace` fallback 모드를 명확히 분리했습니다.
- **Client install URL**: public repo raw `install.sh`, `install.ps1`을 공식 설치 진입점으로 사용하고 GitHub Releases의 client 바이너리를 설치하도록 했습니다.
- **공식 테스트 URL 통일**: 기본 control plane과 Docker 공개 URL을 `https://marumesh.lab.highmaru.com`으로 정리했습니다.
- **Docker env_file 정리**: Compose 서버 환경 변수는 `.env`에서 직접 읽고, `HOST_PORT`와 `PORT`를 분리했습니다.
- **PostgreSQL DSN 파싱 보강**: database 자동 생성 fallback이 password 특수문자와 URL DSN을 처리하도록 수정했습니다.
- **Policy sync 오류 진단 개선**: 인증 실패 같은 plain text 응답을 JSON 파싱 오류 대신 HTTP status/body로 표시합니다.
- **SSO 기반 device 등록 보강**: `marumesh up` 로그인 URL에 기기 이름을 포함하고, Google SSO 사용자와 hostname을 device에 저장합니다.
- **Virtual IP 대역 설정**: 기본 device 가상 IP 대역은 `100.64.0.0/24`이며, `MARUMESH_VIRTUAL_CIDR`로 운영 환경의 기존 대역과 겹치지 않게 변경할 수 있습니다.
- **Device 이름 보존**: 기존 device 재등록 시 hostname을 자동 덮어쓰지 않고, 이름 변경은 dashboard/API 수정 경로로만 수행합니다.
- **Peer 이름 해석**: peer hostname을 DNS/hosts에 반영해 `dev`, `dev.maru`, `<device-id>.maru` 형태의 이름 접근을 지원합니다.
- **up 기본 control URL 고정**: 기존 config에 localhost가 남아 있어도 `marumesh up`은 `--control`이 없으면 공식 기본 서버를 사용합니다.
- **up 로그 quiet 기본값**: `marumesh up`은 기본적으로 내부 JSON 로그를 숨기고, `--debug`에서만 상세 진단 로그를 출력합니다.
- **up 백그라운드 실행**: `marumesh up` 기본 실행은 로그인 후 `run` daemon을 백그라운드로 시작하고 반환하며, `down`은 로컬 API shutdown으로 해당 프로세스를 중지합니다.
- **device 관리 보강**: 같은 device_id 재등록은 기존 device의 이름을 보존하고 public key/최종 로그인 시간을 갱신하며, owner/superuser가 대시보드에서 기기 이름을 수정할 수 있습니다.
- **TUN 인터페이스 표시 보강**: macOS 기본 TUN 이름을 `utun`으로 보정하고, TUN 생성 후 virtual IP를 OS 인터페이스에 설정해 `ifconfig`/`ip addr`에서 확인할 수 있게 했습니다.
- **WireGuard IPC key 포맷 수정**: WireGuard userspace device에는 hex key를 전달하고 control plane/API에는 기존 base64 key를 유지하도록 분리했습니다.
- **device 삭제/재등록 flow 보강**: owner/superuser가 대시보드에서 device를 삭제할 수 있고, 삭제된 device는 다음 `marumesh up`에서 SSO device 등록 flow를 다시 수행합니다.
- **device 삭제 강제 로그아웃**: 삭제된 device의 pending SSO token을 폐기하고 실행 중인 agent가 삭제/권한 회수를 감지하면 로컬 auth token을 지우고 종료합니다.
- **CLI SSO polling 표시 보강**: SSO polling timeout을 정상화하고, 로그인 완료 후 보안 채널 시작 메시지를 출력해 `marumesh up` 진행 상태를 명확히 했습니다.
- **CLI SSO polling 진단 보강**: polling HTTP 요청에 timeout을 적용하고 대기 상태를 주기적으로 출력해 브라우저 SSO 이후 CLI가 어느 단계에서 대기 중인지 확인할 수 있게 했습니다.
- **macOS sudo 기본 브라우저 보정**: `sudo marumesh up` 실행 시 SSO URL이 root 설정이 아닌 로그인 사용자 세션의 기본 브라우저에서 열리도록 했습니다.
- **CLI SSO 중복 로그인 방지**: `marumesh up`에서 새 SSO token을 받은 직후 device를 먼저 등록해 백그라운드 agent가 같은 실행에서 로그인 페이지를 다시 열지 않도록 했습니다.
- **macOS/Windows tray menu 보강**: macOS `marumesh up`은 기본으로 menubar tray를 표시하고, Windows tray도 동일한 메뉴 구조로 현재 로그인 사용자와 소유/공유 device 목록을 보여주며, Close 선택 시 `marumesh down`과 같은 VPN cleanup을 수행합니다.
- **실행파일 자체 서비스 설치**: `marumesh install-service` 명령을 추가해 Linux systemd, macOS LaunchAgent, Windows Service 등록을 별도 스크립트 없이 수행할 수 있게 했습니다.
- **실행파일 자체 서비스 제거**: `marumesh uninstall-service` 명령을 추가해 플랫폼별 서비스 제거도 동일 실행파일에서 수행할 수 있게 했습니다.
- **서비스 제거 멱등성 보강**: 서비스가 이미 없거나 중지된 상태에서도 `uninstall-service`가 설정 파일 제거와 reload 절차를 계속 수행하도록 했습니다.
- **서비스 설치 재실행 보강**: macOS LaunchAgent와 Windows Service가 이미 있는 상태에서도 `install-service`가 기존 항목을 정리하고 다시 등록하도록 했습니다.
- **up/down CLI 추가**: `marumesh up`이 로그인 URL 출력/토큰 저장/보안 채널 연결을 처리하고, Windows에서는 로그인 후 서비스 실행까지 수행하도록 했습니다.
- **서비스 config 경로 고정**: 서비스 실행 명령에 `--config`를 포함할 수 있게 해 로그인 토큰이 저장된 설정 파일을 서비스가 그대로 사용하도록 했습니다.
- **플랫폼별 빌드 산출물 정리**: `make build`와 `make build-all`이 바이너리를 `bin/<os>-<arch>/` 아래에 생성하도록 통일하고, macOS는 systray 제약에 따라 native arch 빌드로 처리했습니다.
- **Docker PostgreSQL 연결 정리**: `cp-server`가 `backend_default` 네트워크에서 `postgresql` 컨테이너를 `postgres/postgres` 계정으로 사용하도록 환경 설정을 정리했습니다.
- **프론트엔드 SSO 게이트 적용**: React 대시보드가 `/api/v1/auth/session`으로 로그인 상태를 확인하고, 인증 전에는 SSO 로그인 화면만 표시하도록 했습니다.
- **대시보드 API 권한 보강**: 정책 조회/수정과 device 공유 API가 로그인 사용자 권한을 확인하도록 강화했습니다.
- **권한별 대시보드 메뉴 정리**: 일반 사용자는 자신의 device/공유 device 관리 화면을 중심으로 보고, superuser만 사용자 관리와 전역 보안 정책 메뉴에 접근합니다.
- **검증 경계 정리**: `frontend/go.mod`와 `make test`로 Go 테스트와 React 빌드 검증 범위를 명확히 했습니다.
- **Docker Compose v2 경고 정리**: `docker-compose.yml`의 obsolete `version` 필드를 제거했습니다.
- **서버 단일 실행파일 프론트 내장**: `make build`가 React dist를 서버 embed 경로로 갱신하고, 서버 바이너리가 `STATIC_PATH` 없이 내장 대시보드를 서빙합니다.
- **서버 설치 스크립트 단일 바이너리화**: `install-server.sh`에서 별도 static 복사와 `STATIC_PATH` 강제를 제거해 내장 프론트가 사용되도록 했습니다.
- **README 사용법 최신화**: CLI, 서버, Docker, SSO 대시보드 사용 흐름을 현재 구현 기준으로 정리했습니다.
- **CLI 기본 서버/명령 문서 정리**: `marumesh up`이 기본 control plane으로 바로 연결되도록 보강하고, `docs/commands.md`에 한국어 명령어 사용법을 정리했습니다.
- **Tray 대시보드 URL 정리**: Windows/macOS tray의 `Open Dashboard`가 현재 control plane URL을 열도록 수정했습니다.
- **connect 명령 실제 동작 연결**: `marumesh connect`가 원격 device TCP 서비스에 대한 로컬 proxy를 생성하도록 정리했습니다.
- **TCP proxy 자동 포트 응답 보강**: 로컬 포트 자동 선택 시 실제 할당 주소를 `proxy_address`로 반환하도록 수정했습니다.
- **Docker Linux 빌드 수정**: tray stub 시그니처를 desktop 구현과 맞춰 Docker/Linux 빌드 실패를 해결했습니다.
- **민감정보 파일 정리**: 실제 `.env`는 로컬 파일을 유지한 채 Git 추적에서 제거하고 `.gitignore`에 추가했습니다. 예제/문서/테스트 스크립트는 placeholder 기반으로 정리했습니다.
- **README 언어 분리**: `README.md`는 영어, `README-ko.md`는 최신 한국어 사용법으로 정리했습니다.
- **License verify 경로 호환**: `/api/v1/license/verify`와 legacy `/v1/license/verify`를 모두 지원하도록 정리했습니다.
- **PostgreSQL JSON scan 보강**: text 컬럼 JSON 필드가 string으로 반환되어도 정상 decode되도록 수정했습니다.
- **CLI up 플랫폼별 tray 기본값**: macOS `marumesh up`은 기본 menubar tray를 표시하고, Linux는 기본 headless로 실행합니다.

### 로컬 API 실데이터 연동
- **장치 목록 Mock 제거**: `GET /v1/devices`가 고정 샘플 대신 제어 평면의 `/api/v1/network/peers` 결과를 반환하도록 변경했습니다.
- **원격 장치 필터링**: 로컬 에이전트 자신의 device ID는 목록에서 제외하고 원격 peer만 반환하도록 정리했습니다.
- **API 테스트 추가**: peer 목록 변환 및 제어 평면 오류 시 `503` 반환을 검증하는 단위 테스트를 추가했습니다.
- **TCP 프록시 대상 해석**: `POST /v1/proxy/tcp`가 `target_id`를 제어 평면 peer 목록에서 조회해 대상 장치의 `virtual_ip:remote_port`로 연결하도록 변경했습니다.
- **프록시 통합 테스트 추가**: 제어 평면에서 해석한 peer virtual IP로 로컬 TCP proxy가 실제 payload를 전달하는지 검증했습니다.
- **프론트엔드 빌드 검증**: `npm install` 후 `frontend`의 `npm run build`가 통과함을 확인했습니다.

### 보안 설정 강화
- **JWT 기본 시크릿 제거**: 서버가 `JWT_SECRET` 없이 고정 기본값으로 실행되지 않도록 변경했습니다.
- **개발용 명시 플래그 추가**: 로컬 개발에서만 `MARUMESH_DEV_INSECURE_JWT=true`를 통해 임시 시크릿을 사용할 수 있게 했습니다.
- **OAuth state 서명 검증**: 로그인 state를 HMAC으로 서명하고 callback에서 검증해 변조된 state를 거부하도록 보강했습니다.

### 웹 대시보드 보강
- **Security Rules 화면 구현**: React 대시보드의 placeholder를 제거하고 전역 정책을 조회/편집/저장하는 UI를 실제 API와 연결했습니다.
- **관리자 편집 제어**: superuser에게만 정책 추가, 삭제, 저장 버튼을 노출하도록 정리했습니다.
- **Share Agent 연동**: 대시보드의 장치 공유 다이얼로그를 실제 API와 연결하고 재공유 허용 옵션을 추가했습니다.
- **프론트엔드 의존성 보안 정리**: `npm audit fix`를 적용해 lockfile 기준 취약점 0건을 확인했습니다.
- **Settings 화면 구현**: 계정 정보와 조직 필터 설정을 제공하고 dashboard status 조회 범위를 즉시 갱신하도록 연결했습니다.
- **Audit Logs 화면 구현**: 중앙 감사 로그 API를 대시보드에 연결해 정책/프록시 결정 이력을 조회할 수 있게 했습니다.

## 2026-03-17

### 프로젝트 기반 및 인프라 구축
- **프로젝트 구조 설정**: 소스 코드는 `src/`, 문서는 `docs/` 디렉토리에 배치하도록 구조화했습니다.
- **Go 모듈 초기화**: `github.com/dirmich/marumesh` 모듈을 생성하고 의존성 관리를 시작했습니다.
- **로깅 시스템**: Go의 `slog`를 사용하여 JSON 형식의 정형 로깅 시스템을 구현했습니다.
- **설정 관리**: `config.json` 파일을 통해 로드 및 저장 가능한 유연한 설정 시스템을 구축했습니다.

### 에이전트 핵심 기능
- **라이브사이클 관리**: 시그널(SIGINT, SIGTERM) 처리를 통한 안전한 종료(graceful shutdown) 기능을 포함한 에이전트 런타임 루프를 구현했습니다.
- **보안 식별자 (Identity)**: ED25519 암호화 알고리즘을 사용한 장치 고유 식별자 생성 및 관리 기능을 구현했습니다. 장치의 개인 키는 로컬에 안전하게 저장됩니다.

### 연결 및 API
- **로컬 API 서버**: 에이전트와 로컬 애플리케이션 간 통신을 위한 Unix Domain Socket 기반의 HTTP 서버를 구현했습니다.
- **상태 확인 엔드포인트**: 장치 상태 및 식별자를 확인할 수 있는 `/v1/status` API를 추가했습니다.
- **장치 목록 조회**: 네트워크상의 원격 장치 목록을 조회할 수 있는 `/v1/devices` API를 구현했습니다 (현재 Mock 데이터 제공).
- **동적 TCP 프록시 생성**: 원격 장치로 연결되는 로컬 TCP 프록시 터널을 동적으로 생성 및 관리할 수 있는 `/v1/proxy/tcp` API를 구현했습니다.
- **SSO 로그인 흐름**: 브라우저를 통한 인증과 로컬 콜백(`/callback`) 처리를 포함한 SSO 로그인 기능을 구현했습니다.
- **제어 평면 클라이언트**: 에이전트가 중앙 제어 평면에 장치를 등록할 수 있는 클라이언트 모듈을 구현했습니다.
- **설정 영속성**: 인증 토큰 및 장치 설정을 로컬 파일에 안전하게 저장하고 로드하는 기능을 구축했습니다.
- **TCP 프록시 및 터널링**: 동적으로 TCP 터널을 생성하고 여러 프록시를 관리할 수 있는 네트워킹 핵심 모듈을 구현했습니다.

### 품질 및 안정성
- **유닛 테스트 추가**: `identity` 및 `tunnel` 모듈에 대한 유닛 테스트를 작성하여 핵심 로직의 안정성을 확보했습니다.

### 문서화
- **다국어 README**: 영문(`README.md`) 및 국문(`README-ko.md`) 메인 설명서를 작성했습니다.
- **구현 이력 관리**: 구현된 기능들을 날짜별로 기록하기 위한 `docs/features.md`를 생성했습니다.
- **기존 문서 이전**: PRD 문서를 `docs/prd.md`로 이동하여 문서를 체계화했습니다.
