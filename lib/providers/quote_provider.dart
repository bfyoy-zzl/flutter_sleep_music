import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

// 默认语录
const List<String> _defaultQuotes = [
    "愿你好梦，不仅今晚。",
    "让音乐治愈你的疲惫。",
    "晚安，世界和你。",
    "星河滚烫，你是人间理想。",
    "专注此刻，享受宁静。",
    "闭上眼，世界是你的.",
    "梦里花开，醒来依旧。",
    "夜色温柔，音乐相伴。",
    "让旋律带你远航。",
    "在音乐中找到自我。",
];

class QuoteNotifier extends StateNotifier<List<String>> {
  QuoteNotifier() : super(_defaultQuotes);

  Future<void> init() async {
    final box = await Hive.openBox('settings');
    final List<dynamic>? saved = box.get('custom_quotes');
    if (saved != null && saved.isNotEmpty) {
      state = List<String>.from(saved);
    } else {
      state = _defaultQuotes;
    }
  }

  Future<void> addQuote(String quote) async {
    if (quote.trim().isEmpty) return;
    state = [...state, quote];
    await _save();
  }

  // 【新增】更新指定位置的语录
  Future<void> updateQuote(int index, String newQuote) async {
    if (index >= 0 && index < state.length && newQuote.trim().isNotEmpty) {
      final newState = [...state];
      newState[index] = newQuote;
      state = newState;
      await _save();
    }
  }

  Future<void> removeQuote(int index) async {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState.removeAt(index);
      // 如果删光了，恢复默认，防止界面出错
      if (newState.isEmpty) {
        state = _defaultQuotes;
      } else {
        state = newState;
      }
      await _save();
    }
  }

  Future<void> _save() async {
    final box = await Hive.openBox('settings');
    await box.put('custom_quotes', state);
  }

  // 随机获取一条
  String getRandomQuote() {
    if (state.isEmpty) return "Good Night";
    return state[Random().nextInt(state.length)];
  }
}

final quoteProvider = StateNotifierProvider<QuoteNotifier, List<String>>((ref) {
  final notifier = QuoteNotifier();
  notifier.init();
  return notifier;
});