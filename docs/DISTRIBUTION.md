# MaruMesh 멀티 플랫폼 설치 가이드

본 문서는 MaruMesh를 다양한 환경(Linux, Raspberry Pi, Windows, macOS)에 설치하고 백그라운드 서비스로 등록하는 방법을 안내합니다.

에이전트 설치 산출물은 `marumesh` 단일 실행파일입니다. WireGuard userspace 장치는 바이너리에 내장되어 있으므로 `wg` 또는 `wireguard-tools` 설치가 필요하지 않습니다. 가상 네트워크 인터페이스 생성을 위해 OS TUN 장치와 관리자 권한은 필요합니다.

설치 후 `marumesh check`를 실행하면 TUN 생성 가능 여부와 OS별 조치 힌트를 확인할 수 있습니다.
현재 지원 Mesh 모드는 `tun`이며, `userspace` 모드는 TUN 없는 fallback 구현을 위한 예약 값입니다.

공식 테스트 control plane은 `https://marumesh.lab.highmaru.com`입니다. client 설치 스크립트는 public repo raw URL을 공식 진입점으로 사용합니다.

```bash
curl -fsSL https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.sh | sh
```

```powershell
iwr https://raw.githubusercontent.com/dirmich/maru-mesh/main/install.ps1 -UseB | iex
```

## Control Plane Docker 배포

`scripts/docker_publish.sh`는 `Makefile`의 현재 버전을 읽어 control plane 이미지를 빌드하고 Docker Hub에 push한다. 기본 이미지는 `dirmich/marumesh`이며, 동일한 manifest를 버전 태그와 `latest` 태그로 배포한다.

최초 실행 전 Docker Hub 계정 또는 access token으로 로그인한다.

```bash
docker login -u dirmich
make docker-publish
```

스크립트는 buildx builder를 자동 생성·초기화하고 `linux/amd64`, `linux/arm64` 이미지를 빌드한다. push가 끝나면 배포된 버전 manifest도 출력한다.

필요하면 환경변수로 배포 대상을 변경할 수 있다.

```bash
DOCKER_IMAGE=example/marumesh \
PLATFORMS=linux/amd64 \
./scripts/docker_publish.sh
```

서버에서는 새 이미지를 pull한 뒤 컨테이너를 강제로 다시 생성한다.

```bash
docker compose pull cp-server
docker compose up -d --force-recreate cp-server
```

### 중앙 에이전트 버전 정책

Control plane은 인증된 에이전트에 목표 버전과 최소 허용 버전을 전달한다. 에이전트는 1분마다 정책을 다시 확인하고, 목표 버전이 다르면 해당 플랫폼의 GitHub Release 바이너리를 내려받아 서버가 제공한 SHA-256을 검증한 뒤 현재 실행파일을 원자적으로 교체하고 재시작한다. 명시적인 낮은 목표 버전도 같은 검증 절차로 downgrade된다.

```env
# 비워두면 control plane 자체 버전 사용
DESIRED_AGENT_VERSION=0.11.78
# 이 버전 미만은 WireGuard/ICE를 시작하지 않고 로컬 관리 API만 유지
MINIMUM_AGENT_VERSION=0.11.77
# 선택 사항: 사내 미러의 버전별 산출물 디렉터리
AGENT_UPDATE_BASE_URL=https://downloads.example.com/marumesh/v0.11.78
```

`MINIMUM_AGENT_VERSION`의 기본값은 `0.0.0`이다. 따라서 새 서버를 먼저 배포해도 릴리스 산출물이 준비되지 않은 기존 에이전트가 즉시 차단되지는 않는다. 강제 전환은 산출물이 모든 지원 플랫폼에 게시되고 SHA-256 조회가 정상인 것을 확인한 뒤 최소 버전을 올린다. 최소 버전 미달 에이전트는 다운로드나 검증에 실패해도 데이터 플레인을 열지 않으며, 로컬 상태 API를 유지하면서 1분마다 재시도한다.

강제 정책은 에이전트의 자발적 동작에만 의존하지 않는다. Control plane도 보고된 버전이 최소값보다 낮거나 없는 장치에 peer discovery와 signaling을 제공하지 않으며, 그런 장치를 다른 peer의 연결 대상으로 노출하지 않는다. 이미 새 정책을 지원하는 온라인 에이전트는 최소값 상향을 감지하면 기존 MeshNode를 닫고 즉시 관리 전용 모드로 전환한다.

업데이트 신뢰 경계는 인증된 control plane과 HTTPS 릴리스 저장소다. 서버는 산출물을 직접 읽어 SHA-256을 계산하며, 에이전트는 그 값과 다운로드 결과가 일치하지 않으면 설치하지 않는다. 이전 바이너리는 `<binary>.previous`에 보관된다.

## 펭귄 (Linux & Raspberry Pi)

### 1단계: 실행파일 설치
가장 직접적인 방법은 `marumesh` 실행파일을 배치한 뒤 실행파일 자체의 서비스 설치 명령을 사용하는 것입니다.
```bash
sudo install -m 0755 ./bin/linux-amd64/marumesh /usr/local/bin/marumesh
marumesh up
```
`up`은 기본 control plane(`https://marumesh.lab.highmaru.com`)으로 연결합니다. 로그인 정보가 없으면 로그인 URL을 출력하고, 로그인 완료 후 보안 채널을 백그라운드로 올린 뒤 종료됩니다. 서버를 바꿔야 할 때만 `--control <URL>`을 추가합니다. 서비스 등록이 필요한 환경에서는 `sudo marumesh install-service`를 사용할 수 있습니다.
macOS `up`은 기본적으로 menubar tray를 표시합니다. Tray 없이 실행하려면 `--headless`를 명시합니다. Linux는 기본 headless로 실행합니다.
정상 연결 후 Linux에서는 `ip addr`, macOS에서는 `ifconfig`에서 할당된 virtual IP가 붙은 인터페이스를 확인할 수 있습니다.
보안 채널 중지는 `marumesh down`으로 수행합니다.
서비스 제거는 `sudo marumesh uninstall-service`로 수행합니다.

### 2단계: 수동 서비스 관리
`systemd`를 사용하여 상태를 확인하거나 제어할 수 있습니다.
```bash
sudo systemctl status marumesh
sudo systemctl start marumesh
sudo journalctl -u marumesh -f
```

---

## 윈도우 (Windows)

### 1단계: 바이너리 다운로드
`bin/windows-amd64/marumesh.exe` 파일을 적절한 위치(예: `C:\MaruMesh`)에 복사합니다.

### 2단계: 서비스 등록 (PowerShell)
관리자 권한으로 PowerShell을 열고 다음 명령을 실행합니다.
```powershell
C:\MaruMesh\marumesh.exe check
C:\MaruMesh\marumesh.exe up
```
Windows의 `up`은 로그인 후 MaruMesh 서비스를 등록하고 시작합니다.
서비스 제거는 관리자 권한 PowerShell에서 `C:\MaruMesh\marumesh.exe uninstall-service`를 실행합니다.

---

## 맥 (macOS)

### 1단계: 바이너리 설치
Intel Mac은 `bin/darwin-amd64/marumesh`, Apple Silicon(M1/M2/M3/M4)은 `bin/darwin-arm64/marumesh` 파일을 `/usr/local/bin`으로 복사합니다.

### 2단계: 자동 실행 설정 (Launchd)
```bash
marumesh up
```
macOS에서도 `up`은 보안 채널을 백그라운드로 올린 뒤 종료되며, 기본적으로 menubar tray를 표시합니다. Tray 없이 실행하려면 `--headless`를 명시합니다.
정상 연결 후 `ifconfig`에서 `utunN` 인터페이스와 할당된 virtual IP를 확인할 수 있습니다.
보안 채널 중지는 `marumesh down`으로 수행합니다.
서비스 제거는 `marumesh uninstall-service`로 수행합니다.
