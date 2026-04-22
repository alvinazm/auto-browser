#!/bin/bash

# 抖音视频上传脚本 (stdio 模式)
# 被 upload.sh 调用: upload_video_douyin <视频路径> <标题> [封面路径]
# 或单独运行: ./douyin.sh <视频路径> [标题] [封面路径]

PLATFORM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLATFORM_SCRIPT_DIR/../human.sh"

STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

# 检测是否被 source（作为函数被调用）
_is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

# MCP 调用函数 - 带重试
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

# 抖音视频上传函数
upload_video_douyin() {
    local video_path="$1"
    local title="$2"
    local cover_path="$3"

    echo "============================================"
    echo "抖音视频上传脚本 (stdio模式)"
    echo "视频路径: $video_path"
    echo "标题: $title"
    if [ -n "$cover_path" ]; then
        echo "封面路径: $cover_path"
    fi
    echo "============================================"

    # 检查视频文件
    if [ ! -f "$video_path" ]; then
        echo "错误: 视频文件不存在: $video_path"
        return 1
    fi

    # 检查封面文件
    if [ -n "$cover_path" ] && [ ! -f "$cover_path" ]; then
        echo "错误: 封面文件不存在: $cover_path"
        return 1
    fi

    # 清理端口
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2

    echo ""
    echo "=== 初始化 MCP ==="
    INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
    mcp_call "$INIT_JSON" > /dev/null

    echo ""
    echo "=== 打开上传页面 ==="
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://creator.douyin.com/creator-micro/content/upload"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    # 模拟人类阅读页面
    human_read_page_delay

    echo ""
    echo "=== 点击上传按钮 ==="
    human_reaction_delay
    CLICK_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.semi-button","selectorType":"css"}},"id":3}'
    CLICK_RESULT=$(mcp_call "$CLICK_JSON")
    echo "点击结果: $CLICK_RESULT"

    # 模拟人类延迟
    human_random_delay

    echo ""
    echo "=== 上传视频文件 ==="
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频处理 (2秒)..."
    sleep 2

    echo ""
    echo "=== 滚动页面 ==="
    human_random_delay
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    human_scroll_wait
    echo "滚动完成"

    echo ""
    echo "=== 填写标题 ==="
    human_reaction_delay
    ESCAPED_TITLE=$(echo "$title" | sed 's/"/\\"/g')
    FILL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"input[placeholder*=\\\"填写作品标题\\\"]\",\"value\":\"$ESCAPED_TITLE\"}},\"id\":6}"
    FILL_RESULT=$(mcp_call "$FILL_JSON")
    echo "填写: $FILL_RESULT"
        
        # 如果提供了封面路径
        if [ -n "$cover_path" ]; then
            echo ""
            echo "=== 上传封面 ==="
            
            human_reaction_delay
            
            echo "步骤1: 点击选择封面按钮"
            human_reaction_delay
            CLICK_COVER_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"div.title-wA45Xd","selectorType":"css"}},"id":7}'
            CLICK_COVER_RESULT=$(mcp_call "$CLICK_COVER_JSON")
            echo "点击选择封面: $CLICK_COVER_RESULT"
            
            human_scroll_wait
            
            echo "步骤2: 点击上传封面按钮"
            human_reaction_delay
            CLICK_UPLOAD_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"coordinates":{"x":1097,"y":610}}},"id":9}'
            CLICK_UPLOAD_RESULT=$(mcp_call "$CLICK_UPLOAD_JSON")
            echo "点击上传封面: $CLICK_UPLOAD_RESULT"
            
            human_random_delay
            
            echo "步骤3: 上传封面文件"
            ESCAPED_COVER=$(echo "$cover_path" | sed 's/"/\\"/g')
            UPLOAD_COVER_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"div.upload-BvM5FF input.semi-upload-hidden-input\",\"filePath\":\"$ESCAPED_COVER\"}},\"id\":10}"
            UPLOAD_COVER_RESULT=$(mcp_call "$UPLOAD_COVER_JSON")
            echo "上传封面: $UPLOAD_COVER_RESULT"
            
            SCROLL_COVER_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"up","scrollAmount":2}},"id":10}'
            mcp_call "$SCROLL_COVER_JSON" > /dev/null
            
            echo "等待 3 秒让封面上传完成..."
            sleep 3
            
            echo "步骤4: 点击完成按钮"
            human_reaction_delay
            CLICK_FINISH_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.secondary-zU1YLr","selectorType":"css"}},"id":11}'
            CLICK_FINISH_RESULT=$(mcp_call "$CLICK_FINISH_JSON")
            echo "点击完成: $CLICK_FINISH_RESULT"
        fi
    echo ""
    echo "============================================"
    echo "上传流程完成!"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题] [封面路径]"
        exit 1
    fi
    # 直接运行时：video title cover
    upload_video_douyin "$1" "$2" "$3"
fi