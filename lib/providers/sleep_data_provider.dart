import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/data/models/sleep_models.dart';

class SleepDataState {
  final List<SceneMeta> scenes;
  final List<WhiteNoiseItem> lineItems; // 底噪选项
  final List<WhiteNoiseItem> dotItems; // 点缀音选项

  SleepDataState({
    this.scenes = const [],
    this.lineItems = const [],
    this.dotItems = const [],
  });
}

class SleepDataNotifier extends StateNotifier<SleepDataState> {
  SleepDataNotifier() : super(SleepDataState());

  Future<void> loadAllData() async {
    try {
      // 1. 加载场景元数据
      final sceneJsonStr = await rootBundle.loadString('assets/scene/prebuilt_scene_config.json');
      final List sceneList = json.decode(sceneJsonStr);
      final scenes = sceneList.map((e) => SceneMeta.fromJson(e)).toList();

      // 2. 加载自选底噪配置
      final lineJsonStr = await rootBundle.loadString('assets/icons/prebuilt_icon_config.json');
      final List lineList = json.decode(lineJsonStr);
      final lineItems = lineList.map((e) => WhiteNoiseItem.fromJson(e, 1)).toList();

      // 3. 加载自选点缀配置
      final dotJsonStr = await rootBundle.loadString('assets/icons/prebuilt_dot_icon_config.json');
      final List dotList = json.decode(dotJsonStr);
      final dotItems = dotList.map((e) => WhiteNoiseItem.fromJson(e, 2)).toList();

      state = SleepDataState(
        scenes: scenes,
        lineItems: lineItems,
        dotItems: dotItems,
      );
    } catch (e) {
      print("Error loading sleep data: $e");
    }
  }

  // 加载特定场景的详细配置
  Future<List<SceneAudioConfig>> loadSceneDetail(String sceneTitle) async {
    try {
      // 假设文件名就是 title.json，例如 "夏雨.json"
      final path = 'assets/scene/$sceneTitle.json';
      final jsonStr = await rootBundle.loadString(path);
      final List list = json.decode(jsonStr);
      return list.map((e) => SceneAudioConfig.fromJson(e)).toList();
    } catch (e) {
      print("Error loading scene detail for $sceneTitle: $e");
      return [];
    }
  }
}

final sleepDataProvider = StateNotifierProvider<SleepDataNotifier, SleepDataState>((ref) {
  final notifier = SleepDataNotifier();
  notifier.loadAllData(); // 初始化时自动加载
  return notifier;
});