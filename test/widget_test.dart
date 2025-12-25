// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kutuphane_masaustu/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize database factory for test environment if needed
    // For widget tests, we might need to mock this or ensure it doesn't crash
    // But since main() calls it, and we are pumping KutuphaneApp directly,
    // we might skip main()'s initDatabase call unless KutuphaneApp depends on it.
    // KutuphaneApp is a StatelessWidget that returns MaterialApp.
    // It doesn't seem to do DB init in build().
    // However, if any screen uses DB on init, it might fail.
    // HomeScreen uses AnimationController, but doesn't seem to load data immediately in initState.

    // Set a large surface size to simulate desktop
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const KutuphaneApp());

    // Verify that our app title is present.
    // Note: The title 'Kütüphane Yönetim Sistemi' is in the HomeScreen which is the home of MaterialApp.
    // However, HomeScreen uses animations which might take time.
    // We might need to pump frames.

    await tester.pumpAndSettle(); // Wait for animations to finish

    expect(find.text('Kütüphane Yönetim Sistemi'), findsOneWidget);
    expect(find.text('Hızlı Erişim'), findsOneWidget);

    // Reset the surface size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
