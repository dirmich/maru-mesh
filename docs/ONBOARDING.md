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
5. `docs/vs_tailscale.md`: Tailscale과 같은 점/다른 점, MaruMesh가 만족해야 할 UX 기준.
6. `CHANGELOG.md`: 버전별 변경 기록.

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

MaruMesh virtual IP 기본 대역은 `100.64.0.0/24`입니다. 기존 사내망/VPN/클라우드 라우팅과 겹치면 control plane `.env`의 `MARUMESH_VIRTUAL_CIDR`을 먼저 변경합니다. 클라이언트는 할당받은 CIDR이 로컬 인터페이스 대역과 겹치면 경고를 남겨야 합니다.

## 8. 작업 규칙

- 문서와 커밋 메시지는 한국어를 기본으로 작성합니다.
- 작업 단위가 끝나면 관련 문서를 즉시 갱신합니다.
- source repo에서 commit/push를 수행합니다.
- public 문서와 release는 `publish.sh`로 갱신합니다.
- `.env` 같은 로컬 민감 파일은 삭제하지 말고, Git 추적에서도 제외합니다.
- 사용자가 만든 미커밋 변경은 되돌리지 않습니다. 충돌하면 먼저 상태를 확인하고 그 변경 위에서 작업합니다.

## 9. Publish 절차

사용자가 “publish”라고 지시하면 문서 동기화만 하지 말고 전체 publish 절차를 수행합니다. source repo에서 수정, 검증, commit이 끝난 뒤 다음을 실행합니다.

```bash
./publish.sh
```

`publish.sh` 기본 동작:

- `Makefile`의 `VERSION`을 읽어 `v<VERSION>` release tag를 사용합니다.
- `make test`와 `make release-assets`를 실행합니다.
- macOS asset이 있으면 Developer ID 서명과 notarization을 수행합니다.
- source branch에 push되지 않은 commit이 있으면 push합니다.
- 최상위 `README*.md`와 `docs/`를 `../marumesh-pub`에 동기화하고 public repo에 commit/push합니다.
- `install.sh`, `install.ps1`도 public repo root로 동기화합니다. 공식 설치 진입점은 control plane `/install.sh`가 아니라 GitHub raw URL입니다.
- `dirmich/maru-mesh` GitHub Release를 생성하거나 기존 asset을 덮어씁니다.
- `README-ja.md`, `README-zh.md` 같은 다국어 README는 `README*.md` 패턴으로 자동 동기화됩니다.

빠른 문서 동기화만 필요할 때:

```bash
./publish.sh --docs-only
```

일반 publish는 release 업로드 전에 항상 `make release-assets`로 바이너리를 새로 만듭니다. `--docs-only`는 문서만 public repo에 동기화하고 release upload를 수행하지 않습니다.
사용자가 명시적으로 “문서만”, “docs-only”라고 말한 경우에만 `--docs-only`를 사용합니다.
사용자가 명시적으로 “서명 없이”, “macOS 서명 건너뛰기”라고 말하지 않으면 `--skip-macos-sign`을 사용하지 않습니다.

실행 전 확인:

```bash
./publish.sh --dry-run
```

### macOS Gatekeeper 대응

public GitHub Release에 올리는 `marumesh-darwin-*` 바이너리는 Apple Developer ID 서명과 notarization이 필요합니다. 서명/공증 없이 배포하면 macOS에서 “악성코드가 없음을 확인할 수 없습니다” 경고가 뜨고 실행이 차단될 수 있습니다.
GitHub에서 직접 다운로드해 더블클릭할 macOS `.pkg`는 App Store Connect용 `*-appstore.pkg`가 아니라 Developer ID Installer로 서명하고 notarization ticket을 stapling한 `MaruMesh-<version>-darwin-<arch>.pkg`여야 합니다.
`publish.sh`는 macOS asset이 있는데 서명/공증 설정이 없으면 release upload 전에 실패해야 합니다. 경고만 보고 unsigned macOS binary를 public release에 올리지 않습니다.

publish 환경에 Developer ID 인증서가 설치되어 있으면 다음 환경 변수로 서명/공증을 활성화합니다.

```bash
export MACOS_SIGN_IDENTITY="Developer ID Application: <Name> (<TEAM_ID>)"
export MACOS_NOTARY_PROFILE="marumesh-notary"
./publish.sh
```

keychain profile 대신 Apple ID credential을 직접 사용할 수도 있습니다.

```bash
export MACOS_SIGN_IDENTITY="Developer ID Application: <Name> (<TEAM_ID>)"
export MACOS_NOTARY_APPLE_ID="<apple-id>"
export MACOS_NOTARY_TEAM_ID="<team-id>"
export MACOS_NOTARY_PASSWORD="<app-specific-password>"
./publish.sh
```

테스트 목적으로만 Gatekeeper quarantine을 제거할 수 있습니다. public 배포 해결책으로 사용하지 않습니다.

```bash
xattr -d com.apple.quarantine ./marumesh
```

직접 다운로드용 macOS installer package:

```bash
export MACOS_SIGN_IDENTITY="Developer ID Application: Highmaru, Inc. (X4V7W6GE8X)"
export MACOS_INSTALLER_IDENTITY="Developer ID Installer: Highmaru, Inc. (X4V7W6GE8X)"
export MACOS_NOTARY_PROFILE="marumesh-notary"
make macos-pkg
```

출력은 `dist/macos/MaruMesh-<version>-darwin-<arch>.pkg`입니다. 생성 후 GitHub Release에 이 asset을 올립니다. `MaruMesh-<version>-darwin-<arch>-appstore.pkg`는 App Store Connect 업로드용이며 GitHub 직접 설치용으로 안내하지 않습니다.

### Mac App Store 패키징

Mac App Store Connect 업로드용 산출물은 GitHub Release용 Developer ID/notarization 배포와 다른 경로입니다. 내부 절차는 `docs/app_store.md`에만 기록하고, 해당 문서는 public repo에 동기화하지 않습니다.

현재 제공하는 `make appstore-pkg`는 Apple Distribution으로 `.app`을 서명하고 3rd Party Mac Developer Installer로 `.pkg`를 생성하는 패키징 단계입니다. 현재 CLI/TUN/root 권한 기반 구조가 App Store 심사를 그대로 통과한다는 의미는 아닙니다. 최종 App Store 등록판은 sandbox와 Network Extension 기반 구조로 별도 보강해야 합니다.

```bash
export APPSTORE_APP_IDENTITY="Apple Distribution: Highmaru, Inc. (X4V7W6GE8X)"
export APPSTORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Highmaru, Inc. (X4V7W6GE8X)"
make appstore-pkg
```

Codex shell에서 keychain identity가 보이지 않으면 login shell로 실행합니다.

```bash
/bin/zsh -lc 'make appstore-pkg'
```

## 10. 배포 URL

Client install URL:

```bash
curl -fsSL https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.sh | sh
```

Windows:

```powershell
iwr https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.ps1 -UseB | iex
```

설치 스크립트는 public repo root에 두고 GitHub raw URL로 제공합니다. 스크립트는 public GitHub Releases에서 client binary를 다운로드합니다.

```text
https://github.com/dirmich/maru-mesh/releases/latest/download
```

## 11. 자주 깨지는 경계

- 기본 control URL이 다시 `localhost:8080`으로 돌아가면 안 됩니다.
- license verify endpoint는 `/api/v1/license/verify`와 legacy `/v1/license/verify` 호환을 유지합니다.
- `marumesh up` 기본 실행에서 내부 JSON 로그를 쏟지 않습니다. 상세 로그는 `--debug`에서만 출력합니다.
- `up`은 foreground daemon처럼 붙잡고 있지 않고, mesh 준비 후 반환해야 합니다.
- Linux `tun` 모드의 `up`은 로그인/등록 전에 TUN 권한 preflight를 먼저 수행해야 합니다. 권한이 없으면 device 등록을 만들지 않고 sudo/service 사용을 안내합니다.
- `down`은 local API shutdown을 먼저 시도하고, 그 다음 service stop을 시도합니다. systemd 권한 실패는 `sudo marumesh down` 또는 `sudo systemctl stop marumesh`를 안내합니다.
- macOS TUN 이름은 `utun` 계열이어야 하며, 정상 연결 후 `ifconfig`에 VIP가 보여야 합니다.
- Windows `up`은 로그인 token이 저장된 config 경로를 서비스 실행에 명시해야 합니다.
- frontend는 시작 시 SSO 세션을 확인하고 미로그인 상태에서는 login screen만 보여야 합니다.
- 일반 사용자는 자기 device와 공유받은 device 중심으로 보고, superuser만 전체 사용자/device와 전역 정책을 관리합니다.
- 같은 `device_id` 재등록은 새 row를 만들지 않고 기존 device를 갱신해야 합니다.
- device 재등록 또는 SSO 로그인 시 기존 이름을 덮어쓰지 않습니다. 이름 변경은 dashboard/API의 device rename 경로로만 수행합니다.
- 같은 owner 안에서는 DNS 정규화 기준으로 device 이름이 중복되면 안 됩니다.
- peer 이름은 `dev`, `dev.maru`, `<device-id>.maru` 형태로 내장 MagicDNS와 hosts fallback에 반영합니다. `.maru` 이름은 OS resolver 경로로, short name은 hosts fallback으로 지원합니다. 권한이 없으면 경고만 남기고 VPN 연결 자체는 계속 진행합니다.
- `marumesh version`은 현재 binary 버전을 출력하고, `marumesh upgrade`는 public repo raw installer를 통해 최신 release로 갱신해야 합니다.
- macOS menubar와 Windows tray에는 아이콘이 보여야 합니다. macOS는 template PNG, Windows는 ICO asset을 사용합니다.

## 12. 현재 남은 큰 과제

- ICE/WireGuard E2E 실제 패킷 통신 안정화.
- TUN 없는 userspace netstack fallback 구현 여부 결정.
- 조직/팀 단위 device 및 policy 그룹화.
- Apple Silicon macOS native release asset 자동화.
