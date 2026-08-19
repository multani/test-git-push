#!/bin/bash

set -euo pipefail

COMMIT_MESSAGE="${1:?"Specify the commit message"}"
AUTHOR_NAME="${2:-""}"
AUTHOR_EMAIL="${3:-""}"

# Pass this as an environment variable only.
GITHUB_TOKEN="${GITHUB_TOKEN:-""}"

if ([ -n "$AUTHOR_NAME" ] && [ -z "$AUTHOR_EMAIL"]) || ( [ -z "$AUTHOR_NAME" ] && [ -n "$AUTHOR_EMAIL" ])
then
    echo "Either both AUTHOR_NAME and AUTHOR_EMAIL must be defined, or neither should be"
    exit 1
fi

ignore_file="$(mktemp)"
# Additional "ignore file", in addition to the .gitignore file of the repository.
git config core.excludesFile "$ignore_file"

cat <<EOF > "$ignore_file"
## Ignore well known files
# https://github.com/google-github-actions/auth#prerequisites
gha-creds-*
EOF

echo "Will ignore by default the following patterns:"
echo "=============================================="
cat "$ignore_file"
echo "=============================================="

diff="$(git status --short)"
if [ -z "$diff" ]
then
    echo "No changes detected"
    echo "changes-pushed=false" >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "Changes detected:"
echo "================="
git status --short --branch
echo "================="

if [ -z "$AUTHOR_NAME" ]
then
    echo "No author specified, retrieving author of previous commit"
    AUTHOR_NAME="$(git log --max-count 1 --pretty=format:%an)"
    AUTHOR_EMAIL="$(git log --max-count 1 --pretty=format:%ae)"
fi

echo "Setting commit author: $AUTHOR_NAME <$AUTHOR_EMAIL>"
git config user.name "$AUTHOR_NAME"
git config user.email "$AUTHOR_EMAIL"

git add .
git commit --message "$COMMIT_MESSAGE"

set -x

if [ -n "$GITHUB_TOKEN" ]
then
    echo "Using dedicated credentials to push changes..."
    # If a specific credentials has been provided, use it explicitly instead of relying on the ambiant credentials.
    git -c credential.helper= \
        -c credential.helper='!f() { echo username=x-access-token; echo "password=${GITHUB_TOKEN}"; }; f' \
        push
else
    echo "Using ambiant credentials to push changes..."
    git push
fi

echo "changes-pushed=true" >> "$GITHUB_OUTPUT"
