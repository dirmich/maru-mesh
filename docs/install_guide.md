# MaruMesh 설치 및 실행 가이드 (Unified Install Guide)

본 문서는 MaruMesh **서버(Control Plane)**와 **에이전트(Agent)**를 각 플랫폼에 설치하고 실행하는 통합 방법을 안내합니다.

---

## 🖥️ 1. 서버 (Backend / Control Plane) 설치

관리 대시보드와 에이전트 제어를 담당하는 서버 설치 방법입니다.

### 방법 A: Docker Compose 사용 (가장 추천)
가장 빠르고 안정적인 배포 방식이며, PostgreSQL 등 다양한 데이터베이스 연동을 기본 지원합니다.

```bash
# 1. 환경 변수 파일 생성 (.env)
cp .env.example .env

# 2. .env 파일을 열고 필요한 DB 및 SSO 정보 설정 (예: DB_TYPE=postgres)
# nano .env

# 3. 컨테이너 백그라운드 실행
docker-compose up -d --build

# 4. 로그 확인
docker-compose logs -f cp-server
```
- **데이터베이스**: 기본 SQLite를 사용하며, `.env` 수정으로 손쉽게 외부 PostgreSQL 또는 로컬 Docker DB와 연동 가능합니다.
- **환경 변수**: `docker-compose.yml`은 `env_file: .env`로 서버 컨테이너에 환경 변수를 전달합니다. `HOST_PORT`는 호스트 공개 포트, `PORT`는 컨테이너 내부 서버 포트입니다.
- 현재 Docker PostgreSQL을 사용할 때는 `postgresql` 컨테이너가 `backend_default` 네트워크에 있어야 하며, `.env`의 `DB_DSN`은 `host=postgresql user=postgres password=postgres ...` 형식을 사용합니다.
- PostgreSQL 비밀번호에 `#`, `$`, `!`, `@`, 공백 같은 특수문자가 있으면 DSN 전체를 감싸기보다 `password='...'`처럼 password 값만 작은따옴표로 감싸거나 URL DSN의 password를 percent-encoding 하세요.
- **주소**: 직접 포트 접근시 `http://<SERVER_IP>:8080` 이나, 통상적으로 HAProxy나 Nginx를 통해 `https://marumesh.lab.highmaru.com` 와 같은 도메인을 붙여 서비스합니다.
- **Client install URL**: HAProxy가 Docker의 `cp-server:8080`으로 연결되면 `https://marumesh.lab.highmaru.com/install.sh`, `https://marumesh.lab.highmaru.com/install.ps1`로 client 설치 스크립트를 받을 수 있습니다.

### 방법 B: 리눅스 시스템 서비스로 설치
제공된 `install-server.sh` 스크립트를 사용하여 `systemd`에 등록합니다.
```bash
# 1. 빌드
make build

# 2. 설치 스크립트 실행
./install-server.sh
```
- **관리**: `sudo systemctl status marumesh-server` 명령어로 상태를 확인할 수 있습니다.

---

## 🤖 2. 에이전트 (Agent) 설치

사용자 기기에 설치하여 마루메쉬 네트워크에 참여시키는 방법입니다.

MaruMesh 에이전트의 WireGuard 장치와 키 처리는 `marumesh` 실행파일에 내장되어 있습니다. 별도의 `wg`, `wireguard-tools`, `wireguard-go` 실행파일을 설치할 필요는 없습니다. 다만 가상 IP 네트워크를 만들기 위해 OS TUN 장치 접근 권한은 필요합니다.

- Linux/Container: `/dev/net/tun` 접근과 `CAP_NET_ADMIN` 권한이 필요합니다.
- macOS: utun 생성을 허용할 수 있는 권한으로 실행해야 합니다.
- Windows: Wintun 드라이버는 Go WireGuard 의존성 경로를 통해 사용되며, 서비스 등록/실행은 관리자 권한에서 수행하세요.
- 현재 지원 Mesh 모드는 `tun`입니다. `--mesh-mode userspace`는 향후 TUN 없는 fallback 용도로 예약되어 있으며, 구현 전까지는 명확한 오류를 반환합니다.

### 🐧 리눅스 & 라즈베리 파이 (Linux / RPi)
```bash
# GitHub Releases 바이너리를 공식 테스트 control plane 기준으로 설치
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
marumesh up
```
- 기본 control plane은 `https://marumesh.lab.highmaru.com`입니다. 다른 서버를 사용할 때만 `--control <URL>`을 추가합니다.
- `marumesh up`은 보안 채널을 백그라운드로 시작하고 명령은 종료됩니다. foreground 실행이 필요하면 `marumesh run`을 사용합니다.
- `marumesh install-service`는 기본적으로 `marumesh check`를 먼저 실행합니다. 점검 실패 시 서비스 등록 전에 중단됩니다. 같은 명령을 다시 실행하면 기존 서비스 정의를 갱신합니다.
- `install.sh`는 public 배포 저장소 GitHub Releases(`https://github.com/dirmich/maru-mesh/releases/latest/download`)에서 `marumesh-linux-amd64` 또는 `marumesh-linux-arm64`를 다운로드해 `/usr/local/bin/marumesh`로 설치합니다.
- 설치 후 `sudo systemctl status marumesh`로 확인 가능합니다.
- 제거: `sudo marumesh uninstall-service`. 서비스가 이미 중지되었거나 등록 해제된 상태여도 정리 절차를 계속 수행합니다.

### 🪟 윈도우 (Windows)
1. 관리자 권한 PowerShell에서 client install URL을 실행합니다:
```powershell
iwr https://marumesh.lab.highmaru.com/install.ps1 -UseB | iex
marumesh up
```
2. 직접 복사 방식에서는 `bin/windows-amd64/marumesh.exe`를 `C:\MaruMesh` 폴더에 복사합니다. 서버 바이너리는 `bin/windows-amd64/marumesh-server.exe`에 생성됩니다.
3. 직접 복사 방식으로 설치할 때는 관리자 권한 PowerShell에서 서비스를 등록합니다:
```powershell
C:\MaruMesh\marumesh.exe check
C:\MaruMesh\marumesh.exe up
```
4. `up`은 로그인 토큰이 저장된 config 경로를 Windows 서비스 실행 명령에 명시합니다.
5. 중지는 관리자 권한 PowerShell에서 `C:\MaruMesh\marumesh.exe down`을 실행합니다.
6. 제거는 관리자 권한 PowerShell에서 `C:\MaruMesh\marumesh.exe uninstall-service`를 실행합니다. 서비스가 이미 중지되었거나 삭제된 상태여도 정리 절차를 계속 수행합니다.

### 🍎 맥 (macOS)
1. Client install URL로 설치합니다:
```bash
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
```
2. 직접 복사 방식에서는 Intel Mac은 `bin/darwin-amd64/marumesh`, Apple Silicon(M1/M2/M3/M4)은 `bin/darwin-arm64/marumesh`를 `/usr/local/bin`으로 복사합니다.
3. 점검: `marumesh check`
4. 실행: `marumesh up`
5. 중지: `marumesh down`
6. 제거: `marumesh uninstall-service`. LaunchAgent가 이미 unload된 상태여도 plist 정리를 계속 수행합니다.

---

## 🔑 3. 중요 설정 (SSO 인증)

서버 실행 시 실제 Google 로그인 기능을 사용하려면 환경 변수를 설정해야 합니다.

- **방법**: `.env` 또는 `docker-compose.yml`, 시스템 서비스 파일(`systemd`)에 다음 값을 입력하세요.
  - `GOOGLE_CLIENT_ID`: 구글 클라우드 콘솔 발급 ID
  - `GOOGLE_CLIENT_SECRET`: 구글 클라우드 콘솔 발급 시크릿
  - `AUTH_CALLBACK_URL`: `https://marumesh.lab.highmaru.com/api/v1/auth/callback`
  - `PUBLIC_CONTROL_URL`: `https://marumesh.lab.highmaru.com`
  - `CLIENT_RELEASE_BASE_URL`: `https://github.com/dirmich/maru-mesh/releases/latest/download`
  - `JWT_SECRET`: 대시보드/API 세션 토큰 서명용 랜덤 시크릿. 운영 환경에서는 반드시 설정해야 합니다.

로컬 개발에서만 임시 시크릿을 허용하려면 `MARUMESH_DEV_INSECURE_JWT=true`를 사용할 수 있습니다. 운영 배포에는 사용하지 마세요.

---

## ✅ 4. 실행 확인

1. 브라우저에서 `https://marumesh.lab.highmaru.com` 접속.
2. 'Login with Google'로 인증 완료.
3. 에이전트 목록에 자신의 기기가 나타나면 **Approve** 버튼을 클릭하여 승인.
4. 에이전트 터미널이나 트레이 아이콘에서 가상 IP 할당 확인.
5. 로컬 상태 API의 `mesh_enabled`가 `true`인지 확인. `false`이고 `mesh_error`가 있으면 TUN 권한/드라이버 문제를 먼저 해결하세요.
