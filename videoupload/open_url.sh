#!/bin/bash

# MCP Chrome stdio 模式打开网页脚本
# 用法: ./open_url.sh <URL>

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <URL>"
    exit 1
fi

URL="$1"

# 添加 https:// 如果没有协议
if ! echo "$URL" | grep -q '^https://'; then
    URL="https://$URL"
fi

STDIO_SERVER="/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js"

# 清理端口
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}

# MCP 调用函数 - 带重试
mcp_call() {
    local JSON="$1"
    local max_retries=5
    local retry=0
    local RESULT=""
    
    while [ $retry -lt $max_retries ]; do
        if [ $retry -gt 0 ]; then
            cleanup
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

# 主流程 - stdio 模式不需要端口
cleanup

echo "打开: $URL"

# 先发送 initialize
INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
INIT_RESULT=$(mcp_call "$INIT_JSON")

# 然后导航
NAVIGATE_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_navigate\",\"arguments\":{\"url\":\"$URL\"}},\"id\":2}"
RESULT=$(mcp_call "$NAVIGATE_JSON")

if echo "$RESULT" | grep -q '"isError":false'; then
    echo "✓ 已打开"
    echo "$RESULT"
else
    echo "✗ 失败"
    echo "$RESULT"
    exit 1
fi