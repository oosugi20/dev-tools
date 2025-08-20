# Scripts Directory

このディレクトリには、プロジェクトの開発を補助するための各種スクリプトが格納されています。

## create_draft_issue.sh

GitHub ProjectsにDraft Issueを1件作成します。

### 使い方

```bash
./create_draft_issue.sh --title "Issueのタイトル" --body "Issueの本文" --tag "タグ名" --points 2
```

- `--title`: (必須) Issueのタイトル
- `--body`: (任意) Issueの本文
- `--tag`: (任意) Projectsのカスタムフィールド「Tag」に設定する値
- `--points`: (任意) Projectsのカスタムフィールド「Points」に設定する数値

### 注意: 複数Issueの連続作成について

短時間にこのスクリプトを連続して実行すると、GitHub APIのレート制限や、サーバー側の競合によりIssue作成に失敗することがあります。

手動で複数のIssueを作成する場合は、各コマンドの間に**十分な待機時間**を入れてください。

**【知見】**
実際に連続実行した際、2秒の待機時間ではエラーが頻発しました。APIの応答が不安定になることがあるため、**5秒以上**の待機時間を設定すると、より安定して動作します。

**実行例 (forループ):**

```bash
for i in {1..5}; do
  ./create_draft_issue.sh --title "テストIssue $i" --points 1
  echo "Waiting for 5 seconds..."
  sleep 5
done
```

---

### AIとの連携について

Gemini CLI (AI) に複数のIssue作成を依頼する場合、**AIが自動的に適切な待機時間を挟んで実行します。**
そのため、ユーザーが手動で`sleep`を意識する必要はありません。

---

## get_recent_done_items.sh

GitHub Projectsから直近で"Done"ステータスになったアイテムを取得し、タイトルとポイントを一覧表示します。
ポイントが見積もられていないアイテムは `0` と表示されます。

デフォルトでは直近10件を取得しますが、`--limit`オプションで件数を指定できます。

### 使い方

```bash
# 直近10件を取得
./scripts/get_recent_done_items.sh

# 直近5件を取得
./scripts/get_recent_done_items.sh --limit 5
```

## git_sjis_diff.sh

Shift-JISとUTF-8のファイルが混在するリポジトリで `git diff` を実行した際の文字化けを防ぐためのヘルパースクリプトです。

Gitの `textconv` 機能と連携させることで、差分表示の際にShift-JISのファイルを自動的にUTF-8へ変換します。

### 使い方

#### 手順1: スクリプトの配置と実行権限の付与

本スクリプトを任意のパスに配置し（例: `~/.git_sjis_diff.sh`）、実行権限を付与します。

```bash
# 例: ホームディレクトリにコピーする場合
cp git_sjis_diff.sh ~/.git_sjis_diff.sh

# 実行権限を付与
chmod +x ~/.git_sjis_diff.sh
```

**前提条件:** このスクリプトは `nkf` コマンドを使用します。もしインストールされていない場合は、お使いのOSのパッケージマネージャでインストールしてください。
(例: `brew install nkf`, `sudo apt-get install nkf`)

#### 手順2: Gitへのドライバ登録

スクリプトを `textconv` ドライバとしてGitに登録します。

```bash
git config --global diff.sjis-safe.textconv "~/.git_sjis_diff.sh"
```

#### 手順3: `.gitattributes` での適用

文字化け対策を適用したいリポジトリの `.gitattributes` ファイル（なければ作成）に、対象のファイルとドライバを結びつける設定を記述します。

**例: `.csv` ファイルに適用する場合**
```
*.csv diff=sjis-safe
```

**例: `.txt` と `.log` ファイルにも適用する場合**
```
*.csv diff=sjis-safe
*.txt diff=sjis-safe
*.log diff=sjis-safe
```

---
### 補足: コミットログの文字化け対策

`git diff` だけでなく、ターミナルやGitクライアントでのコミットログの文字化けも防ぎたい場合は、以下の設定を推奨します。

```bash
git config --global core.quotepath false
git config --global i18n.commitencoding utf-8
```
