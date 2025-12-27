import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 定义一个 StateNotifier 来管理收藏列表
// 它维护的状态是一个 List<int>，里面存的是歌曲的 ID
class FavoriteNotifier extends StateNotifier<List<int>> {
  FavoriteNotifier() : super([]) {
    _loadFavorites();
  }

  // 获取数据库盒子
  Box get _box => Hive.box('favorites');

  // 1. 加载所有收藏
  void _loadFavorites() {
    // 从 Hive 读取数据，如果没有数据就返回空列表
    final List<dynamic> ids = _box.get('ids', defaultValue: []);
    // 转换成 int 列表并更新状态
    state = ids.cast<int>();
  }

  // 2. 切换收藏状态 (喜欢 <-> 不喜欢)
  void toggleFavorite(int songId) {
    if (state.contains(songId)) {
      // 如果已经在列表里，就移除
      state = [
        for (final id in state)
          if (id != songId) id
      ];
    } else {
      // 【修改点】把新 ID 放在数组的最前面 (index 0)
      state = [songId, ...state];
    }
    // 保存到数据库
    _box.put('ids', state);
  }

  // 3. 检查某首歌是否被收藏
  bool isFavorite(int songId) {
    return state.contains(songId);
  }
}

// 暴露 Provider 给 UI 使用
final favoriteProvider = StateNotifierProvider<FavoriteNotifier, List<int>>((ref) {
  return FavoriteNotifier();
});