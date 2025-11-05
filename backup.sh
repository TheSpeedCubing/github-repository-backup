#!/bin/bash

NAME="$1"
TYPE="$2"
TOKEN="$3"
PAGE=1

while :; do
  echo "Fetching repos from: $TYPE/$NAME (page $PAGE)..."

  if [ "$TYPE" = "orgs" ]; then
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
      "https://api.github.com/orgs/$NAME/repos?per_page=100&page=$PAGE")
    COUNT=$(echo "$RESPONSE" | jq 'length')

    if [ "$COUNT" -eq 0 ]; then
      break
    fi

    REPOS=$(echo "$RESPONSE" | jq -r '.[] | "\(.name) \(.private)"')
  else
    RESPONSE=$(curl -s -H "Authorization: token $TOKEN" \
      "https://api.github.com/search/repositories?q=user:$NAME&per_page=100&page=$PAGE")
    COUNT=$(echo "$RESPONSE" | jq '.items | length')

    if [ "$COUNT" -eq 0 ]; then
      break
    fi

    REPOS=$(echo "$RESPONSE" | jq -r '.items[] | "\(.name) \(.private)"')
  fi

  echo "$REPOS" | while IFS= read -r LINE; do
    REPO_NAME=$(echo "$LINE" | awk '{print $1}')
    IS_PRIVATE=$(echo "$LINE" | awk '{print $2}')
    SSH_URL="git@github.com:$NAME/$REPO_NAME.git"
    DEST="./$TYPE/$NAME/$REPO_NAME.git"

    echo "Cloning $REPO_NAME into $DEST"
    mkdir -p "$TYPE/$NAME"
    git clone --mirror "$SSH_URL" "$DEST"
  done

  [ -z "$REPOS" ] && break

  sleep 1

  PAGE=$((PAGE + 1))
done
