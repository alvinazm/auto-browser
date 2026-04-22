#!/bin/bash

# B站视频上传脚本
# 平台标识: bilibili
# 创作者后台: https://member.bilibili.com/platform/upload/video/frame

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/human.sh"

# ========== 平台配置 ==========
PLATFORM="bilibili"
PLATFORM_NAME="B站"
PLATFORM_URL="https://member.bilibili.com/platform/upload/video/frame"

# 文件选择器（按优先级排序）
FILE_SELECTORS=(
    'input[type="file"][accept*="video"]'
    'input[type="file"]'
    ".upload-area"
    "div.upload-area"
    '[class*="upload-area"]'
    '[class*="upload"]'
)

# 标题选择器
TITLE_SELECTORS=(
    'input[placeholder*="稿件标题"]'
    'input.input-val[placeholder*="标题"]'
    "input.input-val"
    'input[placeholder*="标题"]'
)

# ========== 平台特定函数 ==========

bilibili_get_file_selectors() {
    echo "${FILE_SELECTORS[*]}"
}

bilibili_get_title_selectors() {
    echo "${TITLE_SELECTORS[*]}"
}

# ========== 主上传流程 ==========

upload_video_bilibili() {
    local video_path="$1"
    local title="$2"

    echo ""
    echo "=== B站视频上传流程 ==="
    echo "视频: $video_path"
    echo "标题: $title"
    echo ""

    # 1. 清理端口并初始化 MCP
    cleanup_port
    init_mcp

    # 2. 导航到上传页面
    echo ""
    echo "=== 导航到上传页面 ==="
    navigate_to "$PLATFORM_URL"
    echo "导航: OK"

    # 3. 模拟人类阅读页面
    human_read_page_delay

    # 4. 滚动查找上传区域
    echo ""
    echo "=== 滚动页面查找上传区域 ==="
    human_scroll_down 2

    # 5. 上传视频文件
    echo ""
    echo "=== 上传视频文件 ==="
    upload_file_first_found "$video_path" "$(bilibili_get_file_selectors)"
    echo "上传视频: OK"

    # 6. 等待视频处理
    echo "等待视频上传 (10秒)..."
    sleep 10

    # 7. 滚动页面
    echo ""
    echo "=== 滚动页面 ==="
    human_scroll_down 2

    # 8. 填写标题
    echo ""
    echo "=== 填写稿件标题 ==="
    read_page_interactive
    fill_title_first_found "$title" "$(bilibili_get_title_selectors)"

    echo ""
    echo "============================================"
    echo "B站视频上传流程完成!"
    echo "请在浏览器中确认发布状态"
    echo "============================================"
}