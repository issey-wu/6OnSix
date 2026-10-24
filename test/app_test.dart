import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_on_six/app/app.dart';
import 'package:six_on_six/features/learning_path/presentation/home_screen.dart';

void main() {
  testWidgets('app boots to the learning path', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SixOnSixApp()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('6 On Six'), findsOneWidget);
    expect(find.text('Court, positions and roles'), findsOneWidget);
    expect(find.text('The court'), findsOneWidget);
  });
}
