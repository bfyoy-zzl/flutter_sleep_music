import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/animated_background.dart';
import 'hidden_songs_page.dart';
import 'quote_editor_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            title: const Text("设置", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader("功能"),
              _buildTile(
                context, 
                icon: Icons.restore_from_trash, 
                title: "已删除歌曲", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HiddenSongsPage())),
              ),
              _buildTile(
                context, 
                icon: Icons.edit_note, 
                title: "心情语录编辑", 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuoteEditorPage())),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("关于"),
              _buildTile(context, icon: Icons.email_outlined, title: "邮箱", subtitle: "bfyoy@qq.com"),
              _buildTile(context, icon: Icons.branding_watermark, title: "作者", subtitle: "Designed by 伯符yoy"),
              _buildTile(context, icon: Icons.info_outline, title: "版本", subtitle: "梦音盒v1.0.0"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTile(BuildContext context, {required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38)) : null,
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38) : null,
        onTap: onTap,
      ),
    );
  }
}