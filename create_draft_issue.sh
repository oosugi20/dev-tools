#!/bin/bash

# スクリプトが配置されているディレクトリに移動
cd "$(dirname "$0")"

# --- .envファイルの読み込み ---
if [ -f .env ]; then
  export $(cat .env | sed 's/#.*//g' | xargs)
fi

# --- 引数の初期化 ---
ISSUE_TITLE=""
ISSUE_BODY=""
TAG_NAME=""
POINTS_VALUE=""

# --- コマンドライン引数の解析 ---
while [ "$#" -gt 0 ]; do
  case "$1" in
    --title)
      ISSUE_TITLE="$2"
      shift 2
      ;;
    --body)
      ISSUE_BODY="$2"
      shift 2
      ;;
    --tag)
      TAG_NAME="$2"
      shift 2
      ;;
    --points)
      POINTS_VALUE="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

# --- 必須引数のチェック ---
if [ -z "$ISSUE_TITLE" ]; then
  echo "Usage: $0 --title <\"issue title\"> [--body <\"issue body\">] [--tag <\"tag name\">] [--points <number>]"
  echo "Error: --title is a required argument."
  exit 1
fi

# --- Step 1: Draft Issueを作成し、そのItem IDを取得する ---
echo "Creating draft issue..."
echo "Title: $ISSUE_TITLE"

read -r -d '' CREATE_ISSUE_QUERY <<'EOF'
mutation($projectId: ID!, $title: String!, $body: String) {
  addProjectV2DraftIssue(input: {
    projectId: $projectId,
    title: $title,
    body: $body
  }) {
    projectItem {
      id
    }
  }
}
EOF

PROJECT_ITEM_ID=$(gh api graphql \
  -f projectId="${PROJECT_ID}" \
  -f title="${ISSUE_TITLE}" \
  -f body="${ISSUE_BODY}" \
  -f query="$CREATE_ISSUE_QUERY" | jq -r '.data.addProjectV2DraftIssue.projectItem.id')

if [ -z "$PROJECT_ITEM_ID" ] || [ "$PROJECT_ITEM_ID" == "null" ]; then
  echo "❌ Failed to create draft issue or get its ID. Check your GITHUB_TOKEN and PROJECT_ID."
  exit 1
fi

echo "✅ Successfully created draft issue with Item ID: $PROJECT_ITEM_ID"

# --- Step 2 & 3: タグとポイントを更新する ---

# タグが指定されている場合のみ実行
if [ -n "$TAG_NAME" ]; then
  echo "Updating 'Tag' field..."
  
  read -r -d '' GET_TAG_FIELD_QUERY <<'EOF'
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }
EOF
  FIELD_DATA_JSON=$(gh api graphql -f projectId="${PROJECT_ID}" -f query="$GET_TAG_FIELD_QUERY" | jq -c '.data.node.fields.nodes[] | select(.name == "Tag")')
  TAGS_FIELD_ID=$(echo $FIELD_DATA_JSON | jq -r '.id')
  TAG_OPTION_ID=$(echo $FIELD_DATA_JSON | jq -r --arg tagName "$TAG_NAME" '.options[] | select(.name == $tagName) | .id')

  if [ -n "$TAGS_FIELD_ID" ] && [ -n "$TAG_OPTION_ID" ]; then
    read -r -d '' UPDATE_TAG_QUERY <<'EOF'
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId,
        itemId: $itemId,
        fieldId: $fieldId,
        value: { singleSelectOptionId: $optionId }
      }) {
        projectV2Item {
          id
        }
      }
    }
EOF
    gh api graphql -f projectId="${PROJECT_ID}" -f itemId="$PROJECT_ITEM_ID" -f fieldId="$TAGS_FIELD_ID" -f optionId="$TAG_OPTION_ID" -f query="$UPDATE_TAG_QUERY"
    echo "✅ 'Tag' field updated to '$TAG_NAME'."
  else
    echo "⚠️ Could not find 'Tag' field or option '$TAG_NAME' in the project."
  fi
fi

# ポイントが指定されている場合のみ実行
if [ -n "$POINTS_VALUE" ]; then
  echo "Updating 'Points' field..."
  
  read -r -d '' GET_POINTS_FIELD_QUERY <<'EOF'
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2Field {
              id
              name
            }
          }
        }
      }
    }
  }
EOF
  POINTS_FIELD_ID=$(gh api graphql -f projectId="${PROJECT_ID}" -f query="$GET_POINTS_FIELD_QUERY" | jq -r '.data.node.fields.nodes[] | select(.name == "Points") | .id')

  if [ -n "$POINTS_FIELD_ID" ]; then
    # printfを使ってGraphQLクエリを動的に生成
    UPDATE_POINTS_QUERY=$(printf '
    mutation {
      updateProjectV2ItemFieldValue(input: {
        projectId: "%s",
        itemId: "%s",
        fieldId: "%s",
        value: { number: %s }
      }) {
        projectV2Item {
          id
        }
      }
    }' "$PROJECT_ID" "$PROJECT_ITEM_ID" "$POINTS_FIELD_ID" "$POINTS_VALUE")

    gh api graphql -f query="$UPDATE_POINTS_QUERY"
    echo "✅ 'Points' field updated to '$POINTS_VALUE'."
  else
    echo "⚠️ Could not find 'Points' field in the project."
  fi
fi