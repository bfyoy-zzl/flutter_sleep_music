import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteNotifier extends StateNotifier<List<int>> {
  // 构造函数：初始化时状态为空，并立即触发异步加载
  FavoriteNotifier() : super([]) {
    _init();
  }

  // 盒子名称常量
  static const String _boxName = 'favorites';

  // 【核心修复】异步初始化方法
  Future<void> _init() async {
    Box box;
    try {
      // 1. 安全检查：如果盒子没开，就现在打开它
      if (!Hive.isBoxOpen(_boxName)) {
        box = await Hive.openBox(_boxName);
      } else {
        box = Hive.box(_boxName);
      }

      // 2. 加载数据
      final List<dynamic> ids = box.get('ids', defaultValue: []);
      if (mounted) {
        state = ids.cast<int>();
      }
    } catch (e) {
      print("❌ FavoriteNotifier 初始化失败: $e");
      // 发生错误时保持空列表，防止红屏
      state = [];
    }
  }

  // 获取盒子（辅助方法，确保安全）
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  // 2. 切换收藏状态
  Future<void> toggleFavorite(int songId) async {
    final box = await _getBox(); // 等待获取盒子
    
    if (state.contains(songId)) {
      state = [
        for (final id in state)
          if (id != songId) id
      ];
    } else {
      state = [songId, ...state];
    }
    // 保存到数据库
    await box.put('ids', state);
  }

  // 3. 检查某首歌是否被收藏
  // 注意：UI层调用这个方法是同步的，基于当前 state 判断，非常快且安全
  bool isFavorite(int songId) {
    return state.contains(songId);
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<int>>((ref) {
  return FavoriteNotifier();
});