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

find . -type f -not -path "./.git/*" -exec fgrep -l "$OLD_VERSION" {} + | xargs sed -i "s/$OLD_VERSION/$NEW_VERSION/g"

echo "Version update from $OLD_VERSION to $NEW_VERSION"
echo "Check your 'git diff' to make sure all went as expected"
