# 视频上传功能扩展方案

## 一、现状分析

### 1.1 当前项目结构

```
/Users/azm/MyProject/auto-browser/video-upload/
├── SKILL.md               # 抖音上传技能文档
└── scripts/
    ├── human.sh         # 人类行为模拟函数库
    └── upload.sh        # 抖音上传脚本
```

### 1.2 当前功能

- 仅支持抖音平台
- 支持视频上传 + 标题填写 + 封面上传
- 使用 mcp-chrome stdio 模式

---

## 二、目标：支持多平台视频上传

### 2.1 需要支持的平台

| 平台 | 创作者后台 URL | 当前状态 |
|------|---------------|----------|
| 抖音 | `https://creator.douyin.com/creator-micro/content/upload` | ✅ 已实现 |
| 小红书 | `https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video` | ❌ 待实现 |
| 快手 | `https://cp.kuaishou.com/article/publish/video?tabType=1` | ❌ 待实现 |
| 百家号 | `https://baijiahao.baidu.com/builder/rc/edit?type=videoV2&is_from_cms=1` | ❌ 待实现 |
| B站 | `https://member.bilibili.com/platform/upload/video/frame` | ❌ 待实现 |

---

## 三、目录结构方案

### 3.1 方案 A：按平台分离（推荐）

```
video-upload/
├── SKILL.md                    # 主技能文档（多平台入口）
├── REFERENCES.md               # 各平台选择器参考（从 xhs-comments-reply2 迁移）
├── scripts/
│   ├── human.sh               # 人类行为模拟函数库
│   ├── upload.sh             # 统一入口脚本（自动识别平台）
│   ├── utils.sh              # 公共工具函数
│   └── platforms/
│       ├── douyin.sh         # 抖音上传（已有，迁移）
│       ├── xiaohongshu.sh    # 小红书上传
│       ├── kuaishou.sh       # 快手上传
│       ├── baijiahao.sh      # 百家号上传
│       └── bilibili.sh       # B站上传
└── templates/
    └── cover-default.jpg      # 默认封面模板
```

### 3.2 方案 B：按功能分离

```
video-upload/
├── SKILL.md
├── REFERENCES.md
├── scripts/
│   ├── human.sh
│   ├── common.sh             # 公共上传逻辑
│   ├── upload-douyin.sh     # 各平台脚本
│   ├── upload-xiaohongshu.sh
│   ├── upload-kuaishou.sh
│   ├── upload-baijiahao.sh
│   └── upload-bilibili.sh
├── configs/
│   └── selectors.json      # 各平台选择器配置
└── templates/
    └── cover-default.jpg
```

### 3.3 方案对比

| 维度 | 方案 A | 方案 B |
|------|--------|--------|
| 结构清晰度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| 复用性 | 高 | 中 |
| 维护成本 | 低 | 中 |
| 新增平台 | 只需加 platform/*.sh | 需加脚本文件 |
| 学习成本 | 中 | 低 |

---

## 四、推荐采用方案 A

### 4.1 详细目录结构

```
video-upload/
├── SKILL.md                    # 主技能文档
│                                # - 包含所有平台的使用说明
│                                # - 通用参数说明
│                                # - 平台特定说明引用
├── REFERENCES.md               # 选择器参考（迁移自 xhs-comments-reply2）
│                                # - 各平台 URL
│                                # - 各平台选择器列表
│                                # - 平台特定行为说明
├── scripts/
│   ├── human.sh               # 人类行为模拟（保持不变）
│   ├── upload.sh              # 统一入口
│   │                          # 用法: ./upload.sh <平台> <视频> [标题]
│   ��                          # 示例: ./upload.sh xiaohongshu /path/video.mp4 "标题"
│   ├── utils.sh              # 公共函数
│   │   ├── get_platform_url()     # 获取平台 URL
│   │   ├── get_file_selectors()  # 获取文件选择器
│   │   ├── get_title_selectors() # 获取标题选择器
│   │   └── wait_video_processing() # 等待视频处理
│   └── platforms/
│       ├── douyin.sh         # 抖音
│       ├── xiaohongshu.sh    # 小红书
│       ├── kuaishou.sh    # 快手
│       ├── baijiahao.sh  # 百家号
│       └── bilibili.sh   # B站
└── templates/
    └── cover-default.jpg  # 默认封面
```

---

## 五、文件命名方案

### 5.1 脚本文件命名规范

| 文件 | 命名 | 说明 |
|------|------|------|
| 公共工具 | `utils.sh` | 平台无关的工具函数 |
| 人类行为 | `human.sh` | 保持不变 |
| 统一入口 | `upload.sh` | 自动路由到 platforms/*.sh |
| 平台脚本 | `platforms/douyin.sh` | 每个平台独立脚本 |

### 5.2 平台脚本内部命名

```bash
#!/bin/bash

# 平台标识
PLATFORM="douyin"
PLATFORM_NAME="抖音"
PLATFORM_URL="https://creator.douyin.com/creator-micro/content/upload"

# 文件选择器（优先顺序）
FILE_SELECTORS=(
    'input[type="file"][accept*="video"]'
    ".upload-input"
    "[data-e2e='upload-input']"
)

# 标题选择器
TITLE_SELECTORS=(
    'input[placeholder*="标题"]'
    "[data-e2e='title-input']"
)

# 描述选择器（部分平台用）
DESCRIPTION_SELECTORS=(
    'textarea[placeholder*="描述"]'
)
```

---

## 六、SKILL.md 文档结构方案

### 6.1 主文档 (SKILL.md)

```markdown
---
name: video-upload
description: 在多平台创作者后台上传视频（抖音、小红书、快手、百家号、B站）
trigger: 视频上传、多平台上传、上传视频
---

# 视频上传

在多平台创作者后台上传视频，支持人类行为模拟。

## 使用方式

# 通用
upload.sh <平台> <视频路径> [标题]

# 示例
./upload.sh douyin /path/video.mp4 "我的标题"
./upload.sh xiaohongshu /path/video.mp4 "我的标题"
./upload.sh kuaishou /path/video.mp4 "我的标题"
./upload.sh baijiahao /path/video.mp4 "我的标题"
./upload.sh bilibili /path/video.mp4 "我的标题"

## 支持的平台

| 平台 | 命令 | URL |
|------|------|-----|
| 抖音 | douyin | creator.douyin.com |
| 小红书 | xiaohongshu | creator.xiaohongshu.com |
| 快手 | kuaishou | cp.kuaishou.com |
| 百家号 | baijiahao | baijiahao.baidu.com |
| B站 | bilibili | member.bilibili.com |

## 参数说明

| 参数 | 说明 | 必填 |
|------|------|------|
| 平台 | 平台标识 | 是 |
| 视频路径 | 视频文件路径 | 是 |
| 标题 | 视频标题 | 否 |

## 人类行为模拟

见 REFERENCES.md

## 平台特定说明

各平台详细选择器见 REFERENCES.md
```

### 6.2 选择器参考 (REFERENCES.md)

```markdown
# 平台选择器参考

## 抖音 (douyin)

### URL
https://creator.douyin.com/creator-micro/content/upload

### 选择器

| 元素 | 选择器 |
|------|--------|
| 上传按钮 | `button.semi-button` |
| 文件输入 | `input[type="file"]` |
| 标题 | `input[placeholder*="填写作品标题"]` |

## 小红书 (xiaohongshu)

### URL
https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video

### 选择器

| 元素 | 选择器 |
|------|--------|
| 文件输入 | `input[type="file"]` |
| 标题 | `input[placeholder*="标题"]` |

... 其他平台 ...
```

---

## 七、实施步骤

### 7.1 阶段一：迁移抖音现有实现

1. 创建 `platforms/` ���录
2. 将 `upload.sh` 重构为 `platforms/douyin.sh`
3. 创建新的 `upload.sh` 统一入口

### 7.2 阶段二：添加小红书

1. 创建 `platforms/xiaohongshu.sh`
2. 迁移选择器配置
3. 测试上传流程

### 7.3 阶段三：添加其他平台

1. 快手 → `platforms/kuaishou.sh`
2. 百家号 → `platforms/baijiahao.sh`
3. B站 → `platforms/bilibili.sh`

### 7.4 阶段四：文档整理

1. 更新 SKILL.md
2. 创建 REFERENCES.md

---

## 八、选择器配置（从 xhs-comments-reply2 迁移）

### 8.1 小红书

```bash
PLATFORM="xiaohongshu"
PLATFORM_URL="https://creator.xiaohongshu.com/publish/publish?source=official&from=menu&target=video"
FILE_SELECTORS=(
    'input[type="file"]'
    'input[type="file"][accept*="video"]'
    ".upload-input"
    "#upload-input"
)
TITLE_SELECTORS=(
    'input[placeholder*="标题"]'
    'input[placeholder*="title"]'
    'textarea[placeholder*="标题"]'
)
```

### 8.2 快手

```bash
PLATFORM="kuaishou"
PLATFORM_URL="https://cp.kuaishou.com/article/publish/video?tabType=1"
FILE_SELECTORS=(
    'input[type="file"]'
    'input[type="file"][accept*="video"]'
    ".upload-input"
    "#upload-input"
    "[class*='upload']"
)
TITLE_SELECTORS=()  # 快手无标题，用描述
DESCRIPTION_SELECTORS=(
    'textarea[placeholder*="作品描述"]'
    'textarea[placeholder*="智能文案"]'
    'textarea[placeholder*="描述"]'
    'textarea[class*="desc"]'
)
```

### 8.3 百家号

```bash
PLATFORM="baijiahao"
PLATFORM_URL="https://baijiahao.baidu.com/builder/rc/edit?type=videoV2&is_from_cms=1"
FILE_SELECTORS=(
    'input[type="file"]'
    'input[type="file"][accept*="video"]'
    ".upload-input"
    "[class*='upload']"
    "[data-upload]"
)
TITLE_SELECTORS=(
    '[data-placeholder*="添加标题"]'
    'input[placeholder*="标题"]'
    'input[class*="title"]'
)
```

### 8.4 B站

```bash
PLATFORM="bilibili"
PLATFORM_URL="https://member.bilibili.com/platform/upload/video/frame"
FILE_SELECTORS=(
    'input[type="file"][accept*="video"]'
    ".upload-area"
    '[class*="upload-area"]'
)
TITLE_SELECTORS=(
    'input[placeholder*="稿件标题"]'
    "input.input-val"
)
```

---

## 九、下一步

请确认采用哪个方案：

- **方案 A（推荐）**: `platforms/` 子目录分离
- **方案 B**: 独立脚本文件 + configs/

确认后我开始实施。