# MaruMesh 멀티 플랫폼 설치 가이드

본 문서는 MaruMesh를 다양한 환경(Linux, Raspberry Pi, Windows, macOS)에 설치하고 백그라운드 서비스로 등록하는 방법을 안내합니다.

에이전트 설치 산출물은 `marumesh` 단일 실행파일입니다. WireGuard userspace 장치는 바이너리에 내장되어 있으므로 `wg` 또는 `wireguard-tools` 설치가 필요하지 않습니다. 가상 네트워크 인터페이스 생성을 위해 OS TUN 장치와 관리자 권한은 필요합니다.

설치 후 `marumesh check`를 실행하면 TUN 생성 가능 여부와 OS별 조치 힌트를 확인할 수 있습니다.
현재 지원 Mesh 모드는 `tun`이며, `userspace` 모드는 TUN 없는 fallback 구현을 위한 예약 값입니다.

공식 테스트 control plane은 `https://marumesh.lab.highmaru.com`입니다. HAProxy가 Docker의 `cp-server:8080`으로 연결되면 다음 client install URL을 바로 사용할 수 있습니다.

```bash
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
```

```powershell
iwr https://marumesh.lab.highmaru.com/install.ps1 -UseB | iex
```

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
