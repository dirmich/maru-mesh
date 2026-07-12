# MaruMesh 작업 목록 (TODO)

## 완료된 작업
- [x] **프로젝트 초기화**
- [x] **에이전트 핵심 구현**
- [x] **보안 및 Identity**
- [x] **로컬 API 서버**
- [x] **제어 평면 연동**
- [x] **네트워킹 및 프록시**
- [x] **품질 및 안정성 보완**
- [x] **Phase 2: 액세스 및 정책 관리**
- [x] **Phase 3: 고급 네트워킹 및 NAT 트래버설 (WireGuard 통합 완료)**
    - [x] WireGuard 키 쌍(Curve25519) 생성 및 관리 로직 구현 완료
    - [x] ICE-WireGuard 브릿지(`ICEBind`) 및 Userspace 터널 래퍼 구현 완료
    - [x] 제어 평면 시그널링 릴레이 및 에이전트 자동 시그널링 루프 구현 완료
    - [x] CLI/SDK 연동 및 에이전트 간 자동 터널 형성 로직 통합 완료
- [x] **Phase 4: 플랫폼 확장 및 SDK 배포**
- [x] **Phase 5: 제어 평면(Control Plane) 백엔드 및 통합**
- [x] **Phase 6: 웹 통합 대시보드 및 중앙 관리**
    - [x] 사용자 및 관리자용 프리미엄 웹 대시보드 구축 완료
    - [x] 백엔드(`marumesh-server`) 내 정적 웹 호스팅 환경 연동 완료
    - [x] 그룹 기반 에이전트 필터링 및 관리 로직 구현 완료
    - [x] 관리자 전용 전체 사용 현황판 및 글로벌 룰 엔진 구축 (`oldtv.cf@gmail.com`)
    - [x] 에이전트 기본 백엔드 URL 동기화 (`marumesh.lab.highmaru.com`)

## 🎉 프로젝트 마일스톤 달성
- 모든 Phase(1~6)의 핵심 기능 구현 및 통합 완료.
- 서비스 제공자 및 사용자를 위한 엔드-투-엔드(E2E) 운영 체계 구축 완료.

## 향후 계획
- [ ] **v0.11.72 실기기 E2E 검증 완료**
    - [x] 중앙 서버, EC2 Linux 에이전트, macOS 에이전트를 모두 v0.11.72로 업그레이드하고 재시작
    - [x] 양쪽 peer 상태가 `Connected`인지 확인
    - [x] EC2(`10.77.0.2`) → Mac(`10.77.0.4`) ping 성공 확인 (5/5, 손실 0%, 평균 6.789ms)
    - [x] Mac(`10.77.0.4`) → EC2(`10.77.0.2`) ping 성공 확인 (5/5, 손실 0%, 평균 7.757ms)
    - [ ] 양방향 TCP/UDP 애플리케이션 트래픽 통신 확인
    - [x] 한쪽 에이전트를 재시작해 15초 응답 타임아웃과 자동 재연결이 정상 동작하는지 확인
    - [ ] 연결을 10분 이상 유지해 ICE가 불필요하게 `Disconnected`/`Failed`로 전환되지 않는지 확인
- [ ] **ICE/WireGuard 연결 수명주기 정리**
    - [ ] ICE 세션 교체 중 WireGuard가 닫힌 이전 endpoint에 패킷을 보내는 `the agent is closed` 오류 제거
    - [ ] 재연결 완료 시 기존 WireGuard peer와 `ICEBind` 연결이 원자적으로 교체되는지 회귀 테스트 추가
    - [ ] responder가 전달받은 `allowed_ips`를 실제 WireGuard IPC 설정에 반영하는 통합 테스트 추가
- [ ] **시그널링 신뢰성 보강**
    - [ ] `SendSignal`과 `ReceiveSignals`에서 HTTP 비정상 상태 코드를 오류로 처리
    - [ ] 요청/응답 유실, 상대 재시작, 중복 시그널을 포함하는 자동화된 2-node E2E 테스트 추가
- [ ] **DNS 및 로컬 운영 권한 정리**
    - [ ] Linux/macOS의 UDP 5353 충돌 원인을 제거하거나 MagicDNS와 ICE mDNS 포트를 분리
    - [ ] `policies.json`이 없을 때의 초기 정책 동기화 경고 처리 개선
    - [ ] macOS에서 root로 실행된 에이전트의 Unix socket을 일반 사용자 CLI가 안전하게 조회할 수 있도록 권한/소유권 정리
- [ ] **배포 패키지 보완**
    - [ ] macOS arm64 릴리스 바이너리 추가
    - [ ] macOS Developer ID 서명 및 notarization을 적용한 정식 배포 경로 구성
    - [ ] Docker 멀티아키텍처 builder를 구성하고 `linux/amd64`, `linux/arm64` 이미지를 함께 배포
- [ ] 정식 버전 1.0 릴리즈 패키징
