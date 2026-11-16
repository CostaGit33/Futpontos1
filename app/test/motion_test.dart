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
}
