import 'package:dartotsu/Screen/Reader/Components/ReaderPinch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('two fingers zoom the page and one finger leaves it alone', (
    tester,
  ) async {
    final zoomed = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPinch(
          settle: const Duration(milliseconds: 100),
          onZoom: zoomed.add,
          child: const SizedBox.expand(key: Key('page')),
        ),
      ),
    );
    final page = find.byKey(const Key('page'));
    final size = tester.getSize(page);
    final one = await tester.startGesture(const Offset(200, 300));
    await one.moveBy(const Offset(0, 50));
    await one.up();
    expect(zoomed, isEmpty);

    final a = await tester.startGesture(const Offset(150, 300));
    final b = await tester.startGesture(const Offset(250, 300));
    await a.moveBy(const Offset(-50, 0));
    await b.moveBy(const Offset(50, 0));
    await tester.pump();
    final shown = tester.getBottomRight(page) - tester.getTopLeft(page);
    expect(shown.dx, closeTo(size.width * 2, 1));
    expect(shown.dy, closeTo(size.height * 2, 1));
    expect(zoomed, [true]);

    await a.up();
    await b.up();
    await tester.pump();
  });

  testWidgets('pinching back in resets the zoom', (tester) async {
    final zoomed = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPinch(
          settle: const Duration(milliseconds: 100),
          onZoom: zoomed.add,
          child: const SizedBox.expand(key: Key('page')),
        ),
      ),
    );
    final a = await tester.startGesture(const Offset(100, 300));
    final b = await tester.startGesture(const Offset(200, 300));
    await a.moveBy(const Offset(-60, 0));
    await b.moveBy(const Offset(60, 0));
    await a.moveBy(const Offset(60, 0));
    await b.moveBy(const Offset(-60, 0));
    await a.up();
    await b.up();
    await tester.pump();
    expect(zoomed, [true, false]);
    expect(tester.getTopLeft(find.byKey(const Key('page'))), Offset.zero);
  });

  testWidgets('zooming out shrinks the page and letting go snaps it back', (
    tester,
  ) async {
    final zoomed = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ReaderPinch(
          settle: const Duration(milliseconds: 100),
          onZoom: zoomed.add,
          child: const SizedBox.expand(key: Key('page')),
        ),
      ),
    );
    final page = find.byKey(const Key('page'));
    final size = tester.getSize(page);
    final a = await tester.startGesture(const Offset(100, 300));
    final b = await tester.startGesture(const Offset(300, 300));
    await a.moveBy(const Offset(60, 0));
    await b.moveBy(const Offset(-60, 0));
    await tester.pump();
    final shown = tester.getBottomRight(page) - tester.getTopLeft(page);
    expect(shown.dx, lessThan(size.width * 0.8));
    expect(zoomed, [true]);

    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(page), Offset.zero);
    expect(tester.getBottomRight(page).dx, closeTo(size.width, 0.5));
    expect(zoomed, [true, false]);
  });
}
