# MaruMesh

SSO 로그인 기반으로 장치를 등록하고, WireGuard 사용자 공간 터널과 ICE 경로를 통해 보안 채널을 구성하는 크로스 플랫폼 mesh agent/control plane입니다.

## 핵심 기능

- `marumesh up|down` CLI로 로그인, 토큰 저장, 보안 채널 연결/중지를 처리합니다.
- `marumesh up`은 기본 control plane(`https://marumesh.lab.highmaru.com`)에 연결합니다.
- 로그인 정보가 없으면 `marumesh up`이 SSO 로그인 URL을 출력합니다.
- 로그인 정보가 있으면 `marumesh up`이 저장된 토큰으로 control plane에 로그인하고 보안 채널을 백그라운드로 올린 뒤 종료됩니다.
- Windows에서는 로그인 후 같은 config 경로를 서비스 실행에 명시해 서비스까지 시작합니다.
- WireGuard는 Go 의존성 기반 사용자 공간 구현을 사용하며, 별도 `wg`/`ip` CLI 패키지에 의존하지 않습니다.
- 서버 실행파일은 React 대시보드를 내장하므로 별도 static 파일 복사 없이 UI를 서빙합니다.
- 대시보드는 시작 시 SSO 세션을 확인하고, 미로그인 상태에서는 로그인 화면만 표시합니다.
- 일반 사용자는 자신의 device/공유 device, 기기 이름, 최종 로그인 시간을 확인하고 자기 소유 기기 이름 수정/삭제를 할 수 있습니다. Superuser는 모든 사용자의 device와 전역 정책/사용자 관리 메뉴를 볼 수 있습니다.

## 빌드

```bash
make build
```

현재 플랫폼용 CLI와 서버 바이너리는 아래에 생성됩니다.

```text
bin/<os>-<arch>/marumesh
bin/<os>-<arch>/marumesh-server
```

전체 배포용 빌드:

```bash
make build-all
make release-assets
```

Windows 서버 바이너리는 `bin/windows-amd64/marumesh-server.exe`에 생성됩니다. `make release-assets`는 GitHub Release 업로드용 파일을 `dist/` 아래에 생성합니다. macOS 빌드는 systray 제약 때문에 macOS 호스트에서 native arch로 생성합니다. Intel Mac은 `darwin-amd64`, Apple Silicon(M1/M2/M3/M4)은 `darwin-arm64`입니다.

## 검증

```bash
make test
```

`make test`는 React 프론트엔드 dist를 서버 embed 경로로 갱신한 뒤 Go 테스트를 실행합니다.

## Control Plane 실행

### Docker Compose

`.env.example`을 `.env`로 복사한 뒤 Docker PostgreSQL 컨테이너 `postgresql`을 사용하도록 필요한 값을 채웁니다. 같은 Docker network에 있어야 하므로 `postgresql` 컨테이너가 `backend_default` 네트워크에 연결되어 있어야 합니다.

```bash
cp .env.example .env
docker network connect backend_default postgresql
docker compose up --build
```

대시보드:

```text
http://localhost:8000
```

Docker Compose는 `env_file`로 `.env` 전체를 컨테이너에 전달합니다. `HOST_PORT`는 호스트 공개 포트이고, `PORT`는 컨테이너 내부 서버 포트입니다. 기본 매핑은 `8000:8080`입니다.

### 단일 서버 실행파일

```bash
./bin/linux-amd64/marumesh-server
```

서버 바이너리는 React 대시보드를 내장합니다. `STATIC_PATH`를 지정하면 외부 정적 파일을 우선 서빙하고, 지정하지 않으면 내장 프론트엔드를 사용합니다.

Linux systemd 설치 스크립트:

```bash
./install-server.sh
```

`install-server.sh`는 서버 바이너리만 복사하며 별도 static 파일을 복사하지 않습니다.

## Agent/CLI 사용

Client install URL:

```bash
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
marumesh up
```

Windows client install URL:

```powershell
iwr https://marumesh.lab.highmaru.com/install.ps1 -UseB | iex
marumesh up
```

설치 URL은 GitHub Releases에서 client 바이너리를 다운로드합니다. Release asset 이름은 `marumesh-linux-amd64`, `marumesh-linux-arm64`, `marumesh-darwin-amd64`, `marumesh-darwin-arm64`, `marumesh-windows-amd64.exe` 형식을 사용합니다.

Linux 예:

```bash
sudo install -m 0755 ./bin/linux-amd64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

macOS Intel:

```bash
sudo install -m 0755 ./bin/darwin-amd64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

macOS Apple Silicon(M1/M2/M3/M4):

```bash
sudo install -m 0755 ./bin/darwin-arm64/marumesh /usr/local/bin/marumesh
marumesh up
marumesh down
```

서비스 등록:

```bash
sudo marumesh install-service
sudo marumesh uninstall-service
```

Windows 예:

```powershell
C:\MaruMesh\marumesh.exe up
C:\MaruMesh\marumesh.exe down
C:\MaruMesh\marumesh.exe uninstall-service
```

Windows의 `up`은 로그인 토큰이 저장된 config 경로를 서비스 실행 명령에 명시합니다.
기본 서버가 아닌 다른 control plane에 연결할 때만 `--control https://mesh.example.com`을 추가합니다.
`marumesh up`은 보안 채널을 백그라운드로 시작하고 명령은 바로 종료됩니다. foreground daemon이 필요할 때만 `marumesh run`을 사용하고, 상세 진단 로그가 필요할 때는 `marumesh up --debug`를 사용합니다.
`tun` 모드에서는 `up`이 종료되기 전에 할당된 virtual IP를 OS 인터페이스에 설정합니다. macOS에서는 `ifconfig`에 `utunN` 형태로 표시됩니다.
`marumesh up`은 CLI/서비스 안정성을 위해 기본적으로 tray UI 없이 실행합니다. Tray UI가 필요할 때만 `--headless=false`를 명시합니다.

로컬 agent API를 통해 원격 device의 TCP 서비스에 연결할 때:

```bash
marumesh connect <device-id> --remote-port 22
```

## SSO와 대시보드

서버에서 실제 SSO를 사용하려면 다음 환경 변수가 필요합니다.

```env
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
AUTH_CALLBACK_URL=http://localhost:8000/api/v1/auth/callback
JWT_SECRET=...
```

운영 환경에서는 `JWT_SECRET`을 반드시 명시해야 합니다. 로컬 개발에서만 `MARUMESH_DEV_INSECURE_JWT=true`로 임시 시크릿을 허용할 수 있습니다.

## 프로젝트 구조

- `src/cmd/marumesh`: 통합 CLI 및 agent 실행파일
- `src/cmd/marumesh-server`: control plane 서버 및 내장 대시보드
- `src/internal`: agent, tunnel, policy, network 내부 구현
- `frontend`: React 대시보드 소스
- `docs`: PRD, 설치 가이드, 기능 문서

더 자세한 명령어는 [docs/commands.md](docs/commands.md), 배포 방법은 [docs/install_guide.md](docs/install_guide.md)와 [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md)를 참고하세요.
