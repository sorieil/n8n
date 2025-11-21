#!/bin/bash

# n8n 볼륨 생성 스크립트

VOLUME_NAME="n8n_data"

echo "📦 n8n 볼륨 생성 중..."

# 볼륨이 이미 존재하는지 확인
if docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
    echo "⚠️  볼륨 '$VOLUME_NAME'이 이미 존재합니다."
    read -p "기존 볼륨을 삭제하고 새로 생성하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  기존 볼륨 삭제 중..."
        docker volume rm "$VOLUME_NAME"
        docker volume create "$VOLUME_NAME"
        echo "✅ 볼륨 생성 완료: $VOLUME_NAME"
    else
        echo "기존 볼륨을 유지합니다."
    fi
else
    docker volume create "$VOLUME_NAME"
    echo "✅ 볼륨 생성 완료: $VOLUME_NAME"
fi

