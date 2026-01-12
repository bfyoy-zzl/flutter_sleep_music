import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tag_provider.dart';
import '../widgets/animated_background.dart';

class HiddenSongsPage extends ConsumerWidget {
  const HiddenSongsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取所有隐藏记录
    final overrides = ref.watch(tagProvider);
    // 筛选出 hidden 为 true 的 ID 列表
    final hiddenIds = overrides.entries
        .where((e) => e.value.isHidden)
        .map((e) => e.key)
        .toSet();

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("已删除歌曲", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            // 【新增】全部还原按钮
            actions: [
              TextButton(
                onPressed: hiddenIds.isEmpty
                  ? null // 列表为空时禁用
                  : () async {
                      // 1. 全部还原
                      await ref.read(tagProvider.notifier).restoreAll();
                      // 2. 刷新主列表
                      ref.refresh(allSongsProvider); // ignore: unused_result
                      // 这里也无需提示，因为列表瞬间清空，反馈很明显
                  },
                child: Text(
                  "全部还原",
                  style: TextStyle(
                    color: hiddenIds.isEmpty ? Colors.white38 : AppTheme.accentPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: hiddenIds.isEmpty
              ? const Center(child: Text("暂无被删除的歌曲", style: TextStyle(color: Colors.white54)))
              : FutureBuilder<List<SongModel>>(
                  // 我们需要直接查询原始文件，因为 allSongsProvider 已经把它们过滤掉了
                  future: OnAudioQuery().querySongs(
                    uriType: UriType.EXTERNAL,
                    ignoreCase: true,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
                    
                    // 从原始列表中找到被隐藏的歌
                    final hiddenSongs = snapshot.data!
                        .where((s) => hiddenIds.contains(s.id))
                        .toList();

                    if (hiddenSongs.isEmpty) {
                      return const Center(child: Text("文件可能已被物理移除", style: TextStyle(color: Colors.white54)));
                    }

                    return ListView.builder(
                      itemCount: hiddenSongs.length,
                      itemBuilder: (context, index) {
                        final song = hiddenSongs[index];
                        return ListTile(
                          leading: QueryArtworkWidget(
                            id: song.id, 
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(song.artist ?? "<未知>", style: const TextStyle(color: Colors.white54)),
                          trailing: IconButton(
                            icon: const Icon(Icons.restore, color: AppTheme.accentPurple),
                            onPressed: () async {
                              // 1. 恢复歌曲
                              await ref.read(tagProvider.notifier).restoreSong(song.id);
                              // 2. 刷新主列表 (让 MinePage 等地方重新显示出来)
                              ref.refresh(allSongsProvider); // ignore: unused_result
                              // 【已修改】移除了 SnackBar 提示
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}