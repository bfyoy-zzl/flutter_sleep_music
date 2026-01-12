import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/quote_provider.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import 'song_list_page.dart';

class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage> {
  String _currentQuote = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateQuote();
    });
  }

  void _updateQuote() {
    final quotes = ref.read(quoteProvider);
    setState(() {
      _currentQuote = quotes.isNotEmpty 
          ? quotes[DateTime.now().second % quotes.length] 
          : "Good Night";
    });
  }

  // 新建歌单弹窗
  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("新建歌单", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppTheme.accentPurple,
                    decoration: const InputDecoration(
                      hintText: "输入歌单名称",
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentPurple)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("取消", style: TextStyle(color: Colors.white54)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            ref.read(playlistProvider.notifier).createPlaylist(controller.text.trim());
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text("创建"),
                      ),
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

  void _playList(List<SongModel> songs) {
    if (songs.isNotEmpty) {
      ref.read(audioControllerProvider).playSong(songs[0], newPlaylist: songs);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("歌单为空")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSongsAsync = ref.watch(allSongsProvider);
    final favorites = ref.watch(favoriteProvider);
    final dynamic historyRaw = ref.watch(historyProvider); 
    final playlists = ref.watch(playlistProvider);
    
    final quotes = ref.watch(quoteProvider);
    if (_currentQuote.isEmpty) {
      _currentQuote = quotes.isNotEmpty 
          ? quotes[DateTime.now().second % quotes.length] 
          : "Good Night";
    }

    List<dynamic> historyIds = [];
    if (historyRaw is List) {
      historyIds = historyRaw;
    } else {
      try { historyIds = (historyRaw as dynamic).songIds ?? []; } catch (_) { historyIds = []; }
    }

    final allSongs = allSongsAsync.value ?? [];
    final songMap = {for (var s in allSongs) s.id: s}; 

    final List<SongModel> listAll = allSongs;
    final List<SongModel> listFav = allSongs.where((s) => favorites.contains(s.id)).toList();

    final List<SongModel> listRecent = [];
    for (var i = historyIds.length - 1; i >= 0; i--) {
      final id = historyIds[i];
      if (songMap.containsKey(id)) {
        if (!listRecent.any((s) => s.id == id)) {
          listRecent.add(songMap[id]!);
        }
      }
    }

    final Map<int, int> playCounts = {};
    for (var id in historyIds) {
      playCounts[id] = (playCounts[id] ?? 0) + 1;
    }
    final List<SongModel> listMostPlayed = playCounts.entries
        .map((e) => songMap[e.key])
        .whereType<SongModel>()
        .toList();
    listMostPlayed.sort((a, b) {
      final countA = playCounts[a.id] ?? 0;
      final countB = playCounts[b.id] ?? 0;
      return countB.compareTo(countA);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _updateQuote,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Good Night,", style: TextStyle(color: Colors.white54, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              _currentQuote, 
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif', letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchBar(context),
              ),

              const SizedBox(height: 20),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3, 
                  children: [
                    _buildMainCard(context, "全部音乐", "${listAll.length}", Icons.music_note_rounded, const Color(0xFF7B61FF), listAll),
                    _buildMainCard(context, "我的收藏", "${listFav.length}", Icons.favorite_rounded, const Color(0xFFFF5252), listFav),
                    _buildMainCard(context, "最近播放", "${listRecent.length}", Icons.history_rounded, const Color(0xFF4CB050), listRecent),
                    _buildMainCard(context, "听得最多", "${listMostPlayed.length}", Icons.bar_chart_rounded, const Color(0xFFFFA726), listMostPlayed),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("创建的歌单", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Colors.white54),
                      onPressed: _showCreatePlaylistDialog,
                    ),
                  ],
                ),
              ),
              
              if (playlists.isEmpty)
                const SizedBox.shrink()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final playlistSongs = playlist.songIds
                        .map((id) => songMap[id])
                        .whereType<SongModel>()
                        .toList();
                        
                    return _buildPlaylistItem(
                      context,
                      Icons.album_rounded, 
                      playlist.name, 
                      "${playlistSongs.length}首", 
                      Colors.orangeAccent.withOpacity(0.1), 
                      Colors.orangeAccent,
                      playlistSongs,
                      playlist.id, 
                    );
                  },
                ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // 【修改】搜索框添加毛玻璃效果
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃强度
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // 半透明背景
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Colors.white54, size: 28),
                const SizedBox(width: 15),
                const Text("搜索本地歌曲...", style: TextStyle(color: Colors.white54, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 【修改】四大金刚卡片添加毛玻璃效果
  Widget _buildMainCard(BuildContext context, String title, String count, IconData icon, Color color, List<SongModel> songs) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => SongListPage(title: title, songs: songs)));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃强度
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08), // 半透明背景
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.play_circle_fill_rounded, color: Colors.white.withOpacity(0.5), size: 32),
                      onPressed: () => _playList(songs),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("$count 首", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 【修改】自定义歌单列表项添加毛玻璃效果
  Widget _buildPlaylistItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
    List<SongModel> songs,
    String playlistId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SongListPage(title: title, songs: songs, playlistId: playlistId)
          )
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 毛玻璃强度
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05), // 半透明背景
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)), // 可选：添加细微边框增强质感
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_fill_rounded, color: Colors.white.withOpacity(0.5), size: 28),
                    onPressed: () => _playList(songs),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}