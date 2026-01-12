# IFLOW.md - 项目上下文文档

## 项目概述

**项目名称**: 梦音岛 (my_music_player)

**项目类型**: Flutter 移动应用（Android/iOS/跨平台）

**项目描述**: 一款专注于助眠和音乐播放的移动应用，提供白噪音、本地音乐播放、播放列表管理、收藏夹、历史记录等功能。应用采用 Material Design 风格的深色主题，支持多种播放模式（顺序、单曲、随机）。

**技术栈**:
- **框架**: Flutter (Dart SDK >=3.0.0 <4.0.0)
- **状态管理**: flutter_riverpod ^2.5.1
- **音频播放**: just_audio ^0.9.36, just_audio_background ^0.0.1-beta.11
- **本地存储**: Hive ^2.2.3, hive_flutter ^1.1.0
- **权限管理**: permission_handler ^11.3.0
- **音频查询**: on_audio_query ^2.9.0
- **其他依赖**: cupertino_icons, scrollable_positioned_list, flutter_launcher_icons

**当前状态**: 
- 项目处于开发阶段，已实现核心播放功能
- 音频后台服务已被暂时禁用（使用纯前台模式）以避免死锁问题
- Git 仓库位于: https://github.com/bfyoy-zzl/flutter_sleep_music.git
- 当前分支有未提交的修改

## 项目结构

```
E:\my_music_player\
├── lib/                          # Dart 源代码目录
│   ├── main.dart                 # 应用入口，初始化 Hive 和提供者
│   ├── core/                     # 核心功能模块
│   │   ├── data/                 # 核心数据
│   │   ├── theme/                # 主题配置
│   │   └── utils/                # 工具类
│   ├── data/                     # 数据层
│   │   ├── models/               # 数据模型
│   │   └── services/             # 服务层
│   ├── providers/                # Riverpod 状态管理
│   │   ├── audio_provider.dart   # 音频播放核心逻辑
│   │   ├── favorite_provider.dart # 收藏功能
│   │   ├── history_provider.dart  # 播放历史
│   │   ├── playlist_provider.dart # 播放列表
│   │   ├── quote_provider.dart    # 引用语
│   │   ├── sleep_data_provider.dart # 助眠数据
│   │   ├── sleep_player_provider.dart # 助眠播放器
│   │   ├── tag_provider.dart      # 标签管理
│   │   └── timer_provider.dart    # 计时器
│   └── ui/                       # 用户界面
│       ├── main_shell.dart       # 主页面框架（底部导航栏）
│       ├── music/                # 音乐播放页面
│       ├── sleep/                # 助眠页面
│       ├── mine/                 # 我的页面
│       ├── search/               # 搜索页面
│       ├── settings/             # 设置页面
│       └── widgets/              # 通用组件
├── assets/                       # 资源文件
│   ├── audio/                    # 音频文件（白噪音等）
│   ├── icons/                    # 图标资源
│   ├── scene/                    # 场景图片和配置
│   └── icon.png                  # 应用图标
├── android/                      # Android 平台配置
│   ├── app/
│   │   ├── build.gradle.kts      # 应用级构建配置
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/           # Kotlin 源代码
│   │       └── res/              # Android 资源
│   └── build.gradle.kts          # 项目级构建配置
├── ios/                          # iOS 平台配置
├── web/                          # Web 平台配置
├── windows/                      # Windows 平台配置
├── linux/                        # Linux 平台配置
├── macos/                        # macOS 平台配置
├── build/                        # 构建输出目录
├── test/                         # 测试文件
├── pubspec.yaml                  # Flutter 项目配置
├── analysis_options.yaml         # Dart 分析配置
└── README.md                     # 项目说明文档
```

## 构建和运行

### 环境要求
- Flutter SDK (3.0.0 或更高版本)
- Dart SDK (>=3.0.0 <4.0.0)
- Android Studio / VS Code
- Android SDK (用于 Android 构建)
- Xcode (用于 iOS 构建，仅 macOS)

### 常用命令

**获取依赖**:
```bash
flutter pub get
```

**运行应用**:
```bash
# 在连接的设备上运行
flutter run

# 指定设备运行
flutter run -d <device_id>

# Release 模式运行
flutter run --release
```

**构建应用**:
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web
```

**测试**:
```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart
```

**代码分析**:
```bash
# 静态代码分析
flutter analyze

# 格式化代码
dart format .
```

**清理构建**:
```bash
flutter clean
```

**生成应用图标**:
```bash
flutter pub run flutter_launcher_icons
```

## 开发约定

### 代码风格
- 使用 Dart 官方代码风格指南
- 使用 `flutter analyze` 进行代码检查
- 使用 `dart format .` 格式化代码
- 遵循 Flutter 最佳实践

### 状态管理
- 使用 Riverpod 作为状态管理方案
- Provider 命名约定：`xxxProvider`（如 `audioPlayerProvider`）
- StateNotifier 命名约定：`XxxNotifier`（如 `CurrentPlaylistNotifier`）

### 文件组织
- Provider 文件放在 `lib/providers/` 目录
- UI 页面放在 `lib/ui/` 对应子目录
- 核心逻辑放在 `lib/core/` 目录
- 数据模型放在 `lib/data/models/` 目录

### 资源管理
- 音频文件放在 `assets/audio/`
- 图标放在 `assets/icons/`
- 场景图片放在 `assets/scene/`
- 所有资源必须在 `pubspec.yaml` 中声明

### 重要配置
- 应用包名: `com.example.my_music_player`
- 应用名称: 梦音岛
- 最低 SDK 版本: 21 (Android)
- 目标 SDK 版本: 由 Flutter 自动配置

### 已知问题和注意事项
1. **音频后台服务**: 当前已禁用 `just_audio_background` 以避免死锁问题，使用纯前台模式播放
2. **权限处理**: 应用需要存储权限和音频权限才能扫描和播放本地音乐
3. **Hive 存储**: 使用多个 Hive Box 存储不同类型的数据（settings, player_state, history, favorite, favorites, tags, tag_overrides）
4. **播放模式**: 支持顺序播放、单曲循环、随机播放三种模式
5. **音频源**: 支持本地音频文件和白噪音 URL

### Git 工作流
- 当前分支有未提交的修改
- 修改文件包括: AndroidManifest.xml, launcher_icon.png, main.dart, audio_provider.dart, favorite_provider.dart, main_shell.dart, music_player_page.dart
- 提交前应运行 `flutter analyze` 确保代码质量

### 平台特定配置
- **Android**: 使用 Kotlin，配置在 `android/` 目录
- **iOS**: 使用 Swift，配置在 `ios/` 目录
- **Web**: 配置在 `web/` 目录
- **桌面平台**: 支持Windows、Linux、macOS

## 核心功能模块

### 1. 音频播放 (audio_provider.dart)
- 使用 `just_audio` 实现音频播放
- 支持本地音乐和白噪音播放
- 实现播放列表管理
- 支持播放历史记录
- 支持播放模式切换（顺序、单曲、随机）
- 支持歌曲删除和隐藏
- 持久化播放状态

### 2. 用户界面 (ui/)
- **MainShell**: 主页面框架，包含底部导航栏
- **MusicPlayerPage**: 音乐播放页面
- **SleepPage**: 助眠页面
- **MinePage**: 我的页面
- 支持深色主题和毛玻璃效果

### 3. 数据持久化
- 使用 Hive 进行本地数据存储
- 存储播放状态、历史记录、收藏夹等
- 支持标签和标签覆盖功能

### 4. 权限管理
- 使用 `permission_handler` 管理应用权限
- 需要存储权限和音频权限

## 开发建议

1. **添加新功能**: 在 `lib/providers/` 中创建新的 Provider，在 `lib/ui/` 中创建对应的 UI 页面
2. **修改样式**: 在 `lib/core/theme/` 中修改主题配置
3. **添加资源**: 将文件放入 `assets/` 对应目录，并在 `pubspec.yaml` 中声明
4. **调试**: 使用 `print()` 输出日志，或使用 Flutter DevTools 进行调试
5. **性能优化**: 使用 `const` 构造函数，避免不必要的重建

## 联系和支持

- 项目仓库: https://github.com/bfyoy-zzl/flutter_sleep_music.git
- Flutter 官方文档: https://docs.flutter.dev/
- Riverpod 文档: https://riverpod.dev/
- just_audio 文档: https://pub.dev/packages/just_audio