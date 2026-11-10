import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/main.dart';

void main() {
  testWidgets('exibe a identidade FutPontos e navegação principal', (tester) async {
    await tester.pumpWidget(const FutPontosApp());
    expect(find.text('FUTPONTOS'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
  });
}
