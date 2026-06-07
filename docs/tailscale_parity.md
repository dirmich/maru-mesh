# Tailscale 대체 목표 기능 목록

MaruMesh의 장기 목표는 Tailscale과 같은 사용자 경험을 자체 control plane으로 제공하는 것입니다. 이 문서는 “완전 대체”를 위해 필요한 기능을 제품/구현 backlog로 정리합니다.

## 원칙

- 기본 UX는 `marumesh up` 하나로 SSO 로그인, device 등록, MagicDNS, 보안 채널 연결까지 끝나야 합니다.
- source와 control plane은 자체 운영 가능해야 하며, public repo는 installer, release, 사용자 문서만 제공합니다.
- Tailscale 기능 parity를 목표로 하되, MaruMesh의 강점은 self-hosted 운영, SSO device lifecycle, DNS inventory, 자체 audit에 둡니다.

## 기능 parity 항목

### 1. Identity와 device lifecycle

필수 기능:

- SSO 로그인과 device 등록
- owner/superuser 권한 모델
- device 삭제 시 실행 중 agent 강제 로그아웃
- device 이름 보존과 dashboard/API rename
- device sharing
- auth key 또는 enrollment key
- ephemeral node
- OAuth/API token

현재 상태:

- SSO device 등록, owner/superuser, device 삭제 강제 로그아웃, 이름 보존은 구현되어 있습니다.
- device sharing UI/API, auth key, ephemeral node, OAuth/API token은 보강이 필요합니다.

### 2. MagicDNS와 이름 관리

필수 기능:

- 같은 owner 또는 공유받은 device 이름 해석
- short name과 FQDN alias
- OS resolver 통합
- 이름 충돌 감지
- DNS inventory UI
- split DNS
- search domain 관리

현재 상태:

- agent 내장 DNS resolver가 peer record를 관리합니다.
- macOS는 `/etc/resolver/maru`, Linux는 `systemd-resolved`를 통해 `.maru` zone을 MaruMesh DNS로 보낼 수 있습니다.
- short name은 hosts fallback으로 보강합니다.
- Windows OS resolver 통합, split DNS, 이름 충돌 UI는 보강이 필요합니다.

### 3. Data plane과 relay fallback

필수 기능:

- WireGuard 기반 암호화 터널
- 직접 P2P 연결
- NAT traversal
- relay fallback
- relay region 선택
- connection health와 path 변경 표시

현재 상태:

- Go 내장 WireGuard와 ICE 기반 직접 연결은 구현되어 있습니다.
- Tailscale DERP에 해당하는 relay fallback, relay 운영 API, region 관리, health UI는 보강이 필요합니다.

### 4. ACL과 정책

필수 기능:

- user/group/tag 기반 ACL
- device tag
- service/port/protocol 정책
- policy preview/test
- policy audit

현재 상태:

- policy engine과 sync skeleton은 있습니다.
- 실제 user/group/tag ACL 모델, policy editor, deny/allow enforcement 검증은 보강이 필요합니다.

### 5. SSH와 service access

필수 기능:

- SSO/ACL 기반 SSH 접근 제어
- SSH audit
- service catalog
- CLI/tray/dashboard에서 서비스 실행

MaruMesh 차별화 방향:

- Tailscale SSH를 단순 복제하기보다 device가 노출하는 `ssh`, `rdp`, `postgres`, `http` 같은 서비스를 catalog로 관리합니다.
- 예: `marumesh open dev ssh`, `marumesh open db postgres`.

현재 상태:

- `marumesh connect`로 로컬 TCP proxy를 만들 수 있습니다.
- SSH 자체 정책, service discovery/catalog, dashboard connect button은 보강이 필요합니다.

### 6. Subnet router와 exit node

필수 기능:

- subnet route advertise/approve
- site-to-site routing
- exit node advertise/select
- route conflict detection
- route audit

현재 상태:

- device virtual CIDR 충돌 경고는 있습니다.
- subnet router, exit node, route approval, route distribution은 보강이 필요합니다.

### 7. App connector

필수 기능:

- domain 기반 app routing
- SaaS/self-hosted app domain policy
- connector device 관리
- connector health와 audit

현재 상태:

- 아직 구현되지 않았습니다.
- MagicDNS와 service catalog 이후 별도 connector 모델로 설계해야 합니다.

### 8. Device posture와 compliance

필수 기능:

- OS, version, agent version, disk encryption, firewall, EDR/MDM 상태 수집
- posture 기반 ACL 조건
- posture audit

현재 상태:

- device/session 기본 정보와 최종 로그인 시간은 관리합니다.
- posture 수집 agent, policy condition, MDM/EDR integration은 보강이 필요합니다.

### 9. Kubernetes와 container 운영

필수 기능:

- Kubernetes operator
- subnet/app connector CRD
- ephemeral workload identity
- container sidecar 또는 userspace mode

현재 상태:

- Docker 배포와 Linux binary는 있습니다.
- Kubernetes operator, CRD, userspace netstack fallback은 보강이 필요합니다.

### 10. Admin console과 observability

필수 기능:

- 모든 사용자/device/session/route/policy 관리
- connection status
- audit log
- network flow log
- release/install status

현재 상태:

- dashboard device/session 관리의 기본 틀은 있습니다.
- flow log, connection path, route/policy UI, alert/export는 보강이 필요합니다.

## 구현 우선순위

1. MagicDNS 완성: Windows resolver, split DNS, 이름 충돌 UI.
2. Relay fallback: 자체 relay server, relay discovery, connection health.
3. ACL v1: user/group/device/tag 기반 allow/deny와 dashboard editor.
4. Service catalog: `marumesh open`, dashboard/tray connect action.
5. Subnet router: route advertise/approve/distribute.
6. Exit node: default route advertise/select.
7. Device sharing과 auth key/ephemeral node.
8. Device posture와 audit/flow log.
9. App connector.
10. Kubernetes operator.

## 문서 기준

Tailscale 기능은 계속 확장되므로, parity 문서는 주기적으로 공식 문서를 기준으로 갱신해야 합니다. 구현 전에 해당 기능의 현재 Tailscale 동작을 다시 확인하고 MaruMesh의 self-hosted 운영 모델에 맞춰 설계합니다.

