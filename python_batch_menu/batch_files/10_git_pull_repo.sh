#!/bin/bash
# 10_git_pull_repo.sh - Git pull a project

REPO_DIR="$HOME/my_project"

echo "Pulling latest code from $REPO_DIR..."
cd "$REPO_DIR" || exit 1
git pull origin main
echo "Git pull complete."

