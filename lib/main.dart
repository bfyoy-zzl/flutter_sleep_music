import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ui/main_shell.dart'; 

Future<void> main() async {
  // 1. 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. 初始化 Hive
    await Hive.initFlutter();
    
    // 3. 打开所有需要用到的 Box (盒子)
    // 加上 try-catch 防止因为某个盒子损坏导致 App 启动失败
    await Hive.openBox('settings');     // 设置、扫描状态、自定义混音
    await Hive.openBox('player_state'); // 播放进度、当前歌单
    await Hive.openBox('history');      // 播放历史
    await Hive.openBox('favorite');     // 收藏夹 (如果有)
    await Hive.openBox('tags');         // 隐藏歌曲/标签 (如果有 tag_provider)
    
    print("✅ Hive 初始化成功");
  } catch (e) {
    print("❌ Hive 初始化失败: $e");
    // 如果初始化失败，这里可以加个简单的容错逻辑，或者仅仅打印日志
    // 甚至可以在这里选择删除损坏的盒子 (高级操作，暂时不需要)
  }
  
  // 4. 启动 App
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