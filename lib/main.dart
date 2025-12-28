import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ui/main_shell.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. 初始化
    await Hive.initFlutter();
    
    // 2. 【大包围战术】把所有可能出现的盒子名字都打开
    // 宁可多开，不可漏开
    await Hive.openBox('settings');
    await Hive.openBox('player_state');
    await Hive.openBox('history');
    
    // 针对 收藏功能 (防止单复数搞错)
    await Hive.openBox('favorite');  
    await Hive.openBox('favorites'); 

    // 针对 标签功能 (防止新旧版本搞错)
    await Hive.openBox('tags');          // 旧版本可能用的名字
    await Hive.openBox('tag_overrides'); // 新版本用的名字

    print("✅ Hive 所有可能的盒子都已准备就绪");
  } catch (e) {
    print("❌ Hive 初始化警告: $e");
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '梦音岛',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainShell(),
    );
  }
}