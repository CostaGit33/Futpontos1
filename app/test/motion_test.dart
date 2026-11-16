import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/widgets/motion.dart';

void main() {
  testWidgets('movimento reduzido exibe o conteúdo sem animação', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MotionReveal(child: Text('Conteúdo')),
                MotionNumber(value: 17),
                MotionProgressBar(value: .75),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Conteúdo'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('MotionTap executa a ação ao toque', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MotionTap(
              onTap: () => tapped = true,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Toque'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Toque'));
    expect(tapped, isTrue);
  });
}
