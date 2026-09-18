# macOS App Store Connect 패키징

이 문서는 source repo 내부 릴리스 엔지니어링용 문서입니다. `publish.sh`는 이 문서를 public repo에 동기화하지 않습니다.

## 현재 범위

`make appstore-pkg`는 App Store Connect 업로드에 사용할 수 있는 macOS `.app` 번들과 signed `.pkg`를 생성합니다.

현재 산출물은 **업로드 가능한 패키지 형식**을 만드는 단계입니다. App Store 심사 통과를 보장하지 않습니다. MaruMesh의 현재 CLI/TUN 구현은 관리자 권한, TUN 인터페이스 생성, 백그라운드 agent 동작을 사용하므로 Mac App Store용 제품으로 완성하려면 다음 구조 보강이 필요합니다.

- GUI 앱 번들 중심의 사용자 실행 경로
- App Sandbox 기준에 맞는 파일/네트워크 권한 정리
- VPN/TUN 동작을 Network Extension 기반으로 이전
- 로그인, device 관리, menubar 상태 표시를 앱 UI 경계 안으로 정리

GitHub Release에 올리는 직접 설치용 macOS 산출물은 기존처럼 Developer ID Application/Developer ID Installer 서명과 notarization으로 배포합니다. App Store Connect 업로드용 패키지는 Apple Distribution 및 3rd Party Mac Developer Installer 인증서를 사용하며, GitHub에서 직접 다운로드해 여는 설치 파일로 쓰지 않습니다.

## 필요한 인증서

Keychain에 다음 identity가 보여야 합니다.

```bash
security find-identity -v | grep "Apple Distribution"
security find-identity -v | grep "3rd Party Mac Developer Installer"
```

현재 Highmaru 계정 기준 예:

```bash
export APPSTORE_APP_IDENTITY="Apple Distribution: Highmaru, Inc. (X4V7W6GE8X)"
export APPSTORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Highmaru, Inc. (X4V7W6GE8X)"
```

## 빌드

macOS에서 실행합니다. Intel Mac은 기본적으로 `darwin-amd64`, Apple Silicon Mac은 `darwin-arm64`를 사용합니다.

```bash
make appstore-pkg
```

아키텍처를 명시하려면 다음처럼 실행합니다.

```bash
HOST_ARCH=amd64 make appstore-pkg
HOST_ARCH=arm64 make appstore-pkg
```

출력:

```text
dist/appstore/MaruMesh-<version>-darwin-<arch>-appstore.pkg
```

실제 서명/패키징 전에 identity와 출력 경로만 확인하려면:

```bash
DRY_RUN=true make appstore-pkg
```

Codex/비대화형 shell에서 `security find-identity`가 인증서를 못 찾는 경우 login shell로 실행합니다.

```bash
/bin/zsh -lc 'make appstore-pkg'
```

## 검증

스크립트 문법:

```bash
bash -n scripts/build_macos_appstore_pkg.sh
```

패키지 서명:

```bash
pkgutil --check-signature dist/appstore/MaruMesh-<version>-darwin-<arch>-appstore.pkg
```

앱 번들 서명은 스크립트 안에서 `codesign --verify --strict --verbose=2`로 확인합니다.

## 업로드

생성된 `.pkg`는 Transporter 또는 App Store Connect 업로드 경로로 제출합니다. 업로드가 성공해도 심사에서 sandbox, entitlement, Network Extension 사용 방식, 백그라운드 실행 정책을 다시 검사합니다.

현재 MaruMesh를 App Store에서 “VPN 앱”으로 제공하려면 단순 패키징을 넘어 Network Extension entitlement와 앱 번들 중심 구조를 별도 구현해야 합니다.
