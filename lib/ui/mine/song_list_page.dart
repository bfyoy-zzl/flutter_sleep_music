import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/playlist_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/edit_tag_sheet.dart';
import '../widgets/song_option_menu.dart'; 

class SongListPage extends ConsumerWidget {
  final String title;
  final List<SongModel> songs; // 进入页面时的初始列表
  final String? playlistId;    // 如果是自定义歌单，这个 ID 不为空

  const SongListPage({
    super.key, 
    required this.title, 
    required this.songs,
    this.playlistId,
  });

  // 删除歌单确认弹窗 (UI 保持不变)
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C).withOpacity(0.3), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded, size: 36, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 20),
                  const Text("删除歌单", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("确定要删除「$title」吗？\n此操作无法撤销。", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.white54)))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(onPressed: () {
                            if (playlistId != null) {
                              ref.read(playlistProvider.notifier).deletePlaylist(playlistId!);
                            }
                            Navigator.pop(context); Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("歌单已删除")));
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text("确认删除"))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSongOptionMenu(BuildContext context, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SongOptionMenu(song: song),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongIndex = ref.watch(currentSongIndexProvider);
    final currentPlaylist = ref.watch(currentPlaylistProvider);
    
    // 1. 监听全局歌曲变化 (处理删除/重命名)
    final allSongsAsync = ref.watch(allSongsProvider);
    
    // 2. 监听歌单变化 (处理“移出歌单”)
    final customPlaylists = ref.watch(playlistProvider);

    final List<SongModel> displaySongs = allSongsAsync.when(
      data: (allSongs) {
        final songMap = {for (var s in allSongs) s.id: s};
        
        // 第一步：基于最新的全量库，过滤掉已彻底删除(隐藏)的歌曲
        var filteredList = songs
            .map((s) => songMap[s.id])
            .where((s) => s != null) 
            .cast<SongModel>()
            .toList();

        // 【核心修复】第二步：如果是“自定义歌单”页面，必须过滤掉已经移出的歌曲
        if (playlistId != null) {
          try {
            // 找到当前这个歌单的最新状态
            final currentCustomPlaylist = customPlaylists.firstWhere((p) => p.id == playlistId);
            // 只保留还在 songIds 列表里的歌
            filteredList = filteredList
                .where((s) => currentCustomPlaylist.songIds.contains(s.id))
                .toList();
          } catch (_) {
            // 如果歌单找不到了(可能被删了)，清空列表
            filteredList = [];
          }
        }
        
        return filteredList;
      },
      loading: () => songs, 
      error: (_, __) => songs,
    );

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
            title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            centerTitle: true,
            actions: [
              if (playlistId != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: () => _showDeleteDialog(context, ref),
                ),
              const SizedBox(width: 10),
            ],
          ),
          body: displaySongs.isEmpty
              ? const Center(child: Text("暂无歌曲", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: displaySongs.length,
                  padding: const EdgeInsets.only(bottom: 100),
                  itemBuilder: (context, index) {
                    final song = displaySongs[index]; 
                    final isPlaying = currentSongIndex != null && 
                                    currentSongIndex < currentPlaylist.length &&
                                    currentPlaylist[currentSongIndex].id == song.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPlaying ? AppTheme.accentPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        ),
                        child: Center(
                          child: isPlaying 
                            ? const Icon(Icons.equalizer, color: AppTheme.accentPurple, size: 20)
                            : Text("${index + 1}", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isPlaying ? AppTheme.accentPurple : Colors.white, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(song.artist ?? "<未知>", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final favorites = ref.watch(favoriteProvider);
                              final isFav = favorites.contains(song.id);
                              return IconButton(
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : Colors.white38, size: 20),
                                onPressed: () => ref.read(favoriteProvider.notifier).toggleFavorite(song.id),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                            onPressed: () => _showSongOptionMenu(context, song),
                          ),
                        ],
                      ),
                      onTap: () => ref.read(audioControllerProvider).playSong(song, newPlaylist: displaySongs),
                    );
                  },
                ),
        ),
      ],
    );
  }
}