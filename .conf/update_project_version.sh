#!/bin/bash

###--- VARIABLES ---###
STATE_IS_STASHED=0      # 1 - stash any changes
STATE_IS_MODIFIED=0     # 2 - modify the version
STATE_IS_STAGED=0       # 3 - stage modified version
STATE_IS_COMMITTED=0    # 4 - commit new version
STATE_IS_TAGGED=0       # 5 - tag new version
STATE_IS_PUSHED=0       # 6 - push to GitHub
STATE_IS_PR=0           # 7 - create GitHub PR

###--- FUNCTIONS ---###

ask_user_confirmation() {
    read -p "Do you want to proceed? (y/n)" -n 1 -r
    echo # just go to newlin

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        user_confirmation=0
    else
        user_confirmation=1
    fi

    return $user_confirmation
}

dirty_exit() {
    printf "\nAborting the release!\n\n"

    # Undo 7 - create GitHub PR
    if [ "$STATE_IS_PR" -ne "0" ]; then
        gh pr close "$(git branch --show-current)"
        echo "GitHub PR closed. If you want to delete it, do it manually"
        STATE_IS_PR=0
    fi

    # Undo 5 - tag new version
    if [ "$STATE_IS_TAGGED" -ne "0" ]; then
        git tag --delete "$NEW_VERSION"
        STATE_IS_TAGGED=0
    fi

    # Undo 4 - commit new version
    if [ "$STATE_IS_COMMITTED" -ne "0" ]; then
        git reset --soft HEAD~1
        STATE_IS_COMMITTED=0
    fi

    # Undo 6 - push to GitHub
    if [ "$STATE_IS_PUSHED" -ne "0" ]; then
        git push --force
        STATE_IS_PUSHED=0
    fi

    # Undo 3 - stage modified version
    if [ "$STATE_IS_STAGED" -ne "0" ]; then
        git reset
        STATE_IS_STAGED=0
    fi

    # Undo 2 - modify the version
    if [ "$STATE_IS_MODIFIED" -ne "0" ]; then
        git restore .
        STATE_IS_MODIFIED=0
    fi

    # Undo 1 - stash any changes
    if [ "$STATE_IS_STASHED" -ne "0" ]; then
        git stash pop
        STATE_IS_STASHED=0
    fi

    # Remove leftover file(s)
    rm -f .commitmsg

    # Always exit with error code if this function is called
    printf "\n\nRelease aborted\n"
    echo "Double-check your git state (local and remote)"
    exit 1
}

clean_exit() {
    printf "\nConcluding the release process!\n\n"

    # No need to undo 4 - commit new version
    # No need to undo 3 - stage modified version
    # No need to undo 2 - modify the version

    # Undo 1 - stash any changes
    if [ "$STATE_IS_STASHED" -ne "0" ]; then
        git stash pop
        printf "\n\nThe previously stashed changes are unstashed\n"
        STATE_IS_STASHED=0
    fi

    # Remove leftover file(s)
    rm -f .commitmsg

    echo "Double-check your git state (local and remote)"
    echo "Then proceed to making the release on GitHub"
    exit 0
}

###--- SCRIPT ---###

echo "Updating project version..."

# Check if env variables are set
if [[ -z "$NEW_VERSION" ]]; then
    echo "Error: NEW_VERSION is not set $NEW_VERSION"
    dirty_exit
fi

# Check if env variables are set
if [[ -z "$OLD_VERSION" ]]; then
    echo "Error: OLD_VERSION is not set $OLD_VERSION"
    dirty_exit
fi

# Check if the path to the root multi-project directory is passed
if [ -z "$1" ]; then
    echo "Error: No positional argument provided. Exiting."
    dirty_exit
fi

cd "$1" || dirty_exit

# Only proceed if there are no unstaged changes
if ! git diff --quiet; then
    echo "There are unstaged changes"
    echo "If you continue they will be stashed"
    if ! ask_user_confirmation; then
        git stash
        STATE_IS_STASHED=1
    else
        dirty_exit
    fi
fi
cd "$1" || dirty_exit

# Only proceed if there are no unstaged changes
if ! git diff --quiet; then
    echo "There are unstaged changes"
    echo "If you continue they will be stashed"
    if ! ask_user_confirmation; then
        git stash
        STATE_IS_STASHED=1
    else
        dirty_exit
    fi
fi

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

STATE_IS_MODIFIED=1

# Ask the user to review the changes
git --no-pager diff
echo "Version updated from $OLD_VERSION to $NEW_VERSION"
echo "Check the 'git diff' above to make sure all went as expected"

# Only proceed if the user agree
if ! ask_user_confirmation; then
    dirty_exit
fi

# Generate release commit and wait for the user approve it
echo "Generating release commit, please review and commit it"
sleep 3
git add -u
STATE_IS_STAGED=1

{
    printf "### Review and uncomment the following lines ###\n"
    printf "#Release %s\n\n" "$NEW_VERSION"
    git log --pretty=format:'#* %s' HEAD..."$OLD_VERSION"
    printf "\n\n#Signed-off-by: %s <%s> \n\n" "$(git config user.name)" "$(git config user.email)"
} > .commitmsg

if ! git commit --template=.commitmsg; then
    echo "The commit was aborted or failed"
    dirty_exit
fi
STATE_IS_COMMITTED=1
rm -f .commitmsg

# Tag the commit
if ! git tag -a "$NEW_VERSION" -m "Release $NEW_VERSION"; then
    echo "The tagging was aborted or failed"
    dirty_exit
fi
STATE_IS_TAGGED=1

# Push current branch to remote
echo "The following local commits will be pushed to the remote, please review them:"
git log --oneline '@{u}..'

# Only proceed if the user agree
if ! ask_user_confirmation; then
    dirty_exit
fi

# Push commit
if ! git push; then
    echo "Push commit to remote failed. Stopping the release process"
    dirty_exit
else
    # Push tag
    if ! git push --tags; then
        echo "Push tags to remote failed. Stopping the release process"
        dirty_exit
    fi
fi
STATE_IS_PUSHED=1

if ! gh pr create --title "Release $NEW_VERSION" --fill; then
    echo "Creation of GitHub PR failed. Stopping the release process"
    dirty_exit
fi
STATE_IS_PR=1

# Clean exit
clean_exit
