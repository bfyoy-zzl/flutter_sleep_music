import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 定义修改模型 (保持不变)
class TagOverride {
  final String? title;
  final String? artist;
  final bool isHidden;

  TagOverride({
    this.title, 
    this.artist, 
    this.isHidden = false
  });

  factory TagOverride.fromMap(Map<dynamic, dynamic> map) {
    return TagOverride(
      title: map['title'],
      artist: map['artist'],
      isHidden: map['is_hidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      'is_hidden': isHidden,
    };
  }
}

class TagNotifier extends StateNotifier<Map<int, TagOverride>> {
  // 盒子名称常量，防止写错
  static const String boxName = 'tag_overrides';

  TagNotifier() : super({});

  // 初始化方法 - 从 Hive 加载数据
  Future<void> init() async {
    try {
      // 确保盒子已打开
      if (!Hive.isBoxOpen(boxName)) {
        await Hive.openBox(boxName);
      }
      
      final box = Hive.box(boxName);
      final Map<int, TagOverride> loadedData = {};
      
      // 从 Hive 加载所有标签数据
      for (var key in box.keys) {
        if (key is int) {
          final value = box.get(key);
          if (value is Map) {
            loadedData[key] = TagOverride.fromMap(value);
          }
        }
      }
      
      // 更新状态
      state = loadedData;
      print("✅ 标签数据已加载，共 ${loadedData.length} 条记录");
    } catch (e) {
      print("❌ 标签数据加载失败: $e");
      state = {};
    }
  }

  Future<void> updateTag(int songId, String newTitle, String newArtist) async {
    final current = state[songId];
    final newOverride = TagOverride(
      title: newTitle, 
      artist: newArtist,
      isHidden: current?.isHidden ?? false,
    );
    state = {...state, songId: newOverride};
    
    // 保存到本地
    final box = Hive.box(boxName);
    await box.put(songId, newOverride.toMap());
  }

  Future<void> hideSong(int songId) async {
    final current = state[songId];
    final newOverride = TagOverride(
      title: current?.title,
      artist: current?.artist,
      isHidden: true, 
    );
    state = {...state, songId: newOverride};
    
    final box = Hive.box(boxName);
    await box.put(songId, newOverride.toMap());
  }

  Future<void> restoreSong(int songId) async {
    final current = state[songId];
    if (current == null) return;

    final newOverride = TagOverride(
      title: current.title,
      artist: current.artist,
      isHidden: false, // 改回 false
    );

    state = {...state, songId: newOverride};
    final box = Hive.box(boxName);
    await box.put(songId, newOverride.toMap());
  }

  // 全部还原
  Future<void> restoreAll() async {
    final box = Hive.box(boxName);
    final Map<int, TagOverride> newState = {...state};

    // 遍历所有记录，找到隐藏的，全部设为不隐藏
    for (var entry in state.entries) {
      if (entry.value.isHidden) {
        final newOverride = TagOverride(
          title: entry.value.title,
          artist: entry.value.artist,
          isHidden: false,
        );
        newState[entry.key] = newOverride;
        await box.put(entry.key, newOverride.toMap());
      }
    }
    state = newState;
  }
}

final tagProvider = StateNotifierProvider<TagNotifier, Map<int, TagOverride>>((ref) {
  final notifier = TagNotifier();
  // 创建时立即初始化
  notifier.init();
  return notifier;
});