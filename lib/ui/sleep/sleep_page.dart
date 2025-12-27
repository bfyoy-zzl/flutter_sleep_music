import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/sleep_data_provider.dart';
import '../../providers/sleep_player_provider.dart';
import '../../providers/timer_provider.dart';
import 'custom_select_page.dart';

class SleepPage extends ConsumerWidget {
  const SleepPage({super.key});

  // 定时弹窗
  void _showTimerBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.66,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Stack(
              children: [
                // 1. 毛玻璃滤镜
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      color: const Color(0xFF2C2C2C).withOpacity(0.6),
                    ),
                  ),
                ),
                // 2. 内容
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 20),
                          width: 40, height: 4,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const Text("定时关闭", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: (120 ~/ 5), 
                          itemBuilder: (context, index) {
                            final int minutes = (index + 1) * 5;
                            return GestureDetector(
                              onTap: () {
                                ref.read(timerControllerProvider).startTimer(minutes);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "$minutes", 
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                                    ),
                                    const Text(
                                      "分钟", 
                                      style: TextStyle(color: Colors.white54, fontSize: 10)
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(timerControllerProvider).stopTimer();
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPurple.withOpacity(0.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                              elevation: 0,
                            ),
                            child: const Text("取消定时", style: TextStyle(color: AppTheme.accentPurple)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepData = ref.watch(sleepDataProvider);
    final isPlaying = ref.watch(sleepIsPlayingProvider);
    final currentSceneName = ref.watch(currentSceneNameProvider);
    final timerSeconds = ref.watch(timerDurationProvider);

    String timerText = "定时";
    if (timerSeconds != null) {
      final m = timerSeconds ~/ 60;
      final s = timerSeconds % 60;
      timerText = "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    
    final sceneWidgets = sleepData.scenes.map((scene) {
      final isThisSceneActive = (currentSceneName == scene.title);
      return _buildCard(
        context,
        title: scene.title,
        bgImage: "assets/scene/${scene.imagePath}",
        isActive: isThisSceneActive && isPlaying,
        onTap: () async {
          final playerNotifier = ref.read(sleepPlayerProvider.notifier);
          if (isThisSceneActive) {
            if (isPlaying) {
              playerNotifier.pauseAll();
            } else {
              playerNotifier.resumeAll();
            }
          } else {
            final configs = await ref.read(sleepDataProvider.notifier).loadSceneDetail(scene.title);
            if (context.mounted) {
               playerNotifier.playScene(scene.title, configs);
            }
          }
        },
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "助眠场景",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                  children: [
                    ...sceneWidgets,
                    // 自选卡片
                    _buildCard(
                      context,
                      title: "自选",
                      bgImage: "assets/images/custom_bg.jpg",
                      isCustom: true,
                      isActive: currentSceneName == "CUSTOM" && isPlaying,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomSelectPage()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              
              // 底部控制栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showTimerBottomSheet(context, ref),
                      child: Row(
                        children: [
                          Icon(
                            timerSeconds != null ? Icons.timer : Icons.timer_outlined, 
                            color: timerSeconds != null ? AppTheme.accentPurple : Colors.white70
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timerText, 
                            style: TextStyle(
                              color: timerSeconds != null ? AppTheme.accentPurple : Colors.white70,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                         if (ref.watch(sleepPlayerProvider).isNotEmpty) ...[
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, 
                                color: Colors.white, 
                                size: 40
                              ),
                              onPressed: () {
                                final notifier = ref.read(sleepPlayerProvider.notifier);
                                if (isPlaying) {
                                  notifier.pauseAll();
                                } else {
                                  notifier.resumeAll();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white54, size: 30),
                              onPressed: () {
                                ref.read(sleepPlayerProvider.notifier).stopAll();
                              },
                            ),
                         ] else 
                            const Text("点击卡片开始播放", style: TextStyle(color: Colors.white38, fontSize: 12))
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 【核心修复】卡片组件
  Widget _buildCard(BuildContext context, {
    required String title, 
    required String bgImage, 
    required VoidCallback onTap,
    bool isCustom = false,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // 这里移除了 color: const Color(0xFF4A4A4A) 那个实心灰色
          // 改用半透明背景，确保没有图片时也是通透的
          color: Colors.white.withOpacity(0.05),
          border: isActive 
              ? Border.all(color: AppTheme.accentPurple.withOpacity(0.8), width: 2) 
              : Border.all(color: Colors.white.withOpacity(0.1), width: 1), // 默认有个细边框
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
            // 降低遮罩浓度，让图片更清晰一点
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(isActive ? 0.3 : 0.2), BlendMode.darken),
            onError: (_, __) {},
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        // ClipRRect 包裹毛玻璃
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
             // 自选卡片增加强力毛玻璃，普通卡片保持清晰或轻微模糊
             filter: ui.ImageFilter.blur(
               sigmaX: isCustom ? 15.0 : 0.0, 
               sigmaY: isCustom ? 15.0 : 0.0
             ),
             child: Container(
               // 叠加一层淡淡的白色，增强玻璃质感
               color: isCustom ? Colors.white.withOpacity(0.05) : Colors.transparent, 
               child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isActive && !isCustom)
                      const Icon(Icons.equalizer_rounded, color: AppTheme.accentPurple, size: 32)
                    else if (isCustom) 
                      Icon(Icons.tune_rounded, color: isActive ? AppTheme.accentPurple : Colors.white, size: 32),
                    
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: isActive ? AppTheme.accentPurple : Colors.white, 
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.2
                      ),
                    ),
                  ],
                ),
               ),
             ),
          ),
        ),
      ),
    );
  }
}