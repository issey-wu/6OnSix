import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/theme.dart';
import 'package:six_on_six/core/ui/tap_haptics.dart';

void main() {
  late List<String?> buzzes;

  setUp(() {
    buzzes = [];
    TapHaptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            buzzes.add(call.arguments as String?);
          }
          return null;
        });
  });

  tearDown(() {
    TapHaptics.enabled = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> show(WidgetTester tester, {VoidCallback? onPressed}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(onPressed: onPressed, child: const Text('Check')),
                ListTile(title: const Text('Row'), onTap: () {}),
              ],
            ),
          ),
        ),
      );

  testWidgets('a main button gives a firm tap, a row a light one', (
    tester,
  ) async {
    await show(tester, onPressed: () {});
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Row'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(buzzes, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.selectionClick',
    ]);
  });

  testWidgets('a disabled button and the Haptics setting stay quiet', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(buzzes, isEmpty);

    TapHaptics.enabled = false;
    await tester.tap(find.text('Row'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(buzzes, isEmpty);
  });
}
