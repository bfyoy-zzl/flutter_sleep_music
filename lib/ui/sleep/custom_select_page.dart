import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/data/models/sleep_models.dart';
import '../../providers/sleep_data_provider.dart';
import '../../providers/sleep_player_provider.dart';
// 【核心修改】引入动画背景组件
import '../widgets/animated_background.dart'; 

class CustomSelectPage extends ConsumerStatefulWidget {
  const CustomSelectPage({super.key});

  @override
  ConsumerState<CustomSelectPage> createState() => _CustomSelectPageState();
}

class _CustomSelectPageState extends ConsumerState<CustomSelectPage> {
  List<WhiteNoiseItem> _selectedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSelection();
  }

  Future<void> _loadSavedSelection() async {
    try {
      final box = await Hive.openBox('settings');
      final List<dynamic>? savedTitles = box.get('saved_custom_mix');

      if (savedTitles != null && savedTitles.isNotEmpty) {
        final sleepData = ref.read(sleepDataProvider);
        final allItems = [...sleepData.lineItems, ...sleepData.dotItems];

        final restoredItems = allItems.where((item) {
          return savedTitles.contains(item.title);
        }).toList();

        if (restoredItems.length > 3) {
          restoredItems.removeRange(3, restoredItems.length);
        }

        setState(() {
          _selectedItems = restoredItems;
        });

        if (_selectedItems.isNotEmpty && mounted) {
           Future.delayed(const Duration(milliseconds: 100), () {
             ref.read(sleepPlayerProvider.notifier).playCustom(_selectedItems);
           });
        }
      }
    } catch (e) {
      print("Error loading custom mix: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSelection() async {
    final box = await Hive.openBox('settings');
    final titles = _selectedItems.map((e) => e.title).toList();
    await box.put('saved_custom_mix', titles);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(sleepPlayerProvider.notifier).stopAll();
      }
    });
    super.dispose();
  }

  void _toggleItem(WhiteNoiseItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (_selectedItems.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("最多只能选择 3 个声音进行混音"),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        _selectedItems.add(item);
      }
    });

    ref.read(sleepPlayerProvider.notifier).playCustom(_selectedItems);
    _saveSelection();
  }

  Gradient _parseGradient(String colorParam) {
    try {
      final colors = colorParam.split(';').map((c) {
        final hex = c.replaceFirst('#', '');
        return Color(int.parse('0x$hex'));
      }).toList();
      if (colors.length >= 2) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
    } catch (_) {}
    return LinearGradient(
      colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sleepData = ref.watch(sleepDataProvider);

    // 【核心修改】使用 Stack 包裹，底层放 AnimatedBackground
    return Stack(
      children: [
        const AnimatedBackground(), // 统一的动画背景
        Scaffold(
          backgroundColor: Colors.transparent, // 设置 Scaffold 背景透明
          appBar: AppBar(
            backgroundColor: Colors.transparent, // 设置 AppBar 背景透明
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("自选混音", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部提示栏
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.headphones, color: Colors.white54, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "已选 ${_selectedItems.length} / 3",
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const Spacer(),
                            if (_selectedItems.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedItems.clear());
                                  ref.read(sleepPlayerProvider.notifier).stopAll();
                                  _saveSelection();
                                },
                                child: const Text("清空", style: TextStyle(color: Colors.redAccent)),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      _buildSectionTitle("环境底噪 (循环)"),
                      const SizedBox(height: 15),
                      _buildGrid(sleepData.lineItems),

                      const SizedBox(height: 30),
                      _buildSectionTitle("灵动点缀 (随机)"),
                      const SizedBox(height: 15),
                      _buildGrid(sleepData.dotItems),
                      
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildGrid(List<WhiteNoiseItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        childAspectRatio: 0.85, 
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItems.contains(item);
        return _buildItemCard(item, isSelected);
      },
    );
  }

  Widget _buildItemCard(WhiteNoiseItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? _parseGradient(item.colorParam) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: isSelected 
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1) 
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Image.asset(
                "assets/icons/${item.icon}",
                width: 32,
                height: 32,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.music_note, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}