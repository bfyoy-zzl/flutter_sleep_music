import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/favorite_provider.dart';
import '../widgets/common_progress_bar.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/edit_tag_sheet.dart';

class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // 手动请求权限并扫描
  Future<void> _requestAndScan() async {
    // 请求多个权限以适配不同 Android 版本
    // Android 13+ 需要 Permission.audio
    // Android 12及以下 需要 Permission.storage
    Map<Permission, PermissionStatus> statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    // 只要有其中一个被授予，就算成功
    bool isGranted = statuses[Permission.audio] == PermissionStatus.granted || 
                     statuses[Permission.storage] == PermissionStatus.granted;

    if (isGranted) {
      // 获得权限后，刷新列表
      ref.read(audioControllerProvider).scanLocalSongs();
    } else {
      if (mounted) {
        // 如果被永久拒绝，建议引导用户去设置页
        if (statuses[Permission.audio] == PermissionStatus.permanentlyDenied ||
            statuses[Permission.storage] == PermissionStatus.permanentlyDenied) {
           showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               title: const Text("权限说明"),
               content: const Text("请在设置中开启音频访问权限，否则无法扫描本地音乐。"),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
                 TextButton(onPressed: () => openAppSettings(), child: const Text("去设置")),
               ],
             )
           );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("需要权限才能扫描音乐")));
        }
      }
    }
  }

  // 弹出当前播放列表
  void _showCurrentPlaylist(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PlaylistBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final currentIndex = ref.watch(currentSongIndexProvider);
    final songListAsync = ref.watch(allSongsProvider);
    final playMode = ref.watch(playModeProvider);
    final currentPlaylist = ref.watch(currentPlaylistProvider);

    if (isPlaying) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: songListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
        error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.white))),
        data: (songs) {
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note_rounded, size: 80, color: Colors.white24), // 圆润图标
                  const SizedBox(height: 20),
                  const Text("暂无本地音乐", style: TextStyle(color: Colors.white54, fontSize: 18)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _requestAndScan,
                    icon: const Icon(Icons.search_rounded), // 圆润图标
                    label: const Text("扫描本地音乐"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }

          // 【关键修复】从 currentPlaylist 获取当前歌曲，而不是从 allSongs
          final currentSong = currentIndex != null && currentIndex < currentPlaylist.length
              ? currentPlaylist[currentIndex]
              : (currentPlaylist.isNotEmpty ? currentPlaylist[0] : songs[0]);

          return Column(
            children: [
              _buildHeader(),
              
              // 1. 唱片区域
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => EditTagSheet(song: currentSong),
                      );
                    },
                    child: RotationTransition(
                      turns: _rotationController,
                      child: _buildVinylRecord(currentSong),
                    ),
                  ),
                ),
              ),
              
              // 2. 歌词区域
              const SizedBox(
                height: 160, 
                child: LyricsView(), 
              ),
              
              const SizedBox(height: 20),
              
              // 3. 控制区域
              _buildControls(ref, currentSong, isPlaying, currentIndex, songs, playMode),
              
              const SizedBox(height: 120),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox(height: 60); 
  }

  Widget _buildVinylRecord(SongModel song) {
    return Container(
      width: 240, height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: const Color(0xFF222222), width: 8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkWidth: 160,
              artworkHeight: 160,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                width: 160, height: 160, color: AppTheme.accentPurple,
                child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.white54), // 圆润图标
              ),
            ),
          ),
          Container(width: 15, height: 15, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildControls(
      WidgetRef ref, 
      SongModel song, 
      bool isPlaying, 
      int? currentIndex, 
      List<SongModel> songs, 
      PlayMode mode) {
    final controller = ref.read(audioControllerProvider);

    IconData modeIcon;
    Color modeColor = Colors.white70;
    switch (mode) {
      case PlayMode.single:
        modeIcon = Icons.repeat_one_rounded; // 圆润图标
        modeColor = AppTheme.accentPurple;
        break;
      case PlayMode.shuffle:
        modeIcon = Icons.shuffle_rounded; // 圆润图标
        modeColor = AppTheme.accentPurple;
        break;
      case PlayMode.sequence:
        modeIcon = Icons.repeat_rounded; // 圆润图标
        modeColor = Colors.white70;
        break;
    }

    return Column(
      children: [
        // 歌名和歌手区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                     showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => EditTagSheet(song: song),
                      );
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(song.artist ?? "未知艺术家", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final favorites = ref.watch(favoriteProvider);
                  final isLiked = favorites.contains(song.id);
                  return IconButton(
                    onPressed: () => ref.read(favoriteProvider.notifier).toggleFavorite(song.id),
                    // 【修改】圆润心形图标
                    icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isLiked ? Colors.redAccent : Colors.white38, size: 28),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: CommonProgressBar(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: Icon(modeIcon, color: modeColor), onPressed: () => controller.togglePlayMode()),
            
            // 【修改】圆润上一首
            IconButton(icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36), onPressed: () => controller.playPrevious()),
            
            GestureDetector(
              onTap: () {
                if (currentIndex == null && songs.isNotEmpty) {
                  controller.playSong(songs[0], newPlaylist: songs);
                } else {
                  controller.togglePlay();
                }
              },
              child: Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentPurple),
                // 【修改】圆润播放/暂停
                child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
            
            // 【修改】圆润下一首
            IconButton(icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36), onPressed: () => controller.playNext()),
            
            // 【修改】圆润列表
            IconButton(icon: const Icon(Icons.queue_music_rounded, color: Colors.white70), onPressed: () => _showCurrentPlaylist(context)),
          ],
        ),
      ],
    );
  }
}

// === PlaylistBottomSheet (搜索修复版 + 圆润图标) ===
class PlaylistBottomSheet extends ConsumerStatefulWidget {
  const PlaylistBottomSheet({super.key});

  @override
  ConsumerState<PlaylistBottomSheet> createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends ConsumerState<PlaylistBottomSheet> {
  bool isSearching = false;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentPlaylist = ref.watch(currentPlaylistProvider);
    final allSongs = ref.watch(allSongsProvider).value ?? [];
    final currentIndex = ref.watch(currentSongIndexProvider);

    final displayList = isSearching
        ? allSongs.where((s) {
            final query = searchQuery.toLowerCase();
            final titleMatch = s.title.toLowerCase().contains(query);
            final artistMatch = s.artist?.toLowerCase().contains(query) ?? false;
            return titleMatch || artistMatch;
          }).toList()
        : currentPlaylist;

    final modalHeight = MediaQuery.of(context).size.height * 0.7;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          Container(
            height: modalHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
              ),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.1)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
                  child: isSearching 
                    ? _buildSearchBar()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              const TextSpan(text: "当前播放 ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              TextSpan(text: "(${currentPlaylist.length})", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ]),
                          ),
                          IconButton(
                            // 【修改】圆润搜索图标
                            icon: const Icon(Icons.search_rounded, color: Colors.white),
                            onPressed: () => setState(() => isSearching = true),
                          ),
                        ],
                      ),
                ),

                Expanded(
                  child: displayList.isEmpty
                      ? const Center(child: Text("未找到相关歌曲", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final song = displayList[index];
                            final isPlayingSong = currentIndex != null &&
                                                  currentIndex < currentPlaylist.length &&
                                                  currentPlaylist[currentIndex].id == song.id;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
                              leading: isPlayingSong
                                ? const Icon(Icons.equalizer_rounded, color: AppTheme.accentPurple, size: 24) // 圆润音律
                                : Text("${index + 1}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                              title: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: TextStyle(color: isPlayingSong ? AppTheme.accentPurple : Colors.white, fontSize: 16),
                                  children: _highlightSearch(song.title, searchQuery),
                                ),
                              ),
                              subtitle: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  children: _highlightSearch(song.artist ?? "<未知>", searchQuery),
                                ),
                              ),
                              onTap: () {
                                 // 将当前显示的列表设置为播放列表，确保高亮正确
                                 ref.read(audioControllerProvider).playSong(song, newPlaylist: displayList);
                                 FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppTheme.accentPurple,
        decoration: InputDecoration(
          hintText: "搜索歌名、歌手...", 
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          // 【修改】圆润搜索图标
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
          suffixIcon: IconButton(
            // 【修改】圆润关闭图标
            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
            onPressed: () => setState(() { isSearching = false; searchQuery = ""; _searchController.clear(); }),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (val) => setState(() => searchQuery = val),
      ),
    );
  }

  List<TextSpan> _highlightSearch(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: text)];
    }
    
    final matches = query.toLowerCase().allMatches(text.toLowerCase());
    int lastMatchEnd = 0;
    final List<TextSpan> spans = [];

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    return spans;
  }
}