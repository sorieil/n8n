#!/bin/bash

# n8n 볼륨 복원 스크립트

VOLUME_NAME="n8n_data"
BACKUP_DIR="./backups"

# 백업 디렉토리 확인
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ 백업 디렉토리가 존재하지 않습니다: $BACKUP_DIR"
    exit 1
fi

# 백업 파일 목록 가져오기
BACKUP_FILES=($(ls -t "$BACKUP_DIR"/n8n_backup_*.tar.gz 2>/dev/null))

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
    echo "❌ 복원할 백업 파일이 없습니다."
    exit 1
fi

echo "📋 사용 가능한 백업 파일:"
echo ""
for i in "${!BACKUP_FILES[@]}"; do
    filename=$(basename "${BACKUP_FILES[$i]}")
    filesize=$(du -h "${BACKUP_FILES[$i]}" | cut -f1)
    filedate=$(echo "$filename" | sed -n 's/n8n_backup_\([0-9]\{8\}\)_\([0-9]\{6\}\)\.tar\.gz/\1 \2/p' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/' | sed 's/\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/ \1:\2:\3/')
    echo "  [$((i+1))] $filename"
    echo "      크기: $filesize | 날짜: $filedate"
done

echo ""
read -p "복원할 백업 번호를 선택하세요 (1-${#BACKUP_FILES[@]}): " selection

# 입력 검증
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#BACKUP_FILES[@]} ]; then
    echo "❌ 잘못된 선택입니다."
    exit 1
fi

SELECTED_BACKUP="${BACKUP_FILES[$((selection-1))]}"
echo ""
echo "선택한 백업: $(basename "$SELECTED_BACKUP")"
echo ""

# n8n 컨테이너가 실행 중인지 확인
if docker ps --format '{{.Names}}' | grep -q "^n8n$"; then
    echo "⚠️  n8n 컨테이너가 실행 중입니다."
    read -p "복원을 위해 컨테이너를 중지하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🛑 n8n 컨테이너 중지 중..."
        docker stop n8n
        sleep 2
    else
        echo "❌ 복원을 취소했습니다."
        exit 1
    fi
fi

# 볼륨이 존재하는지 확인하고, 없으면 생성
if ! docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
    echo "📦 볼륨이 존재하지 않아 생성합니다..."
    docker volume create "$VOLUME_NAME"
fi

# 복원 전 안전 백업 (현재 볼륨 내용이 있으면)
echo "💾 복원 전 안전 백업 생성 중..."
SAFETY_BACKUP="$BACKUP_DIR/safety_backup_before_restore_$(date +%Y%m%d_%H%M%S).tar.gz"
docker run --rm \
  -v "$VOLUME_NAME":/data:ro \
  -v "$(pwd)/$BACKUP_DIR":/backup \
  alpine \
  tar czf "/backup/$(basename $SAFETY_BACKUP)" -C /data . 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 안전 백업 완료: $(basename $SAFETY_BACKUP)"
else
    echo "ℹ️  볼륨이 비어있거나 백업할 내용이 없습니다."
fi

echo ""
echo "🔄 볼륨 복원 중..."
echo "백업 파일: $(basename "$SELECTED_BACKUP")"

# 볼륨 내용 삭제 후 복원
docker run --rm \
  -v "$VOLUME_NAME":/data \
  -v "$(pwd)/$BACKUP_DIR":/backup \
  alpine \
  sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null; tar xzf \"/backup/$(basename "$SELECTED_BACKUP")\" -C /data"

if [ $? -eq 0 ]; then
    echo "✅ 복원 완료!"
    echo ""
    echo "다음 명령어로 n8n을 실행하세요:"
    echo "  ./run-n8n.sh"
else
    echo "❌ 복원 실패"
    exit 1
fi

