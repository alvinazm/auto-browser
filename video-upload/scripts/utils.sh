#!/bin/bash

# 公共工具函数库
# 所有平台脚本共享的 MCP 调用和工具函数

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/human.sh"

# MCP 服务器路径
STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

# 默认端口
MCP_PORT="${MCP_PORT:-12306}"

# ========== 端口清理 ==========

cleanup_port() {
    lsof -i :$MCP_PORT 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}

# ========== MCP 初始化 ==========

init_mcp() {
    echo "=== 初始化 MCP ==="
    INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
    INIT_RESULT=$(mcp_call_single "$INIT_JSON")
    echo "初始化: OK"
}

# ========== MCP 调用（单次，不重试）==========
mcp_call_single() {
    local JSON="$1"
    cleanup_port
    echo "$JSON" | node "$STDIO_SERVER" 2>&1
}

# ========== MCP 调用（带重试）==========
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    local RESULT=""

    while [ $retry -lt $max_retries ]; do
        # 每次调用前清理端口，防止旧进程残留
        cleanup_port

        RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)

        if echo "$RESULT" | grep -q '"jsonrpc"'; then
            if echo "$RESULT" | grep -q 'ECONNREFUSED\|Failed to connect'; then
                retry=$((retry + 1))
                continue
            fi
            echo "$RESULT"
            return 0
        fi

        retry=$((retry + 1))
        sleep 2
    done

    echo "$RESULT"
    return 1
}

# ========== 导航到页面 ==========

navigate_to() {
    local url="$1"
    NAVIGATE_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_navigate\",\"arguments\":{\"url\":\"$url\"}},\"id\":2}"
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败: $RESULT"
        return 1
    fi
    return 0
}

# ========== 读取页面 ==========

read_page_interactive() {
    READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":5}'
    RESULT=$(mcp_call_single "$READ_JSON")
    echo "$RESULT"
}

read_page_full() {
    READ_JSON='{"jsonrpc":"2.0","method\":\"tools/call\",\"params\":{\"name\":\"chrome_read_page\",\"arguments\":{}},\"id\":5}'
    RESULT=$(mcp_call_single "$READ_JSON")
    echo "$RESULT"
}

# ========== 点击元素 ==========

click_element() {
    local selector="$1"
    ESCAPED=$(echo "$selector" | sed 's/\"/\\"/g')
    CLICK_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_click_element\",\"arguments\":{\"selector\":\"$ESCAPED\",\"selectorType\":\"css\"}},\"id\":3}"
    RESULT=$(mcp_call "$CLICK_JSON")
    echo "$RESULT"
}

# 尝试多个选择器，返回第一个成功的
click_element_first_found() {
    local selectors=($1)
    for sel in "${selectors[@]}"; do
        if [ -n "$sel" ]; then
            result=$(click_element "$sel")
            if echo "$result" | grep -q '"isError":false'; then
                echo "使用选择器: $sel"
                return 0
            fi
        fi
    done
    echo "警告: 所有选择器都失败"
    return 1
}

# ========== 使用坐标点击 ==========

click_coordinates() {
    local x=$1
    local y=$2
    CLICK_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_click_element\",\"arguments\":{\"coordinates\":{\"x\":$x,\"y\":$y}}},\"id\":3}"
    RESULT=$(mcp_call "$CLICK_JSON")
    echo "$RESULT"
}

# ========== 填写表单 ==========

fill_input() {
    local selector="$1"
    local value="$2"
    ESCAPED=$(echo "$value" | sed 's/\"/\\"/g')
    ESCAPED_SEL=$(echo "$selector" | sed 's/\"/\\"/g')
    FILL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"$ESCAPED_SEL\",\"value\":\"$ESCAPED\"}},\"id\":6}"
    RESULT=$(mcp_call "$FILL_JSON")
    echo "$RESULT"
}

fill_input_first_found() {
    local value="$1"
    local selectors=($2)
    for sel in "${selectors[@]}"; do
        if [ -n "$sel" ]; then
            result=$(fill_input "$sel" "$value")
            if echo "$result" | grep -q '"isError":false'; then
                echo "填写成功: $sel"
                return 0
            fi
        fi
    done
    echo "警告: 填写失败"
    return 1
}

# 填写标题的包装函数
fill_title_first_found() {
    local title="$1"
    local selectors="$2"
    if [ -n "$title" ]; then
        human_read_page_delay
        human_reaction_delay
        fill_input_first_found "$title" "$selectors"
    else
        echo "未提供标题，跳过"
    fi
}

# ========== 上传文件 ==========

upload_file() {
    local selector="$1"
    local file_path="$2"
    ESCAPED_PATH=$(echo "$file_path" | sed 's/\"/\\"/g')
    ESCAPED_SEL=$(echo "$selector" | sed 's/\"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"$ESCAPED_SEL\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"
    RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "$RESULT"
}

upload_file_first_found() {
    local file_path="$1"
    local selectors=($2)
    for sel in "${selectors[@]}"; do
        if [ -n "$sel" ]; then
            result=$(upload_file "$sel" "$file_path")
            if echo "$result" | grep -q 'isError'; then
                # 检查是否是错误
                if echo "$result" | grep -q '"isError":true'; then
                    continue
                fi
            fi
            echo "上传成功: $sel"
            return 0
        fi
    done
    echo "警告: 文件上传失败"
    return 1
}

# ========== 滚动 ==========

scroll_down() {
    local amount=${1:-3}
    SCROLL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_computer\",\"arguments\":{\"action\":\"scroll\",\"scrollDirection\":\"down\",\"scrollAmount\":$amount}},\"id\":4}"
    RESULT=$(mcp_call_single "$SCROLL_JSON")
    echo "$RESULT"
}

scroll_up() {
    local amount=${1:-3}
    SCROLL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_computer\",\"arguments\":{\"action\":\"scroll\",\"scrollDirection\":\"up\",\"scrollAmount\":$amount}},\"id\":4}"
    RESULT=$(mcp_call_single "$SCROLL_JSON")
    echo "$RESULT"
}

# 带人类行为模拟的滚动
human_scroll_down() {
    local times=${1:-1}
    local i
    for ((i=1; i<=times; i++)); do
        human_scroll_wait
        scroll_down 3
        human_random_delay
    done
}

human_scroll_up() {
    local times=${1:-1}
    local i
    for ((i=1; i<=times; i++)); do
        human_scroll_wait
        scroll_up 3
        human_random_delay
    done
}

# ============================================================
# 平台配置映射
# ============================================================

# 获取平台 URL
get_platform_url() {
    local platform="$1"
    case "$platform" in
        douyin)
            echo "https://creator.douyin.com/creator-micro/content/upload"
            ;;
        xiaohongshu)
            echo "https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video"
            ;;
        kuaishou)
            echo "https://cp.kuaishou.com/article/publish/video?tabType=1"
            ;;
        baijiahao)
            echo "https://baijiahao.baidu.com/builder/rc/edit?type=videoV2&is_from_cms=1"
            ;;
        bilibili)
            echo "https://member.bilibili.com/platform/upload/video/frame"
            ;;
        *)
            echo ""
            ;;
    esac
}

# 检查平台是否支持
is_platform_supported() {
    local platform="$1"
    case "$platform" in
        douyin|xiaohongshu|kuaishou|baijiahao|bilibili)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}