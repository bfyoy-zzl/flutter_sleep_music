import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CustomPlaylist {
  final String id;
  final String name;
  final List<dynamic> songIds;

  CustomPlaylist({
    required this.id,
    required this.name,
    this.songIds = const [],
  });

  factory CustomPlaylist.fromMap(Map<dynamic, dynamic> map) {
    return CustomPlaylist(
      id: map['id'] as String,
      name: map['name'] as String,
      songIds: List<dynamic>.from(map['song_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'song_ids': songIds,
    };
  }
}

class PlaylistNotifier extends StateNotifier<List<CustomPlaylist>> {
  PlaylistNotifier() : super([]);

  Future<void> init() async {
    final box = await Hive.openBox('playlists');
    final List<dynamic> rawList = box.get('custom_playlists', defaultValue: []);
    state = rawList.map((e) => CustomPlaylist.fromMap(e as Map)).toList();
  }

  Future<void> createPlaylist(String name) async {
    final newPlaylist = CustomPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      songIds: [],
    );
    state = [...state, newPlaylist];
    await _saveToHive();
  }

  Future<void> deletePlaylist(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _saveToHive();
  }

  // 添加歌曲
  Future<void> addSongToPlaylist(String playlistId, dynamic songId) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        final newIds = [...playlist.songIds];
        if (!newIds.contains(songId)) {
          newIds.add(songId);
        }
        return CustomPlaylist(id: playlist.id, name: playlist.name, songIds: newIds);
      }
      return playlist;
    }).toList();
    await _saveToHive();
  }

  // 【新增】从歌单移除歌曲
  Future<void> removeSongFromPlaylist(String playlistId, dynamic songId) async {
    state = state.map((playlist) {
      if (playlist.id == playlistId) {
        final newIds = [...playlist.songIds]..remove(songId);
        return CustomPlaylist(id: playlist.id, name: playlist.name, songIds: newIds);
      }
      return playlist;
    }).toList();
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    final box = await Hive.openBox('playlists');
    final data = state.map((e) => e.toMap()).toList();
    await box.put('custom_playlists', data);
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<CustomPlaylist>>((ref) {
  final notifier = PlaylistNotifier();
  notifier.init();
  return notifier;
});