import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jw_study_v2/main.dart';

void main() {
  testWidgets('App shows the desktop sidebar on wide screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: JWStudyApp()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('JW Workspace'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('App shows the bottom navigation on compact screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: JWStudyApp()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('JW Workspace'), findsNothing);
  });
}
