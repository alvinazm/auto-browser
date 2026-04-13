/**
 * MCP Chrome 工具调用封装
 * 用于抖音视频上传
 */

// 设置模块路径
process.env.NODE_PATH = '/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules:' + process.env.NODE_PATH;
require('module')._initPaths();

const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StreamableHTTPClientTransport } = require('@modelcontextprotocol/sdk/client/streamableHttp.js');
const path = require('path');
const fs = require('fs');

// 配置文件路径 - 指向全局安装的 mcp-chrome-bridge
const CONFIG_PATH = '/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json';

// 加载配置
function loadConfig() {
    const configData = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(configData);
}

// 创建 MCP 客户端 - 每次调用都创建全新的实例
async function createClient() {
    // 等待一下确保之前的连接已完全关闭
    await new Promise(r => setTimeout(r, 1000));
    
    const config = loadConfig();
    
    // 创建全新的 Client 实例
    const client = new Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
    
    // 创建全新的 Transport 实例
    const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
    
    // 连接
    await client.connect(transport);
    
    return { client, transport };
}

// 调用工具
async function callTool(name, args) {
    let client = null;
    let transport = null;
    
    try {
        const conn = await createClient();
        client = conn.client;
        transport = conn.transport;
        
        const result = await client.callTool({ name, arguments: args }, undefined, { timeout: 120000 });
        return result;
    } catch (error) {
        console.error('callTool error:', error.message);
        throw error;
    } finally {
        // 确保关闭
        if (client) {
            try {
                await client.close();
            } catch (e) {
                // 忽略关闭错误
            }
        }
        // 额外等待确保连接完全关闭
        await new Promise(r => setTimeout(r, 500));
    }
}

// 导出函数
module.exports = { callTool, createClient };