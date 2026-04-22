# プロジェクト名

## 概要
<!-- project-init スキルで埋める -->

## 技術スタック
<!-- project-init スキルで埋める -->

## コマンド
<!-- project-init スキルで埋める -->

## Git 運用
- commit のみ許可（push はユーザーの明示的な許可が必要）
- commit メッセージは日本語
- 1 commit = 1 つの論理的な変更

## チケット運用
- `tickets/` にテキストファイルで管理（`<4桁番号>_<チケット名>.txt`）
- 最新番号: `tickets/.latest_ticket_number`
- 「チケットステータス」セクションはユーザーのみ更新可能
- `tickets/done/` 内は対応不要
- 詳細: @.claude/rules/ticket-workflow.md

## レポート
- 作業完了時に `reports/` へ簡易レポートを出力
- reports/ は git に commit しない

## 言語
- ユーザーとのやり取り・ドキュメント・コメントは日本語
