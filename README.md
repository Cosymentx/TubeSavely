<div align="center">

<img src="assets/images/ic_logo.png" width="96" height="96" alt="TubeSavely Logo"/>

# TubeSavely

**全平台视频下载工具 — 支持 YouTube、TikTok、抖音、B站、Instagram 等 1800+ 平台**

[English](./README.en.md) | 简体中文

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/github/license/Cosymentx/TubeSavely)](LICENSE)
[![Stars](https://img.shields.io/github/stars/Cosymentx/TubeSavely?style=social)](https://github.com/Cosymentx/TubeSavely)

</div>

---

## 🌐 TubeSavely 生态系项目

TubeSavely 是一套跨平台的视频下载工具，由以下三个项目共同构成完整生态：

| 项目 | 技术栈 | 说明 | 链接 |
|------|--------|------|------|
| **TubeSavely** | Flutter | 跨平台桌面 & 移动端客户端（Windows / macOS / Linux / iOS / Android） | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely-181717?logo=github)](https://github.com/Cosymentx/TubeSavely) |
| **TubeSavely-Vue** | Vue 3 | 网页端 Web 客户端，支持浏览器直接访问和下载 | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely--Vue-181717?logo=github)](https://github.com/Cosymentx/TubeSavely-Vue) |
| **TubeSavely-Server** | Python | 后端 API 服务，提供视频解析、用户、积分和支付接口 | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely--Server-181717?logo=github)](https://github.com/Cosymentx/TubeSavely-Server) |

[访问 Web 客户端](https://tube-savely-vue.vercel.app) · [查看 API 文档](https://tube-savely-server.vercel.app/docs)

---

## ✨ 功能亮点

### 🌍 海量平台支持，一网打尽
支持国内外超过 **1800 个主流及小众视频平台**，覆盖 YouTube、Instagram、TikTok、抖音、Bilibili、Vimeo 等热门站点，无论你钟情于哪个角落的精彩，一键下载，轻松收藏。

### 🎬 高清画质，随心选择
提供从标清到超高清的多种分辨率选项，满足不同场景的观看需求，每一帧都清晰流畅。

### ⚡ 高速下载，省时省心
采用先进的多线程下载技术，即使面对超大体积的视频文件也能迅速完成。告别漫长等待，享受即下即看的畅快体验。

### 🎞 视频转换 & 压缩
内置 FFmpeg 引擎，支持视频格式转换（MP4 / MKV / MOV / AVI / WEBM / MP3 等）以及多档预设视频压缩，桌面端全原生 UI，丝滑体验。

### 🖥️ 跨平台支持
- **桌面端**：Windows、macOS、Linux — 原生桌面布局，完全适配系统风格
- **移动端**：iOS、Android
- **网页端**：通过 [TubeSavely-Vue](https://github.com/Cosymentx/TubeSavely-Vue) 直接在浏览器中使用

### 🔒 安全合规，尊重版权
严格遵守各平台使用条款，所有下载合法合规；不保存、不传输任何用户个人数据。

---

## 📸 截图

### macOS

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-182915%402x.png)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183008%402x.png)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183054%402x.png)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183128%402x.png)

### iOS

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0154.PNG)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0155.PNG)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0156.PNG)

![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0157.PNG)

---

## 🚀 快速开始

### 环境要求
- Flutter 3.x (`flutter doctor` 检查环境)
- macOS 构建需要 Xcode 14+

### 本地运行
```bash
# 克隆仓库
git clone https://github.com/Cosymentx/TubeSavely.git
cd TubeSavely

# 获取依赖
flutter pub get

# 运行（macOS）
flutter run -d macos

# 运行（iOS）
flutter run -d ios

# 运行（Android）
flutter run -d android
```

---

## 🔗 相关项目

- 🌐 **Web 版**：[TubeSavely-Vue](https://github.com/Cosymentx/TubeSavely-Vue) — Vue 3 网页端
- 🐍 **后端服务**：[TubeSavely-Server](https://github.com/Cosymentx/TubeSavely-Server) — Python 解析服务

---

## 📄 License

Copyright © 2023 TubeSavely. All rights reserved.
