# MaruMesh 보안 아키텍처 및 규정 (Security Architecture)

MaruMesh는 분산 엔터프라이즈 환경에서 보안 경계가 없는 네트워크를 안전하게 연결하기 위해 **Zero-Trust(제로 트러스트)** 및 **비밀키 로컬 격리(Private Key Local Isolation)** 원칙을 기본으로 설계되었습니다.

본 문서는 MaruMesh의 키 관리, 원격 제어 보호, OpenSSH 연동, 자동 업데이트 무결성 검증, 데이터 플레인 암호화 체계를 기술합니다.

---

## 1. 핵심 보안 원칙 (Core Security Principles)

1. **비밀키 불유출 원칙 (Zero-Knowledge Private Keys)**:
   - 모든 비대칭 암호화 키의 개인키(Private Key)는 노드 로컬에서만 생성되며, **어떠한 경우에도 네트워크나 서버(Control Plane)로 전송되지 않습니다.**
   - 파일 권한은 소유자 전용 `0600`으로 엄격히 제한됩니다.
2. **상시 명시적 검증 (Always Verify)**:
   - 네트워크의 위치(내부망/외부망)를 신뢰하지 않으며, 모든 노드 간 통신과 SSH 접속은 중앙 정책 엔진의 실시간 인가를 거칩니다.
3. **최소 권한 및 엄격한 명령 격리 (Strict Command Isolation)**:
   - Control Plane에서 노드를 원격 제어할 때 임의의 쉘 스크립트나 바이너리를 원격 주입(RCE)할 수 없으며, 사전에 정의된 불리언 상태 플래그(`bool`)만 동기화합니다.

---

## 2. 3계층 키페어 아키텍처 (3-Layer Key Architecture)

MaruMesh Agent는 최초 부팅 시 로컬에서 서로 다른 목적의 3가지 키페어를 독립적으로 생성하여 관리합니다.

| 키 명칭 | 알고리즘 | 로컬 저장 위치 | 역할 | 서버 전송 여부 |
| :--- | :--- | :--- | :--- | :--- |
| **디바이스 신원 키** | Ed25519 | `~/.marumesh/device.key` (`0600`) | DeviceID 파생, Control Plane mTLS/API 서명 | 공개키(`device.pub`)만 등록 |
| **WireGuard 터널 키** | Curve25519 | `~/.marumesh/wg_device.key` (`0600`) | WireGuard P2P 메시 터널 종단간 암호화 | 공개키(`wg_device.pub`)만 등록 |
| **OpenSSH 상호 인증 키** | OpenSSH Ed25519 | `~/.marumesh/ssh/id_ed25519` 및 `~/.ssh/marumesh/` (`0600`) | `ssh <device_name>` 무암호 상호 인증 | 공개키만 등록 (`/api/v1/ssh/keys`) |

### 키 회전 및 원자적 롤백 (Key Rotation & Atomicity)
- SSH 키 회전(`marumesh ssh refresh`) 시 신규 키 생성 -> Control Plane 임시 등록(`PUT /api/v1/ssh/keys`) -> 활성화 확인(`POST /api/v1/ssh/keys`) 2단계 트랜잭션을 거칩니다.
- 이전 키(`id_ed25519.previous`)를 보관하여 네트워크 순단 시에도 이전 키를 통한 복구가 가능합니다.

---

## 3. 웹 대시보드 기반 원격 제어 보호 (Remote Management Security)

관리자가 Web Dashboard에서 노드를 관리할 때 발생할 수 있는 취약점을 방어하기 위해 다음과 같은 보호 계층이 적용됩니다.

### 3.1. 인가 검증 및 IDOR(Insecure Direct Object Reference) 방어
- 모든 제어 엔드포인트(`/api/v1/devices/ssh`, `/api/v1/devices/upgrade`, `/api/v1/devices/restart`)는 세션 JWT를 필수 검증합니다.
- 조작 대상 노드의 소유자(`dev.OwnerID == userEmail`) 또는 최고 관리자(`adminEmail`)가 아닌 모든 요청은 즉시 `403 Forbidden`으로 거부됩니다.

### 3.2. RCE(원격 코드 실행) 원천 차단
- 서버가 에이전트로 전달하는 제어 명령은 불리언 플래그뿐입니다:
  - `ssh_enabled`: `true` / `false`
  - `restart_requested`: `true` / `false`
  - `upgrade_requested`: `true` / `false`
- 에이전트는 전달받은 상태 플래그에 따라 사전에 컴파일된 내부 함수만 실행하므로 임의 코드 주입이 불가능합니다.

### 3.3. DoS(서비스 거부) 및 무한 재시작 방어
- **1회성 ACK 메커니즘**: 에이전트는 원격 재시작 신호를 받으면 서버에 `/api/v1/devices/restart/ack`를 호출하여 플래그를 해제한 뒤 재기동에 들어갑니다.
- **기동 쿨다운**: 에이전트 시작 직후 60초 이내에는 원격 재시작 신호가 들어와도 즉시 재시작하지 않고 안정화 기간을 갖습니다.

---

## 4. Zero-Trust OpenSSH 보안 (Zero-Trust OpenSSH)

MaruMesh의 OpenSSH 기능은 편의성을 극대화하면서도 서버 보안을 타협하지 않습니다.

1. **WireGuard 가상 네트워크 바인딩**:
   - SSH 드롭인 설정(`/etc/ssh/sshd_config.d/90-marumesh.conf`)은 오직 MaruMesh 가상 IP 대역(`Match LocalAddress 10.77.0.*`)에만 적용됩니다.
   - 공인 IP나 로컬 LAN의 22번 포트로는 MaruMesh 정책이 적용되지 않습니다.
2. **비밀번호 인증 전면 차단**:
   - MaruMesh 가상 인터페이스를 통한 SSH 접근은 `PasswordAuthentication no`, `PubkeyAuthentication yes`가 강제되어 브루트포스(사전 대입) 공격이 불가능합니다.
3. **실시간 정책 인가 (`AuthorizedKeysCommand`)**:
   - 접속 시도 시 정적 `authorized_keys` 파일을 읽지 않고, `marumesh ssh-auth`가 Control Plane의 `/api/v1/ssh/authorize`를 실시간 호출합니다.
   - 발신 노드의 공개키, 소속 조직, 역할, 접근 제어 규칙(ACL Policy)을 확인하여 인가된 경우에만 임시 세션을 허용합니다.
4. **원클릭 즉시 차단**:
   - 웹 대시보드에서 SSH 토글을 끄면 노드의 `90-marumesh.conf` 파일이 즉시 삭제되고 `sshd`가 리로드되어 연결 권한이 즉각 회수됩니다.

---

## 5. 자동 업그레이드 무결성 보장 (Update Integrity)

원격 업그레이드 기능은 공급망 공격(Supply Chain Attack)과 중간자 공격(MITM)을 방어하도록 설계되었습니다.

1. **공식 릴리스 저장소 한정**:
   - 기본 다운로드 엔드포인트는 GitHub 공식 릴리스(`https://github.com/dirmich/maru-mesh/releases/download/...`)로 제한됩니다.
2. **SHA-256 체크섬 강제 검증**:
   - Control Plane은 각 플랫폼별(Linux amd64/arm64, Windows amd64) 공식 해시값을 에이전트에 전달합니다.
   - 에이전트는 아티팩트를 다운로드한 후 SHA-256 해시를 계산하여 불일치 시 파일 크기나 내용에 상관없이 즉시 파기(`ErrHashMismatch`)하고 업그레이드를 중단합니다.
3. **원자적 파일 교체 (Atomic Replacement)**:
   - 기존 실행 중인 바이너리를 덮어쓰지 않고, 임시 파일(`.new`)에 기록 및 권한 설정 후 원자적 이름 변경(`os.Rename`)으로 교체하여 실패 시 기존 바이너리를 보존합니다.

---

## 6. 데이터 플레인 암호화 (Data Plane Encryption)

1. **ChaCha20-Poly1305 & Curve25519**:
   - 모든 노드 간 데이터 트래픽은 WireGuard 표준의 최신 암호화 스위트를 사용하여 전송 구간 전체가 암호화됩니다.
2. **P2P 우선 및 DERP 릴레이 암호화**:
   - NAT 통과가 가능한 경우 노드 간 직접(Direct P2P) 연결됩니다.
   - 직접 연결이 불가능하여 DERP 릴레이를 경유하는 경우에도, 릴레이 서버는 WireGuard 페이로드를 복호화할 수 없으며 단순히 암호화된 패킷을 전달하는 역할만 수행합니다.
