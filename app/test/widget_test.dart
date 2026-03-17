import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clawtalk/main.dart';

void main() {
  testWidgets('App should start with ProviderScope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ClawTalkApp()));

    expect(find.text('ClawTalk'), findsOneWidget);
  });
}
