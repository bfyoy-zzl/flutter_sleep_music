import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/tag_provider.dart'; // 【新增】引入 TagProvider
import 'edit_tag_sheet.dart';

class SongOptionMenu extends ConsumerWidget {
  final SongModel song;

  const SongOptionMenu({super.key, required this.song});

  // 添加到歌单
  void _addToPlaylist(BuildContext context, WidgetRef ref, String playlistId) {
    ref.read(playlistProvider.notifier).addSongToPlaylist(playlistId, song.id);
    Navigator.pop(context);
  }

  // 从歌单移出
  void _removeFromPlaylist(BuildContext context, WidgetRef ref, String playlistId) {
    ref.read(playlistProvider.notifier).removeSongFromPlaylist(playlistId, song.id);
    Navigator.pop(context);
  }

  // 【核心功能】删除歌曲（逻辑隐藏）
  Future<void> _deleteSong(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    
    // 调用控制器去处理所有的逻辑（隐藏 + 切歌 + 刷新）
    await ref.read(audioControllerProvider).deleteSong(song.id);
    
    // 【已删除】ScaffoldMessenger.of(context).showSnackBar...
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistProvider);
    final isFavorite = ref.watch(favoriteProvider).contains(song.id);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(
                color: const Color(0xFF2C2C2C).withOpacity(0.3),
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: QueryArtworkWidget(
                      id: song.id, 
                      type: ArtworkType.AUDIO, 
                      nullArtworkWidget: const Icon(Icons.music_note, color: Colors.white, size: 32)
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(song.artist ?? "未知艺术家", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                  ),
                  
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 5),

                  ListTile(
                    leading: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : Colors.white),
                    title: Text(isFavorite ? "取消收藏" : "添加到收藏", style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      ref.read(favoriteProvider.notifier).toggleFavorite(song.id);
                      Navigator.pop(context);
                    },
                  ),

                  ...playlists.map((playlist) {
                    final bool isInPlaylist = playlist.songIds.contains(song.id);
                    if (isInPlaylist) {
                      return ListTile(
                        leading: const Icon(Icons.playlist_remove, color: Colors.redAccent),
                        title: Text("从「${playlist.name}」移出", style: const TextStyle(color: Colors.redAccent)),
                        onTap: () => _removeFromPlaylist(context, ref, playlist.id),
                      );
                    } else {
                      return ListTile(
                        leading: const Icon(Icons.playlist_add, color: Colors.white),
                        title: Text("添加到「${playlist.name}」", style: const TextStyle(color: Colors.white)),
                        onTap: () => _addToPlaylist(context, ref, playlist.id),
                      );
                    }
                  }).toList(),

                  ListTile(
                    leading: const Icon(Icons.edit_note, color: Colors.white),
                    title: const Text("编辑标签", style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context); 
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => EditTagSheet(song: song),
                      );
                    },
                  ),

                  // 【修改】删除功能对接真实逻辑
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    title: const Text("删除歌曲", style: TextStyle(color: Colors.redAccent)),
                    onTap: () => _deleteSong(context, ref), // 调用上面那个方法
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}