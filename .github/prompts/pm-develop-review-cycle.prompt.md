# PM主導の開発・レビューサイクル（orchestrator統合版）

PMとして現状分析から実行計画策定・orchestrator起動・結果確認までの一連のサイクルを実行してください。

## ワークフロー

以下の手順を順番に実行してください。

### 1. 現状分析・次タスク提案

- `docs/roadmap.md` を確認し、現在のフェーズと進捗を把握する
- `tickets/` 内の未着手チケットと `tickets/done/` 内の完了済みチケットを確認する
- 依存関係・優先度を分析し、次に対応すべきチケット群を特定する
- 分析結果を `reports/` にレポートとして出力する
- `usercomu input` でユーザーに分析結果と次タスクの提案を説明し、承認を取る

### 2. 完了チケットの整理

- チケットステータスが「完了」であるにもかかわらず `tickets/` に残っているチケットは `tickets/done/` に移動する
- 移動後、コミットする（コミットメッセージは日本語）

### 3. 実行計画の策定

- 特定した次のチケット群について、実行計画を策定する
- 実行計画には以下を含めること:
  - 各チケットの開発タスク（code_developer）
  - 各チケットのレビュータスク（reviewer）
  - タスク間の依存関係（開発→レビューの順序）
  - 各タスクのレポート出力先

実行計画のフォーマット:

```yaml
execution_plan:
  - task_id: task_001
    type: development
    agent: code_developer
    ticket: tickets/0123_feature_a.txt
    description: "機能Aの実装"
    depends_on: []
    report_path: reports/task_001_dev.txt
  
  - task_id: task_002
    type: review
    agent: reviewer
    ticket: tickets/0123_feature_a.txt
    description: "機能Aのレビュー"
    depends_on: [task_001]
    report_path: reports/task_001_review.txt
  
  - task_id: task_003
    type: development
    agent: code_developer
    ticket: tickets/0124_feature_b.txt
    description: "機能Bの実装"
    depends_on: []
    report_path: reports/task_003_dev.txt
  
  - task_id: task_004
    type: review
    agent: reviewer
    ticket: tickets/0124_feature_b.txt
    description: "機能Bのレビュー"
    depends_on: [task_003]
    report_path: reports/task_003_review.txt
```

### 3.5. TLへの技術相談

策定した実行計画について `technical_lead` サブエージェントに技術的な妥当性を確認する:

- 技術的なリスク・課題の洗い出し
- タスクの実行順序・依存関係が技術的に妥当かの確認
- 必要に応じて計画を調整

### 4. 実行計画の確認

- 策定した実行計画を `usercomu input` でユーザーに提示する
- 実行順序と想定実行時間を説明する
- ユーザーの承認を得る

### 5. orchestrator の起動

- `@orchestrator` を起動し、実行計画を渡す
- orchestrator が各タスクを順次実行する
- orchestrator からの進捗報告を確認する（orchestrator はユーザーと対話するため、PM側での特別な対応は不要）

### 6. 実行結果の確認

- orchestrator から実行結果レポートを受け取る
- 以下を確認:
  - 成功したタスク数
  - 失敗・スキップされたタスク
  - 生成されたコミット一覧
  - レビュー指摘の有無と重要度
  - 発見事項・推奨アクション

### 7. レビュー指摘対応（必要な場合）

orchestrator の実行結果で 🔴 Critical または 🟡 Warning が報告された場合:

1. 指摘内容をユーザーに報告する
2. 対応方針を相談する:
  - 即座に修正チケットを作成して再実行
  - 次のイテレーションで対応
  - 設計の見直しが必要（TLに相談）
3. 修正チケット作成の場合:
  - 修正チケットを作成
  - 修正チケットの実行計画を策定
  - orchestrator を再度起動

### 8. 完了確認

- すべてのチケットが ✅ Approve を取得したら、`usercomu input` でユーザーに完了報告と追加指示の確認を行う

## 実行計画策定のガイドライン

### タスクIDの採番

- task_001, task_002, ... のように連番で採番
- 同一チケットの開発とレビューは連続した番号にする

### 依存関係の定義

- 開発タスク（code_developer）→ レビュータスク（reviewer）の順序を必ず守る
- 異なるチケット間で依存関係がない場合は `depends_on: []` とする
- 現フェーズでは並列実行は未対応のため、orchestrator が依存順に順次実行する

### レポートパスの命名規則

- 開発タスク: `reports/<チケット番号>_dev.txt`
- レビュータスク: `reports/<チケット番号>_review.txt`
- テストタスク: `reports/<チケット番号>_test.txt`
- インフラタスク: `reports/<チケット番号>_infra.txt`

### タスクタイプ

以下のタイプを使用:
- `development`: コード実装（code_developer）
- `review`: コードレビュー（reviewer）
- `test`: テスト実装（test_engineer）
- `e2e_test`: E2Eテスト（e2e_test_engineer）
- `infrastructure`: インフラ変更（aws_infra_engineer）
- `qa`: 品質検証（qa_engineer）
- `security`: セキュリティ監査（security_auditor）
- `documentation`: ドキュメント整備（doc_manager）

## orchestrator を使わない場合（緊急時・単発タスク）

以下の場合は orchestrator を経由せず、直接サブエージェントを呼び出すことができます:

- 緊急の修正が必要な場合
- 単一のタスクのみを実行する場合
- orchestrator が正常動作しない場合

直接呼び出しの例:

```
`code_developer` サブエージェントを `runSubagent` で起動:

対象チケット: tickets/0123_hotfix.txt
タスク説明: 緊急バグ修正
レポート出力先: reports/0123_hotfix_dev.txt

実施内容:
（チケットファイルから読み取った対応内容）
```

## ルール

- `usercomu input` を適宜実行し、ユーザーの追加指示がないか確認する
- ユーザーから明確に終了を告げられるまでタスクを終了しない
- チケットステータスセクションは編集しない
- コミットメッセージは日本語
- 2回以上ユーザーがコマンド実行をスキップした場合は `usercomu input` で確認を取る
- orchestrator の実行中は orchestrator がユーザーと対話するため、PM側からの介入は不要（orchestrator から結果を受け取るまで待機）
