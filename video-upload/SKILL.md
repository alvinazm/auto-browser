---
name: video-upload
description: 在多平台创作者后台上传视频（抖音、小红书、快手、百家号、B站），包含人类行为模拟
trigger: 视频上传、多平台上传、上传视频、douyin、xiaohongshu、kuaishou、baijiahao、bilibili
related_skills:
  - mcp-chrome-stdio-automation
---

# 视频上传

在多平台创作者后台上传视频，支持人类行为模拟防止被识别为机器操作。

## 支持的平台

| 平台 | 标识 | 创作者后台 | 支持封面 |
|------|-----|-----------|---------|
| 抖音 | douyin | creator.douyin.com | ✅ |
| 小红书 | xiaohongshu | creator.xiaohongshu.com | ❌ |
| 快手 | kuaishou | cp.kuaishou.com | ❌ |
| 百家号 | baijiahao | baijiahao.baidu.com | ❌ |
| B站 | bilibili | member.bilibili.com | ❌ |

## 使用方式

```bash
# 进入脚本目录
cd /Users/azm/MyProject/auto-browser/video-upload/scripts

# 上传视频 (平台 视频路径 标题)
./upload.sh douyin /path/to/video.mp4 "视频标题"
./upload.sh xiaohongshu /path/to/video.mp4 "视频标题"
./upload.sh kuaishou /path/to/video.mp4 "视频标题"
./upload.sh baijiahao /path/to/video.mp4 "视频标题"
./upload.sh bilibili /path/to/video.mp4 "视频标题"

# 仅抖音支持封面上传
./upload.sh douyin /path/to/video.mp4 "视频标题" /path/to/cover.jpg
```

## 参数说明

| 参数 | 说明 | 必填 | 默认值 |
|------|------|------|--------|
| 平台 | 目标平台标识 | 是 | - |
| 视频路径 | 视频文件路径 | 是 | - |
| 标题 | 视频标题 | 否 | "测试视频上传" |
| 封面路径 | 封面图片路径（仅抖音支持）| 否 | - |

## 执行流程（通用）

1. 清理端口，初始化 MCP
2. 导航到平台创作者后台
3. 模拟人类阅读页面（500-1200ms）
4. 滚动查找上传区域
5. 上传视频文件
6. 等待视频处理（8-10秒）
7. 滚动页面（模拟人类行为）
8. 检查页面状态，填写标题/描述

## 平台特定说明

### 抖音 (douyin)

- 需要先点击"上传按钮"再选择文件
- 支持封面选择
- 标题输入框: `input[placeholder*="填写作品标题"]`

### 小红书 (xiaohongshu)

- 直接上传视频文件
- 标题和描述使用相同输入框

### 快手 (kuaishou)

- **无标题输入框**，使用"作品描述"代替
- 需要把标题内容填入描述框

### 百家号 (baijiahao)

- 标题 placeholder 包含"添加标题"
- 页面可能有 iframe

### B站 (bilibili)

- 使用"稿件标题"作为标题 placeholder
- 上传区域有特殊 UI

详细选择器见 [references/platform-selectors.md](references/platform-selectors.md)

## 人类行为模拟

脚本使用 `human.sh` 库提供人类行为模拟：

- `human_random_delay`: 随机延迟 300-700ms
- `human_read_page_delay`: 页面阅读延迟 500-1200ms
- `human_reaction_delay`: 反应时间 300-800ms
- `human_scroll_wait`: 滚动后等待 300-500ms
- `human_scroll_down`: 向下滚动并等待
- `human_scroll_up`: 向上滚动并等待

每个关键操作前后都有随机延迟和滚动，模拟真实用户行为。

## 项目结构

```
video-upload/
├── SKILL.md              # 主技能文档
├── REFERENCES.md         # 选择器参考 (已移至 references/)
├── PROPOSAL.md           # 设计提案 (已移至 doc/)
├── doc/                  # 设计文档
│   └── PROPOSAL.md
├── references/           # 参考资料
│   └── platform-selectors.md
└── scripts/
    ├── human.sh         # 人类行为模拟函数库
    ├── upload.sh       # 统一入口脚本
    ├── utils.sh        # 公共工具函数
    └── platforms/
        ├── douyin.sh         # 抖音
        ├── xiaohongshu.sh   # 小红书
        ├── kuaishou.sh      # 快手
        ├── baijiahao.sh    # 百家号
        └── bilibili.sh      # B站
```

## 前置条件

1. **Chrome 扩展连接（必须！）** - stdio 模式需要 MCP Chrome 扩展先连接
   - 在 Chrome 工具栏点击 MCP Chrome 扩展图标
   - 点击连接按钮，状态显示 "connected"
   - 如果扩展未连接，所有 MCP 调用都会失败！

2. **Chrome 浏览器已登录目标平台创作者后台**

3. **MCP 服务器路径正确**：
   ```
   /Users/azm/Library/pnpm/global/5/node_modules/mcp-chrome-bridge/dist/mcp/mcp-server-stdio.js
   ```

> 相关技能: [mcp-chrome-stdio-automation](../mcp/mcp-chrome-stdio-automation/SKILL.md)

## 常见问题

**MCP 连接失败**：先确认 MCP Chrome 扩展已连接（扩展 popup 显示 connected），然后检查端口 12306

**端口被占用**：
```bash
lsof -i :12306 | grep -v PID | awk '{print $2}' | xargs kill -9
```

**上传失败**：确认视频文件存在，路径正确

**选择器失效**：平台可能更新了页面结构，请参考 references/platform-selectors.md 或 xhs-comments-reply2 项目