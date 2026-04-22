# ハンズオン学習ガイド

このガイドでは、起動した監視環境を使って Prometheus・Loki・Grafana の基本操作を学びます。

---

## 事前準備

### 1. 環境の起動

```bash
cd monitoring-handson
docker compose up -d --build
```

### 2. テストデータの生成

```bash
bash scripts/generate_test_data.sh
```

正常リクエスト30件・エラーリクエスト5件が送信され、メトリクスとログが生成されます。

### ディレクトリ構成

```
monitoring-handson/
├── app/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── grafana/
│   ├── dashboards.yml
│   ├── datasources.yml
│   └── demo-dashboard.json
├── loki/
│   └── loki-config.yml
├── prometheus/
│   └── prometheus.yml
├── promtail/
│   └── promtail-config.yml
├── scripts/
│   ├── generate_test_data.sh
│   └── verify_queries.sh
└── docker-compose.yml
```

### アクセス先

> ポートはホスト環境によって異なる場合があります。`docker-compose.yml` を確認してください。

| サービス | URL |
|---|---|
| demo-app | http://localhost:5001 |
| Prometheus | http://localhost:9090 |
| Grafana | http://localhost:3003（admin/admin） |

---

## ステップ1: Prometheus でメトリクスを見る

ブラウザで **http://localhost:9090** を開いてください。

### 基本クエリ（PromQL）

#### リクエスト総数を見る

```promql
app_request_total
```

- **学べること**: Counter 型メトリクスの基本
- **見方**: `status="200"` と `status="500"` に分かれてカウントが表示される

#### 1分あたりのリクエスト率

```promql
rate(app_request_total[1m])
```

- **学べること**: `rate()` 関数の使い方
- **見方**: Counter の増加率（req/s）に変換される。`[1m]` は直近1分間のウィンドウ

#### レイテンシの95パーセンタイル

```promql
histogram_quantile(0.95, rate(app_request_latency_seconds_bucket[1m]))
```

- **学べること**: Histogram 型メトリクスの分析
- **見方**: リクエストの95%がこの秒数以内に完了している、という意味

#### ステータス別に集計

```promql
sum by (status) (rate(app_request_total[1m]))
```

- **学べること**: ラベルを使ったグルーピング
- **見方**: `status="200"` と `status="500"` ごとのリクエスト率が表示される

### クエリの試し方

1. Prometheus の画面上部の入力欄にクエリを貼り付ける
2. **Execute** ボタンをクリック
3. **Graph** タブに切り替えると時系列グラフで確認できる

---

## ステップ2: Grafana でログを見る（Loki）

ブラウザで **http://localhost:3003** を開き、**Explore**（左メニューのコンパスアイコン）に移動してください。  
画面上部のデータソース選択から **Loki** を選びます。

### 基本クエリ（LogQL）

#### アプリのログを全件取得

```logql
{service="app"}
```

- **学べること**: ラベルセレクタの基本
- **見方**: `service="app"` というラベルを持つログストリームを選択

#### エラーログだけ絞り込む

```logql
{service="app"} |= "ERROR"
```

- **学べること**: フィルタ式（`|=` で文字列を含む行を絞り込む）
- **見方**: ERROR を含むログだけが表示される

#### エラー発生頻度（メトリクス化）

```logql
rate({service="app"} |= "ERROR" [1m])
```

- **学べること**: ログからメトリクスを作る
- **見方**: 1分あたりのエラーログ発生率がグラフで表示される

#### コンテナ名でフィルタ

```logql
{container="demo-app"}
```

- Promtail が自動付与する `container` ラベルを使う方法

### Explore の使い方

1. クエリ入力欄にLogQLを入力
2. **Run query** ボタンをクリック
3. ログビューでフィルタ結果を確認
4. 右上の時間範囲を変更して過去のログを遡ることも可能

---

## ステップ3: Grafana ダッシュボードを見る

**Dashboards**（左メニューのグリッドアイコン）を開くと、自動プロビジョニングされた **「demo-app 監視ダッシュボード」** があります。

### ダッシュボードのパネル構成

| パネル | 内容 |
|---|---|
| リクエストレート（1分あたり） | ステータスコード別のリクエスト率（req/s） |
| レイテンシ（95パーセンタイル） | エンドポイント別のp95レイテンシ |
| リクエスト総数 | 成功リクエストの累計数 |
| エラー総数 | エラーリクエストの累計数 |
| エラーログ | ERRORを含むログの一覧（リアルタイム） |
| アプリログ（全件） | demo-appの全ログ |

### 操作のポイント

- **右上の時間範囲**を変更して過去データを確認できる（例: `Last 30 minutes`）
- **自動更新**は10秒ごとに設定済み
- パネルのタイトルをクリック → **Edit** でクエリや表示設定を変更できる

---

## ステップ4: カスタムダッシュボードを作る（発展）

### 新規ダッシュボードの作成手順

1. **Dashboards → New Dashboard** を開く
2. **Add visualization** をクリック
3. データソースを選択（Prometheus or Loki）
4. クエリを入力して **Apply** で保存

### おすすめのカスタムパネル例

#### エラー率（%）

```promql
sum(rate(app_request_total{status="500"}[1m])) 
  / sum(rate(app_request_total[1m])) * 100
```

Visualization: **Stat** または **Gauge**

#### エンドポイント別のリクエスト数

```promql
sum by (endpoint) (increase(app_request_total[5m]))
```

Visualization: **Bar chart**

#### ログの件数をグラフ化

```logql
sum(count_over_time({service="app"}[1m]))
```

Visualization: **Time series**

---

## よく使うクエリ集

### PromQL

| 用途 | クエリ |
|---|---|
| 直近5分のエラー数 | `sum(increase(app_request_total{status="500"}[5m]))` |
| 平均レイテンシ | `rate(app_request_latency_seconds_sum[1m]) / rate(app_request_latency_seconds_count[1m])` |
| p99 レイテンシ | `histogram_quantile(0.99, rate(app_request_latency_seconds_bucket[1m]))` |
| エラー率 | `sum(rate(app_request_total{status="500"}[1m])) / sum(rate(app_request_total[1m]))` |

### LogQL

| 用途 | クエリ |
|---|---|
| ERRORログの数 | `count_over_time({service="app"} \|= "ERROR" [5m])` |
| INFOログのみ | `{service="app"} \|= "INFO"` |
| 特定パスのログ | `{service="app"} \|= "/error"` |
| ログの件数グラフ | `sum(count_over_time({container="demo-app"}[1m]))` |

---

## クリーンアップ

```bash
docker compose down -v
```

`-v` オプションにより、コンテナと一緒にボリュームも削除されます。

---

## トラブルシューティング

### サービスが起動しない

```bash
# ログを確認する
docker compose logs <サービス名>

# 例
docker compose logs app
docker compose logs prometheus
docker compose logs loki
```

### Prometheus にメトリクスが表示されない

- demo-app が起動しているか確認: `docker compose ps`
- http://localhost:5001/metrics に直接アクセスしてメトリクスが出力されるか確認

### Loki にログが表示されない

- Promtail のログを確認: `docker compose logs promtail`
- Docker ソケット（`/var/run/docker.sock`）へのアクセス権限を確認

### ポートが競合する場合

`docker-compose.yml` のホスト側ポートを変更してください（コンテナ内ポートは変更不要）:

```yaml
ports:
  - "5001:5000"  # ホスト5001 → コンテナ5000 に変更
```
