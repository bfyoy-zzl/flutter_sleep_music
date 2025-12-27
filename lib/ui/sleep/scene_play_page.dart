import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/sleep_models.dart';
import '../../providers/sleep_data_provider.dart';
import '../../providers/sleep_player_provider.dart';

class ScenePlayPage extends ConsumerStatefulWidget {
  final SceneMeta scene;
  const ScenePlayPage({super.key, required this.scene});

  @override
  ConsumerState<ScenePlayPage> createState() => _ScenePlayPageState();
}

class _ScenePlayPageState extends ConsumerState<ScenePlayPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动播放
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(sleepDataProvider.notifier);
      final player = ref.read(sleepPlayerProvider.notifier);
      
      // 加载配置
      final configs = await notifier.loadSceneDetail(widget.scene.title);
      
      // 【核心修复】传入两个参数：场景标题 和 配置列表
      if (mounted) {
        player.playScene(widget.scene.title, configs);
      }
    });
  }

  @override
  void dispose() {
    // 页面退出时停止播放？
    // 根据之前的逻辑，我们希望保留后台播放，所以这里注释掉停止代码
    // ref.read(sleepPlayerProvider.notifier).stopAll(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图
          Image.asset(
            "assets/scene/${widget.scene.imagePath}",
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return Container(color: Colors.black87); // 图片加载失败时的兜底
            },
          ),
          // 遮罩
          Container(color: Colors.black.withOpacity(0.3)),
          
          // 内容
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      // 退出页面时不停止播放，保持后台运行
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Spacer(),
                Text(widget.scene.title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(widget.scene.engTitle, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 20),
                const Text("正在播放助眠场景...", style: TextStyle(color: Colors.white54)),
                const Spacer(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}