import logging
import random
import time
from flask import Flask, request
from prometheus_client import (
    Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
)

# ──────────────────────────────────
# ログ設定（Promtail が拾う）
# ──────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
logger = logging.getLogger("demo-app")

# ──────────────────────────────────
# Prometheus メトリクス定義
# ──────────────────────────────────
REQUEST_COUNT = Counter(
    "app_request_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
)

app = Flask(__name__)


# ──────────────────────────────────
# エンドポイント
# ──────────────────────────────────
@app.route("/")
def index():
    start = time.time()
    # ランダムに遅延を入れて「重いリクエスト」を再現
    delay = random.uniform(0.01, 0.5)
    time.sleep(delay)

    logger.info("Handled / — latency=%.3fs", delay)
    REQUEST_COUNT.labels("GET", "/", 200).inc()
    REQUEST_LATENCY.labels("/").observe(time.time() - start)
    return "Hello from demo app!\n"


@app.route("/error")
def error():
    logger.error("Intentional error triggered on /error")
    REQUEST_COUNT.labels("GET", "/error", 500).inc()
    return "Something went wrong!\n", 500


@app.route("/metrics")
def metrics():
    """Prometheus が scrape するエンドポイント"""
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
