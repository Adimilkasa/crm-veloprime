import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veloprime_hybrid_app/features/update/models/update_models.dart';
import 'package:veloprime_hybrid_app/features/update/presentation/update_gate_page.dart';

void main() {
  testWidgets('shows update action for application updates', (tester) async {
    const comparison = VersionComparisonResult(
      requiresAnyUpdate: true,
      requiresCriticalUpdate: false,
      items: [
        VersionComparisonItem(
          artifactType: 'APPLICATION',
          currentVersion: 'v6',
          publishedVersion: 'v7',
          priority: 'STANDARD',
          requiresUpdate: true,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateGatePage(comparison: comparison),
      ),
    );

    expect(find.text('Aktualizuj teraz'), findsOneWidget);
    expect(find.text('Wroc do aplikacji'), findsOneWidget);
  });

  testWidgets('does not show update action when application package is current', (tester) async {
    const comparison = VersionComparisonResult(
      requiresAnyUpdate: true,
      requiresCriticalUpdate: true,
      items: [
        VersionComparisonItem(
          artifactType: 'DATA',
          currentVersion: 'v1',
          publishedVersion: 'v2',
          priority: 'CRITICAL',
          requiresUpdate: true,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateGatePage(comparison: comparison),
      ),
    );

    expect(find.text('Aktualizuj teraz'), findsNothing);
    expect(find.text('Wroc do aplikacji'), findsOneWidget);
  });
}