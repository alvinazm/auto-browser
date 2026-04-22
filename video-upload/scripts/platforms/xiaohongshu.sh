#!/bin/bash

# 小红书视频上传脚本 (stdio 模式)
# 被 upload.sh 调用: upload_video_xiaohongshu <视频路径> <标题>
# 或单独运行: ./xiaohongshu.sh <视频路径> [标题]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../human.sh"

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

# 小红书视频上传函数
upload_video_xiaohongshu() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "小红书视频上传脚本 (stdio模式)"
    echo "视频路径: $video_path"
    echo "标题: $title"
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
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video"}},"id":2}'
    RESULT=$(mcp_call "$NAVIGATE_JSON")

    if ! echo "$RESULT" | grep -q '"isError":false'; then
        echo "导航失败"
        return 1
    fi
    echo "导航: OK"

    # 模拟人类阅读页面
    human_read_page_delay

    echo ""
    echo "=== 上传视频文件 ==="
    human_reaction_delay
    ESCAPED_PATH=$(echo "$video_path" | sed 's/"/\\"/g')
    UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":3}"
    UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
    echo "上传结果: $UPLOAD_RESULT"

    echo "等待视频处理 (2秒)..."
    sleep 2

    echo ""
    echo "=== 滚动页面 ==="
    human_random_delay
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    echo "滚动完成"

    echo ""
    echo "=== 滚动后等待 ==="
    human_scroll_wait

    echo "=== 检查页面状态 ==="
    READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":5}'
    PAGE_RESULT=$(mcp_call "$READ_JSON")
    echo "页面: $PAGE_RESULT"

    # 填写标题 - 100% 参照原项目 cdp.py 的 input_text 方法
    if echo "$PAGE_RESULT" | grep -q "标题"; then
        echo ""
        echo "=== 填写标题 ==="
        human_reaction_delay
        ESCAPED_TITLE=$(echo "$title" | sed 's/"/\\"/g')
        
        # 步骤1: 检测是否是 contenteditable (参照原项目 cdp.py 第508-515行)
        echo "检测元素类型..."
        CHECK_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_javascript","arguments":{"code":"(()=>{const el=document.querySelector(\"input[placeholder*=\\\u6807\\u9896\\\"]\");return el?el.getAttribute(\"contenteditable\")===\"true\":false})()"}},"id":6}'
        CHECK_RESULT=$(mcp_call "$CHECK_JSON")
        
        # 步骤2: 根据元素类型选择填写方式
        if echo "$CHECK_RESULT" | grep -q '"result":true'; then
            # contenteditable: 用 JavaScript innerText (参照原项目 cdp.py 第520-560行)
            echo "contenteditable 元素，使用 JavaScript innerText"
            SET_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_javascript","arguments":{"code":"(()=>{const el=document.querySelector(\"input[placeholder*=\\u6807\\u9896\\\"]\");if(el){el.innerText=\"'$ESCAPED_TITLE'\";el.dispatchEvent(new Event(\"input\",{bubbles:true}));el.dispatchEvent(new Event(\"change\",{bubbles:true}))}})()"}},"id":7}'
        else
            # 普通 input: 先清空，再用 chrome_fill_or_select (参照原项目 cdp.py 第560-571行)
            echo "普通 input 元素，先清空后填写"
            CLEAR_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_javascript","arguments":{"code":"(()=>{const el=document.querySelector(\"input[placeholder*=\\u6807\\u9896\\\"]\");if(el){el.value=\"\";el.dispatchEvent(new Event(\"input\",{bubbles:true}))}})()"}},"id":7}'
            mcp_call "$CLEAR_JSON" > /dev/null
            sleep 0.2
            SET_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"input[placeholder*=\\\\\"标题\\\\\"],\"value\":\"$ESCAPED_TITLE\"}},\"id\":8}"
        fi
        
        FILL_RESULT=$(mcp_call "$SET_JSON")
        echo "填写结果: $FILL_RESULT"
    fi

    echo ""
    echo "============================================"
    echo "上传流程完成!"
    echo "============================================"
}

# 如果直接运行此脚本
if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题]"
        exit 1
    fi
    upload_video_xiaohongshu "$1" "$2"
fi
