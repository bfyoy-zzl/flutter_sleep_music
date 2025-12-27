import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../core/data/models/sleep_models.dart';
// 【核心修改】引入音频控制器，以便暂停本地音乐
import 'audio_provider.dart';

// 助眠播放状态 (true=播放中, false=暂停或停止)
final sleepIsPlayingProvider = StateProvider<bool>((ref) => false);

// 记录当前正在播放的场景名称 (用于判断点击卡片是切换还是暂停)
final currentSceneNameProvider = StateProvider<String?>((ref) => null);

// 单个音频轨道的控制器
class AudioTrack {
  final AudioPlayer player = AudioPlayer();
  final String assetPath;
  final bool isLoop;
  Timer? _timer;
  final List<String> _randomFiles;
  final Random _rng = Random();

  AudioTrack(this.assetPath, {this.isLoop = true, List<String> randomFiles = const []}) 
      : _randomFiles = randomFiles;

  Future<void> init() async {
    if (isLoop) {
      await player.setAsset(assetPath);
      await player.setLoopMode(LoopMode.one);
      player.play();
    }
  }

  void startRandomPlay(int frequencySeconds) {
    if (isLoop || _randomFiles.isEmpty) return;
    _scheduleNext(frequencySeconds);
  }

  void _scheduleNext(int frequencySeconds) {
    int safeFreq = frequencySeconds > 0 ? frequencySeconds : 10;
    final delay = (safeFreq * 0.5 + _rng.nextDouble() * safeFreq).toInt();
    _timer = Timer(Duration(seconds: delay), () async {
      if (!player.playing) { 
        final file = _randomFiles[_rng.nextInt(_randomFiles.length)];
        try {
          await player.setAsset('assets/audio/$file.mp3'); 
          await player.play();
        } catch(e) { print("Error playing point audio: $e"); }
      }
      _scheduleNext(safeFreq);
    });
  }

  void setVolume(double v) {
    player.setVolume(v);
  }

  void dispose() {
    _timer?.cancel();
    player.dispose();
  }
}

class SleepPlayerNotifier extends StateNotifier<List<AudioTrack>> {
  final Ref ref;

  SleepPlayerNotifier(this.ref) : super([]);

  void stopAll() {
    for (var track in state) {
      track.dispose();
    }
    state = [];
    ref.read(sleepIsPlayingProvider.notifier).state = false;
    ref.read(currentSceneNameProvider.notifier).state = null; 
  }

  void pauseAll() {
    for (var track in state) {
      track.player.pause();
    }
    ref.read(sleepIsPlayingProvider.notifier).state = false;
  }

  void resumeAll() {
    // 【核心修改】恢复助眠播放时，也要确保本地音乐是暂停的
    ref.read(audioControllerProvider).pause();

    for (var track in state) {
      if (track.isLoop) {
        track.player.play();
      }
    }
    ref.read(sleepIsPlayingProvider.notifier).state = true;
  }

  // 播放场景
  Future<void> playScene(String sceneTitle, List<SceneAudioConfig> configs) async {
    // 【核心修改】开始播放助眠前，强制暂停本地音乐
    ref.read(audioControllerProvider).pause();

    stopAll(); 

    final List<AudioTrack> newTracks = [];
    for (var cfg in configs) {
      if (cfg.isLineAudio && cfg.audioName.isNotEmpty) {
        final track = AudioTrack('assets/audio/${cfg.audioName}.mp3', isLoop: true);
        await track.init();
        track.setVolume(cfg.volume);
        newTracks.add(track);
      } else if (cfg.isPointAudio && cfg.names.isNotEmpty) {
        final track = AudioTrack('', isLoop: false, randomFiles: cfg.names);
        int interval = cfg.frequency > 0 ? (60 ~/ cfg.frequency) : 10;
        track.startRandomPlay(interval);
        track.setVolume(cfg.volume);
        newTracks.add(track);
      }
    }
    state = newTracks;
    ref.read(sleepIsPlayingProvider.notifier).state = true;
    ref.read(currentSceneNameProvider.notifier).state = sceneTitle; 
  }

  // 播放自选组合
  Future<void> playCustom(List<WhiteNoiseItem> items) async {
    // 【核心修改】开始播放助眠前，强制暂停本地音乐
    ref.read(audioControllerProvider).pause();

    stopAll();
    final List<AudioTrack> newTracks = [];

    for (var item in items) {
      if (item.type == 1) { // 底噪
        if (item.audioUrls.isNotEmpty) {
           final url = item.audioUrls.first.url;
           final track = AudioTrack('assets/audio/$url.mp3', isLoop: true);
           await track.init();
           track.setVolume(item.volume);
           newTracks.add(track);
        }
      } else { // 点缀
         final files = item.audioUrls.map((e) => e.url).toList();
         final track = AudioTrack('', isLoop: false, randomFiles: files);
         int interval = item.frequency > 0 ? (60 ~/ item.frequency) : 10;
         track.startRandomPlay(interval); 
         track.setVolume(item.volume);
         newTracks.add(track);
      }
    }
    state = newTracks;
    ref.read(sleepIsPlayingProvider.notifier).state = true;
    ref.read(currentSceneNameProvider.notifier).state = "CUSTOM"; 
  }
}

final sleepPlayerProvider = StateNotifierProvider<SleepPlayerNotifier, List<AudioTrack>>((ref) {
  return SleepPlayerNotifier(ref);
});