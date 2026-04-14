# 抖音视频上传完整指南

## 核心经验总结

经过多次尝试和失败，最终成功上传视频。以下是关键发现和注意事项：

---

## 一、关键成功要素

### 1. 使用 MCP 客户端的正确方式

**错误做法**：每个环节创建新的客户端连接
```javascript
// ❌ 错误 - 会导致 "Already connected to a transport" 错误
await createClient(); // 环节3
await createClient(); // 环节4 - 失败！
```

**正确做法**：整个流程只使用一个客户端连接
```javascript
// ✅ 正确 - 单进程单连接
const client = new Client({ name: 'Mcp Chrome Proxy', ... });
const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
await client.connect(transport);

// 所有操作使用同一个 client
await client.callTool({ name: 'chrome_navigate', ... });
await client.callTool({ name: 'chrome_upload_file', ... });
await client.callTool({ name: 'chrome_read_page', ... });

// 最后关闭
await client.close();
```

### 2. 等待时间很关键

| 环节 | 等待时间 | 原因 |
|------|----------|------|
| 导航后 | 5 秒 | 等待页面完全加载 |
| 上传后 | **8 秒** | 等待视频处理完成（关键！） |

**教训**：之前只等 5 秒导致失败，需要 8 秒才能让视频处理完成并跳转到编辑页面。

### 3. 不要启动 MCP 服务

**错误做法**：尝试在脚本中启动 MCP 服务
```bash
# ❌ 错误
node mcp-server-stdio.js &
```

**正确做法**：MCP 服务应该已经由 Chrome 扩展启动
```bash
# ✅ 正确 - 检查服务是否已运行
if lsof -i :12306 | grep -q LISTEN; then
    echo "MCP 服务已在运行"
else
    echo "请先在 Chrome 中激活 mcp-chrome 扩展"
fi
```

---

## 二、完整上传流程

### 步骤 1: 确认前置条件

1. **Chrome 浏览器已登录抖音账号** - 打开 creator.douyin.com 确认
2. **MCP 服务已运行** - 检查端口 12306：
   ```bash
   lsof -i :12306 | grep LISTEN
   ```
3. **视频文件存在** - 检查文件路径

### 步骤 2: 执行上传脚本

```bash
cd /Users/azm/MyProject/auto-browser
./video-upload/scripts/upload.sh /path/to/video.mp4 "视频标题"
```

### 步骤 3: 流程说明

```
环节 1: 检查 MCP 服务 (端口 12306)
       ↓
环节 2: 导航到上传页面 (等待 5 秒)
       ↓
环节 3: 上传视频文件 (选择器: input[type="file"])
       ↓
环节 4: 等待视频处理 (等待 8 秒) ← 关键！
       ↓
环节 5: 检查页面状态 (是否出现标题输入框)
       ↓
环节 6: 填写标题 (可选)
```

---

## 三、关键代码片段

### MCP 客户端初始化

```javascript
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StreamableHTTPClientTransport } = require('@modelcontextprotocol/sdk/client/streamableHttp.js');

// 设置模块路径
process.env.NODE_PATH = '/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules:' + process.env.NODE_PATH;
require('module')._initPaths();

// 加载配置
const config = JSON.parse(fs.readFileSync('/path/to/stdio-config.json', 'utf8'));

// 创建客户端（只创建一次）
const client = new Client({ name: 'Mcp Chrome Proxy', version: '1.0.0' }, { capabilities: {} });
const transport = new StreamableHTTPClientTransport(new URL(config.url), {});
await client.connect(transport);
```

### 上传视频

```javascript
const uploadResult = await client.callTool({ 
    name: 'chrome_upload_file', 
    arguments: { 
        selector: 'input[type="file"]',  // 必须使用这个选择器
        filePath: '/path/to/video.mp4'
    }
}, undefined, { timeout: 180000 });
```

### 检查上传结果

```javascript
// 上传后等待 8 秒
await new Promise(r => setTimeout(r, 8000));

// 检查页面是否出现标题输入框
const pageResult = await client.callTool({ 
    name: 'chrome_read_page', 
    arguments: { filter: 'interactive' }
}, undefined, { timeout: 30000 });

const content = JSON.stringify(pageResult.content);
if (content.includes('textbox') && content.includes('标题')) {
    console.log('✓ 上传成功');
}
```

---

## 四、常见错误及解决

### 错误 1: "Already connected to a transport"

**原因**：多次创建客户端连接

**解决**：整个流程只使用一个客户端连接

### 错误 2: "视频文件不存在"

**原因**：文件路径错误或文件不存在

**解决**：
```bash
# 检查文件是否存在
ls -la /path/to/video.mp4
```

### 错误 3: "MCP 服务未运行"

**原因**：MCP 服务未启动

**解决**：
1. 打开 Chrome 扩展管理页面
2. 找到 mcp-chrome 扩展
3. 点击连接，确保显示"服务运行中 (端口: 12306)"

### 错误 4: 上传后页面没有跳转

**原因**：等待时间不够

**解决**：上传后等待至少 8 秒

---

## 五、相关文件路径

| 文件 | 路径 |
|------|------|
| 上传脚本 | `/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh` |
| stdio 配置 | `/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/stdio-config.json` |
| MCP SDK | `/Users/azm/Library/pnpm/global/5/.pnpm/@modelcontextprotocol+sdk@1.29.0_zod@3.25.76/node_modules/` |

---

## 六、重要提示

1. **不要多次创建客户端** - 这是导致 "Already connected" 错误的根本原因
2. **等待时间要足够** - 特别是上传后的 15 秒等待
3. **MCP 服务由扩展管理** - 不需要在脚本中启动
4. **使用正确的选择器** - `input[type="file"]` 是上传视频的关键选择器

---

## 七、stdio 模式脚本（当前成功方案）

### 为什么这次成功了？

2024年4月14日更新的脚本采用了**纯 bash + stdio 模式**，与之前的 node.js MCP SDK 方案不同。成功原因如下：

#### 1. 每次 MCP 调用都是独立的进程

```bash
# 每次调用都启动新的 node 进程
mcp_call() {
    RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
}
```

每次调用都会：
1. 清理端口残留进程
2. 启动新的 node 进程
3. 发送 JSON-RPC 请求
4. 获取响应后进程退出

#### 2. 端口清理机制

```bash
cleanup() {
    lsof -i :12306 2>/dev/null | grep -v PID | awk '{print $2}' | head -1 | xargs kill -9 2>/dev/null
    sleep 2
}
```

每次调用前都清理端口，确保没有残留进程占用端口。

#### 3. 重试机制

```bash
while [ $retry -lt $max_retries ]; do
    if [ $retry -gt 0 ]; then
        cleanup
    fi
    RESULT=$(echo "$JSON" | node "$STDIO_SERVER" 2>&1)
    
    if echo "$RESULT" | grep -q 'ECONNREFUSED\|Failed to connect'; then
        retry=$((retry + 1))
        continue
    fi
    return 0
done
```

如果遇到连接错误，会自动重试（最多5次）。

#### 4. 完整的流程设计

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | cleanup | 清理残留进程 |
| 2 | initialize | 初始化 MCP 连接 |
| 3 | navigate | 打开上传页面 |
| 4 | sleep 5 | 等待页面加载 |
| 5 | click_element | 点击"上传视频"按钮 |
| 6 | sleep 2 | 等待文件对话框 |
| 7 | upload_file | 上传视频文件 |
| 8 | sleep 8 | 等待视频处理（关键！） |
| 9 | read_page | 检查页面状态 |
| 10 | fill_or_select | 填写标题（可选） |

#### 5. 与之前失败方案的区别

| 对比项 | 之前的 node.js 方案 | 现在的 stdio 方案 |
|--------|---------------------|-------------------|
| 连接方式 | HTTP 客户端 (StreamableHTTPClientTransport) | 标准输入输出 (stdio) |
| 进程模型 | 单进程内多个 HTTP 请求 | 每次调用独立进程 |
| 端口占用 | 需要端口持续监听 | 每次启动后释放 |
| 错误恢复 | 容易出现 "Already connected" | 每次重试都是全新进程 |
| 连续运行 | 第二次会失败 | 可以连续成功 |

### stdio 模式的核心优势

1. **无状态**：每次调用都是独立的，不存在状态残留
2. **自动清理**：进程退出后自动释放资源
3. **简单可靠**：不需要管理长连接
4. **易于调试**：每次调用都可以单独测试

### 当前脚本路径

```bash
/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh
```

### 使用方法

```bash
cd /Users/azm/MyProject/auto-browser
./video-upload/scripts/upload.sh /path/to/video.mp4 "视频标题"
```