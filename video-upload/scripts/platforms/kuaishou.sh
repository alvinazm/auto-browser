#!/bin/bash

# 快手视频上传脚本 (stdio 模式)
# 100% 参照 douyin.sh 的 MCP 处理方式

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../human.sh"

STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

# 检测是否被 source（作为函数被调用）
_is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# ========== MCP 调用函数 - 完全参照 douyin.sh ==========
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    local RESULT=""

    while [ $retry -lt $max_retries ]; do
        if [ $retry -gt 0 ]; then
            lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
            sleep 2
        fi

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

# ========== 快手视频上传函数 ==========
upload_video_kuaishou() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "快手视频上传脚本 (stdio模式)"
    echo "视频路径: $video_path"
    echo "描述: $title"
    echo "============================================"

    # 检查视频文件
    if [ ! -f "$video_path" ]; then
        echo "错误: 视频文件不存在: $video_path"
        return 1
    fi

    # 清理端口
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2

    echo ""
    echo "=== 初始化 MCP ==="
    INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
    INIT_RESULT=$(mcp_call "$INIT_JSON")
    echo "初始化: OK"

    echo ""
    echo "=== 打开上传页面 ==="
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://cp.kuaishou.com/article/publish/video?tabType=1"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    # 模拟人类阅读页面
    human_read_page_delay

    echo ""
    echo "=== 滚动页面查找上传区域 ==="
    human_scroll_wait
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":3}'
    mcp_call "$SCROLL_JSON" > /dev/null
    human_random_delay
    echo "滚动: OK"

    echo ""
    echo "=== 上传视频文件 ==="
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频上传 (10秒)..."
    sleep 10

    echo ""
    echo "=== 滚动页面 ==="
    human_random_delay
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    human_scroll_wait
    echo "滚动: OK"

    echo ""
    echo "=== 检查页面状态 ==="
    human_read_page_delay
    READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":5}'
    PAGE_RESULT=$(mcp_call "$READ_JSON")
    echo "页面: $PAGE_RESULT"

    # 参照原项目 xhs-comments-reply2 的 description_selectors
    # 方案1: 点击元素后用 keyboard type
    if echo "$PAGE_RESULT" | grep -q "work-description-edit"; then
        human_read_page_delay

        echo ""
        echo "=== 填写作品描述 (JavaScript直接设置) ==="
        human_reaction_delay
        
        # 使用 JavaScript 直接设置 innerText
        # 注意：需要处理引号转义
        ESCAPED_TITLE=$(echo "$title" | sed "s/'/\\\\'/g")
        
        JS_CODE="var el = document.getElementById('work-description-edit'); if(el) { el.innerText = '$ESCAPED_TITLE'; el.dispatchEvent(new Event('input', {bubbles:true})); }"
        JS_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_javascript\",\"arguments\":{\"code\":\"$JS_CODE\"}},\"id\":6}"
        JS_RESULT=$(mcp_call "$JS_JSON")
        echo "JS设置: $JS_RESULT"
    else
        echo "警告: 未找到描述输入框，尝试其他选择器..."
        # 回退到 chrome_fill_or_select
        for selector in 'div[contenteditable="true"][placeholder*="描述"]' 'textarea[placeholder*="描述"]'; do
            human_reaction_delay
            ESCAPED_TITLE=$(echo "$title" | sed 's/"/\\"/g')
            ESCAPED_SEL=$(echo "$selector" | sed 's/"/\\"/g')
            FILL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"$ESCAPED_SEL\",\"value\":\"$ESCAPED_TITLE\"}},\"id\":6}"
            FILL_RESULT=$(mcp_call "$FILL_JSON")

            if echo "$FILL_RESULT" | grep -q '"isError":false'; then
                echo "填写成功 (选择器: $selector)"
                break
            fi
        done
    fi

    echo ""
    echo "============================================"
    echo "快手视频上传流程完成!"
    echo "请在浏览器中确认发布状态"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题] [封面路径]"
        exit 1
    fi
    # 直接运行时：video title cover
    upload_video_kuaishou "$1" "$2"
fi