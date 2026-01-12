import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audio_provider.dart';
import '../../core/theme/app_theme.dart';


class CommonProgressBar extends ConsumerWidget {
  const CommonProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);

    // 使用 StreamBuilder 监听播放进度
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = player.duration ?? Duration.zero;

        // 这里我们不用普通的 Slider，推荐使用一个非常棒的第三方库 audio_video_progress_bar
        // 或者我们暂时用 Slider 实现基础功能，如下：
        
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                activeColor: AppTheme.accentPurple,
                inactiveColor: Colors.white10,
                min: 0,
                max: total.inMilliseconds.toDouble(),
                value: position.inMilliseconds.toDouble().clamp(0, total.inMilliseconds.toDouble()),
                onChanged: (value) {
                  // 拖动时跳转
                  player.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
            // 显示时间文字
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text(_formatDuration(total), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 时间格式化工具 (03:45)
  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}