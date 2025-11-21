# n8n Docker 관리 스크립트

n8n을 Docker로 실행하고 자동 백업/복원 기능을 제공하는 스크립트 모음입니다.

## 📋 목차

- [요구사항](#요구사항)
- [파일 구조](#파일-구조)
- [빠른 시작](#빠른-시작)
- [상세 사용법](#상세-사용법)
- [주요 기능](#주요-기능)
- [백업 관리](#백업-관리)
- [문제 해결](#문제-해결)

## 요구사항

- Docker 설치 및 실행 중
- Bash 쉘 환경
- 실행 권한 (스크립트는 자동으로 설정됨)

## 파일 구조

```
.
├── README.md              # 이 메뉴얼
├── setup-n8n.sh          # 볼륨 초기 설정 스크립트
├── run-n8n.sh            # 백업 후 n8n 실행 스크립트
├── restore-n8n.sh        # 볼륨 복원 스크립트
└── backups/              # 백업 파일 저장 디렉토리 (자동 생성)
    ├── n8n_backup_YYYYMMDD_HHMMSS.tar.gz
    └── ...
```

## 빠른 시작

### 1. 초기 설정 (최초 1회)

```bash
./setup-n8n.sh
```

Docker 볼륨 `n8n_data`를 생성합니다. 이미 존재하는 경우 덮어쓸지 물어봅니다.

### 2. n8n 실행

```bash
./run-n8n.sh
```

- 자동으로 볼륨을 백업합니다
- 백업 후 n8n을 백그라운드로 실행합니다
- 접속 URL: http://localhost:5678

### 3. 복원 (필요 시)

```bash
./restore-n8n.sh
```

백업 목록에서 복원할 파일을 선택합니다.

## 상세 사용법

### setup-n8n.sh - 볼륨 초기 설정

**용도**: n8n 데이터를 저장할 Docker 볼륨을 생성합니다.

**사용 시점**: 
- 최초 1회 실행
- 볼륨을 완전히 초기화하고 싶을 때

**실행 예시**:
```bash
$ ./setup-n8n.sh
📦 n8n 볼륨 생성 중...
✅ 볼륨 생성 완료: n8n_data
```

**주의사항**:
- 기존 볼륨이 있으면 삭제 여부를 확인합니다
- 볼륨 삭제 시 모든 데이터가 사라집니다

---

### run-n8n.sh - n8n 실행 (자동 백업)

**용도**: n8n을 실행하기 전에 자동으로 백업을 수행하고 n8n을 시작합니다.

**주요 기능**:
1. 백업 디렉토리 자동 생성
2. 현재 볼륨 내용 백업 (타임스탬프 포함)
3. 오래된 백업 파일 정리 (최근 10개만 유지)
4. n8n 컨테이너 백그라운드 실행

**실행 예시**:
```bash
$ ./run-n8n.sh
📦 n8n 볼륨 백업 중...
백업 파일: ./backups/n8n_backup_20241121_143022.tar.gz
✅ 백업 완료: ./backups/n8n_backup_20241121_143022.tar.gz
🧹 오래된 백업 파일 정리 중...

🚀 n8n 시작 중...
접속 URL: http://localhost:5678
```

**백업 파일 형식**:
- 파일명: `n8n_backup_YYYYMMDD_HHMMSS.tar.gz`
- 예시: `n8n_backup_20241121_143022.tar.gz`
- 위치: `./backups/` 디렉토리

**백업 관리**:
- 최근 10개의 백업만 유지 (오래된 파일 자동 삭제)
- 백업 실패 시 n8n 실행이 중단됩니다

**컨테이너 관리**:
- 컨테이너 이름: `n8n`
- 포트: `5678:5678`
- 볼륨: `n8n_data:/home/node/.n8n`
- 실행 모드: 백그라운드 (`-d`)

---

### restore-n8n.sh - 볼륨 복원

**용도**: 이전에 백업한 볼륨 데이터로 복원합니다.

**주요 기능**:
1. 사용 가능한 백업 파일 목록 표시
2. 대화형으로 복원할 백업 선택
3. 실행 중인 컨테이너 자동 감지 및 중지 확인
4. 복원 전 현재 상태 자동 백업 (안전 백업)
5. 선택한 백업으로 볼륨 복원

**실행 예시**:
```bash
$ ./restore-n8n.sh
📋 사용 가능한 백업 파일:

  [1] n8n_backup_20241121_143022.tar.gz
      크기: 15M | 날짜: 2024-11-21 14:30:22
  [2] n8n_backup_20241121_120000.tar.gz
      크기: 14M | 날짜: 2024-11-21 12:00:00

복원할 백업 번호를 선택하세요 (1-2): 1

선택한 백업: n8n_backup_20241121_143022.tar.gz

💾 복원 전 안전 백업 생성 중...
✅ 안전 백업 완료: safety_backup_before_restore_20241121_150000.tar.gz

🔄 볼륨 복원 중...
백업 파일: n8n_backup_20241121_143022.tar.gz
✅ 복원 완료!

다음 명령어로 n8n을 실행하세요:
  ./run-n8n.sh
```

**안전 기능**:
- 복원 전 현재 볼륨 내용을 자동으로 백업합니다
- 안전 백업 파일명: `safety_backup_before_restore_YYYYMMDD_HHMMSS.tar.gz`
- 복원 실패 시 안전 백업으로 되돌릴 수 있습니다

**주의사항**:
- n8n 컨테이너가 실행 중이면 복원 전에 중지해야 합니다
- 복원은 볼륨의 모든 내용을 덮어씁니다

---

## 주요 기능

### ✅ 자동 백업
- n8n 실행 전 자동 백업
- 타임스탬프가 포함된 백업 파일명
- 최근 10개 백업 자동 관리

### ✅ 안전한 복원
- 복원 전 현재 상태 자동 백업
- 대화형 백업 선택
- 실행 중인 컨테이너 자동 감지

### ✅ 사용자 친화적
- 명확한 상태 메시지
- 에러 처리 및 검증
- 단계별 진행 상황 표시

## 백업 관리

### 백업 파일 위치
```
./backups/
├── n8n_backup_20241121_143022.tar.gz
├── n8n_backup_20241121_120000.tar.gz
└── safety_backup_before_restore_20241121_150000.tar.gz
```

### 백업 파일 종류

1. **일반 백업** (`n8n_backup_*.tar.gz`)
   - `run-n8n.sh` 실행 시 자동 생성
   - 최근 10개만 유지

2. **안전 백업** (`safety_backup_before_restore_*.tar.gz`)
   - `restore-n8n.sh` 실행 시 자동 생성
   - 복원 전 현재 상태 보존용

### 백업 수동 관리

백업 파일을 직접 관리하려면:

```bash
# 백업 목록 확인
ls -lh backups/

# 특정 백업 삭제
rm backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz

# 모든 백업 삭제 (주의!)
rm backups/*.tar.gz
```

## 문제 해결

### n8n 컨테이너가 이미 실행 중입니다

**증상**: `run-n8n.sh` 실행 시 컨테이너 이름 충돌

**해결**:
```bash
# 실행 중인 컨테이너 확인
docker ps

# 기존 컨테이너 중지 및 삭제
docker stop n8n
docker rm n8n

# 다시 실행
./run-n8n.sh
```

### 볼륨이 존재하지 않습니다

**증상**: `run-n8n.sh` 실행 시 볼륨 오류

**해결**:
```bash
# 볼륨 생성
./setup-n8n.sh

# 다시 실행
./run-n8n.sh
```

### 백업 파일이 없습니다

**증상**: `restore-n8n.sh` 실행 시 백업 파일 없음

**해결**:
- `run-n8n.sh`를 최소 1회 실행하여 백업 생성
- `backups/` 디렉토리에 백업 파일이 있는지 확인

### 복원 후 n8n이 정상 작동하지 않습니다

**해결**:
1. 안전 백업으로 다시 복원:
   ```bash
   # 안전 백업 파일 확인
   ls -lh backups/safety_backup_*
   
   # 안전 백업 파일을 일반 백업으로 복사 후 복원
   cp backups/safety_backup_before_restore_*.tar.gz backups/n8n_backup_restore.tar.gz
   ./restore-n8n.sh
   ```

2. 컨테이너 로그 확인:
   ```bash
   docker logs n8n
   ```

### 포트가 이미 사용 중입니다

**증상**: 포트 5678이 이미 사용 중

**해결**:
```bash
# 포트 사용 중인 프로세스 확인
lsof -i :5678

# 다른 포트로 실행하려면 run-n8n.sh 수정
# -p 5678:5678 부분을 원하는 포트로 변경
```

## 추가 정보

### Docker 볼륨 확인

```bash
# 볼륨 목록 확인
docker volume ls

# 볼륨 상세 정보
docker volume inspect n8n_data

# 볼륨 내용 확인 (임시 컨테이너 사용)
docker run --rm -v n8n_data:/data alpine ls -la /data
```

### n8n 컨테이너 관리

```bash
# 실행 중인 컨테이너 확인
docker ps | grep n8n

# 컨테이너 로그 확인
docker logs n8n

# 컨테이너 중지
docker stop n8n

# 컨테이너 삭제 (중지 후)
docker rm n8n

# 컨테이너 재시작
docker restart n8n
```

### 백업 파일 크기 확인

```bash
# 백업 디렉토리 크기
du -sh backups/

# 개별 백업 파일 크기
ls -lh backups/
```

## 라이선스

이 스크립트는 n8n 프로젝트와 독립적으로 제공됩니다.

## 참고 자료

- [n8n 공식 문서](https://docs.n8n.io/)
- [Docker 공식 문서](https://docs.docker.com/)
- [n8n Docker 이미지](https://hub.docker.com/r/n8nio/n8n)

