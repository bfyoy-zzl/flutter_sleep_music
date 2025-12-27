// lib/core/utils/mood_quotes.dart
import 'dart:math';

class MoodQuotes {
  static final List<String> _quotes = [
    "愿你有个好梦，晚安。",
    "静静享受此刻的宁静。",
    "星光不问赶路人，时光不负有心人。",
    "累了就歇歇，明天又是新的一天。",
    "保持热爱，奔赴山海。",
    "万物皆有裂痕，那是光照进来的地方。",
    "心若向阳，无畏悲伤。",
    "生活原本沉闷，但跑起来就有风。",
  ];

  static String getRandomQuote() {
    return _quotes[Random().nextInt(_quotes.length)];
  }
}