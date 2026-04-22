# 開発者エージェントの設計・更新

PMとして、開発者エージェント（対話型・非対話型）の設計・作成・更新を行ってください。

## 対象エージェント

### 対話型開発者エージェント

| エージェント | ファイル | レベル | モデル | 用途 |
|---|---|---|---|---|
| `junior_developer` | `.github/agents/junior_developer.agent.md` | Level 1 | Claude Haiku 4.5 | シンプルなタスク（バグ修正・小機能追加・設定変更等） |
| `developer` | `.github/agents/developer.agent.md` | Level 2 | Claude Sonnet 4.6 | 標準的な機能開発（**デフォルト**） |
| `expert_developer` | `.github/agents/expert_developer.agent.md` | Level 3 | Claude Opus 4.6 | 複雑・高難易度の実装・アーキテクチャ変更 |

### 非対話型開発者エージェント（Claude セット・デフォルト）

| エージェント | ファイル | レベル | モデル | 用途 |
|---|---|---|---|---|
| `junior_code_developer` | `.github/agents/junior_code_developer.agent.md` | Level 1 | Claude Haiku 4.5 | シンプルなタスクをサブエージェントとして実施 |
| `code_developer` | `.github/agents/code_developer.agent.md` | Level 2 | Claude Sonnet 4.6 | 標準的なタスクをサブエージェントとして実施（**デフォルト**） |
| `expert_code_developer` | `.github/agents/expert_code_developer.agent.md` | Level 3 | Claude Opus 4.6 | 複雑・高難易度タスクをサブエージェントとして実施 |

### 非対話型開発者エージェント（OpenAI Codex セット）

| エージェント | ファイル | レベル | モデル | 用途 |
|---|---|---|---|---|
| `junior_code_developer_openai` | `.github/agents/junior_code_developer_openai.agent.md` | Level 1 | GPT-5.4 | シンプルなタスクをサブエージェントとして実施（指示が明確な場合） |
| `code_developer_openai` | `.github/agents/code_developer_openai.agent.md` | Level 2 | GPT-5.2-Codex | 標準的なタスクをサブエージェントとして実施（指示が明確な場合） |
| `expert_code_developer_openai` | `.github/agents/expert_code_developer_openai.agent.md` | Level 3 | GPT-5.3-Codex | 複雑・高難易度タスクをサブエージェントとして実施（指示が明確な場合） |

### モデルセット選択の指針

| 状況 | 選択するセット |
|---|---|
| 要件が曖昧・探索的なタスク | **Claude セット**（要件が不明確でも良い結果を出しやすい） |
| 指示が明確・具体的なタスク | **OpenAI Codex セット**（指示が明確なほど高い精度を発揮） |
| デフォルト（判断に迷う場合） | **Claude セット** |
| Claude がレート制限された場合 | **OpenAI Codex セット**（同レベルのエージェントに切り替え） |

### レベル選択の判断基準

| レベル | 対象タスク例 |
|---|---|
| Level 1 | バグ修正・誤字修正・設定変更・ドキュメント更新・小さな機能追加 |
| Level 2 | 新機能実装・複数ファイルに渡る変更・テスト実装（通常はこれを選択） |
| Level 3 | アーキテクチャ変更・複雑な設計判断・高難易度アルゴリズム実装 |

## ワークフロー

### 1. 現状把握

以下を確認し、プロジェクトの現状を把握する:

- `docs/roadmap.md` — 現在のフェーズ・技術スタック・アーキテクチャ
- `.github/copilot-instructions.md` — プロジェクト全体のルール
- `.github/instructions/review-request-flow.instructions.md` — レビューフロー・エージェント一覧
- `.github/agents/orchestrator.agent.md` — orchestrator の役割と呼び出し規約（新規）
- `tickets/` — 未着手チケットの内容・技術要件
- `docs/architecture.md` — システムアーキテクチャ
- `docs/` 配下のドキュメント全般 — 技術情報

### 2. エージェントファイルの存在確認

`.github/agents/` ディレクトリを確認し、以下のファイルの存在を判定する:

**対話型エージェント（Claude セット）**
- `.github/agents/junior_developer.agent.md`
- `.github/agents/developer.agent.md`
- `.github/agents/expert_developer.agent.md`

**非対話型エージェント（Claude セット）**
- `.github/agents/junior_code_developer.agent.md`
- `.github/agents/code_developer.agent.md`
- `.github/agents/expert_code_developer.agent.md`

**非対話型エージェント（OpenAI Codex セット）**
- `.github/agents/junior_code_developer_openai.agent.md`
- `.github/agents/code_developer_openai.agent.md`
- `.github/agents/expert_code_developer_openai.agent.md`

### 3-A. 存在しない場合 → 新規設計・作成

エージェントファイルが存在しない場合は、以下の手順で新規作成する:

1. **既存エージェントの分析** — 既存のエージェント（`reviewer`, `lead_reviewer`, `product_manager`, `orchestrator` 等）のフォーマット・構成パターンを確認する
2. **要件定義** — プロジェクトの技術スタック・チケット内容から、開発者エージェントに必要な知識・ツール・ワークフローを整理する
3. **設計** — 以下の項目を設計する:
   - YAML フロントマター（name, description, argument-hint, model, tools）
   - 役割と責務
   - 必読ドキュメント
   - ワークフロー
   - プロジェクト固有の情報（技術スタック、ディレクトリ構成、操作コマンド）
   - コミット規約・レポートフォーマット
   - 境界（できること・できないこと）
4. **作成** — エージェントファイルを作成する
5. **コミット** — 変更をコミットする

#### 対話型エージェントの設計方針

- ユーザーと `usercomu` コマンドで対話する
- 疑問点はユーザーに確認してから実装する
- tools: `vscode`, `execute`, `read`, `agent`, `edit`, `search`, `web`, `todo`
- **Level 1（junior_developer）**: シンプルなタスク向け・Claude Haiku 4.5
- **Level 2（developer）**: 標準的な開発・Claude Sonnet 4.6（デフォルト）
- **Level 3（expert_developer）**: 複雑な開発・設計判断の根拠をレポートに含める・Claude Opus 4.6

#### 非対話型エージェントの設計方針

- `reviewer` と同じパターン: orchestrator または PM から `runSubagent` で起動される非対話型
- `usercomu` は使用しない
- 疑問点は推測で続行し、レポートに記載する
- 呼び出し元には対応サマリー・コミットハッシュ・テスト結果を返す
- tools: `read`, `execute`, `edit`, `search`, `agent`, `web`
- **orchestrator からの呼び出しを想定** — 実行計画のタスクとして起動される
**Claude セット（デフォルト）:**
- **Level 1（junior_code_developer）**: シンプルなタスク向け・Claude Haiku 4.5
- **Level 2（code_developer）**: 標準的な実装・Claude Sonnet 4.6（デフォルト）
- **Level 3（expert_code_developer）**: 複雑な実装・設計判断の根拠をレポートに含める・Claude Opus 4.6

**OpenAI Codex セット（指示が明確な場合）:**
- **Level 1（junior_code_developer_openai）**: シンプルなタスク向け・GPT-5.4
- **Level 2（code_developer_openai）**: 標準的な実装・GPT-5.2-Codex
- **Level 3（expert_code_developer_openai）**: 複雑な実装・設計判断の根拠をレポートに含める・GPT-5.3-Codex

### 3-B. 存在する場合 → 現状に基づく更新

エージェントファイルが既に存在する場合は、以下の観点で更新が必要かを評価する:

1. **プロジェクト状況との整合性**
   - 技術スタックの記載が最新か（新しいフレームワーク、ライブラリ、ツールが追加されていないか）
   - ディレクトリ構成の記載が最新か（新しいサービスやモジュールが追加されていないか）
   - 操作コマンド（Makefile）の記載が最新か
   - インフラ構成の記載が最新か

2. **ロードマップ・チケットとの整合性**
   - 今後のチケットで必要になる技術知識がエージェントに記載されているか
   - 新しいコンポーネント（Parse Server、music-api 等）の情報が反映されているか

3. **ワークフローの改善**
   - レビューフロー（`review-request-flow.instructions.md`）との整合性
   - セルフレビューの手順が含まれているか
   - テスト先行の手順が含まれているか

4. **orchestrator 統合対応（重要）**
   - `code_developer` が orchestrator からの呼び出しを想定した設計になっているか
   - 実行計画のタスクとして起動されることを明記しているか
   - 呼び出し元への返却情報が明確か（レポートパス、サマリー、コミット、テスト結果等）
   - 非対話型の制約（usercomu 使用禁止、推測で続行）が明記されているか

5. **他エージェントとの一貫性**
   - `reviewer` / `lead_reviewer` のパターンと対になっているか
   - PM・orchestrator からの呼び出しインターフェースが明確か

6. **更新実施**
   - 更新が必要な箇所を特定し、修正する
   - 特に orchestrator 関連の記載を追加:
     - 「orchestrator から実行計画のタスクとして起動される」
     - 「実行計画に定義されたチケット・レポート出力先に従う」
     - 「前のタスクの結果サマリーを受け取る場合がある」
   - 変更内容をレポートに記載する
   - コミットする

### 4. レポート出力

作業内容を `reports/` にレポートとして出力する:

- 新規作成の場合: 設計判断の根拠と作成したファイルの概要
- 更新の場合: 変更前後の差分と更新理由（特に orchestrator 統合対応）

### 5. 完了確認

`usercomu input` でユーザーに完了報告を行う。

## orchestrator 統合のための code_developer 更新チェックリスト

`code_developer.agent.md` が既に存在する場合、以下の項目が記載されているか確認し、不足があれば追加する:

- □ 「orchestrator または PM から起動される非対話型エージェント」と明記
- □ インプットとして「実行計画のタスク定義」を受け取ることを記載
- □ 「前のタスクの結果サマリー」を受け取る可能性を記載
- □ 呼び出し元への返却情報が明確（レポートパス、サマリー、コミット、テスト結果、推測事項、発見事項）
- □ `usercomu` コマンドを使用しないことを明記
- □ 疑問点は推測で続行し、レポートに記載することを明記

## ルール

- `usercomu input` を適宜実行し、ユーザーの追加指示がないか確認する
- コミットメッセージは日本語
- チケットステータスセクションは編集しない
- 既存エージェントのフォーマット・パターンに合わせて一貫性を保つ
- orchestrator の導入に伴う更新は、既存の設計思想を壊さず段階的に追加する
