# MaruMesh vs Tailscale

이 문서는 MaruMesh가 목표로 하는 사용 경험을 Tailscale과 비교해 정리합니다.

## MaruMesh의 목표 사용 흐름

MaruMesh의 기본 목표는 다음입니다.

1. 여러 기기에서 `marumesh up`을 실행합니다.
2. 로그인 정보가 없으면 Google SSO로 로그인합니다.
3. 기기 이름을 등록합니다.
4. 같은 SSO 사용자로 등록된 기기끼리 자동으로 보안 mesh에 참여합니다.
5. 다른 기기 이름이 `dev`라면 `dev`, `dev.maru`, `<device-id>.maru` 같은 이름으로 해석됩니다.
6. 이름 또는 virtual IP로 `ping`, `nslookup`, `ssh`, HTTP, 개발 서버 등 일반 TCP/UDP 서비스를 사용할 수 있어야 합니다.

즉, 사용자는 “VPN에 붙는다”보다 “내 기기들이 같은 사설 이름 공간 안에 들어온다”는 경험을 기대합니다.

## 같은 점

### 1. WireGuard 기반 보안 채널

Tailscale은 WireGuard를 기반으로 mesh VPN을 구성합니다. MaruMesh도 WireGuard userspace 경로를 사용해 기기 간 암호화된 보안 채널을 구성하는 방향입니다.

공통점:

- 기기마다 key pair를 가집니다.
- control plane은 peer 정보와 public key를 배포합니다.
- 실제 데이터 경로는 기기 간 암호화 터널을 목표로 합니다.
- 사용자는 원격 기기의 private IP 또는 이름으로 서비스를 접근합니다.

### 2. Control plane과 data plane 분리

Tailscale은 coordination server가 device registry, key 정보, 정책, NAT traversal 정보를 관리하고, 실제 데이터는 WireGuard data plane에서 이동합니다.

MaruMesh도 control plane이 다음을 관리합니다.

- SSO 사용자 세션
- device 등록
- device owner
- virtual IP
- WireGuard public key
- 정책과 공유 관계
- peer 목록

데이터 plane은 agent가 담당합니다.

### 3. SSO 기반 device 등록

Tailscale은 identity provider와 tailnet 계정 기반으로 device를 등록합니다. MaruMesh도 Google SSO 사용자 기준으로 device owner를 정하고, 같은 사용자 소유 기기 또는 공유받은 기기를 mesh peer로 취급합니다.

### 4. 이름 기반 접근

Tailscale은 MagicDNS를 통해 device 이름으로 접속할 수 있게 합니다. MaruMesh도 내장 MagicDNS와 hosts fallback으로 `dev`, `dev.maru`, `<device-id>.maru` 형태의 이름 해석을 목표로 합니다.

MaruMesh에서 기대하는 예:

```bash
nslookup dev
ping dev
ssh dev
curl http://dev:3000
```

### 5. NAT 뒤 기기 연결

Tailscale은 NAT traversal을 자동 처리하고, 직접 연결이 어려울 때 relay 경로를 사용합니다. MaruMesh도 ICE 경로와 peer signaling을 통해 NAT 뒤 기기 간 연결을 구성하는 방향입니다.

## 다른 점

### 1. 제품 성숙도

Tailscale은 production-ready 제품입니다. MagicDNS, ACL, subnet router, exit node, DERP relay, admin console, device posture, audit, SSH 등 운영 기능이 성숙합니다.

MaruMesh는 현재 구현 중인 프로젝트입니다. 핵심 방향은 같지만 다음 영역은 아직 안정화가 필요합니다.

- WireGuard over ICE E2E 실제 패킷 통신 안정화
- relay fallback
- 이름 해석의 OS별 자동 적용
- service discovery
- admin 정책 모델
- macOS notarized release
- 운영 관측성

### 2. Relay 인프라

Tailscale은 DERP relay 서버를 사용합니다. 직접 연결이 어려운 NAT/firewall 환경에서도 DERP 또는 peer relay fallback으로 연결성을 확보합니다.

MaruMesh는 현재 ICE 기반 직접 연결을 우선 목표로 합니다. 따라서 hard NAT, strict firewall 환경에서는 relay fallback 설계가 아직 필요합니다.

차이:

- Tailscale: direct, peer relay, DERP relay fallback이 제품화되어 있음.
- MaruMesh: ICE signaling과 직접 연결 중심. relay는 향후 보강 과제.

### 3. DNS와 이름 해석

Tailscale의 MagicDNS는 tailnet 전체 이름 공간을 관리합니다. 사용자는 기기 이름 또는 FQDN으로 접근합니다.

MaruMesh는 agent가 peer 정보를 받아 내장 MagicDNS resolver, OS resolver 설정, hosts fallback에 반영하는 방식입니다.

차이:

- Tailscale: MagicDNS가 제품 기능으로 통합됨.
- MaruMesh: `.maru` zone은 내장 MagicDNS로 처리하고 `dev` 같은 short name은 hosts fallback으로 보강함. OS resolver/hosts 권한이 없으면 제한될 수 있음.

### 4. IP 대역 관리

Tailscale은 자체 tailnet IP 대역과 device 주소 할당 체계를 제공합니다.

MaruMesh는 control plane의 `MARUMESH_VIRTUAL_CIDR`로 virtual IP 할당 대역을 정합니다. 기본값은 `100.64.0.0/24`입니다.

운영자가 해야 할 일:

- 기존 사내망/VPN/클라우드 VPC와 겹치지 않는 CIDR 선택
- 이미 등록된 device가 많은 경우 CIDR 변경 시 migration 정책 수립
- client에서 CIDR overlap 경고 확인

### 5. Device 이름 정책

Tailscale은 device 이름/MagicDNS 이름을 안정적인 식별자처럼 다룹니다.

MaruMesh도 같은 방향입니다. 특히 다음 원칙을 둡니다.

- 최초 등록 시 hostname을 device 이름으로 사용합니다.
- 이후 `marumesh down` 후 `marumesh up`을 다시 해도 기존 이름을 덮어쓰지 않습니다.
- 이름 변경은 dashboard/API의 rename 경로로만 수행합니다.

이 원칙이 중요한 이유:

- `ssh dev`, `ping dev` 같은 이름 기반 workflow가 안정적으로 유지되어야 합니다.
- 노트북 hostname 변경이나 OS 재설치 과정에서 의도치 않게 device 이름이 바뀌면 안 됩니다.

### 6. SSH 기능

Tailscale은 Tailscale SSH라는 별도 기능을 제공합니다. 이 기능은 Tailscale ACL과 통합되어 SSH 접근 자체를 제어합니다.

MaruMesh의 현재 목표는 더 단순합니다.

- mesh 연결이 되면 일반 SSH daemon을 그대로 사용합니다.
- 예: `ssh dev`
- SSH 사용자/키/port 정책은 기본적으로 OS SSH 설정을 따릅니다.

향후 MaruMesh가 Tailscale SSH와 유사한 기능을 제공하려면 다음이 필요합니다.

- SSH 접근 정책 모델
- 사용자별 SSH principal 매핑
- session audit
- just-in-time approval
- port 22 외 서비스 접근 정책

### 7. Subnet router와 exit node

Tailscale은 subnet router와 exit node 기능을 제공합니다. 이 기능을 사용하면 Tailscale이 설치되지 않은 내부망 장치 접근이나 전체 트래픽 우회를 구성할 수 있습니다.

MaruMesh는 현재 “등록된 device 간 mesh”가 우선입니다.

차이:

- Tailscale: subnet router/exit node가 성숙한 기능.
- MaruMesh: device-to-device 접근 중심. subnet routing/exit routing은 향후 과제.

### 8. Admin/Policy 모델

Tailscale은 tailnet ACL, groups, tags, posture, SSH policy 등 다양한 정책 모델을 제공합니다.

MaruMesh는 현재 다음 수준을 목표로 합니다.

- SSO 사용자 기준 owner
- 일반 사용자는 자기 device와 공유받은 device 관리
- superuser는 전체 device/user/policy 관리
- device sharing
- 전역 network policy

차이:

- Tailscale: 조직/기업 운영 기능이 성숙.
- MaruMesh: 필요한 기능을 프로젝트 요구에 맞춰 직접 구현 중.

### 9. 운영 방식

Tailscale은 SaaS control plane을 기본으로 사용하고, 클라이언트/relay/관리 기능이 통합되어 있습니다.

MaruMesh는 자체 control plane을 운영하는 방식입니다.

장점:

- 서버와 데이터 저장 위치를 직접 통제할 수 있습니다.
- 조직 요구에 맞는 custom dashboard/API를 만들 수 있습니다.
- 특정 환경에 맞는 인증/정책/기기 관리 흐름을 빠르게 바꿀 수 있습니다.

단점:

- relay, NAT traversal, DNS, signing, packaging, observability를 직접 책임져야 합니다.
- 운영 안정성은 구현과 배포 품질에 좌우됩니다.

## Tailscale과 차별화할 수 있는 강점 후보

Tailscale은 MagicDNS, SSH, subnet router, exit node, app connector, device posture, Kubernetes operator 등 완성된 기능 폭이 넓습니다. MaruMesh는 동일 기능을 단순 복제하기보다 자체 control plane과 조직 내부 운영 흐름을 강점으로 잡는 것이 현실적입니다.

완전 대체를 위한 기능 parity backlog는 `docs/tailscale_parity.md`에 별도로 관리합니다.

### 1. Private-first self-hosted control plane

device 목록, SSO session, audit log, DNS inventory를 자체 DB와 자체 서버에 둡니다.

강점:

- 조직이 서버와 데이터 저장 위치를 직접 통제합니다.
- public repo는 installer/release/docs만 노출하고 source와 운영 정책은 private repo에서 관리할 수 있습니다.
- 폐쇄망, homelab, SMB처럼 외부 SaaS 의존을 줄이고 싶은 환경에 맞출 수 있습니다.

### 2. SSO device lifecycle 중심 UX

`marumesh up`만으로 SSO 로그인, device 등록, 이름 확정, VPN 연결까지 끝나는 흐름을 기본값으로 둡니다.

강점:

- device 삭제 시 실행 중 agent가 로그아웃되고 다음 실행에서 재등록 flow로 들어갑니다.
- 같은 SSO owner의 device끼리 자동으로 peer/discovery 대상이 됩니다.
- device 이름은 최초 등록 후 자동으로 덮어쓰지 않고 dashboard/API rename 경로로만 바꿉니다.

### 3. MagicDNS inventory와 이름 관리

단순 DNS가 아니라 dashboard에서 owner, device, virtual IP, 마지막 로그인, DNS alias를 같이 관리합니다.

강점:

- `dev`, `stage`, `db`, `gpu-01` 같은 운영 short name을 조직 표준으로 관리할 수 있습니다.
- 이름 충돌, 삭제된 device, 공유받은 device의 DNS 상태를 UI에서 바로 확인할 수 있습니다.
- DNS 이름이 실제 device/session과 어떻게 연결되는지 감사할 수 있습니다.

### 4. Service catalog 기반 접속

SSH만 별도 기능으로 제공하기보다 device가 노출하는 `ssh`, `rdp`, `postgres`, `http` 같은 서비스를 수집해 CLI/tray/dashboard에서 바로 연결합니다.

예:

```bash
marumesh open dev ssh
marumesh open db postgres
```

강점:

- 사용자는 IP/port를 기억하지 않고 서비스 이름으로 접근합니다.
- 운영자는 device별 공개 서비스와 접근 이력을 dashboard에서 관리합니다.

### 5. 운영 감사와 강제 회수

누가 어떤 device/session/service에 접근했는지 자체 audit log를 남깁니다.

강점:

- device 삭제, owner 변경, 공유 회수 시 agent logout, DNS 제거, peer 연결 종료까지 한 번에 처리할 수 있습니다.
- 자체 DB에 감사 데이터를 남기므로 조직 요구에 맞는 retention/export 정책을 구현하기 쉽습니다.

### 6. Homelab/SMB용 단순 gateway

복잡한 네트워크 제품보다 Docker Compose, HAProxy, PostgreSQL 기반으로 바로 운영할 수 있는 설치형 mesh를 지향합니다.

예:

```bash
marumesh gateway enable --cidr 192.168.1.0/24
```

강점:

- 작은 조직이 별도 네트워크 엔지니어 없이 subnet gateway를 운영할 수 있습니다.
- 자체 control plane의 policy/dashboard와 바로 연결할 수 있습니다.

## 현재 MaruMesh가 반드시 만족해야 할 기준

아래는 Tailscale과 비교하기 전에 MaruMesh 자체가 만족해야 할 최소 UX입니다.

### 1. 같은 SSO 사용자 기기 간 자동 연결

같은 Google SSO 사용자로 등록된 device는 승인/정책 조건을 만족하면 peer 목록에 나타나야 합니다.

### 2. 이름 기반 접근

device 이름이 `dev`라면 다음이 동작해야 합니다.

```bash
nslookup dev
ping dev
ssh dev
```

가능하면 다음 alias도 동작해야 합니다.

```bash
nslookup dev.maru
ping dev.maru
ssh dev.maru
```

### 3. 일반 서비스 접근

mesh가 연결되면 SSH뿐 아니라 일반 TCP 서비스도 접근 가능해야 합니다.

예:

```bash
ssh dev
curl http://dev:3000
psql -h dev -p 5432
```

### 4. 이름 안정성

한 번 `dev`로 등록된 device는 `marumesh down` 후 `marumesh up`을 반복해도 이름이 바뀌면 안 됩니다.

### 5. IP 대역 충돌 회피

기본 virtual CIDR은 `100.64.0.0/24`입니다. 기존 네트워크와 겹치면 `MARUMESH_VIRTUAL_CIDR`를 바꿔야 합니다.

### 6. 권한 실패 전 등록 방지

Linux `tun` 모드에서 `/dev/net/tun` 또는 `CAP_NET_ADMIN` 권한이 없으면 device 등록을 만들기 전에 실패해야 합니다.

## 정리

MaruMesh가 지향하는 사용자 경험은 Tailscale과 비슷합니다.

- SSO 로그인
- 기기 등록
- 이름 기반 접근
- WireGuard 기반 보안 채널
- 중앙 control plane
- device 관리 dashboard

하지만 현재 MaruMesh는 “Tailscale 대체품”이라기보다, 특정 조직/운영 요구에 맞춘 자체 mesh control plane 구현입니다. Tailscale 수준의 완성도를 내려면 relay fallback, MagicDNS 수준의 DNS 통합, ACL/SSH 정책, subnet routing, packaging/signing, 관측성을 계속 보강해야 합니다.

## 참고한 Tailscale 공식 자료

- Tailscale WireGuard 개념 문서: https://tailscale.com/docs/concepts/wireguard
- Tailscale control/data plane 문서: https://tailscale.com/docs/concepts/control-data-planes
- Tailscale device connectivity 문서: https://tailscale.com/kb/1411/device-connectivity
- Tailscale DERP servers 문서: https://tailscale.com/kb/1232/derp-servers/
- Tailscale device 접속/MagicDNS 설명: https://tailscale.com/docs/how-to/connect-to-devices
- Tailscale SSH 문서: https://tailscale.com/docs/features/tailscale-ssh
