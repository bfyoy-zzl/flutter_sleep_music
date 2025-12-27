import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 定义一个简单的 Notifier，状态就是 ID 列表
class HistoryNotifier extends StateNotifier<List<dynamic>> {
  HistoryNotifier() : super([]);

  // 初始化：从 Hive 读取数据
  Future<void> init() async {
    final box = await Hive.openBox('history');
    // 读取名为 'played_ids' 的列表，如果没有则为空
    final List<dynamic> stored = box.get('played_ids', defaultValue: []);
    state = stored;
  }

  // 记录播放：允许重复添加，以便统计“听得最多”
  Future<void> recordPlay(dynamic songId) async {
    final box = await Hive.openBox('history');
    
    // 1. 获取当前列表
    // 注意：我们不要去重 (Do NOT remove duplicates)，直接追加
    // 这样 MinePage 里的 playCounts 才能统计出频次
    final currentList = [...state];
    
    // 2. 追加到末尾 (MinePage 会倒序遍历来显示"最近播放")
    currentList.add(songId);

    // 3. 限制最大数量 (例如只保留最近1000次播放)，防止数据无限膨胀
    if (currentList.length > 1000) {
      currentList.removeAt(0); // 移除最早的一条
    }

    // 4. 更新状态和数据库
    state = currentList;
    await box.put('played_ids', currentList);
  }
  
  // 提供一个清空历史的方法（可选）
  Future<void> clearHistory() async {
    final box = await Hive.openBox('history');
    await box.delete('played_ids');
    state = [];
  }
}

// 这里的 Provider 返回一个 List<dynamic>，与 MinePage 的逻辑完美兼容
final historyProvider = StateNotifierProvider<HistoryNotifier, List<dynamic>>((ref) {
  final notifier = HistoryNotifier();
  notifier.init(); // 创建时自动初始化数据
  return notifier;
});