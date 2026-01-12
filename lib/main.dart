import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:just_audio_background/just_audio_background.dart'; // 暂时注释掉
import 'ui/main_shell.dart';
import 'providers/tag_provider.dart'; // 添加导入 

// 🔴 强制设为 false，这会触发 audio_provider 中的“哑巴模式”
bool isAudioServiceAvailable = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置系统UI覆盖样式，让状态栏透明且内容延伸到状态栏下方
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 状态栏透明
      statusBarIconBrightness: Brightness.light, // 状态栏图标为白色
      systemNavigationBarColor: Colors.transparent, // 导航栏透明
      systemNavigationBarIconBrightness: Brightness.light, // 导航栏图标为白色
    ),
  );

  // 启用边缘到边缘的显示模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // 🔴🔴🔴 彻底注释掉初始化代码 🔴🔴🔴
  // 既然我们换回了普通 Activity，就绝对不能调用这个 init
  /*
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.my_music_player.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/launcher_icon', 
    );
    isAudioServiceAvailable = true;
    print("✅ 音频后台服务初始化成功");
  } catch (e) {
    print("❌ 音频后台初始化失败: $e");
  }
  */
  print("⚠️ 强制禁用后台服务，使用纯前台模式");

  try {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('player_state'),
      Hive.openBox('history'),
      Hive.openBox('favorite'),  
      Hive.openBox('favorites'), 
      Hive.openBox('tags'),          
      Hive.openBox('tag_overrides'),
    ]);
    
    print("✅ Hive 初始化完成");
  } catch (e) {
    print("❌ Hive 初始化警告: $e");
  }
  
  runApp(const ProviderScope(child: const AppInitializer(child: MyApp())));
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

// 【修复】创建一个初始化组件来初始化 tagProvider
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_initialized) {
        _initialized = true;
        final tagNotifier = ref.read(tagProvider.notifier);
        await tagNotifier.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}