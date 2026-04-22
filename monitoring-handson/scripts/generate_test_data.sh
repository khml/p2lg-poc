#!/bin/bash
# テストデータ生成スクリプト
# demo-app にリクエストを送信してメトリクス・ログデータを生成する

set -e

BASE_URL="http://localhost:5001"

echo "=== テストデータ生成開始 ==="

echo "通常リクエスト 30件 送信中..."
for i in $(seq 1 30); do
  curl -s "${BASE_URL}/" > /dev/null
done
echo "通常リクエスト完了"

echo "エラーリクエスト 5件 送信中..."
for i in $(seq 1 5); do
  curl -s "${BASE_URL}/error" > /dev/null
done
echo "エラーリクエスト完了"

echo "=== テストデータ生成完了 ==="
