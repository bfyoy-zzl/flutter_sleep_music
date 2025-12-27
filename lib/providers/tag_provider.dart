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
  TagNotifier() : super({});

  Future<void> init() async {
    final box = await Hive.openBox('tag_overrides');
    final Map<int, TagOverride> loaded = {};
    for (var key in box.keys) {
      final val = box.get(key);
      if (val is Map) {
        loaded[key as int] = TagOverride.fromMap(val);
      }
    }
    state = loaded;
  }

  Future<void> updateTag(int songId, String newTitle, String newArtist) async {
    final current = state[songId];
    final newOverride = TagOverride(
      title: newTitle, 
      artist: newArtist,
      isHidden: current?.isHidden ?? false,
    );
    state = {...state, songId: newOverride};
    final box = await Hive.openBox('tag_overrides');
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
    final box = await Hive.openBox('tag_overrides');
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
    final box = await Hive.openBox('tag_overrides');
    await box.put(songId, newOverride.toMap());
  }

  // 【新增】全部还原
  Future<void> restoreAll() async {
    final box = await Hive.openBox('tag_overrides');
    final Map<int, TagOverride> newState = {...state}; // 复制一份当前状态

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
  notifier.init();
  return notifier;
});