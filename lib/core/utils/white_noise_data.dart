
import 'package:flutter/material.dart';

class WhiteNoiseModel {
  final String name;
  final IconData icon;
  final String url; // 音频链接 (可以是 asset:// 或 https://)
  final Color color;

  WhiteNoiseModel(this.name, this.icon, this.url, this.color);
}

class WhiteNoiseData {
  static final List<WhiteNoiseModel> sounds = [
    WhiteNoiseModel("细雨", Icons.water_drop, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.blueAccent), // 临时测试链接
    WhiteNoiseModel("雷声", Icons.thunderstorm, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.deepPurple),
    WhiteNoiseModel("海浪", Icons.waves, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.cyan),
    WhiteNoiseModel("篝火", Icons.local_fire_department, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.orange),
    WhiteNoiseModel("森林", Icons.forest, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.green),
    WhiteNoiseModel("夜虫", Icons.nightlife, "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", Colors.indigo),
  ];
}