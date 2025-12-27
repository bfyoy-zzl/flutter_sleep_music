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
import '../../providers/tag_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _keyword = "";
  
  // === 选择模式状态 ===
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {}; 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // === 逻辑方法 ===

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

  // 批量操作：添加到收藏
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

  // 批量操作：添加到指定自定义歌单
  void _batchAddToPlaylist(String playlistId, String playlistName) {
    final playlistNotifier = ref.read(playlistProvider.notifier);
    
    for (var songId in _selectedIds) {
      playlistNotifier.addSongToPlaylist(playlistId, songId);
    }
    
    _exitSelectionMode("已将 ${_selectedIds.length} 首歌曲添加到「$playlistName」");
  }

  // 批量操作：删除
  Future<void> _batchDelete() async {
    final audioController = ref.read(audioControllerProvider);

    for (var songId in _selectedIds) {
      await audioController.deleteSong(songId);
    }

    _exitSelectionMode("已隐藏 ${_selectedIds.length} 首歌曲");
  }

  void _exitSelectionMode(String message) {
    Navigator.pop(context); // 关闭底部弹窗
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 【新增】显示批量操作的毛玻璃菜单
  void _showBatchMenu(List<SongModel> results, List<CustomPlaylist> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          children: [
            // 1. 毛玻璃背景
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  color: const Color(0xFF2C2C2C).withOpacity(0.3), // 通透深色
                ),
              ),
            ),
            
            // 2. 内容区域
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text("已选择 ${_selectedIds.length} 首歌曲", 
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    
                    // 选项1: 批量收藏
                    ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.white),
                      title: const Text("批量收藏", style: TextStyle(color: Colors.white)),
                      onTap: () => _batchAddToFavorite(results),
                    ),

                    // 选项2: 动态歌单列表
                    ...playlists.map((p) {
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: Colors.white),
                        title: Text("批量添加到「${p.name}」", style: TextStyle(color: Colors.white)),
                        onTap: () => _batchAddToPlaylist(p.id, p.name),
                      );
                    }).toList(),

                    // 选项3: 批量删除
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

  @override
  Widget build(BuildContext context) {
    final allSongsAsync = ref.watch(allSongsProvider);
    final playlists = ref.watch(playlistProvider);
    
    final allSongs = allSongsAsync.value ?? [];
    
    final searchResults = _keyword.isEmpty 
        ? <SongModel>[] 
        : allSongs.where((s) {
            final q = _keyword.toLowerCase();
            return s.title.toLowerCase().contains(q) || 
                   (s.artist?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Stack(
      children: [
        const AnimatedBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false, 
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(searchResults, playlists),
                _buildSearchInput(),
                Expanded(
                  child: searchResults.isEmpty && _keyword.isNotEmpty
                      ? const Center(child: Text("未找到相关歌曲", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final song = searchResults[index];
                            return _buildListItem(song);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === 顶部栏 ===
  Widget _buildHeader(List<SongModel> results, List<CustomPlaylist> playlists) {
    final hasResults = results.isNotEmpty;
    final hasSelection = _selectedIds.isNotEmpty;
    final isAllSelected = hasResults && _selectedIds.length == results.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          const Text(
            "搜索音乐",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),

          if (hasResults) ...[
            if (_isSelectionMode)
              TextButton(
                onPressed: () => _toggleSelectAll(results),
                child: Text(
                  isAllSelected ? "取消全选" : "全选",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

            // 【核心修改】将 PopupMenuButton 替换为调用底部弹窗的按钮
            if (_isSelectionMode && hasSelection)
               IconButton(
                 icon: const Icon(Icons.menu_open, color: AppTheme.accentPurple),
                 onPressed: () => _showBatchMenu(results, playlists), // 调用新写的毛玻璃菜单
               )
            else if (_isSelectionMode)
               TextButton(
                 onPressed: _toggleSelectionMode,
                 child: const Text("取消", style: TextStyle(color: Colors.white)),
               )
            else
               TextButton(
                 onPressed: _toggleSelectionMode,
                 child: const Text("选择", style: TextStyle(color: Colors.white)),
               ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              cursorColor: AppTheme.accentPurple,
              decoration: const InputDecoration(
                hintText: "输入歌曲或歌手名...",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white38),
              ),
              onChanged: (val) => setState(() => _keyword = val),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(SongModel song) {
    final isSelected = _selectedIds.contains(song.id);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) _selectedIds.remove(song.id);
            else _selectedIds.add(song.id);
          });
        } else {
          ref.read(audioControllerProvider).playSong(song);
          FocusScope.of(context).unfocus();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentPurple.withOpacity(0.2) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentPurple : Colors.transparent,
            width: 1
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: QueryArtworkWidget(
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
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(song.artist ?? "未知", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
                   onChanged: (val) {
                      setState(() {
                        if (val == true) _selectedIds.add(song.id);
                        else _selectedIds.remove(song.id);
                      });
                   },
                 ),
               )
            else ...[
              Consumer(
                builder: (context, ref, child) {
                  final favorites = ref.watch(favoriteProvider);
                  final isFav = favorites.contains(song.id);
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, 
                      color: isFav ? Colors.redAccent : Colors.white38, size: 24),
                    onPressed: () => ref.read(favoriteProvider.notifier).toggleFavorite(song.id),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white38),
                onPressed: () {
                   showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (ctx) => SongOptionMenu(song: song),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}