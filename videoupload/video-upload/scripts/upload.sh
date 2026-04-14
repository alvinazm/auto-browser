#!/bin/bash

# 抖音视频上传脚本 (stdio 模式)
# 用法: ./upload.sh <视频路径> [标题]

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 <视频路径> [标题] [封面路径]"
    exit 1
fi

VIDEO_PATH="$1"
TITLE="${2:-测试视频上传}"
COVER_PATH="$3"
URL="https://creator.douyin.com/creator-micro/content/upload"

STDIO_SERVER="/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js"

echo "============================================"
echo "抖音视频上传脚本 (stdio模式)"
echo "视频路径: $VIDEO_PATH"
echo "标题: $TITLE"
if [ -n "$COVER_PATH" ]; then
    echo "封面路径: $COVER_PATH"
fi
echo "============================================"

# 检查视频文件是否存在
if [ ! -f "$VIDEO_PATH" ]; then
    echo "错误: 视频文件不存在: $VIDEO_PATH"
    exit 1
fi

# 检查封面文件是否存在（如果提供了封面）
if [ -n "$COVER_PATH" ] && [ ! -f "$COVER_PATH" ]; then
    echo "错误: 封面文件不存在: $COVER_PATH"
    exit 1
fi

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

# 主流程
cleanup

echo ""
echo "=== 初始化 MCP ==="
INIT_JSON='{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"cli","version":"1.0"}},"id":1}'
INIT_RESULT=$(mcp_call "$INIT_JSON")
echo "初始化: OK"

echo ""
echo "=== 打开上传页面 ==="
NAVIGATE_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_navigate\",\"arguments\":{\"url\":\"$URL\"}},\"id\":2}"
RESULT=$(mcp_call "$NAVIGATE_JSON")

if ! echo "$RESULT" | grep -q '"isError":false'; then
    echo "导航失败"
    exit 1
fi
echo "导航: OK"

echo "等待 5 秒让页面加载..."
sleep 5

echo ""
echo "=== 点击上传按钮 ==="
CLICK_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.semi-button","selectorType":"css"}},"id":3}'
CLICK_RESULT=$(mcp_call "$CLICK_JSON")
echo "点击结果: $CLICK_RESULT"

echo "等待 2 秒..."
sleep 2

echo ""
echo "=== 上传视频文件 ==="
ESCAPED_PATH=$(echo "$VIDEO_PATH" | sed 's/"/\\"/g')
UPLOAD_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"input[type=\\\"file\\\"]\",\"filePath\":\"$ESCAPED_PATH\"}},\"id\":4}"
UPLOAD_RESULT=$(mcp_call "$UPLOAD_JSON")
echo "上传结果: $UPLOAD_RESULT"

echo ""
echo "=== 等待视频处理 (8秒) ==="
sleep 8

echo ""
echo "=== 检查页面状态 ==="
READ_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{"filter":"interactive"}},"id":5}'
PAGE_RESULT=$(mcp_call "$READ_JSON")
echo "页面: $PAGE_RESULT"

if echo "$PAGE_RESULT" | grep -q "标题"; then
    echo ""
    echo "=== 填写标题 ==="
    ESCAPED_TITLE=$(echo "$TITLE" | sed 's/"/\\"/g')
    FILL_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_fill_or_select\",\"arguments\":{\"selector\":\"input[placeholder*=\\\"填写作品标题\\\"]\",\"value\":\"$ESCAPED_TITLE\"}},\"id\":6}"
    FILL_RESULT=$(mcp_call "$FILL_JSON")
    echo "填写: $FILL_RESULT"
    
    # 如果提供了封面路径，则上传封面
    if [ -n "$COVER_PATH" ]; then
        echo ""
        echo "=== 上传封面 ==="
        
        # 根据页面元素，选择封面按钮在 (702, 563)
        # 步骤1: 点击"选择封面"按钮 (使用 CSS 选择器)
        echo "步骤1: 点击选择封面按钮"
        CLICK_COVER_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"div.title-wA45Xd","selectorType":"css"}},"id":7}'
        CLICK_COVER_RESULT=$(mcp_call "$CLICK_COVER_JSON")
        echo "点击选择封面: $CLICK_COVER_RESULT"
        
        echo "等待 3 秒让弹框出现..."
        sleep 3
        
        # 步骤2: 读取弹框内容
        echo "步骤2: 读取弹框元素"
        READ_DIALOG_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_read_page","arguments":{}},"id":8}'
        READ_DIALOG_RESULT=$(mcp_call "$READ_DIALOG_JSON")
        echo "弹框元素: $READ_DIALOG_RESULT"
        
        # 步骤3: 点击"上传封面"按钮
        echo "步骤3: 点击上传封面按钮"
        CLICK_UPLOAD_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"coordinates":{"x":1097,"y":610}}},"id":9}'
        CLICK_UPLOAD_RESULT=$(mcp_call "$CLICK_UPLOAD_JSON")
        echo "点击上传封面: $CLICK_UPLOAD_RESULT"
        
        echo "等待 2 秒..."
        sleep 2
        
        # 步骤4: 上传封面文件 (使用精确的选择器)
        echo "步骤4: 上传封面文件"
        ESCAPED_COVER=$(echo "$COVER_PATH" | sed 's/"/\\"/g')
        UPLOAD_COVER_JSON="{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"chrome_upload_file\",\"arguments\":{\"selector\":\"div.upload-BvM5FF input.semi-upload-hidden-input\",\"filePath\":\"$ESCAPED_COVER\"}},\"id\":10}"
        UPLOAD_COVER_RESULT=$(mcp_call "$UPLOAD_COVER_JSON")
        echo "上传封面: $UPLOAD_COVER_RESULT"
        
        echo "等待 3 秒让封面上传完成..."
        sleep 3
        
        # 步骤5: 点击"完成"按钮
        echo "步骤5: 点击完成按钮"
        CLICK_FINISH_JSON='{"jsonrpc":"2.0","method":"tools/call","params":{"name":"chrome_click_element","arguments":{"selector":"button.secondary-zU1YLr","selectorType":"css"}},"id":11}'
        CLICK_FINISH_RESULT=$(mcp_call "$CLICK_FINISH_JSON")
        echo "点击完成: $CLICK_FINISH_RESULT"
    fi
fi

echo ""
echo "============================================"
echo "上传流程完成!"
echo "============================================"