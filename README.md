<div align="center">

<img src="assets/images/ic_logo.png" width="96" height="96" alt="TubeSavely Logo"/>

# TubeSavely

**全平台极速视频下载与音画处理工具 — 支持 YouTube、TikTok、抖音、B站、Instagram 等 1800+ 平台**

[English](./README.en.md) | 简体中文

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-brightgreen)](https://github.com/Cosymentx/TubeSavely)
[![License](https://img.shields.io/github/license/Cosymentx/TubeSavely)](LICENSE)
[![Stars](https://img.shields.io/github/stars/Cosymentx/TubeSavely?style=social)](https://github.com/Cosymentx/TubeSavely)

</div>

---

## 🌐 TubeSavely 系列项目生态

TubeSavely 是一套完整的跨平台音视频解析与下载解决方案，由三个独立且深度联动的核心项目协同构成：

| 项目 / 客户端 | 技术栈 | 职责与定位 | 仓库地址 | 在线体验 / 交付物 |
| :--- | :--- | :--- | :--- | :--- |
| **TubeSavely** (当前仓库) | Flutter 3 + Dart | iOS / Android / Windows / macOS / Linux 客户端，提供原生交互与桌面端视频转换/压缩 | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely-02569B?logo=flutter)](https://github.com/Cosymentx/TubeSavely) | [Releases 下载](https://github.com/Cosymentx/TubeSavely/releases) |
| **TubeSavely-Vue** | Vue 3 + TypeScript + Vite | 现代化响应式 Web 端，无须安装即开即用，支持在线解析、格式筛选与下载 | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely--Vue-4FC08D?logo=vuedotjs)](https://github.com/Cosymentx/TubeSavely-Vue) | [访问 Web 演示站](https://tube-savely-vue.vercel.app) |
| **TubeSavely-Server** | Python 3 + FastAPI + yt-dlp | 核心音视频解析引擎、任务队列、多平台提取、支付积分与下载分发 API | [![GitHub](https://img.shields.io/badge/GitHub-TubeSavely--Server-3776AB?logo=python)](https://github.com/Cosymentx/TubeSavely-Server) | [Swagger API 文档](https://tube-savely-server.vercel.app/docs) |

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

### 🖥️ 跨平台无缝支持
- **桌面端**：Windows、macOS、Linux — 原生桌面交互与现代化胶囊风格布局
- **移动端**：iOS、Android
- **网页端**：通过 [TubeSavely-Vue](https://github.com/Cosymentx/TubeSavely-Vue) 直接在浏览器中使用

### 🔒 安全合规，尊重版权
严格遵守各平台使用条款，所有下载合法合规；不保存、不传输任何用户个人隐私数据。

---

## 📸 客户端截图

### macOS 桌面端
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-182915%402x.png)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183008%402x.png)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183054%402x.png)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/macos/WX20240625-183128%402x.png)

### iOS 移动端
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0154.PNG)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0155.PNG)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0156.PNG)
![](https://github.com/Cosyment/TubeSavely/blob/master/screenshots/%E8%8B%B9%E6%9E%9C%E5%BA%94%E7%94%A8%E5%95%86%E5%BA%97-5.5%E5%AF%B8-1242X2208/IMG_0157.PNG)

---

## 🚀 快速开始

### 🛠️ 环境要求
- Flutter SDK 3.24+ (`flutter doctor` 检查环境)
- macOS 构建需 Xcode 15+
- Windows 构建需 Visual Studio 2022+ (安装 C++ 桌面开发工作负载)

### 💻 本地运行
```bash
# 1. 克隆仓库
git clone https://github.com/Cosymentx/TubeSavely.git
cd TubeSavely

# 2. 安装 Flutter 依赖
flutter pub get

# 3. 本地调试运行
flutter run -d macos     # macOS 桌面端
flutter run -d windows   # Windows 桌面端
flutter run -d ios       # iOS 模拟器/真机
flutter run -d android   # Android 模拟器/真机
```

### 📦 产物打包
```bash
flutter build apk --release        # Android Release APK
flutter build macos --release      # macOS 产物 (配合 build-dmg.sh 打包 DMG)
flutter build windows --release    # Windows Release 绿色包
```

---

## 📄 开源协议

Copyright © 2023-2026 TubeSavely. All rights reserved.
