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
