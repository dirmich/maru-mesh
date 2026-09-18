# Changelog

모든 변경 사항은 이 파일에 기록됩니다. MaruMesh는 유의적 버전(Semantic Versioning)을 따릅니다.

## [Unreleased]

## [0.11.86] - 2026-09-18
### Added
- **웹 대시보드 원격 에이전트 제어 기능**:
  - **원격 SSH On/Off 토글**: 대시보드에서 각 노드의 SSH 상태를 원클릭으로 켜고 끌 수 있으며, 에이전트가 로컬 `sshd` 드롭인 설정을 동적으로 자동 적용 및 해제합니다.
  - **원격 버전 업그레이드 [Upgrade]**: 대시보드에서 대상 노드를 최신 릴리스 버전으로 원격 업그레이드 지시할 수 있으며, 에이전트가 GitHub Release 바이너리를 다운로드 및 SHA-256 검증 후 원자적으로 교체합니다.
  - **원격 서비스 재시작 [Restart]**: 대시보드에서 에이전트 서비스 재시작을 요청할 수 있으며, 1회성 ACK 수신 후 안전하게 재기동됩니다.
- **보안 아키텍처 공식 문서**: `docs/security.md`에 3계층 키페어, Zero-Trust OpenSSH, 원격 제어 명령 격리, 공급망 공격 방어 규정 수록.

### Changed
- `handleLicenseVerify` 및 `SyncDeviceState` 인터페이스를 확장하여 장치별 원하는 상태(Desired State)를 15초 주기로 실시간 동기화합니다.

## [0.11.85] - 2026-09-18
### Fixed
- `sudo marumesh up --ssh` 실행 시 호출 사용자(`SUDO_USER`) 환경으로 SSH 키(`~/.ssh/marumesh/id_ed25519*`) 복사 및 소유권(`0600`) 위임 자동화.
- `~/.ssh/config`에 `User <SUDO_USER>` 및 `StrictHostKeyChecking accept-new` 설정을 자동 주입하여, 일반 사용자가 `ssh <hostname>`만으로 비밀번호 없이 즉시 접속 가능하도록 OpenSSH 클라이언트 연동 개선.

### Fixed
- 중앙 agent update 기본 산출물 경로를 private source repository가 아닌 public release repository로 수정하고 `CLIENT_RELEASE_BASE_URL` override를 지원합니다.

### Changed
- 로컬 테스트 상태·키·로그·DB snapshot을 `test/` 아래로 통일하고 `.gitignore`에서 제외했습니다. `test-local.sh`도 새 경로를 사용합니다.

### Fixed
- agent 시작 시 control plane 정책을 즉시 동기화해 초기 1분 동안 빈 정책으로 P2P가 거부되는 문제를 수정했습니다. 동기화 실패 시 기존 로컬 정책은 유지합니다.
- peer ID 정렬로 ICE initiator를 하나만 선택하고 실패한 세션을 재생성해 양방향 동시 연결 충돌을 방지했습니다.
- `marumesh up`에서 virtual CIDR route를 TUN에 자동 설치하고 tunnel 종료 시 제거하도록 했습니다.
- WireGuard가 bind를 재시작한 뒤에도 ICE transport를 유지하고 실제 tunnel 종료 시에만 연결을 닫도록 생명주기를 수정했습니다.
- WireGuard peer 설정 중 bind 재설정이 먼저 등록된 ICE 연결을 닫아 handshake가 실패하던 문제를 수정했습니다.

### Added
- 로그인 후 control plane 대시보드를 dark-tech와 lime accent 기반으로 개편하고, SSO 로그인 화면·실시간 상태 헤더·세션 표시·반응형 navigation을 보강했습니다.
- source repo 수정 완료 후 public repo 문서 동기화와 GitHub Release 업로드를 한 번에 수행하는 `publish.sh`를 추가했습니다.
- publish flow가 최상위 `README*.md`를 모두 동기화하도록 해 향후 다국어 README 추가를 지원합니다.
- 새로운 기기나 새 세션에서 먼저 확인해야 할 저장소 경계, 개발 규칙, publish 절차를 `docs/ONBOARDING.md`에 정리했습니다.
- 새 기기에서 `../marumesh-pub`가 없으면 먼저 public repo를 clone하도록 온보딩 문서와 `publish.sh`를 보강했습니다.
- `publish.sh`가 일반 publish에서 항상 release asset을 새로 빌드한 뒤 업로드하고, 문서 전용 동기화는 `--docs-only`로 release upload를 건너뛰도록 변경했습니다.
- public repo에 publish 운영 절차가 노출되지 않도록 README/docs에서 publish 관련 내용을 제거하고, 내부 문서 `docs/ONBOARDING.md`, `docs/SESSION_CONTEXT.md`는 public 동기화에서 제외했습니다.
- macOS public release가 Gatekeeper에 차단되지 않도록 `publish.sh`에 Developer ID signing/notarization 지원을 추가했습니다.
- 사용자가 publish를 지시하면 테스트, release asset 빌드, macOS 서명/공증, public 문서 동기화, GitHub Release 업로드까지 전체 절차를 수행하도록 온보딩 문서를 보강하고, macOS asset 서명/공증 설정 누락 시 release 업로드 전에 실패하게 했습니다.
- 운영 서버 `/install.sh` 대신 public repo raw `install.sh`/`install.ps1`을 공식 설치 진입점으로 사용하도록 문서와 publish 동기화 대상을 변경했습니다.
- `install.sh`가 쓰기 가능한 `INSTALL_DIR`에서도 무조건 `sudo`를 요구하지 않도록 수정했습니다.
- 기본 virtual IP 대역을 `100.64.0.0/24`로 바꾸고 `MARUMESH_VIRTUAL_CIDR`로 운영 대역을 설정할 수 있게 했습니다.
- 기존 device 재등록 시 저장된 device 이름을 자동 덮어쓰지 않도록 변경했습니다.
- peer hostname을 로컬 DNS/hosts에 반영해 `dev`, `dev.maru`, `<device-id>.maru` 형태의 이름 해석을 지원했습니다.
- `marumesh up`이 Linux TUN 권한 실패 전에 device 등록을 진행하지 않도록 preflight를 추가하고, 기존 token/VIP가 있는 agent run에서는 불필요한 재등록 호출을 생략합니다.
- `marumesh down`이 local agent shutdown을 먼저 시도하고 systemd 권한 실패 시 sudo 명령을 안내하도록 개선했습니다.
- Tailscale과 MaruMesh의 같은 점/다른 점, MaruMesh가 만족해야 할 기기 이름 기반 VPN UX를 `docs/vs_tailscale.md`에 정리했습니다.
- macOS App Store Connect 업로드용 `.app`/`.pkg` 패키징 스크립트와 내부 문서(`docs/app_store.md`)를 추가했습니다.
- GitHub 직접 다운로드용 macOS installer package를 Developer ID Installer 서명, notarization, stapling까지 수행하도록 `make macos-pkg`를 추가했습니다.
- macOS/Linux local agent API socket 기본값을 사용자 홈(`~/.marumesh/marumesh.sock`)으로 바꿔 root 소유 `/tmp/marumesh.sock` stale socket과 충돌하지 않도록 했습니다.

## [0.11.63] - 2026-06-07
### Changed
- installer 기본 다운로드 repo를 private 원본 `dirmich/marumesh`가 아닌 public 배포 repo `dirmich/maru-mesh`의 GitHub Releases로 변경했습니다.
- public 배포 repo에는 문서와 release asset을 동기화하고, 소스 원본은 이 repo에서 계속 관리하는 방식으로 정리했습니다.

## [0.11.62] - 2026-06-06
### Changed
- installer 기본 다운로드 방식을 control plane `/downloads`가 아닌 GitHub Releases `releases/latest/download`로 되돌렸습니다.
- server가 client binary를 직접 서빙하는 `/downloads` 변경은 제거했습니다.

## [0.11.61] - 2026-06-06
### Added
- macOS `marumesh up` 기본 실행에서 menubar tray를 표시하고, 현재 로그인 사용자와 소유/공유 device 목록을 볼 수 있게 했습니다.
- macOS menubar와 Windows tray에서 사용할 투명 PNG mesh icon을 추가했습니다.
### Fixed
- menubar `Close`가 UI만 닫지 않고 agent shutdown을 호출해 `marumesh down`과 같은 VPN/TUN cleanup 경로를 타도록 수정했습니다.
### Changed
- macOS 기본 `up` 실행은 tray 표시 모드로 동작하고, 필요 시 `--headless`로 menubar 없이 실행할 수 있습니다.

## [0.11.60] - 2026-06-06
### Fixed
- private GitHub Release asset이 인증 없는 `install.sh`에서 404가 나는 문제를 피하기 위해 기본 client 다운로드 경로를 control plane `/downloads`로 변경했습니다.
### Changed
- Docker image 빌드 시 client release asset을 함께 생성해 `/app/downloads`에 포함하고, server가 `/downloads/<asset>`로 직접 서빙하도록 했습니다.
- 설치 후 안내 명령을 기본값 기반 `marumesh up`으로 정리했습니다.

## [0.11.59] - 2026-06-06
### Fixed
- `marumesh up`에서 첫 SSO 로그인 직후 백그라운드 agent가 아직 등록되지 않은 device를 404로 판단해 SSO 로그인 페이지를 한 번 더 여는 문제를 수정했습니다.
### Changed
- CLI에서 새로 SSO token을 받은 경우 백그라운드 agent 시작 전에 해당 token으로 device를 먼저 등록해 단일 로그인 flow로 연결되도록 했습니다.

## [0.11.58] - 2026-06-06
### Fixed
- macOS에서 `sudo marumesh up` 실행 시 SSO URL이 root의 LaunchServices 설정을 따라 Safari로 열릴 수 있던 문제를 수정했습니다.
### Changed
- macOS sudo 실행에서는 `SUDO_UID`의 로그인 사용자 세션으로 URL을 열어 실행 중인 기본 브라우저 또는 새 기본 브라우저 창에서 SSO가 진행되도록 했습니다.

## [0.11.57] - 2026-06-06
### Fixed
- CLI SSO token polling HTTP 요청에 context/timeout을 적용해 네트워크 응답 지연 시 `marumesh up`이 계속 멈춘 것처럼 보이던 문제를 보강했습니다.
- control URL 끝의 `/`를 정규화해 auth/token polling URL이 이중 slash로 생성될 수 있는 경우를 방지했습니다.
### Changed
- `marumesh up`이 SSO 완료 대기 중임을 주기적으로 출력해 브라우저 로그인 후 어느 단계에서 대기 중인지 확인할 수 있게 했습니다.

## [0.11.56] - 2026-06-06
### Fixed
- CLI SSO polling timeout이 매 loop마다 재생성되어 실제 timeout이 동작하지 않던 문제를 수정했습니다.
### Changed
- `marumesh up` SSO 완료 후 터미널에 완료/보안 채널 시작 메시지를 출력해 다음 단계 진행 상태를 명확히 표시합니다.

## [0.11.55] - 2026-06-06
### Fixed
- device 삭제 시 pending SSO token을 폐기하고, 실행 중인 agent가 삭제/권한 회수를 감지하면 로컬 auth token을 지우고 종료하도록 했습니다.

## [0.11.54] - 2026-06-06
### Added
- 대시보드에서 owner/superuser가 device를 삭제할 수 있게 했습니다.
### Fixed
- device 이름 수정 다이얼로그에서 목록 refresh 중 입력 중인 값이 기존 이름으로 되돌아가던 문제를 수정했습니다.
- 삭제된 device로 `marumesh up`을 실행하면 저장 토큰만 재사용하지 않고 SSO device 등록 flow를 다시 진행하도록 했습니다.

## [0.11.53] - 2026-06-06
### Fixed
- WireGuard userspace IPC에는 hex key를 전달하고, control plane/API에는 기존 base64 key를 유지하도록 key 포맷 경계를 분리했습니다.

## [0.11.52] - 2026-06-06
### Fixed
- macOS에서 기본 TUN 이름을 `utun`으로 보정해 `maru0` 이름 오류로 TUN 생성이 실패하지 않도록 수정했습니다.
- TUN 생성 후 OS 인터페이스에 virtual IP를 설정하고 `up` 상태로 올려 `ifconfig`/`ip addr`에서 확인되도록 했습니다.
- `marumesh up`이 백그라운드 프로세스 시작만 확인하지 않고 mesh interface 준비 상태까지 기다린 뒤 종료하도록 변경했습니다.

## [0.11.51] - 2026-06-06
### Added
- device 등록 시 최종 로그인 시간(`last_login_at`)을 저장하고 대시보드에 표시하도록 했습니다.
- 대시보드에서 superuser 또는 device owner가 기기 이름을 수정할 수 있는 API와 UI를 추가했습니다.
### Fixed
- 동일 `device_id`가 다시 등록될 때 새 device row를 만들지 않고 기존 device 정보를 갱신하도록 테스트로 고정했습니다.

## [0.11.50] - 2026-06-06
### Changed
- `marumesh up` 기본 실행이 로그인 후 `run` daemon을 백그라운드로 시작하고 반환하도록 변경했습니다.
- `marumesh up --debug`는 상세 로그 확인을 위해 foreground 실행을 유지합니다.
### Added
- 백그라운드로 시작된 로컬 에이전트를 `marumesh down`으로 중지할 수 있도록 로컬 API shutdown 경로를 추가했습니다.

## [0.11.49] - 2026-06-06
### Changed
- `marumesh up` 기본 실행에서는 내부 JSON 로그를 숨기고, `--debug`를 명시했을 때만 상세 진단 로그를 출력하도록 변경했습니다.

## [0.11.48] - 2026-06-06
### Fixed
- `marumesh up`에서 `--control`을 명시하지 않으면 기존 config에 남아 있는 구버전 localhost 값보다 공식 기본 control plane(`https://marumesh.lab.highmaru.com`)을 우선하도록 수정했습니다.

## [0.11.47] - 2026-06-06
### Changed
- `marumesh up`의 SSO 로그인 URL에 기기 이름을 포함하고, SSO 완료 후 발급된 JWT로 device owner와 hostname을 등록하도록 개선했습니다.

## [0.11.46] - 2026-06-06
### Fixed
- control plane policy sync 실패 시 plain text 응답을 JSON으로 파싱하지 않고 HTTP status와 body를 포함한 명확한 오류를 반환하도록 수정했습니다.

## [0.11.45] - 2026-06-06
### Fixed
- PostgreSQL database 자동 생성 fallback이 password 특수문자와 URL DSN을 포함한 DSN에서 대상 database 이름을 안정적으로 파싱하도록 수정했습니다.

## [0.11.44] - 2026-06-06
### Added
- control plane에서 `/install.sh`, `/install.ps1` client install URL을 제공하고 GitHub Releases의 플랫폼별 client binary를 다운로드해 설치하도록 했습니다.
- 공식 테스트 control plane 기본 URL을 `https://marumesh.lab.highmaru.com`으로 통일했습니다.
### Changed
- Docker Compose 서버 환경 변수를 `environment` 블록 대신 `env_file: .env`로 전달하고, `HOST_PORT`와 `PORT`를 분리했습니다.

## [0.11.43] - 2026-06-06
### Fixed
- macOS에서 `marumesh up`을 CLI로 실행할 때 system tray 초기화로 프로세스가 종료될 수 있어, `up` 기본 실행을 headless 모드로 변경했습니다. Tray가 필요하면 `--headless=false`를 명시합니다.

## [0.11.42] - 2026-06-06
### Fixed
- PostgreSQL text 컬럼에서 JSON 필드(`shared_with`, `services`, `members`, `policies`)를 읽을 때 string 타입으로 반환되어 scan이 실패하던 문제를 수정했습니다.

## [0.11.41] - 2026-06-06
### Fixed
- control plane license verify API에 legacy `/v1/license/verify` alias를 추가해 경로 차이로 agent `up`이 404에서 중단되는 호환성 문제를 완화했습니다.
- license verify 실패 시 HTTP status와 응답 body를 함께 출력해 실제 서버/라우팅 문제를 진단하기 쉽게 했습니다.

## [0.11.40] - 2026-06-06
### Changed
- `README.md`를 영어 문서로 정리하고, 최신 한국어 사용법은 `README-ko.md`로 분리했습니다.
- macOS Intel(`darwin-amd64`)과 Apple Silicon(`darwin-arm64`) 안내를 영어/한국어 README 모두에 반영했습니다.

## [0.11.39] - 2026-06-06
### Fixed
- Linux/headless 빌드에서 tray stub의 `StartTray` 시그니처가 desktop 구현과 달라 Docker 빌드가 실패하던 문제를 수정했습니다.
### Security
- 실제 `.env` 파일은 Git 추적에서 제거하고 `.gitignore`에 추가했습니다. 로컬 파일은 유지됩니다.
- `.env.example`, 테스트 스크립트, 로컬 테스트 문서에 들어 있던 고정 secret 예시를 placeholder로 교체했습니다.

## [0.11.38] - 2026-06-06
### Fixed
- TCP proxy 생성 시 `local_port: 0`을 사용하면 실제 OS 할당 포트를 `proxy_address`로 반환하도록 수정했습니다.
- `marumesh connect` 기본 로컬 포트 자동 선택 결과를 사용자가 바로 확인할 수 있도록 보강했습니다.

## [0.11.37] - 2026-06-06
### Changed
- `marumesh connect`를 수동 ICE 안내 명령에서 실제 로컬 TCP proxy 생성 명령으로 정리했습니다.
- TCP proxy 생성 SDK가 HTTP 에러 응답을 명확히 반환하도록 보강했습니다.

## [0.11.36] - 2026-06-06
### Fixed
- Windows/macOS tray의 `Open Dashboard`가 `localhost:8080` 고정값 대신 현재 control plane URL을 열도록 수정했습니다.

## [0.11.35] - 2026-06-06
### Changed
- `marumesh up`이 기본 control plane(`https://marumesh.lab.highmaru.com`)으로 바로 연결되도록 config normalize를 보강했습니다.
- `install-service`의 기본 control plane도 공통 기본값으로 통일하고, `--control`은 서버 변경용 override로 문서화했습니다.
- 한국어 명령어 참조 문서 `docs/commands.md`를 추가했습니다.

## [0.11.34] - 2026-06-06
### Changed
- README 사용법을 현재 `marumesh up/down`, 플랫폼별 `bin/<os>-<arch>` 산출물, 내장 프론트엔드, Docker PostgreSQL, SSO 대시보드 흐름 기준으로 갱신했습니다.

## [0.11.33] - 2026-06-06
### Changed
- `install-server.sh`가 더 이상 별도 static 파일을 복사하거나 `STATIC_PATH`를 강제하지 않도록 정리했습니다.
- systemd 서버 설치가 내장 React 프론트엔드를 사용하는 단일 바이너리 설치 흐름과 맞도록 조정했습니다.

## [0.11.32] - 2026-06-06
### Added
- 서버 바이너리에 React 프론트엔드 dist를 embed해 `STATIC_PATH` 없이도 실행파일 하나로 대시보드를 서빙하도록 했습니다.
### Changed
- `make build`와 `make build-all`이 프론트엔드 dist를 embed 위치로 갱신한 뒤 Go 서버를 빌드하도록 정리했습니다.
- Docker 빌드는 frontend-builder 산출물을 Go builder embed 위치에 복사하고, 최종 이미지에는 별도 정적 파일 디렉터리를 복사하지 않도록 단순화했습니다.

## [0.11.31] - 2026-06-06
### Changed
- Docker Compose v2에서 obsolete 경고가 나오지 않도록 `docker-compose.yml`의 최상위 `version` 필드를 제거했습니다.

## [0.11.30] - 2026-06-06
### Changed
- `frontend/go.mod`를 추가해 루트 `go test ./...`가 npm 의존성 내부 Go 샘플을 테스트 대상으로 포함하지 않도록 분리했습니다.
- `make test`를 추가해 Go 테스트와 프론트엔드 빌드를 한 번에 검증할 수 있도록 했습니다.

## [0.11.29] - 2026-06-06
### Changed
- 프론트엔드 대시보드에서 일반 사용자는 사용자 관리/전역 보안 정책 메뉴에 진입하지 않도록 제한했습니다.
- device 목록에 owner와 접근 상태를 표시해 로그인 사용자가 자신의 device와 공유 device를 구분할 수 있도록 했습니다.

## [0.11.28] - 2026-06-06
### Fixed
- `/api/v1/network/policies` 조회/수정에 인증을 필수화하고, 전역 정책은 superuser만 조회/수정하도록 제한했습니다.
- `/api/v1/devices/share`에 인증 필수 조건을 추가하고 device owner, superuser, 또는 해당 org 권한자만 공유할 수 있도록 보강했습니다.

## [0.11.27] - 2026-06-06
### Added
- 대시보드 세션 확인 API `/api/v1/auth/session`을 추가했습니다.
- React 대시보드가 로그인 전에는 SSO 로그인 화면만 표시하고, 로그인 후 디바이스/관리 화면을 로드하도록 변경했습니다.

### Fixed
- 일반 사용자가 조직 멤버십이 없어도 자신이 소유한 device를 대시보드에서 볼 수 있도록 `/api/v1/status` 필터를 보강했습니다.

## [0.11.26] - 2026-06-06
### Changed
- `.env`의 활성 DB 설정을 Docker PostgreSQL 컨테이너 기준 `host=postgresql user=postgres password=postgres` DSN으로 정리했습니다.
- `cp-server`가 PostgreSQL 컨테이너와 같은 `backend_default` Docker network를 사용하도록 `docker-compose.yml` 외부 네트워크 이름을 맞췄습니다.
- Makefile과 Go 런타임 버전 값을 `0.11.26`으로 다시 정렬했습니다.

## [0.11.25] - 2026-06-06
### Changed
- `make build` 산출물을 `bin/<os>-<arch>/` 아래로 통일해 `bin/marumesh`, `bin/marumesh-server`, 루트 `marumesh-server.exe` 형태가 생기지 않도록 정리했습니다.
- `make build-all`이 Windows 서버 바이너리도 `bin/windows-amd64/marumesh-server.exe`로 생성하도록 보강했습니다.
- macOS `systray` 제약 때문에 `build-all`은 현재 macOS 아키텍처만 native build로 생성하고, 다른 macOS 아키텍처는 해당 플랫폼에서 `make build`로 생성하도록 정리했습니다.
- Dockerfile과 설치 문서가 플랫폼별 `bin/<os>-<arch>/` 경로를 사용하도록 갱신되었습니다.
- 기존에 추적되던 `bin/marumesh`, `bin/marumesh-server`, 루트 `marumesh-server.exe` 산출물을 제거하고 `bin/`을 생성물로 무시하도록 했습니다.

## [0.11.24] - 2026-06-06
### Fixed
- Windows `marumesh up`이 로그인 토큰을 저장한 동일 config 경로로 서비스를 실행하도록 `--config`를 서비스 명령에 포함했습니다.
- `install-service`에도 `--config` 옵션을 추가해 Linux/macOS/Windows 서비스가 명시 config를 사용할 수 있게 했습니다.

## [0.11.23] - 2026-06-06
### Added
- `marumesh up`/`marumesh down` 명령을 추가했습니다.
- `up`은 로그인 정보가 없으면 로그인 URL을 출력하고 토큰을 저장한 뒤 보안 채널을 올립니다. Windows에서는 로그인 후 서비스 등록/시작까지 수행합니다.
- `down`은 플랫폼별 서비스 채널을 중지합니다.

### Fixed
- 로그인 토큰 polling URL이 `localhost:8080`에 고정되던 문제를 수정해 설정된 제어 평면 URL을 사용하도록 했습니다.

## [0.11.22] - 2026-06-06
### Fixed
- `marumesh install-service` 재실행 시 macOS LaunchAgent는 기존 항목을 unload한 뒤 갱신하고, Windows Service는 기존 서비스를 stop/delete 허용 후 다시 등록하도록 보강했습니다.

## [0.11.21] - 2026-06-06
### Fixed
- `marumesh uninstall-service`가 서비스가 이미 없거나 중지된 상태에서도 제거 절차를 계속 진행하도록 보강했습니다.
- 권한 오류처럼 실제 조치가 필요한 실패는 계속 오류로 반환하도록 선별 처리 테스트를 추가했습니다.

## [0.11.20] - 2026-06-06
### Added
- `marumesh uninstall-service` 명령을 추가해 Linux systemd, macOS LaunchAgent, Windows Service 제거를 실행파일 자체에서 수행할 수 있게 했습니다.

## [0.11.19] - 2026-06-06
### Added
- `marumesh install-service`가 Windows 서비스 등록을 지원하도록 확장했습니다.
- Windows 서비스 등록 인자 렌더링 테스트를 추가했습니다.

## [0.11.18] - 2026-06-06
### Added
- `marumesh install-service`가 macOS LaunchAgent 설치를 지원하도록 확장했습니다.
- launchd plist 렌더링 테스트를 추가해 단일 실행파일 서비스 설치 산출물을 검증합니다.

## [0.11.17] - 2026-06-06
### Added
- `marumesh install-service` 명령을 추가해 Linux systemd 서비스 설치를 실행파일 자체에서 수행할 수 있게 했습니다.
- 서비스 설치 명령은 기본적으로 TUN 권한을 사전 점검하고, `--control`, `--mesh-mode`, `--service-path`, `--skip-check` 옵션을 제공합니다.

## [0.11.16] - 2026-06-06
### Changed
- `install.sh`가 바이너리 복사 직후 `marumesh check`를 실행해 TUN 권한 문제가 있으면 서비스 등록 전에 중단하도록 개선했습니다.
- Linux systemd 서비스가 `--mesh-mode tun`을 명시하고 `CONTROL_URL` 환경변수로 제어 평면 주소를 주입받도록 정리했습니다.

## [0.11.15] - 2026-06-06
### Added
- 에이전트 설정과 `marumesh run`에 `mesh_mode`/`--mesh-mode`를 추가해 TUN 모드와 향후 userspace netstack fallback 모드를 명시적으로 구분했습니다.

### Fixed
- 기존 설정 파일에 `mesh_mode` 또는 `tun_name`이 없어도 기본값으로 보정되도록 구성 로딩을 보강했습니다.
- 아직 구현되지 않은 `userspace` Mesh 모드는 조용히 실패하지 않고 명확한 오류를 반환하도록 했습니다.

## [0.11.14] - 2026-06-06
### Added
- `marumesh check` 명령을 추가해 단일 실행파일만으로 로컬 TUN 생성 권한을 사전 점검할 수 있게 했습니다.

### Changed
- TUN 생성 실패 오류에 Linux/macOS/Windows별 권한 및 드라이버 조치 힌트를 포함하도록 개선했습니다.

## [0.11.13] - 2026-06-06
### Changed
- Docker 최종 이미지에서 `wireguard-tools`, `iproute2` 설치를 제거해 외부 `wg`/`ip` CLI 없이 MaruMesh 실행파일로 동작하도록 정리했습니다.
- 설치 문서에 WireGuard userspace 장치는 바이너리에 내장되어 있고, 남은 요구사항은 OS TUN 장치와 권한이라는 설치 경계를 명확히 했습니다.

## [0.11.12] - 2026-06-06
### Fixed
- WireGuard/TUN Mesh 초기화 실패 시에도 로컬 API가 계속 실행되는 degrade 상태를 `/v1/status`의 `mesh_enabled`, `mesh_error` 필드로 노출합니다.
- Mesh 상태 응답 단위 테스트를 추가해 TUN 미초기화 상태가 대시보드/CLI에서 감지 가능하도록 고정했습니다.

## [0.11.11] - 2026-06-06
### Added
- React 대시보드에 `Audit Logs` 화면을 추가하고 `/api/v1/audit/list` API와 연결했습니다.
- 정책/프록시 결정 로그를 시간, source, target, action, effect, rule 기준으로 조회할 수 있게 했습니다.

## [0.11.10] - 2026-06-06
### Added
- React 대시보드의 `Settings` placeholder를 제거하고 계정 정보와 조직 필터 설정 화면을 추가했습니다.
- 저장된 조직 필터가 dashboard status 조회에 즉시 반영되도록 연결했습니다.

## [0.11.9] - 2026-06-06
### Security
- `npm audit fix`로 프론트엔드 lockfile의 Vite/PostCSS/glob 파서 계열 취약점을 해소했습니다.
- `npm audit` 기준 취약점 0건을 확인했습니다.

## [0.11.8] - 2026-06-06
### Added
- React 대시보드의 `Share Agent` 다이얼로그를 실제 `/api/v1/devices/share` API와 연결했습니다.
- 공유 대상 조직 입력, 재공유 허용 스위치, 제출 상태와 오류 표시를 추가했습니다.

## [0.11.7] - 2026-06-06
### Added
- React 대시보드의 `Security Rules` 화면을 실제 `/api/v1/network/policies` API와 연결했습니다.
- 전역 정책 조회, 행 추가/삭제, allow/deny 선택, 관리자 저장 UI를 추가했습니다.

## [0.11.6] - 2026-06-06
### Security
- OAuth 로그인 `state` 값을 HMAC 서명해 callback에서 검증하도록 변경했습니다.
- 변조된 OAuth state와 빈 subject를 거부하는 단위 테스트를 추가했습니다.

## [0.11.5] - 2026-06-06
### Security
- `JWT_SECRET` 미설정 시 고정 기본 시크릿을 사용하던 동작을 제거했습니다.
- 로컬 개발에서만 `MARUMESH_DEV_INSECURE_JWT=true`로 명시적 임시 시크릿을 허용하도록 변경했습니다.

### Added
- JWT secret 로딩 정책 단위 테스트와 설치 문서의 필수 `JWT_SECRET` 설명을 추가했습니다.

## [0.11.4] - 2026-06-06
### Changed
- 프론트엔드 의존성을 설치한 상태에서 `npm run build`가 통과함을 확인하고 lockfile 메타데이터를 현재 npm 결과에 맞게 정리했습니다.

### Known Issues
- `npm install` 기준으로 moderate 3건, high 2건의 npm audit 취약점이 남아 있습니다.

## [0.11.3] - 2026-06-06
### Changed
- `POST /v1/proxy/tcp`가 `target_id`를 제어 평면 peer 목록에서 조회해 대상 장치의 `virtual_ip:remote_port`로 프록시를 생성하도록 변경했습니다.
- 프록시 요청의 필수 입력과 터널 매니저/제어 평면 초기화 상태를 명확히 검증하도록 보완했습니다.

### Added
- 로컬 프록시가 제어 평면에서 해석한 peer virtual IP로 실제 TCP payload를 전달하는 API 테스트를 추가했습니다.

## [0.11.2] - 2026-06-06
### Changed
- 로컬 에이전트 API의 `GET /v1/devices`가 고정 mock 데이터 대신 제어 평면의 peer 목록을 반환하도록 변경했습니다.
- 제어 평면 peer 조회 실패 시 로컬 API가 `503 Service Unavailable`을 반환하도록 오류 처리를 명확히 했습니다.

### Added
- `/v1/devices`가 자기 자신을 제외하고 원격 peer 정보를 변환하는지 검증하는 API 단위 테스트를 추가했습니다.

## [0.11.1] - 2026-06-06
### Fixed
- ICE 연결을 실제 `Dial`/`Accept` 기반으로 시작하도록 수정하고, Pion ICE `Conn`을 `net.PacketConn`으로 어댑트해 `ReadFrom`/`WriteTo` 데이터 경로를 구현했습니다.

### Added
- 외부 STUN 의존 없이 host candidate만으로 ICE peer 간 payload 전송을 검증하는 네트워크 단위 테스트를 추가했습니다.

## [0.11.0] - 2026-03-20
### Added
- **GORM Persistence**: Support for SQLite, PostgreSQL, and MySQL databases.
- **JWT Authentication**: Enhanced security with JSON Web Token-based authentication.
- **Admin User Management**: New dashboard section for system-wide user and device monitoring.
- **Reorganized CLI**: Specialized `marumesh-agent` and `marumesh-ctl` commands.

### Changed
- Refactored all backend handlers to use unified `getTokenUser` authentication.
- Updated Agent `control.Client` to support JWT `Authorization` headers.
- Enhanced database robustness with custom JSON type handlers.

## [0.10.0] - 2026-03-17

### Added (추가)
- **Quick Connect (원클릭 연결)**: 트레이 메뉴에서 SSH 및 웹 서비스를 즉시 실행하는 기능.
- **서비스 접근 제어**: 장치 소유자가 허용할 포트 및 연결 앱(터미널 등)을 직접 설정 가능.
- **OS 네이티브 터미널 연동**: macOS(Terminal.app) 및 Windows(Windows Terminal) 자동 감지 및 명령 실행.

## [0.9.0] - 2026-03-18

### Added (추가)
- **가입 위저드 (Joining Wizard)**: 초대 수락 시 장치 공유를 함께 진행하는 온보딩 가이드 모달.
- **장치 일괄 공유**: 가입 프로세스 중 여러 장치를 한 번에 조직에 공유하는 백엔드 로직.
- **개선된 UI/UX**: 정적 확인창(confirm)을 동적 모달 인터페이스로 교체.

## [0.8.0] - 2026-03-18

### Added (추가)
- **RBAC (역할 기반 접근 제어)**: Admin, Member, Viewer 중심의 세부 권한 체계 구축.
- **멤버 관리 인터페이스**: 조직원 리스트 조회 및 실시간 역할 변경 API/UI 구현.
- **Dynamic UI Control**: 사용자 권한에 따른 대시보드 기능(초대, 정책 수정 등) 자동 활성화/비활성화.

## [0.7.0] - 2026-03-18

### Added (추가)
- **멤버십 관리**: 조직별 멤버(이메일 기반) 리스트 관리 및 가입 승인 로직.
- **보안 필터링**: 인증된 멤버만 자신의 조직 및 공유받은 리소스에 접근할 수 있도록 API 레벨의 권한 검증 도입.
- **초대 수락 랜딩**: 브라우저 URL 파라미터를 통한 자동 초대 감지 및 확인 팝업 UI.

## [0.6.0] - 2026-03-18

### Added (추가)
- **초대 시스템**: 조직 참여를 위한 만료 방식의 보안 초대 링크 생성 및 검증 기능.
- **장치 공유 엔진**: 타 조직에 장치를 안전하게 공유하고, 공유받은 목록을 통합 모니터링하는 인프라 구축.
- **재공유 권한 제어**: 수신자의 재공유 가능 여부를 설정할 수 있는 소유자 권한 관리 기능.

## [0.5.0] - 2026-03-18

### Added (추가)
- **Kubernetes 배포 자동화 (Helm Chart)**: MaruMesh 제어 평면 서버를 위한 공식 Helm Chart 서비스 시작.
- **클라우드 네이티브 지원**: PVC(영구 볼륨), Ingress, Secret 템플릿을 포함한 표준 배포 구성.
- **운영 가이드**: [KUBERNETES.md](docs/KUBERNETES.md) 배포 매뉴얼 추가.

## [0.4.1] - 2026-03-18

### Added (추가)
- **조직별 맞춤형 정책(ACL)**: 개별 조직이 독자적인 네트워크 보안 규칙을 정의하고 강제할 수 있는 기능 추가.
- **조직 정책 관리자**: 대시보드 내 조직 관리 탭에서 특정 조직의 정책을 실시간으로 편집할 수 있는 전용 UI 구현.

## [0.4.0] - 2026-03-18

### Added (추가)
- **멀티테넌시(Multi-tenancy) 기반 구축**: 조직(Organization) 및 팀(Team) 데이터 모델과 관리 인프라 도입.
- **조직 관리 UI**: 대시보드에 조직 생성 및 관리 탭 추가, 에이전트 목록의 조직별 가시화 지원.
- **지속성 강화**: `devices.json`에 조직 및 팀 정보를 영구 보관하는 기능 구현.

## [0.3.1] - 2026-03-18

### Added (추가)
- **중앙 집중형 감사 로그(Centralized Audit Log)**: 에이전트의 보안 위반 및 접속 이벤트를 제어 평면 서버로 실시간 수집하는 기능 추가.
- **통합 로그 대시보드**: 웹 관리 페이지에서 모든 에이전트의 로그를 한곳에서 볼 수 있는 실시간 뷰어 추가.

## [0.3.0] - 2026-03-18

## [0.2.2] - 2026-03-18

## [0.2.1] - 2026-03-18

## [0.2.0] - 2026-03-18

### Added (추가)
- **백엔드 통합 인증 (Polling Auth)**: 에이전트가 로컬 콜백 포트를 열지 않고 서버(8080)를 통해 인증 토큰을 획득하는 폴링 방식 도입.
- **다중 에이전트 환경 지원**: 동일 기기에서 Alice, Bob 등 여러 에이전트를 독립된 작업 디렉토리와 소켓으로 실행 가능하도록 개선.
- **통합 설치 가이드**: 서버와 에이전트의 플랫폼별 설치 및 실행 방법을 정리한 `docs/install_guide.md` 추가.
- **시스템 트레이 아이콘**: macOS 및 Windows 환경에서 에이전트 상태를 확인할 수 있는 트레이 아이콘 및 메뉴 추가.

### Changed (변경)
- **실제 Google OAuth2 연동**: Mock 인증을 실제 구글 계정 연동 및 세션 관리(쿠키) 구조로 업그레이드.
- **대시보드 기능 고도화**: 네트워크 맵, 에이전트 승인, 전역 규칙 설정 등 모든 사이드바 메뉴 활성화.
- **테스트 스크립트 개선**: `test-local.sh`에서 에이전트별 홈 디렉토리를 분리하여 IP 충돌 해결.

### Fixed (수정)
- 이전 에이전트들이 같은 가상 IP(10.0.0.x)를 할당받던 식별자 충돌 문제 해결.
- 대시보드 JS 내 변수 참조(urlParams) 및 관리자 권한 확인 로직 버그 수정.

---

## [0.1.0] - 2026-03-16
- 초기 릴리스: 기본 P2P 네트워킹 및 초기 대시보드 프로토타입 구현.
