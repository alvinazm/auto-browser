#!/bin/bash

# 百家号视频上传脚本 (stdio 模式)
# 100% 参照 douyin.sh 的 MCP 处理方式

PLATFORM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PLATFORM_SCRIPT_DIR/../human.sh"

STDIO_SERVER="${STDIO_SERVER:-/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js}"

# 检测是否被 source（作为函数被调用）
_is_sourced() {
    [[ "${BASH_SOURCE[0]}" != "${0}" ]]
}

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

upload_video_baijiahao() {
    local video_path="$1"
    local title="$2"

    echo "============================================"
    echo "百家号视频上传脚本 (stdio模式)"
    echo "视频路径: $video_path"
    echo "标题: $title"
    echo "============================================"

    if [ ! -f "$video_path" ]; then
        echo "错误: 视频文件不存在: $video_path"
        return 1
    fi

    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2

    echo ""
    echo "=== 初始化 MCP ==="
    INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
    mcp_call "$INIT_JSON" > /dev/null

    echo ""
    echo "=== 打开上传页面 ==="
    # 百家号上传页面 URL (参照原项目 routes.py)
    NAVIGATE_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_navigate","arguments":{"url":"https://baijiahao.baidu.com/builder/rc/edit?type=videoV2&is_from_cms=1"}},"id":2}'
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

    echo "等待视频处理 (3秒)..."
    sleep 3

    echo ""
    echo "=== 滚动页面 ==="
    human_random_delay
    SCROLL_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_computer","arguments":{"action":"scroll","scrollDirection":"down","scrollAmount":3}},"id":4}'
    mcp_call "$SCROLL_JSON" > /dev/null
    echo "滚动完成"

    echo ""
    echo "=== 滚动后等待 ==="
    human_scroll_wait
    sleep 2
    echo ""
    echo "=== 填写标题 ==="
    human_reaction_delay

    # JS 代码写临时文件, 避免 bash 引号嵌套问题 (100% 参照 douyin.sh 风格)
    JS_TEMP=$(mktemp)
    cat > "$JS_TEMP" << 'JSEOF'
var el = document.querySelector('[data-lexical-editor="true"]');
if (el) {
    el.textContent = '';
    el.dispatchEvent(new InputEvent('beforeinput', {inputType: 'deleteContentBackward', bubbles: true}));
    el.dispatchEvent(new InputEvent('input', {inputType: 'deleteContentBackward', bubbles: true}));
    el.focus();
    document.execCommand('selectAll', false, null);
    document.execCommand('insertText', false, 'TITLE_PLACEHOLDER');
    el.dispatchEvent(new Event('change', {bubbles: true}));
}
JSEOF

    # 替换标题占位符
    ESCAPED_TITLE=$(echo "$title" | sed 's/'\''/\\'\''/g')
    sed -i '' "s/TITLE_PLACEHOLDER/$ESCAPED_TITLE/g" "$JS_TEMP"

    # 用 Python 构造 JSON (避免 bash 引号嵌套问题, 参照 douyin.sh sed 风格)
    JS_JSON=$(python3 -c "
import json
with open('$JS_TEMP', 'r') as f:
    code = f.read()
d = {'jsonrpc': '2.0', 'method': 'tools/call', 'params': {'name': 'chrome_javascript', 'arguments': {'code': code}}, 'id': 6}
print(json.dumps(d, ensure_ascii=False))
")
    rm -f "$JS_TEMP"

    FILL_RESULT=$(mcp_call "$JS_JSON")
    echo "填写结果: $FILL_RESULT"

    echo ""
    echo "============================================"
    echo "百家号视频上传流程完成!"
    echo "============================================"
}

if ! _is_sourced; then
    if [ -z "$1" ]; then
        echo "用法: $0 <视频路径> [标题]"
        exit 1
    fi
    upload_video_baijiahao "$1" "$2"
fi