#!/bin/bash
# 部署前端构建产物到 surge.sh 脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DOMAIN="${1:-goofish-hunter-rocsail.surge.sh}"
EMAIL="rocsail97@gmail.com"

echo "=========================================="
echo "正在准备部署前端到 Surge.sh"
echo "目标域名: https://$DOMAIN"
echo "Surge 账号: $EMAIL"
echo "=========================================="

if [ ! -d "dist" ]; then
    echo "构建产物不存在，正在构建前端..."
    cd web-ui && npm run build && cd "$SCRIPT_DIR"
fi

# Surge 部署单页应用路由重定向 (SPA 404 支持)
if [ -f "dist/index.html" ] && [ ! -f "dist/200.html" ]; then
    cp dist/index.html dist/200.html
fi

echo "正在执行 surge 部署..."
echo "提示: 如果尚未在本地登录过 Surge，请在提示时输入密码完成认证（首次使用输入新密码即自动注册）。"

npx --yes surge dist "$DOMAIN"

echo "=========================================="
echo "部署命令执行完毕！"
echo "访问地址: https://$DOMAIN"
echo "=========================================="
