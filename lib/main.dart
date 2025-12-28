import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ui/main_shell.dart'; 
// 👇 1. 引入这个包
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 👇 2. 【核心修改】加了 try-catch 的安全初始化
  // 以前黑屏是因为这里报错没人管，现在报错了我们只打印日志，继续让 App 启动
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.my_music_player.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    );
    print("✅ 后台服务初始化成功");
  } catch (e) {
    // ⚠️ 重点：如果这里报错，说明 Manifest 没配好，但 App 不会黑屏了！
    print("❌ 后台服务初始化失败 (但不影响 App 启动): $e");
  }

  // 👇 下面是你验证过完全可用的代码，原封不动
  try {
    await Hive.initFlutter();
    
    await Hive.openBox('settings');
    await Hive.openBox('player_state');
    await Hive.openBox('history');
    
    await Hive.openBox('favorite');  
    await Hive.openBox('favorites'); 

    await Hive.openBox('tags');         
    await Hive.openBox('tag_overrides'); 

    print("✅ Hive 盒子准备就绪");
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