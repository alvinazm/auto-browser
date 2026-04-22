# 平台选择器参考

本文档包含各平台的创作者后台 URL 和选择器配置，用于视频自动上传。

## 目录

- [抖音 (douyin)](#抖音-douyin)
- [小红书 (xiaohongshu)](#小红书-xiaohongshu)
- [快手 (kuaishou)](#快手-kuaishou)
- [百家号 (baijiahao)](#百家号-baijiahao)
- [B站 (bilibili)](#b站-bilibili)

---

## 抖音 (douyin)

### 创作者后台 URL

```
https://creator.douyin.com/creator-micro/content/upload
```

### 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 上传按钮 | `button.semi-button` | 点击触发文件选择 |
| 视频文件输入 | `input[type="file"]` | 直接上传视频 |
| 标题输入框 | `input[placeholder*="填写作品标题"]` | 视频标题 |
| 选择封面按钮 | `div.title-wA45Xd` | 封面选择按钮 |
| 封面上传输入 | `div.upload-BvM5FF input.semi-upload-hidden-input` | 封面文件输入 |
| 完成按钮 | `button.secondary-zU1YLr` | 确认封面 |

### 流程特点

1. 需要先点击"上传按钮"再选择文件
2. 支持封面选择（点击选择封面 → 上传 → 完成）
3. 有"填写作品标题"输入框

---

## 小红书 (xiaohongshu)

### 创作者后台 URL

```
https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video
```

### 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 视频文件输入 | `input[type="file"]` | 直接上传视频 |
| 视频文件输入 | `input[type="file"][accept*="video"]` | video 类型 |
| 视频文件输入 | `.upload-input` | class 选择器备用 |
| 标题输入框 | `input[placeholder*="标题"]` | 视频标题 |
| 描述输入框 | `textarea[placeholder*="描述"]` | 视频描述 |

### 流程特点

1. 直接上传视频文件
2. 标题和描述在同一区域
3. 需要滚动找到上传区域

---

## 快手 (kuaishou)

### 创作者后台 URL

```
https://cp.kuaishou.com/article/publish/video?tabType=1
```

### 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 视频文件输入 | `input[type="file"]` | 直接上传视频 |
| 视频文件输入 | `input[type="file"][accept*="video"]` | video 类型 |
| 视频文件输入 | `[class*="upload"]` | class 选择器备用 |
| 描述输入框 | `textarea[placeholder*="作品描述"]` | **快手无标题，用描述** |
| 描述输入框 | `textarea[placeholder*="智能文案"]` | 智能文案 |
| 描述输入框 | `textarea[class*="desc"]` | class 备用 |

### 流程特点

1. **没有标题输入框**，使用"作品描述"代替标题
2. 需要把标题内容填入描述框
3. 选择器较多，需要逐个尝试

---

## 百家号 (baijiahao)

### 创作者后台 URL

```
https://baijiahao.baidu.com/builder/rc/edit?type=videoV2&is_from_cms=1
```

### 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 视频文件输入 | `input[type="file"]` | 直接上传视频 |
| 视频文件输入 | `[class*="upload"]` | class 选择器 |
| 视频文件输入 | `[data-upload]` | data 属性 |
| 标题输入框 | `[data-placeholder*="添加标题"]` | 添加标题 |
| 标题输入框 | `input[placeholder*="标题"]` | 标题备用 |
| 标题输入框 | `input[class*="title"]` | class 备用 |
| 标题输入框 | `[class*="video-title"]` | video-title |

### 流程特点

1. 标题 placeholder 包含"添加标题"
2. 选择器较多，需要逐个尝试
3. 页面可能有 iframe

---

## B站 (bilibili)

### 创作者后台 URL

```
https://member.bilibili.com/platform/upload/video/frame
```

### 选择器

| 元素 | 选择器 | 说明 |
|------|--------|------|
| 视频文件输入 | `input[type="file"][accept*="video"]` | accept video |
| 视频文件输入 | `.upload-area` | 上传区域 |
| 视频文件输入 | `[class*="upload-area"]` | class 选择器 |
| 标题输入框 | `input[placeholder*="稿件标题"]` | 稿件标题 |
| 标题输入框 | `input.input-val` | input-val class |

### 流程特点

1. 使用"稿件标题"作为标题 placeholder
2. 上传区域可能有特殊 UI
3. 需要等待视频上传完成

---

## 通用 MCP 调用

### 导航

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_navigate",
    "arguments": {
      "url": "https://..."
    }
  }
}
```

### 点击元素

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_click_element",
    "arguments": {
      "selector": "button.semi-button",
      "selectorType": "css"
    }
  }
}
```

### 上传文件

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_upload_file",
    "arguments": {
      "selector": "input[type=\"file\"]",
      "filePath": "/path/to/video.mp4"
    }
  }
}
```

### 填写输入

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_fill_or_select",
    "arguments": {
      "selector": "input[placeholder*=\"标题\"]",
      "value": "视频标题"
    }
  }
}
```

### 滚动

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_computer",
    "arguments": {
      "action": "scroll",
      "scrollDirection": "down",
      "scrollAmount": 3
    }
  }
}
```

### 读取页面

```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "chrome_read_page",
    "arguments": {
      "filter": "interactive"
    }
  }
}
```

---

## 选择器优先级策略

1. **优先使用精确选择器**
   - `input[placeholder*="具体文字"]` > `input[type="file"]`

2. **使用多个备选选择器**
   - 在数组中按优先级排列
   - 逐个尝试直到成功

3. **动态选择器**
   - 包含 `*` 通配符匹配部分属性
   - 如 `[class*="upload"]` 可以匹配 `upload-area`、`upload-button` 等

4. **备用坐标点击**
   - 如果选择器都失败
   - 使用坐标点击作为最后手段