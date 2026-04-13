# 抖音视频上传完整流程

## 概述

本文档记录如何使用 MCP Chrome 工具在抖音创作者后台上传并发布视频。

## 关键发现

### 1. 上传视频的核心方法

使用 `chrome_upload_file` 工具可以直接上传视频文件，**不需要点击"上传视频"按钮**：

```javascript
// 选择器使用 input[type="file"]
{
  "selector": "input[type=\"file\"]",
  "filePath": "/path/to/video.mp4"
}
```

### 2. 上传后的等待时间

视频上传后需要等待约 **15 秒**让系统处理视频。等待时间过短会导致页面仍然是上传界面。

### 3. 页面跳转

视频处理完成后，页面会自动跳转到视频编辑页面：
- URL: `https://creator.douyin.com/creator-micro/content/post/video?enter_from=publish_page`
- 特征：出现标题输入框 `input[placeholder*="标题"]`

## 完整操作流程

### 步骤 1: 导航到上传页面

```javascript
await callTool('chrome_navigate', {
  url: 'https://creator.douyin.com/creator-micro/content/upload'
});
```

### 步骤 2: 上传视频文件

```javascript
await callTool('chrome_upload_file', {
  selector: 'input[type="file"]',
  filePath: '/Users/azm/Downloads/工具介绍_软字幕版.mp4'
});
```

**注意**: 
- 选择器必须是 `input[type="file"]`
- 文件路径可以是绝对路径
- 支持的视频格式: mp4, webm, mov, avi, wmv, flv, mkv 等

### 步骤 3: 等待视频处理

```javascript
await new Promise(r => setTimeout(r, 15000)); // 等待15秒
```

### 步骤 4: 检查页面状态

处理完成后，页面会出现标题输入框。检查页面是否有可交互元素：

```javascript
const page = await callTool('chrome_read_page', { filter: 'interactive' });
// 如果出现 ref_19 (textbox 标题输入框)，说明上传成功
```

### 步骤 5: 填写标题

```javascript
await callTool('chrome_fill_or_select', {
  ref: 'ref_19',  // 标题输入框
  value: '测试视频上传 - 工具介绍'
});
```

### 步骤 6: 滚动到底部找到发布按钮

```javascript
// 找到发布按钮 (通常是页面右侧的按钮)
await callTool('chrome_computer', {
  action: 'scroll_to',
  ref: 'ref_24'  // 发布按钮的 ref
});
```

### 步骤 7: 点击发布按钮

```javascript
await callTool('chrome_click_element', {
  ref: 'ref_24',  // 发布按钮
  waitForNavigation: true
});
```

## 关键选择器参考

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 文件输入 | `input[type="file"]` | 上传视频文件 |
| 标题输入 | `input[placeholder*="标题"]` 或 `.semi-input` | 填写作品标题 |
| 上传按钮 | `.semi-button-primary` 或 `button.semi-button-primary` | 页面上的上传按钮 |
| 发布按钮 | ref_24 (动态) | 页面右侧的发布/确认按钮 |

## 重要注意事项

1. **不要使用固定的 ref**: ref 是动态的，每次页面加载后都会变化。必须使用 CSS 选择器。

2. **等待时间**: 视频上传后必须等待足够时间（约15秒），否则页面不会跳转到编辑页面。

3. **选择器优先**: 优先使用 CSS 选择器而非 ref，避免元素变化导致操作失败。

4. **文件路径**: 确保视频文件存在且路径正确。

## 常见问题

### Q: 上传后页面没有跳转怎么办?
A: 增加等待时间到 15-20 秒，然后重新检查页面元素。

### Q: 找不到发布按钮怎么办?
A: 使用 `chrome_computer` 的 `scroll_to` 滚动到页面底部，或使用 `screenshot` 查看页面布局。

### Q: "File chooser dialog can only be shown with a user activation" 警告
A: 这是正常的警告，`chrome_upload_file` 工具可以直接设置文件而不需要用户交互。

## 测试视频路径

```
/Users/azm/Downloads/工具介绍_软字幕版.mp4
/Users/azm/Downloads/xhs智能总结.mp4
```

## 相关文件

- SKILL.md: `/Users/azm/MyProject/auto-browser/video-upload/SKILL.md`
- 上传脚本: `/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh`
- MCP 工具: `/Users/azm/MyProject/auto-browser/video-upload/scripts/mcp-tools.js`


## 我的尝试过程

### 1. 第一次尝试 - 失败
- 使用 `chrome_upload_file` 上传文件
- 等待约 8 秒
- 页面没有变化，仍然是上传界面

### 2. 第二次尝试 - 失败  
- 点击"上传视频"按钮 (ref_15)
- 等待 10 秒
- 页面还是没有跳转

### 3. 第三次尝试 - 成功
- 再次使用 `chrome_upload_file` 上传同一个视频
- 等待了 **15 秒**
- 这次页面成功跳转到编辑页面，出现了标题输入框

## 成功的关键原因

回头看，其实方法一直是对的：**使用 `chrome_upload_file` 工具，选择器 `input[type="file"]"`**

但之前失败的原因是 **等待时间不够**。抖音的视频处理需要时间，我之前只等了 8 秒，但实际上需要 **15 秒左右**。

## 关键发现

1. **`chrome_upload_file` 工具可以直接上传** - 不需要点击"上传视频"按钮
2. **等待时间很关键** - 至少等待 15 秒让视频处理完成
3. **页面会自动跳转** - 处理完成后会自动跳转到编辑页面，无需手动操作
4. **直接用 MCP 工具** - 直接用 MCP 工具是成功的。问题是脚本里启动了 stdio 服务器，跟已有的 Chrome 扩展服务冲突。