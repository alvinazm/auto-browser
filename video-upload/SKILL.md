---
name: douyin-stdio-upload
description: 使用 MCP Chrome stdio 模式在抖音创作者后台上传并发布视频
trigger: 抖音上传、视频发布、stdio抖音上传
---

# 抖音视频上传 (stdio 模式)

使用 MCP Chrome stdio 模式在抖音创作者后台上传并发布视频。

## 触发条件

当用户请求"上传抖音视频"、"发布视频"、"stdio抖音上传"时触发。

## 执行流程

1. **打开上传页面** - 导航到抖音创作者上传页面
2. **直接上传视频** - 使用选择器 `input[type="file"]` 直接上传，无需点击上传按钮
3. **等待处理** - 视频上传后需要等待处理 (约8秒)
4. **填写标题** - 使用 CSS 选择器定位标题输入框
5. **滚动到底部** - 滚动到页面底部显示发布按钮
6. **点击发布** - 使用 CSS 选择器点击发布按钮

## 关键选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 上传视频 | `.semi-button-primary` 或 `button.semi-button-primary` | 发布视频按钮 |
| 标题输入框 | `input[placeholder*="标题"]` 或 `.semi-input` | 填写作品标题 |


**重要**: 不要使用固定的 ref（如 ref_15），ref 是动态的，每次页面加载后会变化。必须使用 CSS 选择器。

## 前置条件

1. **Chrome 浏览器已登录抖音账号** - 打开 creator.douyin.com 确认已登录
2. **stdio 服务器可用** - 路径：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js`
3. **端口 12306 未被占用** - 每次调用前需要清理

## 使用方式

```bash
/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh <视频路径> [标题]
```

## 核心要点

1. **直接上传文件** - `chrome_upload_file` 可以直接通过选择器上传，不需要先点击"上传视频"按钮
2. **使用 CSS 选择器** - 所有元素操作使用选择器而非固定 ref
3. **每次调用前清理端口** - 避免 "Already connected" 错误：
   ```bash
   lsof -i :12306 | grep LISTEN | awk '{print $2}' | xargs kill -9
   sleep 2
   ```
4. **sleep 等待** - 视频上传后需要等待处理

## 常见问题

### "Already connected to a transport"

原因：MCP 服务被其他连接占用
解决：清理 12306 端口再重试

### "Failed to connect: ECONNREFUSED"

原因：端口 12306 未启动
解决：先在 Chrome 中激活扩展，然后重试

### 填写标题失败

解决：使用 CSS 选择器而非 ref
- `input[placeholder*="标题"]`
- `.semi-input`

### 点击发布按钮失败

解决：尝试多个选择器
- `.semi-button-primary:not(.semi-button-light)`
- `button.semi-button-primary`

## 相关文件

- 脚本文件：`scripts/upload.sh`
- 项目目录：`/Users/azm/MyProject/auto-browser/video-upload/`
- stdio 服务器：`/Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js`