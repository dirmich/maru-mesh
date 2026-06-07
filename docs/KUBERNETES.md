# MaruMesh Kubernetes 배포 가이드 (Helm)

이 문서는 Helm을 사용하여 MaruMesh 제어 평면(Server)을 Kubernetes 클러스터에 배포하는 방법을 설명합니다.

## 전제 조건
- Kubernetes 클러스터 v1.19+
- Helm v3+
- (선택 사항) Ingress Controller (Nginx, Traefik 등)
- Google OAuth2 Client ID 및 Secret

## 설치 단계

### 1. 전역 설정(values.yaml) 수정
배포 전 `auth` 섹션에 실제 Google OAuth2 정보를 입력해야 합니다.

```yaml
auth:
  googleClientID: "YOUR_CLIENT_ID"
  googleClientSecret: "YOUR_CLIENT_SECRET"
  callbackURL: "https://marumesh.your-domain.com/api/v1/auth/callback"
```

### 2. Helm 차트 설치
차트 디렉토리에서 다음 명령을 실행합니다.

```bash
helm install marumesh ./deploy/charts/marumesh-server
```

### 3. 영구 저장소(Persistence) 확인
기본적으로 1Gi 크기의 PVC가 생성되어 `devices.json` 데이터가 영구 보존됩니다.

```bash
kubectl get pvc
```

## 주요 설정 파라미터

| 매개변수 | 설명 | 기본값 |
|----------|------|--------|
| `replicaCount` | 실행할 서버 포드 수 | `1` |
| `service.type` | 서비스 노출 방식 | `ClusterIP` |
| `persistence.size` | 데이터 저장 공간 크기 | `1Gi` |
| `auth.googleClientID` | Google OAuth2 클라이언트 ID | `""` |
| `ingress.enabled` | Ingress 활성화 여부 | `false` |

## 삭제
```bash
helm uninstall marumesh
```
