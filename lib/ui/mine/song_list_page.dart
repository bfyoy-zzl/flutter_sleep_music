import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/playlist_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/song_option_menu.dart';

class SongListPage extends ConsumerStatefulWidget {
  final String title;
  final List<SongModel> songs;
  final String? playlistId;

  const SongListPage({
    super.key,
    required this.title,
    required this.songs,
    this.playlistId,
  });

  @override
  ConsumerState<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends ConsumerState<SongListPage> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<SongModel> currentList) {
    setState(() {
      if (_selectedIds.length == currentList.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var song in currentList) {
          _selectedIds.add(song.id);
        }
      }
    });
  }

  void _toggleSongSelection(int songId) {
    setState(() {
      if (_selectedIds.contains(songId)) {
        _selectedIds.remove(songId);
      } else {
        _selectedIds.add(songId);
      }
    });
  }

  void _batchAddToFavorite(List<SongModel> allSongs) {
    final favNotifier = ref.read(favoriteProvider.notifier);
    final currentFavs = ref.read(favoriteProvider);
    int count = 0;

    for (var id in _selectedIds) {
      if (!currentFavs.contains(id)) {
        favNotifier.toggleFavorite(id);
        count++;
      }
    }
    _exitSelectionMode("成功收藏 $count 首歌曲");
  }

  void _batchRemoveFromFavorite() {
    final favNotifier = ref.read(favoriteProvider.notifier);
    int count = 0;

    for (var id in _selectedIds) {
      favNotifier.toggleFavorite(id);
      count++;
    }
    _exitSelectionMode("已取消收藏 $count 首歌曲");
  }

  void _batchAddToPlaylist(String playlistId, String playlistName) {
    final playlistNotifier = ref.read(playlistProvider.notifier);

    for (var songId in _selectedIds) {
      playlistNotifier.addSongToPlaylist(playlistId, songId);
    }

    _exitSelectionMode("已将 ${_selectedIds.length} 首歌曲添加到「$playlistName」");
  }

  void _batchRemoveFromPlaylist() {
    if (widget.playlistId == null) return;

    final playlistNotifier = ref.read(playlistProvider.notifier);

    for (var songId in _selectedIds) {
      playlistNotifier.removeSongFromPlaylist(widget.playlistId!, songId);
    }

    _exitSelectionMode("已从歌单中移除 ${_selectedIds.length} 首歌曲");
  }

  Future<void> _batchDelete() async {
    final audioController = ref.read(audioControllerProvider);

    for (var songId in _selectedIds) {
      await audioController.deleteSong(songId);
    }

    _exitSelectionMode("已隐藏 ${_selectedIds.length} 首歌曲");
  }

  void _exitSelectionMode(String message) {
    Navigator.pop(context);
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showBatchMenu(List<SongModel> currentList, List<CustomPlaylist> playlists) {
    final isFavoritePlaylist = widget.title == "我的收藏";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text("已选择 ${_selectedIds.length} 首歌曲",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    if (isFavoritePlaylist)
                      ListTile(
                        leading: const Icon(Icons.favorite_border, color: Colors.white),
                        title: const Text("批量取消收藏", style: TextStyle(color: Colors.white)),
                        onTap: () => _batchRemoveFromFavorite(),
                      )
                    else
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.white),
                        title: const Text("批量收藏", style: TextStyle(color: Colors.white)),
                        onTap: () => _batchAddToFavorite(currentList),
                      ),
                    ...playlists.where((p) => p.id != widget.playlistId).map((p) {
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: Colors.white),
                        title: Text("批量添加到「${p.name}」", style: TextStyle(color: Colors.white)),
                        onTap: () => _batchAddToPlaylist(p.id, p.name),
                      );
                    }).toList(),
                    if (widget.playlistId != null)
                      ListTile(
                        leading: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                        title: const Text("从歌单移除", style: TextStyle(color: Colors.orange)),
                        onTap: () => _batchRemoveFromPlaylist(),
                      ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text("批量删除", style: TextStyle(color: Colors.redAccent)),
                      onTap: () => _batchDelete(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMenu(List<SongModel> currentList, List<CustomPlaylist> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
          child: Container(
            color: const Color(0xFF2C2C2C).withOpacity(0.3),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.white),
                    title: const Text("选择", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleSelectionMode();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.select_all, color: Colors.white),
                    title: const Text("全选", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleSelectAll(currentList);
                      setState(() {
                        _isSelectionMode = true;
                      });
                    },
                  ),
                  if (widget.playlistId != null)
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      title: const Text("删除歌单", style: TextStyle(color: Colors.redAccent)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showDeleteDialog();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
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
                  Text("确定要删除「${widget.title}」吗？\n此操作无法撤销。", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.white54)))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(onPressed: () {
                            if (widget.playlistId != null) {
                              ref.read(playlistProvider.notifier).deletePlaylist(widget.playlistId!);
                            }
                            Navigator.pop(context);
                            Navigator.pop(context);
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

  void _showSongOptionMenu(SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SongOptionMenu(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSongsAsync = ref.watch(allSongsProvider);
    final customPlaylists = ref.watch(playlistProvider);

    final List<SongModel> displaySongs = allSongsAsync.when(
      data: (allSongs) {
        final songMap = {for (var s in allSongs) s.id: s};

        var filteredList = widget.songs
            .map((s) => songMap[s.id])
            .where((s) => s != null)
            .cast<SongModel>()
            .toList();

        if (widget.playlistId != null) {
          try {
            final currentCustomPlaylist = customPlaylists.firstWhere((p) => p.id == widget.playlistId);
            filteredList = filteredList
                .where((s) => currentCustomPlaylist.songIds.contains(s.id))
                .toList();
          } catch (_) {
            filteredList = [];
          }
        }

        return filteredList;
      },
      loading: () => widget.songs,
      error: (_, __) => widget.songs,
    );

    final hasSelection = _selectedIds.isNotEmpty;
    final isAllSelected = displaySongs.isNotEmpty && _selectedIds.length == displaySongs.length;

    return Stack(
      children: [
        const AnimatedBackground(),
        WillPopScope(
          onWillPop: () async {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  if (_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              title: Text(
                _isSelectionMode ? "已选择 ${_selectedIds.length}" : widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                if (_isSelectionMode) ...[
                  if (hasSelection)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIds.clear();
                        });
                      },
                      child: const Text("取消选择", style: TextStyle(color: Colors.white70)),
                    ),
                  TextButton(
                    onPressed: () => _toggleSelectAll(displaySongs),
                    child: Text(
                      isAllSelected ? "取消全选" : "全选",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (hasSelection)
                    IconButton(
                      icon: const Icon(Icons.menu_open, color: AppTheme.accentPurple),
                      onPressed: () => _showBatchMenu(displaySongs, customPlaylists),
                    ),
                  if (!hasSelection)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      child: const Text("取消", style: TextStyle(color: Colors.white)),
                    ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onPressed: () => _showEditMenu(displaySongs, customPlaylists),
                  ),
                ],
                const SizedBox(width: 5),
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
                      final isSelected = _selectedIds.contains(song.id);

                      // 获取当前播放歌曲信息
                      final currentPlaylist = ref.watch(currentPlaylistProvider);
                      final currentIndex = ref.watch(currentSongIndexProvider);
                      final isPlayingSong = currentIndex != null &&
                          currentIndex < currentPlaylist.length &&
                          currentPlaylist[currentIndex].id == song.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: _isSelectionMode ? Border.all(
                            color: isSelected ? AppTheme.accentPurple : Colors.transparent,
                            width: 1,
                          ) : null,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSongSelection(song.id);
                            } else {
                              ref.read(audioControllerProvider).playSong(song, newPlaylist: displaySongs);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _isSelectionMode
                                  ? (isSelected
                                      ? AppTheme.accentPurple.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05))
                                  : Colors.transparent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: const BoxDecoration(shape: BoxShape.circle),
                                      child: ClipOval(
                                        child: isPlayingSong
                                          ? Container(
                                              decoration: const BoxDecoration(
                                                color: AppTheme.accentPurple,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.equalizer_rounded,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            )
                                          : QueryArtworkWidget(
                                              id: song.id,
                                              type: ArtworkType.AUDIO,
                                              nullArtworkWidget: Container(
                                                color: Colors.white10,
                                                child: const Icon(Icons.music_note, color: Colors.white54),
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isPlayingSong ? AppTheme.accentPurple : Colors.white,
                                              fontSize: 16,
                                              fontWeight: isPlayingSong ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            song.artist ?? "<未知>",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isSelectionMode)
                                      Transform.scale(
                                        scale: 1.1,
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: AppTheme.accentPurple,
                                          side: const BorderSide(color: Colors.white54, width: 2),
                                          shape: const CircleBorder(),
                                          onChanged: (_) => _toggleSongSelection(song.id),
                                        ),
                                      ),
                                    if (!_isSelectionMode)
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final favorites = ref.watch(favoriteProvider);
                                          final isFav = favorites.contains(song.id);
                                          return IconButton(
                                            icon: Icon(
                                              isFav ? Icons.favorite : Icons.favorite_border,
                                              color: isFav ? Colors.redAccent : Colors.white38,
                                              size: 24,
                                            ),
                                            onPressed: () => ref.read(favoriteProvider.notifier).toggleFavorite(song.id),
                                          );
                                        },
                                      ),
                                    if (!_isSelectionMode)
                                      IconButton(
                                        icon: const Icon(Icons.more_vert, color: Colors.white38),
                                        onPressed: () => _showSongOptionMenu(song),
                                      ),
                                  ],
                            ),
                          ),
                        ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}