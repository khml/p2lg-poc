---
applyTo: ["agents/lead_reviewer.agent.md", "prompts/review.prompt.md"]
---

# レビュー依頼フロー

## 概要

コード・ドキュメントの変更に対してレビューを依頼する際の標準フローを定義する。

## レビュー依頼の手順

### 1. セルフレビュー

レビュー依頼の前に、自分でセルフレビューを実施する。

- copilot-instructions.md のルールに違反していないか確認
- review-guidelines.instructions.md の観点に基づいて自己チェック
- 指摘を発見した場合は修正してからレビュー依頼を出す

### 2. レビュー依頼の送信

`.request.txt` に以下の情報を記載し、`usercomu request` を実行する。

```
レビュー依頼

対象: <変更の概要>
ブランチ: <ブランチ名>

対象コミット:
- <コミットハッシュ>: <コミットメッセージ>
- <コミットハッシュ>: <コミットメッセージ>

対応チケット: <チケット番号（あれば）>
対応レポート: <レポートファイルパス（あれば）>

セルフレビューで改善した点:
- <改善内容1>
- <改善内容2>

レビュー観点:
- <特に確認してほしいポイント>
```

### 3. レビュー結果の確認

ユーザーからレビューレポートのパスが返される。

- レポートファイル（`reports/` 内）を読んで指摘事項を確認する
- 指摘事項に対して修正を実施する
- 修正後にコミットする

### 4. 再レビュー依頼

修正後、`.request.txt` に以下の情報を記載して `usercomu request` を実行する。

```
レビュー指摘対応後の再レビュー依頼

対象: <変更の概要>
ブランチ: <ブランチ名>

前回レビュー: <前回レビューレポートのパス>
対応コミット: <修正コミットハッシュ>

指摘への対応:
1. [重要度] <指摘タイトル>
    - <対応内容>
2. [重要度] <指摘タイトル>
    - <対応内容>
```

### 5. Approve まで繰り返す

レビュー結果が Approve になるまで、手順3→4を繰り返す。

## レビューレポートの格納先

- `reports/` ディレクトリ
- ファイル名形式: `<チケット番号>_<チケット名>_review_report_<version>.txt`
- version は `v1` から始め、再レビューのたびにインクリメント

## 注意事項

- レビューレポートは git にコミットしない（`reports/` は .gitignore に含まれている）
- レビュー中はコードを変更しない（レビュー完了後にまとめて修正する）
- 指摘の重要度に応じた対応を行う:
  - 🔴 Critical: 必ず修正が必要
  - 🟡 Warning: 修正を強く推奨
  - 🔵 Suggestion: 改善提案（マージをブロックしない）

## エージェントの使い分け

### 全エージェント一覧

#### 対話型エージェント（ユーザーと直接やり取り）

| エージェント | 略称 | 用途 |
|---|---|---|
| `product_manager` | PM | ロードマップ策定・方針提案・チケット作成・orchestrator起動 |
| `technical_lead` | TL | 技術的意思決定・アーキテクチャ設計・技術標準策定 |
| `orchestrator` | Orch | PMの実行計画に基づくサブエージェント呼び出し・進捗管理 |
| `junior_developer` | JrDev | ユーザーと対話しながらシンプルなタスクを実装（Level 1・Haiku 4.5） |
| `developer` | Dev | ユーザーと対話しながらチケットに基づく実装・修正・テスト（Level 2・デフォルト） |
| `expert_developer` | ExpDev | ユーザーと対話しながら複雑・高難易度なタスクを実装（Level 3・Opus 4.6） |
| `lead_reviewer` | LR | ユーザーと対話しながら変更全般のレビュー |
| `tech_writer` | TW | ユーザー向けドキュメント・ガイド・手順書の作成 |
| `project_guide` | Guide | プロジェクトに関する質問応答（必要時 project_researcher に委譲） |
| `agent_manager` | AM | エージェント定義ファイル群の一元管理・整合性保証 |
| `project_initializer` | Init | 新規プロジェクト初期セットアップ（プロジェクト定義確認・copilot-instructions初期化・エージェント体制構築） |

#### 非対話型エージェント（サブエージェントとして起動）

| エージェント | 呼び出し元 | 用途 |
|---|---|---|
| `junior_code_developer` | orchestrator | シンプルなチケットに基づく機能実装・修正・テスト作成（Level 1 / Claude） |
| `code_developer` | orchestrator | チケットに基づく機能実装・修正・テスト作成（Level 2 / Claude・デフォルト） |
| `expert_code_developer` | orchestrator | 複雑・高難易度チケットに基づく機能実装・修正・テスト作成（Level 3 / Claude） |
| `junior_code_developer_openai` | orchestrator | シンプルなチケットに基づく機能実装・修正・テスト作成（Level 1 / OpenAI・指示が明確な場合） |
| `code_developer_openai` | orchestrator | チケットに基づく機能実装・修正・テスト作成（Level 2 / OpenAI・指示が明確な場合） |
| `expert_code_developer_openai` | orchestrator | 複雑・高難易度チケットに基づく機能実装・修正・テスト作成（Level 3 / OpenAI・指示が明確な場合） |
| `reviewer` | orchestrator | 変更全般のレビュー結果をレポートに出力 |
| `aws_infra_engineer` | orchestrator | CDKスタック管理・AWSインフラ構成変更 |
| `test_engineer` | orchestrator | テスト戦略設計・テストコード実装・環境構築 |
| `e2e_test_engineer` | orchestrator | Playwright E2Eテスト設計・実装・実行 |
| `qa_engineer` | orchestrator | テスト設計・品質検証 |
| `inspector` | orchestrator | プロジェクト要件適合性検証・トレーサビリティ検証 |
| `security_auditor` | orchestrator | IAM・S3・API認可・OWASP観点のセキュリティ監査 |
| `doc_manager` | orchestrator | ドキュメント整備・一貫性チェック・ADR記録 |
| `project_researcher` | project_guide | コードベース・ドキュメント・チケットの深い調査 |
| `context_compactor` | orchestrator | サブエージェント間のコンテキスト圧縮・要約 |

### レビューエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `reviewer` | サブエージェント（非対話型） | PMや開発者エージェントが自動でレビューを実施・結果を受け取って対応する場合 |
| `lead_reviewer` | 対話型エージェント | ユーザーと対話しながらレビューを進める場合 |

### 開発者エージェント

| エージェント | 種別 | レベル | モデル | 用途 |
|---|---|---|---|---|
| `junior_developer` | 対話型エージェント | Level 1 | Claude Haiku 4.5 | シンプルなタスク（バグ修正・小機能追加等）をユーザーと対話しながら実装 |
| `developer` | 対話型エージェント | Level 2 | Claude Sonnet 4.6 | 標準的な開発をユーザーと対話しながら進める場合（デフォルト） |
| `expert_developer` | 対話型エージェント | Level 3 | Claude Opus 4.6 | 複雑・高難易度なタスクをユーザーと対話しながら実装 |
| `junior_code_developer` | サブエージェント（非対話型） | Level 1 | Claude Haiku 4.5 | シンプルなチケット開発をサブエージェントとして実施 |
| `code_developer` | サブエージェント（非対話型） | Level 2 | Claude Sonnet 4.6 | PMがorchestratorを通じて、または直接チケット開発を指示・結果を受け取る場合（デフォルト） |
| `expert_code_developer` | サブエージェント（非対話型） | Level 3 | Claude Opus 4.6 | 複雑・高難易度チケットをサブエージェントとして実施 |
| `junior_code_developer_openai` | サブエージェント（非対話型） | Level 1 | GPT-5.4 | シンプルなチケット開発をサブエージェントとして実施（指示が明確な場合） |
| `code_developer_openai` | サブエージェント（非対話型） | Level 2 | GPT-5.2-Codex | チケット開発をサブエージェントとして実施（指示が明確な場合） |
| `expert_code_developer_openai` | サブエージェント（非対話型） | Level 3 | GPT-5.3-Codex | 複雑・高難易度チケットをサブエージェントとして実施（指示が明確な場合） |

### QAエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `qa_engineer` | サブエージェント（非対話型） | PMがユーザーと相談し、まとまりのあるタイミングで品質検証を実施する場合 |

### ドキュメントエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `doc_manager` | サブエージェント（非対話型） | PMがユーザーと相談し、適切なタイミングでドキュメント整備・一貫性チェックを実施する場合 |

### インフラエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `aws_infra_engineer` | サブエージェント（非対話型） | PMがorchestratorを通じて、または直接インフラ関連チケットで呼び出し、CDKスタック実装・AWSインフラ構成変更を実施する場合 |

### 要件適合性検証エージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `inspector` | サブエージェント（非対話型） | PMがプロジェクト全体の要件適合性を検証する場合 |

### セキュリティ監査エージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `security_auditor` | サブエージェント（非対話型） | PMがリリース前やまとまった変更後にセキュリティ監査を実施する場合 |

### プロジェクト初期化エージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `project_initializer` | 対話型エージェント | 新規プロジェクト最初の一度だけ実行。プロジェクト定義確認・copilot-instructions初期化・ロードマップ作成・エージェント体制構築・初期チケット計画を一括実施 |

### プロジェクトガイドエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `project_guide` | 対話型エージェント | ユーザーからのプロジェクトに関する質問（仕様・設計・実装・運用）への回答、チケット作成・軽微なドキュメント修正 |
| `project_researcher` | サブエージェント（非対話型） | `project_guide` が詳細調査を委譲する際に起動。コードベース・ドキュメント・チケットを深く調査してレポートを出力 |

### テストエージェント

| エージェント | 種別 | 用途 |
|---|---|---|
| `test_engineer` | サブエージェント（非対話型） | PMがorchestratorを通じて、または直接テスト関連チケットで呼び出し、テスト戦略設計・コード実装・環境構築を実施する場合 |
| `e2e_test_engineer` | サブエージェント（非対話型） | PMがorchestratorを通じて、または直接E2Eテスト関連チケットで呼び出し、Playwrightテストのシナリオ設計・コード実装・実行を行う場合 |

### orchestrator を使用した実行フロー（新規）

PMが複数のチケットをまとめて実行する場合:

1. **実行計画の策定**: PMが実行対象チケット群と依存関係を整理し、実行計画を作成する
2. **orchestrator の起動**: PMが `@orchestrator` を起動し、実行計画を渡す
3. **タスクの順次実行**: orchestrator が依存関係に従ってサブエージェントを順次呼び出す
   - 各タスク開始時・完了時にユーザーに報告
   - エラー発生時はユーザーに確認を取る
4. **結果の集約**: orchestrator が全タスクの結果をレポートにまとめる
5. **PMへの報告**: orchestrator がPMに実行結果を返す
6. **ユーザーへの最終報告**: PMがユーザーに結果を報告する

### 実行計画の例

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

### サブエージェントレビュー（reviewer）の手順

開発者エージェントがサブエージェントとしてレビューを呼び出す場合:

1. セルフレビューを実施する（上記「1. セルフレビュー」と同じ）
2. `reviewer` サブエージェントを `runSubagent` で呼び出す
3. レビュー結果を受け取り、指摘事項に対応する
4. 修正後に再度 `reviewer` を呼び出して再レビューを実施する
5. ✅ Approve が得られるまで繰り返す

### サブエージェント開発（code_developer）の手順

PMがサブエージェントとして開発者を呼び出す場合:

1. `code_developer` サブエージェントを `runSubagent` で呼び出す（チケット番号・実装要件・レポート出力先を指定）
2. 実装結果（サマリー・コミットハッシュ・テスト結果・推測事項）を受け取る
3. 必要に応じて `reviewer` でレビューを実施する
4. 発見事項がある場合はチケット作成を検討する

### サブエージェントQA（qa_engineer）の手順

PMがユーザーと相談してQA実施を決定した場合:

1. QA対象のチケット群と検証範囲を明確にする
2. `qa_engineer` サブエージェントを `runSubagent` で呼び出す
    - 対象チケット番号群、変更概要、検証範囲、レポート出力先を指定
3. 品質レポートを受け取る
4. FAIL / CONDITIONAL PASS の場合、PMがユーザーと相談して修正チケットを作成する
5. 修正完了後、必要に応じて再度QAを実施する

### サブエージェントドキュメント（doc_manager）の手順

PMがユーザーと相談してドキュメント整備を決定した場合:

1. 整備対象のチケット群・範囲・実行モードを明確にする
2. `doc_manager` サブエージェントを `runSubagent` で呼び出す
    - 対象チケット番号群、変更概要、実行モード、レポート出力先を指定
3. ドキュメント整備レポートを受け取る
4. INCONSISTENT / NEEDS UPDATE の場合、PMがユーザーと相談して対応を判断する
5. 必要に応じてドキュメント修正チケットを作成する

### 対話型レビュー（lead_reviewer）の手順

ユーザーから `lead_reviewer` の起動を指示された場合は、上記「レビュー依頼の手順」に従う。

### サブエージェントインフラ（aws_infra_engineer）の手順

PMがインフラ関連チケットでインフラ変更を実施する場合:

1. インフラ関連チケットを特定する
2. `aws_infra_engineer` サブエージェントを `runSubagent` で呼び出す
    - チケット番号、変更要件、レポート出力先を指定
3. 変更レポートを受け取る
4. `reviewer` でインフラ変更のレビューを実施する
5. 発見事項がある場合はチケット作成を検討する

### サブエージェント要件適合性検証（inspector）の手順

PMがプロジェクト全体の要件適合性を検証する場合:

1. 検証対象（全体/特定機能領域）と実行モード（formalize/verify）を明確にする
2. `inspector` サブエージェントを `runSubagent` で呼び出す
    - 検証対象、実行モード、レポート出力先を指定
3. トレーサビリティレポートを受け取る
4. FAIL / PARTIAL の場合、PMがユーザーと相談して修正チケットを作成する
5. 修正完了後、再度 verify モードで検証を実施する

### サブエージェントセキュリティ監査（security_auditor）の手順

PMがセキュリティ監査を実施する場合:

1. セキュリティ監査の対象・範囲を明確にする
2. `security_auditor` サブエージェントを `runSubagent` で呼び出す
    - 監査対象、監査範囲、レポート出力先を指定
3. 監査レポートを受け取る
4. FAIL / CONDITIONAL PASS の場合:
    - ユーザーに報告し、修正方針を相談する
    - 修正チケットを作成する（修正担当: aws_infra_engineer or code_developer）
5. PASS の場合: ユーザーに報告する

### サブエージェントテスト（test_engineer）の手順

PMがテスト関連チケットでテスト作業を実施する場合:

1. テスト関連チケットを特定する
2. `test_engineer` サブエージェントを `runSubagent` で呼び出す
    - チケット番号、テスト要件、実行モード、レポート出力先を指定
3. テストレポートを受け取る
4. `reviewer` でテストコードのレビューを実施する
5. 発見事項がある場合はチケット作成を検討する

### サブエージェントE2Eテスト（e2e_test_engineer）の手順

PMがE2Eテスト関連チケットでE2Eテストを実施する場合:

1. E2Eテスト関連チケットの内容を明確にする
2. `e2e_test_engineer` サブエージェントを `runSubagent` で呼び出す
    - 対象チケット番号、テスト要件、実行モード（scenario/implementation/execution/environment）、レポート出力先を指定
3. テストレポートを受け取る
4. data-testid追加が必要な場合、code_developerに修正を依頼する
5. data-testid追加完了後、`e2e_test_engineer` を再度呼び出してテストコードを更新・実行する
6. 必要に応じて `reviewer` でE2Eテストコードのレビューを実施する
