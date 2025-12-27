import 'package:flutter/material.dart';

class AppTheme {
  // 背景色：深色带一点蓝紫
  static const Color primaryBackground = Color(0xFF121422); 
  // 强调色：紫色
  static const Color accentPurple = Color(0xFF7B61FF);
  // 辅助色：深蓝
  static const Color secondaryBlue = Color(0xFF2D3454);
  
  // 文字颜色
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.white54;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBackground,
      primaryColor: accentPurple,
      // 定义全局字体样式 (后续可引入 Google Fonts)
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textWhite),
        titleLarge: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
      ),
      // 底部导航栏主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent, // 透明，为了能在上面做模糊层
        selectedItemColor: accentPurple,
        unselectedItemColor: textGrey,
        elevation: 0,
      ),
    );
  }
}