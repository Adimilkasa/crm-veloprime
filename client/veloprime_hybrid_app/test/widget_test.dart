import 'package:flutter_test/flutter_test.dart';

import 'package:veloprime_hybrid_app/app.dart';

void main() {
  testWidgets('login screen renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(const VeloPrimeApp());

    expect(find.text('VeloPrime Hybrid Client'), findsOneWidget);
    expect(find.text('Zaloguj'), findsOneWidget);
  });
}
