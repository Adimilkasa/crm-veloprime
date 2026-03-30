import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veloprime_hybrid_app/app.dart';

void main() {
  testWidgets('login screen renders without overflow on desktop viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const VeloPrimeApp());
    await tester.pumpAndSettle();

    expect(find.text('VELOPRIME CRM'), findsOneWidget);
    expect(find.text('Zaloguj się do centrali'), findsOneWidget);
    expect(find.text('Wejdź do CRM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
