#!/bin/bash

# n8n 볼륨 백업 및 실행 스크립트

# 볼륨 이름
VOLUME_NAME="n8n_data"
BACKUP_DIR="./backups"

# n8n 라이센스
N8N_LICENSE="4f5ca5fe-f3ce-466f-9636-fd4bf22fe0b3"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 백업 파일명 (타임스탬프 포함)
BACKUP_FILE="$BACKUP_DIR/n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "📦 n8n 볼륨 백업 중..."
echo "백업 파일: $BACKUP_FILE"

# 볼륨 백업 수행
docker run --rm \
  -v "$VOLUME_NAME":/data:ro \
  -v "$(pwd)/$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/$(basename $BACKUP_FILE)" -C /data .

if [ $? -eq 0 ]; then
    echo "✅ 백업 완료: $BACKUP_FILE"
    
    # 오래된 백업 파일 정리 (선택사항: 최근 10개만 유지)
    echo "🧹 오래된 백업 파일 정리 중..."
    cd "$BACKUP_DIR"
    ls -t n8n_backup_*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f
    cd ..
else
    echo "❌ 백업 실패"
    exit 1
fi

echo ""
echo "🚀 n8n 시작 중..."
echo "접속 URL: http://localhost:5678"
echo ""

# n8n 실행
docker run -it --rm \
  -d \
  --name n8n \
  -p 5678:5678 \
  -v "$VOLUME_NAME":/home/node/.n8n \
  -e N8N_LICENSE="$N8N_LICENSE" \
  docker.n8n.io/n8nio/n8n

