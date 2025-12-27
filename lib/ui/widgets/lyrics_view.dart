import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  bool _userScrolling = false;
  int _prevIndex = -1; 
  Duration _lastPosition = Duration.zero; // 【新增】用于检测进度突变(Seek)

  @override
  Widget build(BuildContext context) {
    final lyricsAsync = ref.watch(currentLyricsProvider);

    return lyricsAsync.when(
      loading: () => const Center(child: Text("加载歌词...", style: TextStyle(color: Colors.white54))),
      error: (err, stack) => const Center(child: Text("暂无歌词", style: TextStyle(color: Colors.white54))),
      data: (lyrics) {
        if (lyrics.isEmpty) {
          return const Center(child: Text("暂无歌词", style: TextStyle(color: Colors.white54)));
        }

        return StreamBuilder<Duration>(
          stream: ref.read(audioPlayerProvider).positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            
            // 【核心修复1】检测进度是否发生了突变（用户点击了进度条）
            // 如果突变超过 500毫秒，说明是 Seek 操作，强制取消用户的滚动锁定
            if ((position - _lastPosition).abs() > const Duration(milliseconds: 500)) {
              _userScrolling = false; 
            }
            _lastPosition = position;

            int currentIndex = 0;
            // 计算当前行
            for (int i = 0; i < lyrics.length; i++) {
              final line = lyrics[i];
              final time = _parseTime(line);
              if (time != null && position >= time) {
                currentIndex = i;
              } else if (time != null && position < time) {
                break;
              }
            }

            // 触发滚动
            if (currentIndex != _prevIndex) {
              _prevIndex = currentIndex;
              
              if (!_userScrolling && _itemScrollController.isAttached) {
                _itemScrollController.scrollTo(
                  index: currentIndex,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                  alignment: 0.45,
                );
              }
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _userScrolling = true;
                } else if (notification is ScrollEndNotification) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _userScrolling = false);
                  });
                }
                return false;
              },
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent
                    ],
                    stops: const [0.0, 0.2, 0.8, 1.0], 
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  physics: const BouncingScrollPhysics(),
                  itemCount: lyrics.length,
                  // 【核心修复2】加大内边距到 80
                  // 之前是 64，是理论最小值。加大到 80 可以确保最后一行绝对能滚到中间，不会因为空间不足卡住
                  padding: const EdgeInsets.symmetric(vertical: 80), 
                  itemBuilder: (context, index) {
                    final line = lyrics[index];
                    final text = line.replaceAll(RegExp(r'\[.*?\]'), '').trim();
                    final isCurrent = index == currentIndex;

                    if (text.isEmpty) return const SizedBox(height: 32);

                    return Container(
                      height: 32,
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.white38,
                          fontSize: isCurrent ? 18 : 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'sans-serif',
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Duration? _parseTime(String line) {
    try {
      final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\]');
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0').substring(0, 3));
        return Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds);
      }
    } catch (_) {}
    return null;
  }
}