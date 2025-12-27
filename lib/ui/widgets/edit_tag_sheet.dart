import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/audio_provider.dart';
import '../../providers/tag_provider.dart';

class EditTagSheet extends ConsumerStatefulWidget {
  final SongModel song;

  const EditTagSheet({super.key, required this.song});

  @override
  ConsumerState<EditTagSheet> createState() => _EditTagSheetState();
}

class _EditTagSheetState extends ConsumerState<EditTagSheet> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist ?? "<未知>");
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  void _autoIdentify() {
    final fileName = widget.song.displayNameWOExt;
    if (fileName.contains('-')) {
      final parts = fileName.split('-');
      if (parts.length >= 2) {
        setState(() {
          _artistController.text = parts[0].trim();
          _titleController.text = parts.sublist(1).join('-').trim();
        });
        // 【已修改】移除成功提示
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已尝试从文件名智能识别")));
        return;
      }
    }
    // 【已修改】移除失败提示
    // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("文件名格式无法识别，请手动输入")));
  }
// ... 前面的代码不变 ...

  Future<void> _save() async {
    final newTitle = _titleController.text.trim();
    final newArtist = _artistController.text.trim();

    if (newTitle.isEmpty) {
      // 这里的错误提示建议保留，否则用户不知道为什么没反应
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("歌名不能为空")));
      return;
    }

    // 1. 保存到 Hive
    await ref.read(tagProvider.notifier).updateTag(
      widget.song.id, 
      newTitle, 
      newArtist
    );

    // 2. 刷新全部歌曲
    final newAllSongs = await ref.refresh(allSongsProvider.future);

    // 3. 同步更新播放列表
    final currentPlaylist = ref.read(currentPlaylistProvider);
    try {
      final updatedSong = newAllSongs.firstWhere((s) => s.id == widget.song.id);
      final newPlaylist = currentPlaylist.map((s) {
        return s.id == widget.song.id ? updatedSong : s;
      }).toList();
      ref.read(currentPlaylistProvider.notifier).setList(newPlaylist);
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
      // 【已修改】注释掉下面这一行，保存成功不再弹出提示
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("标签已更新")));
    }
  }

// ... 后面的代码不变 ...

  @override
  Widget build(BuildContext context) {
    // 获取键盘高度
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 点击空白处收起键盘
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Stack(
          children: [
            // 1. 背景：更通透的毛玻璃
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  // 【修复】透明度改为 0.3，不再那么黑
                  color: const Color(0xFF2C2C2C).withOpacity(0.3),
                ),
              ),
            ),
            
            // 2. 内容：支持滚动 + 键盘顶起
            SingleChildScrollView(
              child: Padding(
                // 【修复】底部增加 padding = 键盘高度，把内容顶上去
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 高度自适应
                    children: [
                      // 顶部栏
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "编辑标签", 
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            TextButton.icon(
                              onPressed: _autoIdentify,
                              icon: const Icon(Icons.auto_fix_high, size: 16, color: AppTheme.accentPurple),
                              label: const Text("自动识别", style: TextStyle(color: AppTheme.accentPurple, fontSize: 14)),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(height: 1, color: Colors.white10),
                      
                      // 输入框区域
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                        child: Column(
                          children: [
                            _buildTextField("歌曲名", _titleController),
                            const SizedBox(height: 20),
                            _buildTextField("歌手", _artistController),
                          ],
                        ),
                      ),

                      // 底部按钮
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("取消", style: TextStyle(color: Colors.white54)),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentPurple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                              ),
                              child: const Text("保存"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppTheme.accentPurple,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 8), // 垂直居中微调
              ),
            ),
          ),
        ),
      ],
    );
  }
}