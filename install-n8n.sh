#!/bin/bash

# n8n 초기 설치 스크립트 (라이센스 포함)

VOLUME_NAME="n8n_data"
N8N_LICENSE="4f5ca5fe-f3ce-466f-9636-fd4bf22fe0b3"

echo "🚀 n8n 초기 설치 중..."
echo ""

# 볼륨이 이미 존재하는지 확인
if docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
    echo "⚠️  볼륨 '$VOLUME_NAME'이 이미 존재합니다."
    echo "이 스크립트는 새로 설치할 때만 사용하세요."
    read -p "기존 볼륨을 삭제하고 새로 설치하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "설치를 취소했습니다."
        exit 1
    fi
    echo "🗑️  기존 볼륨 삭제 중..."
    docker volume rm "$VOLUME_NAME"
fi

# 볼륨 생성
echo "📦 볼륨 생성 중..."
docker volume create "$VOLUME_NAME"
echo "✅ 볼륨 생성 완료: $VOLUME_NAME"

echo ""
echo "🚀 n8n 시작 중 (라이센스 포함)..."
echo "접속 URL: http://localhost:5678"
echo ""

# n8n 실행 (라이센스 포함)
docker run -it --rm \
  -d \
  --name n8n \
  -p 5678:5678 \
  -v "$VOLUME_NAME":/home/node/.n8n \
  -e N8N_LICENSE="$N8N_LICENSE" \
  docker.n8n.io/n8nio/n8n

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ n8n 설치 완료!"
    echo ""
    echo "다음부터는 ./run-n8n.sh를 사용하여 실행하세요."
else
    echo "❌ n8n 설치 실패"
    exit 1
fi

