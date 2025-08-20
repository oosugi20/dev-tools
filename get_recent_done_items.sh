#!/bin/bash

# スクリプトが配置されているディレクトリに移動
cd "$(dirname "$0")"

# --- .envファイルの読み込み ---
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# --- 必須変数のチェック ---
if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID is not set in your .env file."
  exit 1
fi

# --- 引数の解析 ---
LIMIT=10 # デフォルト値
if [[ "$1" == "--limit" && -n "$2" ]]; then
  # 入力が数値であるかチェック
  if ! [[ "$2" =~ ^[0-9]+$ ]]; then
    echo "Error: --limit requires a numeric value."
    exit 1
  fi
  LIMIT="$2"
fi

echo "Fetching the last $LIMIT 'Done' items from Project ID: $PROJECT_ID"
echo "---"

# --- GraphQL クエリの定義 ---
read -r -d '' GET_DONE_ITEMS_QUERY <<'EOF'
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100, orderBy: {field: POSITION, direction: DESC}) {
        nodes {
          status: fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue {
              name
            }
          }
          points: fieldValueByName(name: "Points") {
            ... on ProjectV2ItemFieldNumberValue {
              number
            }
          }
          content {
            ... on Issue {
              title
            }
            ... on DraftIssue {
              title
            }
          }
        }
      }
    }
  }
}
EOF

# --- JQ Filterの定義 ---
read -r -d '' JQ_FILTER <<'EOF'
.data.node.items.nodes |
map(select(.status.name == "Done")) |
.[0:$limit] |
.[] |
{
  title: .content.title,
  points: (if .points.number then .points.number else 0 end)
}
EOF

# --- APIの実行と結果の整形 ---
gh api graphql -f projectId="$PROJECT_ID" -f query="$GET_DONE_ITEMS_QUERY" | \
  jq --argjson limit "$LIMIT" "$JQ_FILTER"

