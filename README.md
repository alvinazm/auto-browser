# TODO
- 笔试做题
- 帮你填表


改完成之后先用通用入口调用抖音看看能否执行成功，确保video-upload/scripts/utils.sh 你修改的是对的;确保douyin没问题了,再测试kuaishou       
谁调用了video-upload/scripts/utils.sh

## 已完成
- fill-userinfo 是一个独立的skill，校招简历自动填写
- video-upload自动发布抖音视频，<视频路径> [标题] [封面路径]
- 独立运行：cd /Users/azm/MyProject/auto-browser/video-upload/scripts && ./platforms/douyin.sh /Users/azm/Downloads/test.mp4 "单独运行测试" /Users/azm/Downloads/封面1.png
- 通用入口运行： cd /Users/azm/MyProject/auto-browser/video-upload/scripts && ./upload.sh douyin /Users/azm/Downloads/test.mp4 "使用通用入口测试测试" /Users/azm/Downloads/封面1.png
- ./video-upload/scripts/upload.sh kuaishou /Users/azm/Downloads/test.mp4 "使用通用入口测试测试"

一个给 AI 使用的标准 skill 主要包含：

| 部分 | 内容 | 必填 |
|------|------|------|
| **name** | 技能名称 | ✅ |
| **description** | 简短描述（1-2句话） | ✅ |
| **trigger** | 触发关键词 | ✅ |
| **执行流程** | 按顺序的步骤列表 | ✅ |
| **关键选择器** | CSS 选择器表格 | 推荐 |
| **前置条件** | 执行前需要满足的条件 | ✅ |
| **参数说明** | 输入参数的说明 | 如果有参数 |
| **使用示例** | 命令示例 | 推荐 |
| **常见问题** | 错误和解决 | 推荐 |

**不需要包含**：
- 技术实现细节（函数、变量等）
- 调试日志
- 过多解释性文字

**当前 SKILL.md 的问题**：缺少触发关键词（trigger），建议改成：

```yaml
---
name: douyin-video-upload
description: 在抖音创作者后台上传视频、填写标题、上传封面
trigger: 抖音上传、视频发布、上传封面、douyin
---

# 抖音视频上传
...
```


标准的 skill 目录结构：

```
skill-name/
├── SKILL.md              # 必需：AI 使用的标准 skill（唯一入口）
├── README.md             # 可选：简要说明（人类可读）
├── scripts/              # 可选：脚本文件
│   └── upload.sh
├── templates/             # 可选：模板文件
│   └── config.yaml
├── references/            # 可选：参考资料（AI 可能用到）
│   └── api.md
└── assets/                # 可选：静态资源
    └── icon.png
```

**核心原则**：
- **SKILL.md 是唯一入口** - AI 只读这个文件
- **其他目录是可选的** - 根据需要添加
- **不要放技术调试文档** - 那不是 skill 的一部分



找到问题了！对比 upload.sh 和 SKILL.md：
**关键区别**：
- upload.sh: **每次调用都启动新进程 + 杀进程**，**不需要初始化**
- SKILL.md: 先初始化，然后在同一个 session 调用多个工具

**正确方案**：每次调用前都杀掉进程、启动新进程，不需要初始化。