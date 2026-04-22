#!/bin/bash
# Prometheus・Loki 動作確認スクリプト
# 各クエリの実行結果を確認する

PROMETHEUS_URL="http://localhost:9090/api/v1/query"
LOKI_URL="http://localhost:3100/loki/api/v1/query_range"

echo "============================================"
echo "  Prometheus 動作確認"
echo "============================================"

echo ""
echo "--- [1] app_request_total ---"
curl -s "${PROMETHEUS_URL}?query=app_request_total" | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "--- [2] rate(app_request_total[1m]) ---"
curl -s "${PROMETHEUS_URL}?query=rate(app_request_total%5B1m%5D)" | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "--- [3] histogram_quantile(0.95, rate(app_request_latency_seconds_bucket[1m])) ---"
curl -s "${PROMETHEUS_URL}?query=histogram_quantile(0.95%2C%20rate(app_request_latency_seconds_bucket%5B1m%5D))" | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "--- [4] sum by (status) (rate(app_request_total[1m])) ---"
curl -s "${PROMETHEUS_URL}?query=sum%20by%20(status)%20(rate(app_request_total%5B1m%5D))" | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "============================================"
echo "  Loki 動作確認"
echo "============================================"

# 現在時刻から1時間前までの範囲でクエリ（macOS/Linux 両対応）
if date -u -v-1H +%s >/dev/null 2>&1; then
  # macOS (BSD date)
  START=$(date -u -v-1H +%s)000000000
else
  # Linux (GNU date)
  START=$(date -u -d '1 hour ago' +%s)000000000
fi
END=$(date -u +%s)000000000

echo ""
echo "--- [1] {container=\"demo-app\"} ログ取得 ---"
curl -s "${LOKI_URL}?query=%7Bcontainer%3D%22demo-app%22%7D&start=${START}&end=${END}&limit=5" | python3 -m json.tool 2>/dev/null | head -50

echo ""
echo "--- [2] {service=\"app\"} ログ取得 ---"
curl -s "${LOKI_URL}?query=%7Bservice%3D%22app%22%7D&start=${START}&end=${END}&limit=5" | python3 -m json.tool 2>/dev/null | head -50

echo ""
echo "--- [3] {container=\"demo-app\"} |= \"ERROR\" エラーログ確認 ---"
curl -s "${LOKI_URL}?query=%7Bcontainer%3D%22demo-app%22%7D%20%7C%3D%20%22ERROR%22&start=${START}&end=${END}&limit=5" | python3 -m json.tool 2>/dev/null | head -50

echo ""
echo "--- [4] {service=\"app\"} |= \"ERROR\" エラーログ確認（チケット #0003 必須） ---"
curl -s "${LOKI_URL}?query=%7Bservice%3D%22app%22%7D%20%7C%3D%20%22ERROR%22&start=${START}&end=${END}&limit=5" | python3 -m json.tool 2>/dev/null | head -50

echo ""
echo "--- [5] rate({service=\"app\"} |= \"ERROR\" [1m]) エラー頻度確認（チケット #0003 必須） ---"
curl -s "${LOKI_URL}?query=rate(%7Bservice%3D%22app%22%7D%20%7C%3D%20%22ERROR%22%20%5B1m%5D)&start=${START}&end=${END}&limit=5" | python3 -m json.tool 2>/dev/null | head -50

echo ""
echo "============================================"
echo "  確認完了"
echo "============================================"
