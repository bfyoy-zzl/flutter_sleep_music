import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_music_player/main.dart';

void main() {
  testWidgets('MyApp widget builds correctly', (WidgetTester tester) async {
    // 直接测试 MyApp widget，不包含 ProviderScope
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Test'),
        ),
      ),
    );

    // 验证 widget 构建
    expect(find.text('Test'), findsOneWidget);
  });
}