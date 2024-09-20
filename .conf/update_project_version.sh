#!/bin/bash

echo "Updating project version..."

# Check if env variables are set
if [[ -z "$NEW_VERSION" ]]; then
    echo "Error: NEW_VERSION is not set $NEW_VERSION"
    exit 1
fi

# Check if env variables are set
if [[ -z "$OLD_VERSION" ]]; then
    echo "Error: OLD_VERSION is not set $OLD_VERSION"
    exit 1
fi

# Check if the path to the root multi-project directory is passed
if [ -z "$1" ]; then
  echo "Error: No positional argument provided. Exiting."
  exit 1
fi

cd "$1" || exit

# Replace the version string in Docker Compose files
# shellcheck disable=SC2038
find . -name "docker-compose*yml" \
    -type f -not -path "./.git/*" \
    -exec fgrep -l "$OLD_VERSION" {} + \
    | xargs -I {} sed -i \
    -E "s#(^\s*image: .+):$OLD_VERSION#\1:$NEW_VERSION#g" {}

# Replace the version string in settings JSON files
# shellcheck disable=SC2038
find . -name "settings.json" \
    -type f -not -path "./.git/*" \
    -exec fgrep -l "$OLD_VERSION" {} + \
    | xargs -I {} sed -i \
    -E "s/(^\s*\"docker_tag\": \")$OLD_VERSION(\")/\1$NEW_VERSION\2/g" {}

# Replace the version string in the top-level settings JSON file
sed -i \
    -E "s/(^\s*\"project_version\": \")$OLD_VERSION(\")/\1$NEW_VERSION\2/g" \
    .vscode/settings.json

# Ask the user to review the changes
git --no-pager diff
echo "Version updated from $OLD_VERSION to $NEW_VERSION"
echo "Check the 'git diff' above to make sure all went as expected"
