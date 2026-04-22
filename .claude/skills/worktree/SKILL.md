---
name: worktree
description: git worktree を使って複数チケットを並列実装する。チケットごとに独立したブランチ・作業ディレクトリを作成し、developer を並列起動して実装後にメインブランチへマージする
---

# Worktree 並列実装ワークフロー

git worktree を使い、複数チケットを独立した作業ディレクトリで並列実装する。

## フェーズ 0: 対象チケットの確認

引数でチケット番号が指定されている場合はそれを使う。  
指定がない場合は `docs/roadmap.md` と `tickets/` を読み、並列実行可能な未着手チケットを特定してユーザーに確認する。

## フェーズ 1: 計画の確認

各チケットに対して `/plan` スキル相当の調査・計画を実施する。  
計画をユーザーに提示し、承認を得てからフェーズ 2 に進む。

軽微なチケット（ruff 修正・単純な if-else 置き換え等）は計画省略可。

## フェーズ 2: Worktree の作成

承認を得たチケットごとに worktree とブランチを作成する。

```bash
# ブランチ名: ticket/<チケット番号>
# worktree パス: .worktrees/<チケット番号>
git worktree add .worktrees/<番号> -b ticket/<番号>
```

複数チケットの場合は一度にまとめて作成してよい。

`.worktrees/` は `.gitignore` に追加されていることを前提とする。  
未登録の場合はこのフェーズで追加する。

## フェーズ 3: 並列実装

**全チケット分の developer を単一メッセージで同時起動する（並列実行）。**

各 developer に以下を渡す:

- チケットファイルのパス（絶対パス）
- 実装計画の内容
- 作業ディレクトリ: `.worktrees/<番号>`（`cd` してから操作するよう指示）
- コミット先ブランチ: `ticket/<番号>`
- `git push` は行わないこと

developer が完了したら結果を受け取る。いずれかが失敗した場合はユーザーに報告して判断を仰ぐ。

## フェーズ 4: 結果確認とマージ

全 developer の完了後、各ブランチの差分を確認する。

```bash
git diff main..ticket/<番号> --stat
```

問題がなければ main ブランチへマージする:

```bash
git checkout main
git merge --no-ff ticket/<番号> -m "Merge ticket/<番号>: <チケットタイトル>"
```

複数チケットがある場合は 1 件ずつ順番にマージし、テストが通ることを確認してから次へ進む。

```bash
make test
```

## フェーズ 5: Worktree のクリーンアップ

マージ完了後、不要になった worktree とブランチを削除する。

```bash
git worktree remove .worktrees/<番号>
git branch -d ticket/<番号>
```

## フェーズ 6: レビュー

全チケットのマージが完了したら `/review` スキルを起動し、変更全体をレビューする。

---

## ブランチ・パス命名規則

| 項目 | 形式 | 例 |
|------|------|-----|
| ブランチ | `ticket/<4桁番号>` | `ticket/0165` |
| Worktree パス | `.worktrees/<4桁番号>` | `.worktrees/0165` |

## 注意事項

- worktree 内の developer は **メインの作業ディレクトリを変更しない**。変更はすべて worktree 内で完結させる
- `git push` はフェーズ 4 のマージ前には行わない
- マージ前に `make test` を実行し、既存テストが通ることを確認する
- `.worktrees/` は作業中のみ存在するディレクトリ。完了後は必ず削除する
