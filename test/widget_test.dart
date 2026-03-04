import 'package:flutter_test/flutter_test.dart';
import 'package:vsync_lab/app.dart';

void main() {
  testWidgets('dashboard shows baseline actions', (tester) async {
    await tester.pumpWidget(const VsyncLabApp());
    await tester.pumpAndSettle();

    expect(find.text('VSync Lab (Android only)'), findsOneWidget);
    expect(find.text('Open animation stress'), findsOneWidget);
    expect(find.text('Open scroll stress'), findsOneWidget);
  });

  testWidgets('can navigate to animation stress page', (tester) async {
    await tester.pumpWidget(const VsyncLabApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open animation stress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Animation stress'), findsOneWidget);
    expect(find.text('Live frame metrics'), findsOneWidget);
  });
}
