import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui; 
import '../core/theme/app_theme.dart';
import '../providers/audio_provider.dart'; 
import 'music/music_player_page.dart';
import 'mine/mine_page.dart';
import 'sleep/sleep_page.dart';
import 'widgets/animated_background.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 1; 

  final List<Widget> _pages = const [
    SleepPage(),
    MusicPlayerPage(),
    MinePage(),
  ];

  @override
  void initState() {
    super.initState();
    // 启动后尝试初始化控制器
    // 如果还没扫描过，这里什么都不会发生，绝对安全
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioControllerProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildFloatingNavBar(),
        ),
      ],
    );
  }

  Widget _buildFloatingNavBar() {
    const double navBarHeight = 70;
    const double bottomMargin = 20;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: navBarHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.nightlight_round, "助眠"),
                        _buildNavItem(1, Icons.music_note_rounded, "音乐"),
                        _buildNavItem(2, Icons.person_rounded, "我的"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: bottomMargin),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentPurple : Colors.white54,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.accentPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}