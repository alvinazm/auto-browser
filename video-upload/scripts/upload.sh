#!/bin/bash

# 抖音视频上传脚本
# 用法: ./upload.sh <视频路径> [标题]

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=12306

# 设置 NODE_PATH 以找到 MCP SDK
export NODE_PATH="/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules:$NODE_PATH"

# 参数检查
if [ -z "$1" ]; then
    echo "用法: $0 <视频路径> [标题]"
    exit 1
fi

VIDEO_PATH="$1"
TITLE="${2:-测试视频上传}"

echo "============================================"
echo "抖音视频上传脚本"
echo "视频路径: $VIDEO_PATH"
echo "标题: $TITLE"
echo "============================================"

# 检查视频文件是否存在
if [ ! -f "$VIDEO_PATH" ]; then
    echo "错误: 视频文件不存在: $VIDEO_PATH"
    exit 1
fi

# 检查 MCP 服务是否已运行（不需要启动）
echo ""
echo "=== 检查 MCP 服务 ==="
if lsof -i :$PORT | grep -q LISTEN; then
    echo "MCP 服务已在运行 (端口 $PORT)"
else
    echo "错误: MCP 服务未运行"
    echo "请先在 Chrome 中激活 mcp-chrome 扩展"
    exit 1
fi

echo ""
echo "=== 执行上传流程 (单进程单连接) ==="

node -e "
// 设置模块路径
process.env.NODE_PATH = '/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules:' + process.env.NODE_PATH;
require('module')._initPaths();

const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StreamableHTTPClientTransport } = require('@modelcontextprotocol/sdk/client/streamableHttp.js');
const fs = require('fs');

const videoPath = '$VIDEO_PATH';
const title = '$TITLE';
const configPath = '/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json';

async function run() {
    // 加载配置
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    // 创建单一客户端
    console.log('创建 MCP 客户端...');
    const client = new Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
    const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
    await client.connect(transport);
    console.log('客户端已连接');
    
    try {
        // 环节 3: 导航
        console.log('');
        console.log('=== 环节 3: 导航到上传页面 ===');
        await new Promise(r => setTimeout(r, 2000));
        
        const navResult = await client.callTool({ 
            name: 'chrome_navigate', 
            arguments: { url: 'https://creator.douyin.com/creator-micro/content/upload' }
        }, undefined, { timeout: 60000 });
        console.log('导航结果:', navResult.content?.[0]?.text);
        
        console.log('等待 5 秒让页面加载...');
        await new Promise(r => setTimeout(r, 5000));
        
        // 环节 4: 上传
        console.log('');
        console.log('=== 环节 4: 上传视频文件 ===');
        console.log('视频路径:', videoPath);
        
        const uploadResult = await client.callTool({ 
            name: 'chrome_upload_file', 
            arguments: { 
                selector: 'input[type=\"file\"]',
                filePath: videoPath
            }
        }, undefined, { timeout: 180000 });
        console.log('上传结果:', uploadResult.content?.[0]?.text);
        
        // 环节 5: 等待处理
        console.log('');
        console.log('=== 环节 5: 等待视频处理 ===');
        console.log('等待 15 秒...');
        await new Promise(r => setTimeout(r, 15000));
        
        // 环节 6: 检查状态
        console.log('');
        console.log('=== 环节 6: 检查页面状态 ===');
        const pageResult = await client.callTool({ 
            name: 'chrome_read_page', 
            arguments: { filter: 'interactive' }
        }, undefined, { timeout: 30000 });
        
        const content = typeof pageResult.content === 'string' ? pageResult.content : JSON.stringify(pageResult.content);
        
        if (content.includes('textbox') && (content.includes('标题') || content.includes('标题'))) {
            console.log('✓ 视频上传成功！页面已跳转到编辑页面');
            
            // 环节 7: 填写标题
            console.log('');
            console.log('=== 环节 7: 填写标题 ===');
            
            const fillResult = await client.callTool({ 
                name: 'chrome_fill_or_select', 
                arguments: { 
                    selector: 'input[placeholder*=\"标题\"]',
                    value: title
                }
            }, undefined, { timeout: 30000 });
            console.log('填写结果:', fillResult.success ? '成功' : '失败');
        } else {
            console.log('页面元素:', content.substring(0, 1000));
        }
        
    } catch (e) {
        console.error('错误:', e.message);
    } finally {
        console.log('');
        console.log('关闭客户端...');
        await client.close();
    }
}

run().then(() => {
    console.log('');
    console.log('============================================');
    console.log('上传流程完成!');
    console.log('============================================');
}).catch(e => {
    console.error('Fatal error:', e);
    process.exit(1);
});
"

echo ""
echo "脚本执行完成"