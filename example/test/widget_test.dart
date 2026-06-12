import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nf5503_flutter_example/main.dart';

void main() {
  testWidgets('renders the Cupertino probe shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(CupertinoApp), findsOneWidget);
    expect(find.text('NF5503 SDK Probe'), findsOneWidget);
    expect(find.text('扫码 SDK 测试'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('打印 SDK 测试'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('打印 SDK 测试'), findsOneWidget);
  });
}
