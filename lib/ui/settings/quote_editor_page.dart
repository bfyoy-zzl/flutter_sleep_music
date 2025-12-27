import 'dart:ui' as ui; // 引入 UI 库以使用 ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/quote_provider.dart';
import '../widgets/animated_background.dart';

class QuoteEditorPage extends ConsumerWidget {
  const QuoteEditorPage({super.key});

  // 通用的添加/编辑弹窗 (毛玻璃风格)
  void _showQuoteDialog(BuildContext context, WidgetRef ref, {int? index, String? initialText}) {
    final controller = TextEditingController(text: initialText);
    final isEditing = index != null;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // 背景遮罩
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // 背景透明
        elevation: 0, // 去除默认阴影
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20), // 高斯模糊
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                // 30% 透明度的深色背景，实现通透感
                color: const Color(0xFF2C2C2C).withOpacity(0.3), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)), // 细微边框
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "编辑语录" : "添加语录", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppTheme.accentPurple,
                    maxLines: 3, // 允许多行输入
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "输入一句话...",
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
                            if (isEditing) {
                              // 编辑模式
                              ref.read(quoteProvider.notifier).updateQuote(index, controller.text.trim());
                            } else {
                              // 添加模式
                              ref.read(quoteProvider.notifier).addQuote(controller.text.trim());
                            }
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
                        child: Text(isEditing ? "保存" : "添加"),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quoteProvider);

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
            title: const Text("编辑心情语录", style: TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.accentPurple,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showQuoteDialog(context, ref), // 添加模式
          ),
          body: ListView.builder(
            itemCount: quotes.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        quote, 
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    // 【新增】编辑按钮
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _showQuoteDialog(context, ref, index: index, initialText: quote), // 编辑模式
                    ),
                    // 删除按钮
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => ref.read(quoteProvider.notifier).removeQuote(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}