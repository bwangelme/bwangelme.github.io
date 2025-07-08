#!/bin/bash

# 设置错误处理：任何命令失败都会导致脚本退出
set -e

# 定义错误处理函数
handle_error() {
    echo "Error: $1"
    exit 1
}

if [[ ! -d ".deploy_git" ]]; then
    echo "please clone blog to .deploy_git"
    echo "git clone -b gh-page git@github.com:bwangelme/bwangelme.github.io.git .deploy_git"
    exit 0
fi

echo "Reset Commit"
cd .deploy_git
git reset --hard origin/gh-page || handle_error "Failed to reset git repository"
git pull origin gh-page --rebase || handle_error "Failed to pull from remote repository"
cd ..

echo "Cleaning up old files"
rm -rf public/ && rm -rf .deploy_git/* || handle_error "Failed to clean up old files"

echo "Generating static files with Hugo"
hugo || handle_error "Hugo failed to generate static files"

# 检查 public 目录是否存在且不为空
if [[ ! -d "public" ]] || [[ -z "$(ls -A public)" ]]; then
    handle_error "Hugo generated no files or public directory is empty"
fi

echo "Copying files to deployment directory"
cp -r public/* .deploy_git/ || handle_error "Failed to copy files to deployment directory"

echo "Commit changes"
cd .deploy_git
git add . || handle_error "Failed to add files to git"
git commit -m "update on $(date '+%Y-%m-%d %H:%M:%S')" || handle_error "Failed to commit changes"

echo "Start to push"
git push origin gh-page || handle_error "Failed to push to remote repository"

echo "Deployment completed successfully!"
