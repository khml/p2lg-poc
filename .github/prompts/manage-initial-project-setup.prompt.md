# 新規プロジェクト初期セットアップ

PMまたは project_initializer として、新規プロジェクトにおけるマルチエージェント開発体制を一括で初期化してください。

## 目的

新しいプロジェクトで最初の一度だけ実行するプロンプト。
プロジェクト定義の確認から、設定ファイルの初期化、エージェント体制の構築まで、初期セットアップをまとめて実施する。

## 前提条件

- `tickets/0001_プロジェクト定義.txt`（または同等のプロジェクト定義チケット）が存在すること
- `.github/copilot-instructions.md` が存在すること
- `.github/prompts/manage-developer-agents.prompt.md` が存在すること
- `.github/prompts/manage-project-guide-agents.prompt.md` が存在すること

## ワークフロー

### ステップ1: プロジェクト定義の確認

1. `tickets/` ディレクトリを確認し、0001番台のチケット（プロジェクト定義チケット）を特定する
2. プロジェクト定義チケットを熟読し、以下を把握する:
   - プロジェクトの目的・概要
   - 主要技術スタック
   - アーキテクチャ・モジュール構成
   - エラーハンドリング方針
   - テスト方針
3. `.github/copilot-instructions.md` の現在の内容を確認し、プロジェクト定義との齟齬を洗い出す

### ステップ2: copilot-instructions.md の初期化

プロジェクト定義チケットの内容に基づき、`.github/copilot-instructions.md` の以下の項目を最新化する:

- **プロジェクト概要**: プロジェクトの目的・説明を正確に記述する
- **主要技術スタック**: テーブル形式で技術スタックを記載する
- **アーキテクチャ**: 処理フロー・モジュール構成をリストまたは図で記載する
- **プロジェクトのファイル構成**: ディレクトリツリー形式で記載する

更新後、変更内容をコミットする（コミットメッセージは日本語）。

### ステップ3: docs/roadmap.md の作成

1. `docs/` ディレクトリが存在しなければ作成する
2. `docs/roadmap.md` が存在するか確認する
3. **存在しない場合**: 以下の内容でロードマップを新規作成する
   - プロジェクト概要
   - 現在のフェーズ（初期セットアップ）
   - 技術スタック（テーブル形式）
   - アーキテクチャ概要
   - 今後の実装ステップ（プロジェクト定義チケットに基づく）
4. **存在する場合**: 内容を確認し、プロジェクト定義と整合していることを確認する
5. 変更がある場合はコミットする

### ステップ4: tickets/.latest_ticket_number の初期化

1. `tickets/.latest_ticket_number` が存在するか確認する
2. **存在しない場合**: プロジェクト定義チケットの番号（通常 `0001`）を初期値として作成する
3. **存在する場合**: ファイルに記載された番号と実際の最大チケット番号が合致しているか確認する
4. 変更がある場合はコミットする

### ステップ5: 開発者エージェントの初期化

1. `.github/prompts/manage-developer-agents.prompt.md` の内容を確認する
2. `agent_manager` を起動し、`manage-developer-agents.prompt.md` の手順に従って以下を作成・更新する:
   - `.github/agents/developer.agent.md`
   - `.github/agents/code_developer.agent.md`
3. 体制図（`technical_lead.agent.md`）・エージェント一覧（`review-request-flow.instructions.md`）が更新されていることを確認する
4. 作成・更新完了後にコミットが完了していることを確認する

### ステップ6: プロジェクトガイドエージェントの初期化

1. `.github/prompts/manage-project-guide-agents.prompt.md` の内容を確認する
2. `agent_manager` を起動し、`manage-project-guide-agents.prompt.md` の手順に従って以下を作成・更新する:
   - `.github/agents/project_guide.agent.md`
   - `.github/agents/project_researcher.agent.md`
3. 体制図・エージェント一覧が更新されていることを確認する
4. 作成・更新完了後にコミットが完了していることを確認する

### ステップ7: 初期チケットの作成方針の確認

1. `usercomu input` でユーザーに初期チケットの作成方針を確認する:
   - プロジェクト定義チケット（0001番台）以外に初期チケットが必要か
   - どのような実装順序でチケットを作成するか
   - マイルストーンの設定は必要か
2. ユーザーの回答に基づき、合意した方針で初期チケットを作成する
3. `docs/roadmap.md` にチケット計画を反映する
4. 変更をコミットする

## 完了チェックリスト

全ステップが完了したら、下記を確認する。

- [ ] プロジェクト定義チケットを確認し、内容を把握した
- [ ] `.github/copilot-instructions.md` がプロジェクト定義と整合している
- [ ] `docs/roadmap.md` が作成・確認された
- [ ] `tickets/.latest_ticket_number` が初期化・確認された
- [ ] `developer.agent.md` が作成・更新された
- [ ] `code_developer.agent.md` が作成・更新された
- [ ] `project_guide.agent.md` が作成・更新された
- [ ] `project_researcher.agent.md` が作成・更新された
- [ ] 各変更がコミットされた
- [ ] 初期チケットの作成方針がユーザーと合意された
