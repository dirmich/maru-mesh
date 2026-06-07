# MaruMesh Session Context (세션 지속성 가이드)

이 문서는 새로운 AI 에이전트 세션이 시작될 때 현재 프로젝트의 상태와 작업 규칙을 즉시 동기화하기 위해 작성되었습니다.

## 📌 현재 프로젝트 상태
- **현재 버전**: `0.11.63`
- **주요 구현 완료 사항**:
    - **백엔드 통합 인증(Polling Auth)**: 서버(8080) 단일 포트 기반 인증 체계.
    - **다중 에이전트 테스트**: `alice_home`, `bob_home` 분리를 통한 동일 기기 내 다중 실행 환경.
    - **웹 대시보드 고도화**: 실시간 네트워크 맵, 기기 승인, 정책 관리 연동 완료.
    - **배포 가이드**: `docs/install_guide.md` 및 `install-server.sh` 구축.
    - **ICE 데이터 경로 보강**: Pion ICE `Conn`을 `net.PacketConn`으로 연결하여 ICE peer 간 payload 전송 단위 테스트 통과.
    - **로컬 장치 목록 실데이터화**: `/v1/devices`가 제어 평면 peer 목록을 기반으로 원격 장치를 반환하도록 개선.
    - **TCP 프록시 대상 해석**: `/v1/proxy/tcp`가 `target_id`를 peer `virtual_ip`로 해석해 실제 원격 주소로 프록시를 생성.
    - **프론트엔드 빌드 검증**: `frontend` 의존성 설치 후 `npm run build` 통과 확인.
    - **JWT 시크릿 정책 강화**: 운영 기본 JWT 시크릿 제거, `JWT_SECRET` 필수화.
    - **OAuth state 검증 강화**: 로그인 state에 HMAC 서명을 적용해 callback 변조를 거부.
    - **Security Rules UI 연동**: React 대시보드에서 전역 정책 조회/추가/삭제/저장 가능.
    - **Share Agent UI 연동**: React 대시보드에서 장치 공유 API 호출 가능.
    - **프론트엔드 npm audit 정리**: `npm audit fix` 적용 후 취약점 0건 확인.
    - **Settings UI 구현**: 조직 필터 설정과 계정 정보를 실제 화면으로 제공.
    - **Audit Logs UI 구현**: 중앙 감사 로그 조회 화면을 `/api/v1/audit/list`와 연결.
    - **Mesh degrade 상태 노출**: WireGuard/TUN 초기화 실패를 `/v1/status`의 `mesh_enabled`, `mesh_error`로 확인 가능.
    - **단일 실행파일 설치 경계 정리**: 외부 `wg`/`ip` CLI 패키지 의존성을 제거하고 OS TUN 권한만 요구사항으로 문서화.
    - **설치 사전 점검 명령 추가**: `marumesh check`로 TUN 생성 권한을 확인하고 OS별 조치 힌트를 출력.
    - **Mesh 모드 설정 추가**: `mesh_mode`/`--mesh-mode`로 `tun`과 향후 `userspace` fallback을 명시적으로 구분.
    - **Client 설치 스크립트**: `install.sh`/`install.ps1`이 public 배포 repo `dirmich/maru-mesh`의 GitHub Releases에서 client 바이너리를 받아 설치하고 `CONTROL_URL` 환경변수를 반영.
    - **실행파일 자체 서비스 설치**: `marumesh install-service`로 Linux systemd, macOS LaunchAgent, Windows Service 설치 가능.
    - **실행파일 자체 서비스 제거**: `marumesh uninstall-service`로 플랫폼별 서비스 제거 가능.
    - **서비스 제거 멱등성 보강**: 이미 중지/삭제된 서비스 제거 시에도 정리 절차를 계속 진행.
    - **서비스 설치 재실행 보강**: macOS/Windows에서 기존 서비스가 있어도 install-service가 갱신 설치를 수행.
    - **up/down CLI 추가**: `marumesh up`은 로그인 후 보안 채널을 올리고, Windows에서는 서비스 실행까지 처리. `marumesh down`은 채널을 중지.
    - **서비스 config 경로 고정**: Windows `up`과 `install-service --config`가 로그인 토큰이 저장된 설정 파일을 서비스 실행에 명시.
    - **플랫폼별 빌드 산출물 정리**: 바이너리는 `bin/<os>-<arch>/` 아래에 생성되며 Windows 서버도 `bin/windows-amd64/marumesh-server.exe`로 생성. macOS는 systray 제약상 native arch 빌드로 생성하며 Intel은 `darwin-amd64`, Apple Silicon(M1/M2/M3/M4)은 `darwin-arm64`.
    - **Docker PostgreSQL 연결 정리**: `.env`는 `postgres/postgres` 계정으로 `postgresql` 컨테이너를 사용하고, compose는 `backend_default` 네트워크를 사용.
    - **프론트엔드 SSO 게이트 적용**: 로그인 전에는 SSO 화면만 표시하고, 로그인 후 사용자 device 목록/관리 화면을 로드.
    - **대시보드 API 권한 보강**: 정책 API와 device 공유 API에 인증/권한 검사를 강화.
    - **대시보드 권한별 메뉴 정리**: 일반 사용자는 자기 device/공유 device 중심으로 보고, superuser만 사용자 관리와 전역 보안 정책 메뉴를 사용.
    - **테스트 경계 정리**: `frontend/go.mod`로 루트 Go 테스트가 npm 의존성 내부 Go 샘플을 포함하지 않도록 분리하고, `make test`를 추가.
    - **Docker Compose v2 경고 정리**: 최상위 `version` 필드를 제거해 obsolete 경고를 없앰.
    - **서버 단일 실행파일 프론트 내장**: React dist를 서버 바이너리에 embed해 별도 정적 파일 복사 없이 대시보드 서빙 가능.
    - **서버 설치 스크립트 단일 바이너리화**: `install-server.sh`가 별도 static 복사/`STATIC_PATH` 강제 없이 내장 프론트를 사용.
    - **README 사용법 최신화**: `marumesh up/down`, 플랫폼별 `bin/<os>-<arch>` 산출물, 내장 프론트, Docker PostgreSQL, SSO 대시보드 흐름 반영.
    - **CLI 기본 서버/명령 문서 정리**: `marumesh up`은 기본 control plane으로 바로 연결하고, `--control`은 서버 변경용 override로 정리. 한국어 명령 문서 `docs/commands.md` 추가.
    - **Tray 대시보드 URL 정리**: Windows/macOS tray의 `Open Dashboard`가 현재 control plane URL을 열도록 수정.
    - **connect 명령 실제 동작 연결**: `marumesh connect <target> --remote-port <port>`가 로컬 TCP proxy를 생성하도록 정리.
    - **TCP proxy 자동 포트 응답 보강**: `local_port: 0` 사용 시 실제 OS 할당 포트를 `proxy_address`로 반환.
    - **Docker Linux 빌드 수정**: tray stub 시그니처를 desktop 구현과 맞춰 headless/Linux 빌드 실패를 해결.
    - **민감정보 파일 정리**: 실제 `.env`는 로컬 파일을 유지한 채 Git 추적에서 제거하고, `.gitignore`에 추가. `.env.example`/문서/테스트 스크립트는 placeholder 기반으로 정리.
    - **README 언어 분리**: `README.md`는 영어, `README-ko.md`는 최신 한국어 사용법으로 정리.
    - **License verify 경로 호환**: `/api/v1/license/verify`와 legacy `/v1/license/verify`를 모두 지원하고, agent 오류 메시지에 응답 body를 포함.
    - **PostgreSQL JSON scan 보강**: text 컬럼 JSON 필드가 string으로 반환되어도 정상 decode되도록 수정.
    - **CLI up 플랫폼별 tray 기본값**: macOS `marumesh up`은 기본 menubar tray를 표시하고, Linux는 기본 headless로 실행.
    - **Client install URL**: HAProxy 뒤 Docker control plane에서 `/install.sh`, `/install.ps1`을 제공하고 GitHub Releases의 client 바이너리를 설치하도록 정리. 공식 테스트 URL은 `https://marumesh.lab.highmaru.com`.
    - **Docker env_file 정리**: `docker-compose.yml`은 서버 환경 변수를 `env_file: .env`로 전달하고, `HOST_PORT=8000`, `PORT=8080` 기본 매핑을 사용.
    - **PostgreSQL DSN 파싱 보강**: database 자동 생성 fallback이 password 특수문자와 URL DSN을 포함한 DSN에서 database 이름을 안정적으로 파싱.
    - **Policy sync 오류 진단 개선**: control plane policy sync 실패 시 JSON 파싱 오류 대신 HTTP status/body를 포함한 오류를 표시.
    - **SSO 기반 device 등록 보강**: `marumesh up` 로그인 URL에 기기 이름을 포함하고, Google SSO 사용자와 hostname을 device owner/name으로 저장.
    - **up 기본 control URL 고정**: 기존 config에 localhost가 남아 있어도 `marumesh up`은 `--control`이 없으면 공식 기본 서버를 사용.
    - **up 로그 quiet 기본값**: `marumesh up`은 기본적으로 내부 JSON 로그를 숨기고, `--debug`에서만 상세 진단 로그를 출력.
    - **up 백그라운드 실행**: `marumesh up` 기본 실행은 로그인 후 `run` daemon을 백그라운드로 시작하고 즉시 반환하며, `down`은 로컬 API shutdown으로 종료.
    - **device 관리 보강**: 동일 device 재등록은 기존 row를 갱신하고, 최종 로그인 시간/기기 이름을 대시보드에 표시하며 owner/superuser가 이름을 수정 가능.
    - **TUN 인터페이스 표시 보강**: macOS 기본 TUN 이름을 `utun`으로 보정하고, VIP를 OS 인터페이스에 설정해 `ifconfig`에서 확인 가능하게 수정.
    - **WireGuard IPC key 포맷 수정**: device IPC에는 hex key를 전달하고 control plane/API에는 base64 key를 유지하도록 분리.
    - **device 삭제/재등록 flow 보강**: 대시보드에서 owner/superuser가 device를 삭제 가능하며, 삭제된 device의 `up`은 SSO 등록 flow를 다시 수행.
    - **device 삭제 강제 로그아웃**: 삭제 시 pending token을 폐기하고 실행 중인 agent가 삭제/권한 회수를 감지하면 로컬 token을 지우고 종료.
    - **CLI SSO polling 표시 보강**: SSO timeout을 정상 동작하게 수정하고 로그인 완료/보안 채널 시작 메시지를 출력.
    - **CLI SSO polling 진단 보강**: token polling 요청에 HTTP timeout을 적용하고 대기 메시지를 주기적으로 출력해 SSO 완료 후 멈춘 것처럼 보이는 상황을 진단 가능하게 개선.
    - **macOS sudo 기본 브라우저 보정**: `sudo marumesh up`에서 SSO URL을 root가 아닌 로그인 사용자 세션의 기본 브라우저로 열도록 개선.
    - **CLI SSO 중복 로그인 방지**: 새 SSO token을 받은 직후 device를 선등록해 백그라운드 agent가 같은 실행에서 SSO 로그인 페이지를 다시 열지 않도록 개선.
    - **macOS/Windows tray menu 보강**: `marumesh up` 기본 실행에서 macOS menubar를 표시하고 Windows tray도 유사 메뉴를 제공하며, Close 시 VPN/TUN cleanup 및 tray 종료를 수행하고 로그인 사용자/소유/공유 device 목록을 표시.
    - **Public 배포 repo 분리**: 원본 소스는 private repo에서 관리하고, 문서/Release asset은 public repo `dirmich/maru-mesh`에 동기화.

## 🛠️ 개발 및 배포 규칙 (필수 준수)
1. **언어**: 모든 소통과 문서는 **한국어**를 기본으로 함.
2. **버전 관리**: 
    - 작업이 완료될 때마다 반드시 버전을 최소 패치 단위(`0.0.1`) 이상 상향 조정함.
    - 버전에 따른 변경 사항은 `CHANGELOG.md`에 기록함.
3. **Git 워크플로우**: 작업 후 반드시 `git commit` 및 `git push`를 수행하며, 커밋 메시지는 한국어로 작성함.
4. **연속성 유지**: 새로운 세션 시작 시 이 파일을 먼저 읽어 현재 위치를 파악함.

## 🚀 주요 실행 명령어
- **로컬 테스트**: `./test-local.sh` (서버 1개 + 에이전트 2개 자동 실행)
- **서버 빌드**: `make build` (`bin/<os>-<arch>/` 아래 생성)
- **도커 배포**: `docker-compose up --build`

## 🎯 다음 작업 목표 (Next Steps)
- **WireGuard E2E 안정화**: ICE transport 위에서 WireGuard 가상 IP 기반 실제 패킷 통신을 통합 검증.
- **단일 실행파일 설치 강화**: 필요 시 userspace netstack fallback 전략을 구현.
- **조직 관리**: 팀 단위 기기 및 정책 그룹화 기능.

---
*마지막 업데이트: 2026-06-06 (GMT+9)*
