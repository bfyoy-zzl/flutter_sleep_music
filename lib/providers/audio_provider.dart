import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio_background/just_audio_background.dart'; // 导入后台库
import 'sleep_player_provider.dart'; 
import 'history_provider.dart';
import 'tag_provider.dart';

// === 1. 基础 Provider ===
final audioPlayerProvider = Provider<AudioPlayer>((ref) => AudioPlayer());

final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  try {
    final settingsBox = await Hive.openBox('settings');
    final bool hasScanned = settingsBox.get('has_scanned', defaultValue: false);
    if (!hasScanned) return [];

    final OnAudioQuery audioQuery = OnAudioQuery();
    List<SongModel> songs = await audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final overrides = ref.watch(tagProvider);
    if (overrides.isNotEmpty) {
      songs = songs.where((s) {
          if (overrides.containsKey(s.id)) return overrides[s.id]!.isHidden == false; 
          return true;
        }).map((originalSong) {
          if (overrides.containsKey(originalSong.id)) {
            final override = overrides[originalSong.id]!;
            Map<String, dynamic> newMap = Map<String, dynamic>.from(originalSong.getMap);
            if (override.title != null) newMap['title'] = override.title;
            if (override.artist != null) newMap['artist'] = override.artist;
            return SongModel(newMap);
          }
          return originalSong;
        }).toList();
    }
    return songs.where((s) => (s.duration ?? 0) > 90000).toList();
  } catch (e) { return []; }
});

class CurrentPlaylistNotifier extends StateNotifier<List<SongModel>> {
  CurrentPlaylistNotifier() : super([]);
  void setList(List<SongModel> list) => state = list;
}
final currentPlaylistProvider = StateNotifierProvider<CurrentPlaylistNotifier, List<SongModel>>((ref) {
  return CurrentPlaylistNotifier();
});

final currentSongIndexProvider = StateProvider<int?>((ref) => null);
final isPlayingProvider = StateProvider<bool>((ref) => false);
enum PlayMode { sequence, single, shuffle }
final playModeProvider = StateProvider<PlayMode>((ref) => PlayMode.sequence);

final currentLyricsProvider = FutureProvider<List<String>>((ref) async {
  final index = ref.watch(currentSongIndexProvider);
  final playlist = ref.watch(currentPlaylistProvider);
  if (index == null || index >= playlist.length) return [];
  if (index == 9999) return ["助眠白噪音", "专注此刻 享受宁静"];
  final song = playlist[index];
  try {
    final audioPath = song.data;
    final lrcPath = audioPath.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '.lrc');
    final lrcFile = File(lrcPath);
    if (await lrcFile.exists()) return await lrcFile.readAsLines();
  } catch (e) {}
  return [];
});

// === 2. 核心控制器 ===
class AudioController {
  final Ref ref;
  Box? _playerBox;

  AudioController(this.ref);

  AudioPlayer get _player => ref.read(audioPlayerProvider);

  Future<void> init() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _initPersistence();
  }

  Future<void> scanLocalSongs() async {
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('has_scanned', true);
    ref.refresh(allSongsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
    await _initPersistence();
  }

  Future<void> deleteSong(int songId) async {
    await ref.read(tagProvider.notifier).hideSong(songId);
    ref.refresh(allSongsProvider);

    final currentList = ref.read(currentPlaylistProvider);
    final currentIndex = ref.read(currentSongIndexProvider);
    final indexToRemove = currentList.indexWhere((s) => s.id == songId);
    
    if (indexToRemove != -1) {
      final newList = List<SongModel>.from(currentList)..removeAt(indexToRemove);
      ref.read(currentPlaylistProvider.notifier).setList(newList);

      if (currentIndex != null) {
        if (indexToRemove == currentIndex) {
          if (newList.isEmpty) {
            _player.stop();
            ref.read(currentSongIndexProvider.notifier).state = null;
          } else {
            final nextIndex = indexToRemove >= newList.length ? 0 : indexToRemove;
            playSong(newList[nextIndex]); 
          }
        } else if (indexToRemove < currentIndex) {
          final newIndex = currentIndex - 1;
          ref.read(currentSongIndexProvider.notifier).state = newIndex;
          _saveState(newList, newIndex); 
        } else {
          _saveState(newList, currentIndex);
        }
      }
    }
  }

  Future<void> _initPersistence() async {
    try {
      _playerBox = await Hive.openBox('player_state');
      if (!Hive.isBoxOpen('history')) await Hive.openBox('history');
      
      final allSongs = await ref.read(allSongsProvider.future);
      if (allSongs.isEmpty) return;

      final List<dynamic>? savedIds = _playerBox?.get('playlist_ids');
      final int? savedIndex = _playerBox?.get('last_index');
      List<SongModel> initialPlaylist = [];
      int initialIndex = 0;

      if (savedIds != null && savedIds.isNotEmpty) {
        final songMap = {for (var s in allSongs) s.id: s};
        initialPlaylist = savedIds.map((id) => songMap[id]).whereType<SongModel>().toList();
        if (savedIndex != null && savedIndex < initialPlaylist.length) initialIndex = savedIndex;
      } 
      
      if (initialPlaylist.isEmpty) {
        initialPlaylist = List.from(allSongs);
        initialIndex = 0;
      }

      ref.read(currentPlaylistProvider.notifier).setList(initialPlaylist);
      ref.read(currentSongIndexProvider.notifier).state = initialIndex;

      if (initialPlaylist.isNotEmpty) {
        final song = initialPlaylist[initialIndex];
        // 【核心】初始化时也要设置 tag，否则第一次打开通知栏没信息
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(song.uri!),
            tag: MediaItem(
              id: song.id.toString(),
              album: song.album ?? "未知专辑",
              title: song.title,
              artist: song.artist ?? "未知艺术家",
              artUri: Uri.parse("content://media/external/audio/albumart/${song.albumId}"),
            ),
          ),
          initialPosition: Duration.zero,
          preload: true, 
        ).catchError((_) {});
      }
      initListeners();
    } catch (_) {}
  }

  void initListeners() {
    _player.playerStateStream.listen((state) {
      ref.read(isPlayingProvider.notifier).state = state.playing;
      if (state.processingState == ProcessingState.completed) _handleAutoNext();
    });
  }

  void _saveState(List<SongModel> playlist, int index) {
    if (_playerBox == null) return;
    _playerBox!.put('playlist_ids', playlist.map((s) => s.id).toList());
    _playerBox!.put('last_index', index);
  }

  void _handleAutoNext() {
    final mode = ref.read(playModeProvider);
    if (mode == PlayMode.single) {
      _player.seek(Duration.zero); _player.play();
    } else if (mode == PlayMode.shuffle) {
      _playRandom();
    } else {
      playNext(isAuto: true);
    }
  }

  Future<void> playSong(SongModel song, {List<SongModel>? newPlaylist}) async {
    try {
      ref.read(sleepPlayerProvider.notifier).stopAll();
      
      List<SongModel> targetList;
      if (newPlaylist != null) {
        ref.read(currentPlaylistProvider.notifier).setList(newPlaylist);
        targetList = newPlaylist;
      } else {
        targetList = ref.read(currentPlaylistProvider);
        if (targetList.isEmpty) {
            targetList = [song];
            ref.read(currentPlaylistProvider.notifier).setList(targetList);
        }
      }
      int index = targetList.indexWhere((s) => s.id == song.id);
      if (index == -1) {
        final currentIndex = ref.read(currentSongIndexProvider) ?? -1;
        final insertIndex = currentIndex + 1;
        if (insertIndex < targetList.length) {
          targetList.insert(insertIndex, song);
          index = insertIndex;
        } else {
          targetList.add(song);
          index = targetList.length - 1;
        }
        ref.read(currentPlaylistProvider.notifier).setList(targetList);
      }

      // 【核心】播放时传入 MediaItem，通知栏才能显示信息
      // 如果没有这个 tag，通知栏就是空的
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.uri!),
          // 【必须加这个 tag】通知栏才能知道现在放的是什么歌
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album ?? "未知专辑",
            title: song.title,
            artist: song.artist ?? "未知艺术家",
            // 尝试获取封面，没有则为空
            artUri: Uri.parse("content://media/external/audio/albumart/${song.albumId}"),
          ),
        )
      );
      
      // 确保音量正常
      await _player.setVolume(1.0);
      _player.play();
      
      ref.read(currentSongIndexProvider.notifier).state = index;
      ref.read(historyProvider.notifier).recordPlay(song.id);
      _saveState(targetList, index);
    } catch (e) { print("播放失败: $e"); }
  }

  Future<void> playWhiteNoise(String url) async {
     await _player.setAudioSource(
       AudioSource.uri(
         Uri.parse(url),
         tag: const MediaItem(
           id: "whitenoise",
           title: "助眠白噪音",
           artist: "梦音岛",
         )
       )
     );
     _player.play();
     ref.read(currentSongIndexProvider.notifier).state = 9999;
  }

  void togglePlay() {
    if (_player.processingState == ProcessingState.idle) {
       final list = ref.read(currentPlaylistProvider);
       final index = ref.read(currentSongIndexProvider);
       if (list.isNotEmpty && index != null && index < list.length) { 
         playSong(list[index]); 
         return; 
       }
    }

    if (_player.playing) {
      _player.pause();
    } else {
      ref.read(sleepPlayerProvider.notifier).stopAll();
      _player.play();
    }
  }
  
  void pause() => _player.pause();

  void togglePlayMode() {
    final current = ref.read(playModeProvider);
    ref.read(playModeProvider.notifier).state = PlayMode.values[(current.index + 1) % PlayMode.values.length];
  }

  void _playRandom() {
    final list = ref.read(currentPlaylistProvider);
    if (list.isNotEmpty) playSong(list[Random().nextInt(list.length)]);
  }

  void playNext({bool isAuto = false}) {
    ref.read(sleepPlayerProvider.notifier).stopAll();
    if (ref.read(playModeProvider) == PlayMode.shuffle) { _playRandom(); return; }
    final list = ref.read(currentPlaylistProvider);
    final current = ref.read(currentSongIndexProvider);
    if (list.isNotEmpty && current != null) playSong(list[(current + 1) % list.length]);
  }

  void playPrevious() {
    ref.read(sleepPlayerProvider.notifier).stopAll();
    if (ref.read(playModeProvider) == PlayMode.shuffle) { _playRandom(); return; }
    final list = ref.read(currentPlaylistProvider);
    final current = ref.read(currentSongIndexProvider);
    if (list.isNotEmpty && current != null) {
      playSong(list[current > 0 ? current - 1 : list.length - 1]);
    }
  }
}
final audioControllerProvider = Provider<AudioController>((ref) => AudioController(ref));