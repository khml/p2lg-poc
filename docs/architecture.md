# アーキテクチャ詳細

## システム概要

このプロジェクトは、Prometheus + Loki + Promtail + Grafana を Docker Compose で構成したミニマルな監視スタックです。
サンプルWebアプリ（demo-app）が生成するメトリクスとログを、それぞれ異なるパイプラインで収集し、Grafana で統合可視化します。

---

## 全体アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Network                            │
│                                                                  │
│  ┌──────────┐        scrape /metrics         ┌─────────────┐   │
│  │ demo-app │  ◄──────────────────────────── │  Prometheus  │──┐│
│  │ (Flask)  │   メトリクス pull               │  :9090       │  ││
│  │  :5000   │                                └─────────────┘  ││
│  │          │                                                   ││  ┌──────────┐
│  │  stdout  │──┐                                                ├─►│ Grafana  │
│  │  (ログ)  │  │  Promtail がDockerソケット経由で読み取り        ││  │  :3000   │
│  └──────────┘  │                             ┌─────────────┐  ││  └──────────┘
│                └──► Promtail ───push───────► │    Loki      │──┘│
│                     :9080                    │  :3100       │   │
│                                              └─────────────┘   │
└─────────────────────────────────────────────────────────────────┘
         ↑ホスト側からアクセス可能なポートはdocker-compose.ymlで定義
```

---

## コンポーネント詳細

### demo-app（Flask サンプルアプリ）

| 項目 | 内容 |
|---|---|
| ベースイメージ | python:3.12-slim |
| フレームワーク | Flask 3.1.0 |
| メトリクスライブラリ | prometheus-client 0.21.1 |
| コンテナ内ポート | 5000 |

#### エンドポイント

| パス | 説明 |
|---|---|
| `GET /` | 正常レスポンス。0.01〜0.5秒のランダム遅延を含む |
| `GET /error` | 意図的にエラー（500）を返す |
| `GET /metrics` | Prometheus がスクレイプするメトリクスエンドポイント |

#### 定義されているメトリクス

| メトリクス名 | 型 | ラベル | 説明 |
|---|---|---|---|
| `app_request_total` | Counter | method, endpoint, status | HTTPリクエスト総数 |
| `app_request_latency_seconds` | Histogram | endpoint | リクエストレイテンシ（秒） |

---

### Prometheus（メトリクス収集）

| 項目 | 内容 |
|---|---|
| イメージ | prom/prometheus:latest |
| コンテナ内ポート | 9090 |
| スクレイプ間隔 | 5秒 |
| 設定ファイル | `prometheus/prometheus.yml` |

#### スクレイプターゲット

| ジョブ名 | ターゲット | 内容 |
|---|---|---|
| prometheus | localhost:9090 | Prometheus 自身のメトリクス |
| demo-app | app:5000 | サンプルアプリのメトリクス |

---

### Loki（ログ収集バックエンド）

| 項目 | 内容 |
|---|---|
| イメージ | grafana/loki:latest |
| コンテナ内ポート | 3100 |
| 設定ファイル | `loki/loki-config.yml` |

#### 設定概要

| 項目 | 値 | 説明 |
|---|---|---|
| 認証 | 無効（auth_enabled: false） | 開発環境向け設定 |
| KV ストア | inmemory | 永続化なし（PoC向け） |
| スキーマ | v13 (tsdb) | ログインデックス方式 |
| ストレージ | filesystem | コンテナ内 `/loki/chunks` |

---

### Promtail（ログ転送エージェント）

| 項目 | 内容 |
|---|---|
| イメージ | grafana/promtail:latest |
| コンテナ内ポート | 9080 |
| 設定ファイル | `promtail/promtail-config.yml` |

#### ログ収集の仕組み

Promtail は Docker ソケット（`/var/run/docker.sock`）を通じて、実行中のコンテナのログを自動検出する。

**付与されるラベル:**

| ラベル | 値 | 付与元 |
|---|---|---|
| `container` | コンテナ名（例: `demo-app`） | `__meta_docker_container_name` |
| `service` | Compose サービス名（例: `app`） | `__meta_docker_container_label_com_docker_compose_service` |
| `detected_level` | `info` / `error` など | Loki が自動検出 |

---

### Grafana（可視化）

| 項目 | 内容 |
|---|---|
| イメージ | grafana/grafana:latest |
| コンテナ内ポート | 3000 |
| デフォルト認証 | admin / admin |
| 匿名アクセス | 有効（`GF_AUTH_ANONYMOUS_ENABLED=true`） |

#### プロビジョニング（自動設定）

起動時に以下が自動で設定される:

| 設定ファイル | 内容 |
|---|---|
| `grafana/datasources.yml` | Prometheus・Loki のデータソースを登録 |
| `grafana/dashboards.yml` | ダッシュボードのロードパスを設定 |
| `grafana/demo-dashboard.json` | サンプルダッシュボードを定義 |

#### サンプルダッシュボード（demo-app 監視ダッシュボード）

| パネル | データソース | クエリ |
|---|---|---|
| リクエストレート | Prometheus | `sum by (status) (rate(app_request_total[1m]))` |
| レイテンシ（p95） | Prometheus | `histogram_quantile(0.95, rate(app_request_latency_seconds_bucket[1m]))` |
| リクエスト総数 | Prometheus | `sum(app_request_total{status="200"})` |
| エラー総数 | Prometheus | `sum(app_request_total{status="500"})` |
| エラーログ | Loki | `{container="demo-app"} \|= "ERROR"` |
| アプリログ（全件） | Loki | `{service="app"}` |

---

## データフロー

### メトリクスフロー

```
demo-app（/metrics エンドポイント）
  ↑ Pull（5秒ごと）
Prometheus（保存・クエリ）
  ↑ Query（PromQL）
Grafana（可視化）
```

### ログフロー

```
demo-app（stdout へ出力）
  ↓ Docker ログドライバ
Docker ログ
  ↓ Promtail が読み取り（Docker ソケット経由）
Loki（保存・クエリ）
  ↑ Query（LogQL）
Grafana（可視化）
```

---

## Docker Compose ネットワーク

全サービスは同一の Docker Compose デフォルトネットワークに接続されており、サービス名で相互通信が可能。

| 通信 | 使用するホスト名 |
|---|---|
| Prometheus → demo-app | `app:5000` |
| Promtail → Loki | `loki:3100` |
| Grafana → Prometheus | `prometheus:9090` |
| Grafana → Loki | `loki:3100` |
