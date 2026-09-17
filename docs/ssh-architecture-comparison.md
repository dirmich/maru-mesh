# MaruMesh SSH 설계

## 선택

MaruMesh는 내장 SSH 서버 대신 기존 OpenSSH와 연동한다.

- 각 장치가 전용 Ed25519 키를 로컬에서 생성한다.
- 개인키는 장치 밖으로 보내지 않고 Control Plane에는 공개키만 저장한다.
- 대상 Linux의 sshd는 `AuthorizedKeysCommand`로 접속할 때마다 Control Plane에 인가를 요청한다.
- 소스 가상 IP, 등록 공개키, 대상 장치 상태와 정책이 모두 맞아야 접속된다.
- 일반 계정은 `ssh:connect`, root는 별도의 `ssh:root` 정책이 필요하다.

```bash
sudo marumesh up --ssh   # mesh와 SSH 활성화
sudo marumesh ssh on     # SSH 활성화
sudo marumesh ssh off    # SSH 비활성화
marumesh ssh refresh     # 로컬 키 교체 및 공개키 재등록
marumesh ssh status
ssh ec2-user@server.maru
```

대시보드는 `ssh_enabled` 장치에 SSH 배지를 표시한다.

## Tailscale과 차이

Tailscale은 mesh IP의 22번 포트에 자체 SSH 서버를 실행한다. 기존 sshd를 활용하는 MaruMesh 방식은 PAM, SELinux, SCP/SFTP 등 OpenSSH 기능을 그대로 쓸 수 있어 구현과 운영이 단순하다. 반면 sshd 설정을 추가해야 하고 MaruMesh 자체 세션 제어나 녹화 기능은 제한된다.

참고: [Tailscale SSH 문서](https://tailscale.com/kb/1193/tailscale-ssh), [공개 구현](https://github.com/tailscale/tailscale/blob/main/ssh/tailssh/tailssh.go)

## 후속 범위

- OS 계정별 정책 표현
- 기존 세션에 대한 정책 변경 적용
- 자동 주기 키 회전
- macOS 대상 서버 지원
