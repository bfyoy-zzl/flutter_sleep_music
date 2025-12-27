// lib/ui/widgets/animated_background.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    // 1. 初始化动画控制器
    // duration 决定呼吸一次需要多久，6秒比较舒缓
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    // 2. 定义呼吸曲线 (使用 easeInOut 让呼吸更自然)
    // 动画值从 0.0 到 1.0 循环往复
    _breathingAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // 3. 让动画无限循环播放 (往复运动)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 AnimatedBuilder 监听动画值的变化并重绘
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        // 根据动画进度计算缩放和透明度
        // 缩放范围：1.0倍 -> 1.5倍
        final scale = 1.0 + (_breathingAnimation.value * 0.5);
        // 透明度范围：0.3 -> 0.6 (根据你的主题色调整)
        final opacity = 0.3 + (_breathingAnimation.value * 0.3);

        return Stack(
          children: [
            // 1. 最底层的深色背景
            Container(color: AppTheme.primaryBackground),

            // 2. 左上角的色块 (使用紫色系)
            Positioned(
              top: -100, // 让圆心在屏幕外，只露出一角
              left: -100,
              child: Transform.scale(
                scale: scale, // 应用呼吸缩放
                child: _buildBlurredBlob(
                  color: AppTheme.accentPurple.withOpacity(opacity),
                ),
              ),
            ),

            // 3. 右下角的色块 (可以使用另一个互补色，比如偏蓝或偏粉，这里暂用同色系)
            Positioned(
              bottom: -150,
              right: -150,
              child: Transform.scale(
                scale: scale * 0.9, // 让两个球的呼吸节奏稍微错开一点点
                child: _buildBlurredBlob(
                  color: const Color(0xFF5C6BC0).withOpacity(opacity), // 稍微不同的蓝紫色
                ),
              ),
            ),
            
            // 4. 全局覆盖一层淡淡的黑色半透明，增加深邃感（可选）
            Container(color: Colors.black.withOpacity(0.3)),
          ],
        );
      },
    );
  }

  // 构建高斯模糊色块的方法
  Widget _buildBlurredBlob({required Color color}) {
    //这里利用了 Container 的 BoxShadow 来实现极致的模糊效果
    //这种方法比 BackdropFilter 性能更好，适合做背景
    return Container(
      width: 400, // 圆的原始大小
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1), // 圆本身的颜色很淡
        boxShadow: [
          BoxShadow(
            color: color, // 阴影颜色
            blurRadius: 150, // 极大的模糊半径，制造高斯模糊效果
            spreadRadius: 50, // 扩散范围
          ),
        ],
      ),
    );
  }
}