---
name: douyin-video-upload
description: 在抖音创作者后台上传视频、填写标题、上传封面
trigger: 抖音上传、视频发布、上传封面
---

# 抖音视频上传

在抖音创作者后台上传视频。

## 使用方式

```bash
# 仅上传视频和标题
/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh <视频路径> [标题]

# 上传视频、标题和封面
/Users/azm/MyProject/auto-browser/video-upload/scripts/upload.sh <视频路径> [标题] [封面路径]
```

## 参数说明

| 参数 | 说明 | 必填 |
|------|------|------|
| 视频路径 | 要上传的视频文件路径 | 是 |
| 标题 | 视频标题，默认"测试视频上传" | 否 |
| 封面路径 | 封面图片路径（可选） | 否 |

## 示例

```bash
# 上传视频
./upload.sh /Users/azm/Downloads/test.mov 我的视频标题

# 上传视频和封面
./upload.sh /Users/azm/Downloads/test.mov 我的视频标题 /Users/azm/Downloads/cover.png
```

## 前置条件

1. Chrome 浏览器已登录抖音创作者后台
2. mcp-chrome 扩展插件配置完成且已连接（端口 12306）

## 常见问题

**上传失败**：确认视频文件存在，路径正确

**封面没上传成功**：确认封面图片格式为 png/jpg/jpeg/bmp/webp/tif
