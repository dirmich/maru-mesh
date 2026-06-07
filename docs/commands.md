# MaruMesh 명령어 사용법

이 문서는 `marumesh` 단일 실행파일에서 제공하는 주요 명령을 정리합니다.

## 기본 원칙

- 일반 사용자는 기본적으로 `marumesh up`과 `marumesh down`만 사용합니다.
- `marumesh up`은 기본 control plane인 `https://marumesh.lab.highmaru.com`에 연결합니다.
- 다른 서버에 연결해야 할 때만 `--control <URL>`을 지정합니다.
- 로그인 정보가 없으면 `up`이 기기 이름을 포함한 SSO 로그인 URL을 출력하고, Google SSO 로그인 후 토큰을 config에 저장합니다.
- SSO 완료 후 device는 로그인한 사용자와 기기 이름으로 control plane에 등록됩니다.
- 로그인 정보가 있으면 저장된 토큰으로 로그인하고 보안 채널을 백그라운드로 연결한 뒤 명령은 종료됩니다.
- 같은 device_id가 다시 등록되면 새 device가 중복 생성되지 않고 기존 device의 기기 이름, public key, 최종 로그인 시간이 갱신됩니다.
- 대시보드에서 device가 삭제된 경우 다음 `marumesh up`은 저장 토큰만 재사용하지 않고 SSO device 등록 flow를 다시 진행합니다.
- Windows에서는 `up`이 로그인 후 같은 config 경로를 서비스 실행에 넘겨 Windows Service를 설치/시작합니다.

## 빠른 시작

설치:

```bash
curl -fsSL https://marumesh.lab.highmaru.com/install.sh | sh
```

Windows:

```powershell
iwr https://marumesh.lab.highmaru.com/install.ps1 -UseB | iex
```

실행:

```bash
marumesh up
```

다른 서버를 사용할 때:

```bash
marumesh up --control https://mesh.example.com
```

중지:

```bash
marumesh down
```

## 명령어

### `marumesh up`

SSO 로그인 상태를 확인하고 보안 mesh 채널을 백그라운드로 시작한 뒤 종료됩니다.

```bash
marumesh up
```

주요 옵션:

- `--control <URL>`: 기본 control plane 대신 다른 서버에 연결합니다.
- `--config <path>`: 로그인 토큰과 장치 설정을 저장할 config 파일 경로를 지정합니다.
- `--mesh-mode <tun|userspace>`: mesh 전송 모드를 지정합니다. 기본값은 `tun`입니다.
- `--tun <name>`: TUN 장치 이름을 지정합니다.
- `--dns-port <port>`: 로컬 mesh DNS 포트를 지정합니다.
- `--headless`: tray UI 없이 실행합니다. macOS `up`은 기본적으로 menubar tray를 표시하므로 tray 없이 실행할 때 사용합니다. Linux는 기본 headless입니다.
- `--debug`: 내부 등록, license, DNS, TUN 초기화 로그를 JSON 형식으로 자세히 출력합니다. 이 모드에서는 foreground로 실행되어 직접 `Ctrl-C`로 종료합니다.

`tun` 모드에서 정상 연결되면 OS 인터페이스에 virtual IP가 설정됩니다. macOS에서는 `ifconfig`에서 `utunN` 인터페이스로 확인합니다.

### `marumesh down`

로컬 보안 채널 또는 등록된 서비스를 중지합니다.

```bash
marumesh down
```

### `marumesh install-service`

현재 실행파일을 OS 서비스로 등록합니다.

```bash
sudo marumesh install-service
```

다른 서버로 서비스 등록:

```bash
sudo marumesh install-service --control https://mesh.example.com
```

주요 옵션:

- `--control <URL>`: 서비스가 연결할 control plane을 지정합니다. 기본값은 `https://marumesh.lab.highmaru.com`입니다.
- `--config <path>`: 서비스가 사용할 config 파일 경로를 지정합니다.
- `--mesh-mode <tun|userspace>`: 서비스 실행 시 사용할 mesh 모드를 지정합니다.
- `--skip-check`: 서비스 등록 전 TUN 접근 점검을 건너뜁니다.
- `--service-path <path>`: Linux systemd unit 또는 macOS LaunchAgent plist 경로를 직접 지정합니다.

### `marumesh uninstall-service`

등록된 OS 서비스를 제거합니다.

```bash
sudo marumesh uninstall-service
```

### `marumesh run`

agent daemon을 foreground로 직접 실행합니다. 일반 사용자는 보통 `up`을 사용하고, 서비스/디버깅 목적일 때만 직접 실행합니다.

```bash
marumesh run
```

다른 서버로 직접 실행:

```bash
marumesh run --control https://mesh.example.com
```

### `marumesh check`

단일 실행파일 설치 환경에서 TUN 접근 가능 여부를 점검합니다.

```bash
marumesh check
```

### 로컬 API/진단 명령

아래 명령은 로컬 agent API를 통해 상태와 peer 정보를 확인하거나 연결을 요청할 때 사용합니다.

```bash
marumesh status
marumesh list
marumesh peers
marumesh ping <target>
marumesh connect <target> --remote-port 22
```

`connect`는 로컬 TCP proxy를 생성합니다. 로컬 포트를 직접 지정하려면 `--local-port <port>`를 추가합니다. 생략하면 OS가 빈 포트를 자동 배정하고, 응답의 `proxy_address`에서 실제 주소를 확인합니다.

## 플랫폼별 예시

Linux:

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

Windows PowerShell:

```powershell
C:\MaruMesh\marumesh.exe up
C:\MaruMesh\marumesh.exe down
C:\MaruMesh\marumesh.exe uninstall-service
```
