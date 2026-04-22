# プロジェクトガイドエージェントの設計・更新

agent_manager として、プロジェクトガイドエージェント（対話型・非対話型）の設計・作成・更新を行ってください。

## 対象エージェント

| エージェント | ファイル | 種別 |
|---|---|---|
| `project_guide` | `.github/agents/project_guide.agent.md` | 対話型（ユーザーと対話しながら質問に回答） |
| `project_researcher` | `.github/agents/project_researcher.agent.md` | 非対話型（project_guide からサブエージェントとして起動） |

## エージェントの目的

ユーザーからのプロジェクトに関する質問に回答するためのエージェントペアを構築する。

- `project_guide` がユーザーとの対話窓口となり、質問を受け取り回答する
- 詳細な調査が必要な場合は `project_researcher` に委譲する
- 対話の結果、チケット作成等のアクションが必要な場合は `project_guide` が実施する

## ワークフロー

### 1. 現状把握

以下を確認し、プロジェクトの現状を把握する:

- `docs/roadmap.md` — 現在のフェーズ・技術スタック・アーキテクチャ
- `docs/design.md` — システム設計書
- `.github/copilot-instructions.md` — プロジェクト全体のルール
- `.github/instructions/review-request-flow.instructions.md` — エージェント一覧
- `.github/agents/technical_lead.agent.md` — チーム体制図
- `.github/agents/` — 既存エージェントのフォーマット・パターン

### 2. エージェントファイルの存在確認

`.github/agents/` ディレクトリを確認し、以下の2ファイルの存在を判定する:

- `.github/agents/project_guide.agent.md`
- `.github/agents/project_researcher.agent.md`

### 3-A. 存在しない場合 → 新規設計・作成

エージェントファイルが存在しない場合は、以下の手順で新規作成する:

1. **既存エージェントの分析** — 既存の対話型エージェント（`developer`, `lead_reviewer` 等）と非対話型エージェント（`code_developer`, `reviewer` 等）のフォーマット・構成パターンを確認する
2. **要件定義** — プロジェクトの構成・ドキュメント・チケット体系から、ガイドエージェントに必要な知識・ツール・ワークフローを整理する
3. **設計** — 以下の項目を設計する:
   - YAML フロントマター（name, description, argument-hint, model, tools）
   - 役割と責務
   - 必読ドキュメント
   - プロジェクト構成
   - ワークフロー
   - ユーザーとのコミュニケーション方法
   - 境界（できること・できないこと）
4. **作成** — エージェントファイルを作成する
5. **関連ファイル更新** — 体制図・エージェント一覧を更新する
6. **整合性チェック** — 全参照箇所の一貫性を検証する
7. **コミット** — 変更をコミットする

#### 対話型 `project_guide` の設計方針

- ユーザーと `usercomu` コマンドで対話する
- モデル: Claude Sonnet 4.6 (copilot)
- tools: `vscode`, `execute`, `read`, `agent`, `edit`, `search`, `web`
- 簡単な質問は自身で直接回答する
- 詳細な調査が必要な場合は `project_researcher` に委譲する
- 外部技術情報が必要な場合は `web` で検索する
- 対話結果に基づきチケット作成やドキュメントの軽微な修正が可能
- プロダクションコードの実装・変更は行わない（開発エージェントの責務）

#### 非対話型 `project_researcher` の設計方針

- `project_guide` から `runSubagent` で起動される非対話型
- モデル: Claude Sonnet 4.6 (copilot)
- `usercomu` は使用しない
- tools: `read`, `search`, `execute`, `web`, `edit`
- コードベース・ドキュメント・チケットを深く調査する
- 調査結果をレポートファイルに出力して返却する
- 調査の深さ（quick / medium / thorough）を呼び出し元から受け取る
- コード・ドキュメントの変更は行わない

### 3-B. 存在する場合 → 現状に基づく更新

エージェントファイルが既に存在する場合は、以下の観点で更新が必要かを評価する:

1. **プロジェクト状況との整合性**
   - プロジェクト構成の記載が最新か（新しいモジュールが追加されていないか）
   - 必読ドキュメントの一覧が最新か
   - 技術スタックの記載が最新か

2. **チーム体制との整合性**
   - 他エージェントとの役割分担が明確か
   - 呼び出し関係が正しく記載されているか

3. **ワークフローの改善**
   - 質問応答の精度を向上させる改善点はないか
   - 調査委譲のフローに改善点はないか

4. **関連ファイルとの整合性**
   - `technical_lead.agent.md` の体制図に含まれているか
   - `review-request-flow.instructions.md` の一覧に登録されているか

不足・差分があればエージェントファイルを更新し、関連ファイルも合わせて修正する。

### 4. 関連ファイルの更新

エージェント作成・更新後、以下の関連ファイルを必ず更新する:

- `technical_lead.agent.md` の体制図セクション
- `review-request-flow.instructions.md` のエージェント一覧テーブル

### 5. コミット

すべての変更を1つの論理的な変更としてコミットする（日本語のcommitメッセージ）。
