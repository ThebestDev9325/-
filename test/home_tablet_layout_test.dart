import 'package:chameulin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('7-inch landscape uses the compact home header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(home: HomePage(onStart: () {})));

    expect(
      tester.getSize(find.byKey(const ValueKey('home-header'))).height,
      150,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('home-writing-card'))).height,
      greaterThan(250),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('10-inch landscape keeps the regular home header', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(home: HomePage(onStart: () {})));

    expect(
      tester.getSize(find.byKey(const ValueKey('home-header'))).height,
      210,
    );
    expect(tester.takeException(), isNull);
  });
}
