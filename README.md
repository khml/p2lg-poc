# p2lg-poc — Prometheus + Loki + Promtail + Grafana ハンズオン

メトリクス・ログの収集から可視化までの全体像を学ぶためのミニマル構成のPoC。  
サンプルWebアプリ（Python/Flask）がメトリクスとログを出力し、Prometheus / Loki が収集し、Grafana で可視化する。

---

## アーキテクチャ

```
┌──────────┐        scrape /metrics         ┌─────────────┐
│ demo-app │  ◄──────────────────────────── │  Prometheus  │──┐
│ (Flask)  │   メトリクス (数値)             │  :9090       │  │
│  :5000   │                                └─────────────┘  │
│          │                                                  │  ┌──────────┐
│  stdout  │──┐                                               ├─►│ Grafana  │
│  (ログ)  │  │  Promtail が読み取り         ┌─────────────┐  │  │  :3000   │
└──────────┘  │                             │    Loki      │──┘  └──────────┘
              └──► Promtail ───push───────► │  :3100       │
                   :9080                    └─────────────┘
```

| コンポーネント | 役割 | コンテナ内ポート |
|---|---|---|
| demo-app | Flask製サンプルアプリ。`/metrics` でメトリクスを公開 | 5000 |
| Prometheus | メトリクスをpull型で収集 | 9090 |
| Loki | ログを受信・保存・検索 | 3100 |
| Promtail | コンテナログをLokiへ転送 | 9080 |
| Grafana | Prometheus/Lokiのデータを可視化 | 3000 |

---

## ディレクトリ構成

```
p2lg-poc/
├── monitoring-handson/          # メインの実装ディレクトリ
│   ├── docker-compose.yml       # 全サービスの定義
│   ├── app/
│   │   ├── main.py              # Flaskアプリ本体
│   │   ├── requirements.txt     # Python依存パッケージ
│   │   └── Dockerfile           # アプリのコンテナ定義
│   ├── prometheus/
│   │   └── prometheus.yml       # スクレイプ設定
│   ├── loki/
│   │   └── loki-config.yml      # Loki設定
│   ├── promtail/
│   │   └── promtail-config.yml  # ログ収集設定
│   ├── grafana/
│   │   ├── datasources.yml      # データソース自動登録設定
│   │   ├── dashboards.yml       # ダッシュボードプロビジョニング設定
│   │   └── demo-dashboard.json  # サンプルダッシュボード定義
│   └── scripts/
│       ├── generate_test_data.sh  # テストデータ生成スクリプト
│       └── verify_queries.sh      # クエリ動作確認スクリプト
├── docs/
│   ├── roadmap.md               # プロジェクトロードマップ
│   ├── architecture.md          # アーキテクチャ詳細
│   └── handson-guide.md         # ハンズオン学習ガイド
└── tickets/                     # タスクチケット管理
```

---

## クイックスタート

```bash
# 1. 環境を起動
cd monitoring-handson
docker compose up -d --build

# 2. テストデータを生成
bash scripts/generate_test_data.sh
```

### アクセス先

> ⚠️ ポートは環境によって変更されている場合があります（`docker-compose.yml` を確認してください）

| サービス | デフォルトURL |
|---|---|
| demo-app | http://localhost:5001 |
| Prometheus | http://localhost:9090 |
| Loki API | http://localhost:3100 |
| Grafana | http://localhost:3003（admin/admin） |

> ⚠️ このプロジェクトは**ローカル開発・学習目的専用**です。外部公開環境では使用しないでください。
> Grafana の匿名アクセスが有効になっており、本番利用には適していません。

### 停止・クリーンアップ

```bash
docker compose down -v
```

---

## 学習ガイド

詳細は [docs/handson-guide.md](docs/handson-guide.md) を参照してください。

### Prometheus（PromQL）

http://localhost:9090 を開き、以下のクエリを試す。

| クエリ | 学べること |
|---|---|
| `app_request_total` | Counter 型メトリクスの基本 |
| `rate(app_request_total[1m])` | `rate()` 関数の使い方 |
| `histogram_quantile(0.95, rate(app_request_latency_seconds_bucket[1m]))` | Histogram 型の分析 |
| `sum by (status) (rate(app_request_total[1m]))` | ラベルでのグルーピング |

### Loki（LogQL）

Grafana の **Explore** 画面でデータソースを **Loki** に切り替えて試す。

| クエリ | 学べること |
|---|---|
| `{service="app"}` | ラベルセレクタの基本 |
| `{service="app"} \|= "ERROR"` | フィルタ式 |
| `rate({service="app"} \|= "ERROR" [1m])` | ログからメトリクスを作る |

---

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/software-guide.md](docs/software-guide.md) | 初心者向けソフトウェア解説（各ツールの目的・役割） |
| [docs/handson-guide.md](docs/handson-guide.md) | ハンズオン学習ガイド（クエリ集・ダッシュボード作成手順） |
| [docs/architecture.md](docs/architecture.md) | アーキテクチャ詳細・コンポーネント説明 |
| [docs/roadmap.md](docs/roadmap.md) | プロジェクトロードマップ・フェーズ計画 |

---

## 技術スタック

| カテゴリ | 技術 | バージョン |
|---|---|---|
| サンプルアプリ | Python / Flask | Flask 3.1.0 |
| メトリクス収集 | Prometheus | prom/prometheus:latest |
| ログ収集バックエンド | Loki | grafana/loki:latest |
| ログ転送エージェント | Promtail | grafana/promtail:latest |
| 可視化 | Grafana | grafana/grafana:latest |
| コンテナ管理 | Docker Compose | - |
| メトリクスライブラリ | prometheus-client | 0.21.1 |
