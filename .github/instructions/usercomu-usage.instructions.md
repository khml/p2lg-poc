---
applyTo: "**/*"
---

# usercomu コマンドの使い方

## 概要

`usercomu` はプロジェクトルートに配置されたバイナリコマンドで、エージェントとユーザーの非同期コミュニケーションを実現する。

## コマンド一覧

### `./usercomu input`

ユーザーが入力したメッセージ・指示を取得する。

```bash
cd <プロジェクトルート>
./usercomu input
```

- 出力が空の場合: ユーザーからの指示がまだ用意できていない。30秒程度待機して再度実行すること
- 出力がある場合: その内容がユーザーからの指示

**用途**: 定期的に実行してユーザーの追加指示を確認する。フェーズの節目で必ず実行すること。

### `./usercomu request`

ユーザーに対してメッセージ・依頼を送信する。

`.request.txt` への書き込みは、コードファイルと同じようにファイル編集ツール（`create_file` / `replace_string_in_file` / `multi_replace_string_in_file`）を使うこと。シェルコマンド（`cat > file << EOF`）での書き込みは禁止。

```bash
# 2. コマンドを実行してユーザーに送信する（.request.txt を先にファイル編集ツールで用意しておくこと）
cd <プロジェクトルート>
./usercomu request
```

**用途**: ユーザーへの質問・確認・作業依頼を送る場合に使用する。

## 注意事項

- `usercomu input` に heredoc やパイプでテキストを渡してはいけない（stdin渡しは不正な使い方）
- `usercomu request` は必ず `.request.txt` を先に書いてから実行すること
- バックグラウンド実行（`&` や `isBackground: true`）は禁止。対話的に実行すること
- ユーザーからレスポンスが受け取れない場合は30秒程度待機してから再実行すること
- 明確な終了の伝達がない限りタスクを続行し、必ずユーザーに確認を取ること
- **`.request.txt` の書き込みに Python スクリプト等は不要**。`create_file` / `replace_string_in_file` などのファイル編集ツールを直接使うこと（`copilot-instructions.md` の「スクリプト化を推奨」は `.request.txt` には適用しない）

## メッセージ送信の正しいパターン

```
正しい手順:
1. ファイル編集ツール（create_file / replace_string_in_file 等）で .request.txt を書き換える
2. ./usercomu request を実行する

禁止パターン:
- シェルコマンド（cat > .request.txt << 'EOF'）で .request.txt を書き込む
- usercomu input にパイプや heredoc でテキストを渡す
  例: ./usercomu input << 'EOF' ... EOF  ← 禁止
```

## 使用タイミング（対話型エージェント向け）

| タイミング | コマンド | 内容 |
|----------|---------|------|
| 作業開始前 | `input` | ユーザー要望を確認 |
| 計画提示時 | `request` | 実行計画をユーザーに提示し承認を得る |
| タスク完了時 | `request` | 結果を報告し次タスクへの続行確認 |
| エラー発生時 | `request` | エラー内容を報告し対応方針を確認 |
| 定期チェック | `input` | 追加指示がないか確認 |
| 全タスク完了時 | `request` | 最終報告と終了確認 |
