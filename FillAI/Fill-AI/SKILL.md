---
name: fill-user-info
description: 在网页上自动填写个人信息（姓名、邮箱、手机等）
trigger: 填写个人信息、填写表单、个人信息、fill info、fill form
---

# 自动填写个人信息

在网页上自动填写个人信息。

## 执行流程

1. **读取个人信息** - 从 `references/userinfo.md` 读取用户信息
2. **读取页面** - 使用 `chrome_read_page` 获取页面表单元素
3. **识别字段** - 根据输入框的 placeholder、label、name 等属性匹配字段
4. **填写信息** - 使用 `chrome_fill_or_select` 填写各字段

## 个人信息

从 `references/userinfo.md` 读取：

| 字段 | 键名 | 说明 |
|------|------|------|
| 姓名 | name, 姓名, 姓名 | 用户姓名 |
| 邮箱 | email, 邮箱, 邮箱 | 邮箱地址 |
| 手机 | phone, 手机, 电话, mobile | 手机号码 |

## 字段匹配规则

### 常用选择器

| 字段 | 选择器 |
|------|--------|
| 姓名 | `input[placeholder*="姓名"]`, `input[name*="name"]`, `input[id*="name"]` |
| 邮箱 | `input[placeholder*="邮箱"]`, `input[name*="email"]`, `input[type="email"]` |
| 手机 | `input[placeholder*="手机"]`, `input[name*="phone"]`, `input[type="tel"]` |

### 通用匹配逻辑

1. 先尝试 placeholder 匹配：`input[placeholder*="关键字"]`
2. 再尝试 name 属性匹配：`input[name*="关键字"]`
3. 最后尝试 id 属性匹配：`input[id*="关键字"]`

## 关键选择器

| 操作 | 选择器 |
|------|--------|
| 读取页面 | `chrome_read_page` |
| 填写输入框 | `input[type="text"]`, `input[type="email"]`, `input[type="tel"]` |
| 选择下拉框 | `select` |

## 前置条件

1. mcp-chrome 扩展已连接（端口 12306）
2. 已打开目标网页

## 使用方式

当用户说"在xxx页面填写个人信息"时：

1. 导航到目标页面
2. 读取 `references/userinfo.md` 获取个人信息
3. 读取页面表单元素
4. 匹配并填写各字段

## 个人信息文件位置

```
/Users/azm/MyProject/auto-browser/FillAI/Fill-AI/references/userinfo.md
```

内容格式：
```
姓名：xxx
邮箱：xxx
手机或电话：xxx
```

## 常见问题

**找不到输入框**：尝试多种选择器组合，或使用坐标点击

**填写失败**：确认页面元素可见，可能需要先滚动到元素位置
