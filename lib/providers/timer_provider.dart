import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_provider.dart';       // 引入音乐控制器
import 'sleep_player_provider.dart'; // 引入助眠控制器

// 倒计时剩余秒数 (null 代表没开启)
final timerDurationProvider = StateProvider<int?>((ref) => null);

class TimerController {
  final Ref ref;
  Timer? _timer;

  TimerController(this.ref);

  // 开启定时 (单位：分钟)
  void startTimer(int minutes) {
    stopTimer(); // 先取消旧的
    
    // 设置初始秒数
    ref.read(timerDurationProvider.notifier).state = minutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = ref.read(timerDurationProvider);
      
      if (current == null || current <= 0) {
        // 【时间到】执行关闭逻辑
        stopTimer();
        
        // 1. 暂停本地音乐播放器 (歌单歌曲)
        // 即使没有在播放音乐，调用 pause 也是安全的
        ref.read(audioControllerProvider).pause(); 
        
        // 2. 停止助眠白噪音/场景
        // 即使没有在播放助眠，调用 stopAll 也是安全的
        ref.read(sleepPlayerProvider.notifier).stopAll();
        
      } else {
        // 倒计时 -1
        ref.read(timerDurationProvider.notifier).state = current - 1;
      }
    });
  }

  // 取消定时
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    ref.read(timerDurationProvider.notifier).state = null;
  }
}

final timerControllerProvider = Provider<TimerController>((ref) => TimerController(ref));