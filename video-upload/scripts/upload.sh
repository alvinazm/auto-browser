#!/bin/bash

# 视频上传统一入口脚本
# 支持多平台视频上传：抖音、小红书、快手、百家号、B站
# 用法: ./upload.sh <平台> <视频路径> [标题] [封面路径]
#       ./upload.sh all <视频路径> [标题] [封面路径]  # 同步到所有平台

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/human.sh"

is_platform_supported() {
    case "$1" in
        douyin|xiaohongshu|kuaishou|baijiahao|bilibili) return 0 ;;
        *) return 1 ;;
    esac
}

ALL_PLATFORMS="douyin xiaohongshu kuaishou baijiahao bilibili"

# ========== 使用说明 ==========
usage() {
    echo "视频上传脚本 - 多平台支持"
    echo ""
    echo "用法: $0 <平台> <视频路径> [标题] [封面路径]"
    echo ""
    echo "平台选项:"
    echo "  douyin       - 抖音"
    echo "  xiaohongshu - 小红书"
    echo "  kuaishou    - 快手"
    echo "  baijiahao   - 百家号"
    echo "  bilibili    - B站"
    echo "  all         - 同步到所有平台"
    echo ""
    echo "示例:"
    echo "  $0 douyin /path/video.mp4 \"我的标题\""
    echo "  $0 xiaohongshu /path/video.mp4 \"我的标题\""
    echo "  $0 douyin /path/video.mp4 \"我的标题\" /path/cover.jpg"
    echo "  $0 all /path/video.mp4 \"我的标题\""
    echo ""
    exit 1
}

# ========== 参数检查 ==========
if [ -z "$1" ]; then
    usage
fi

PLATFORM="$1"
VIDEO_PATH="$2"
TITLE="${3:-测试视频上传}"
COVER_PATH="$4"

# 同步到所有平台
if [ "$PLATFORM" = "all" ]; then
    if [ ! -f "$VIDEO_PATH" ]; then
        echo "错误: 视频文件不存在: $VIDEO_PATH"
        exit 1
    fi

    if [ -n "$COVER_PATH" ] && [ ! -f "$COVER_PATH" ]; then
        echo "错误: 封面文件不存在: $COVER_PATH"
        exit 1
    fi

    for PLATFORM in $ALL_PLATFORMS; do
        echo ""
        echo "############################################"
        echo "### 同步到: $PLATFORM"
        echo "############################################"

        PLATFORM_SCRIPT="$SCRIPT_DIR/platforms/${PLATFORM}.sh"
        if [ ! -f "$PLATFORM_SCRIPT" ]; then
            echo "警告: 平台脚本不存在: $PLATFORM_SCRIPT，跳过"
            continue
        fi

        source "$PLATFORM_SCRIPT"
        PLATFORM_UPLOAD_FUNC="upload_video_${PLATFORM}"

        if [ -n "$COVER_PATH" ] && [ "$PLATFORM" = "douyin" ]; then
            $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE" "$COVER_PATH"
        else
            $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE"
        fi

        # 每个平台之间等待，避免浏览器状态冲突
        sleep 2
    done

    echo ""
    echo "############################################"
    echo "### 全部平台同步完成"
    echo "############################################"
    exit 0
fi

# 单平台上传
if ! is_platform_supported "$PLATFORM"; then
    echo "错误: 不支持的平台 '$PLATFORM'"
    echo ""
    usage
fi

if [ ! -f "$VIDEO_PATH" ]; then
    echo "错误: 视频文件不存在: $VIDEO_PATH"
    exit 1
fi

if [ -n "$COVER_PATH" ] && [ ! -f "$COVER_PATH" ]; then
    echo "错误: 封面文件不存在: $COVER_PATH"
    exit 1
fi

echo "============================================"
echo "视频上传脚本 (多平台版)"
echo "平台: $PLATFORM"
echo "视频: $VIDEO_PATH"
echo "标题: $TITLE"
if [ -n "$COVER_PATH" ]; then
    echo "封面: $COVER_PATH"
fi
echo "============================================"

PLATFORM_SCRIPT="$SCRIPT_DIR/platforms/${PLATFORM}.sh"

if [ ! -f "$PLATFORM_SCRIPT" ]; then
    echo "错误: 平台脚本不存在: $PLATFORM_SCRIPT"
    exit 1
fi

source "$PLATFORM_SCRIPT"
PLATFORM_UPLOAD_FUNC="upload_video_${PLATFORM}"

if [ -n "$COVER_PATH" ]; then
    if [ "$PLATFORM" = "douyin" ]; then
        $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE" "$COVER_PATH"
    else
        echo "警告: 当前平台 $PLATFORM 不支持封面上传"
        $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE"
    fi
else
    $PLATFORM_UPLOAD_FUNC "$VIDEO_PATH" "$TITLE"
fi