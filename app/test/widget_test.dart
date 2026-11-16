import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:futpontos1/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exibe login antes de liberar o aplicativo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      // A instalação limpa não possui token salvo; a leitura deve retornar null.
      return null;
    });
    await tester.pumpWidget(const FutPontosApp());
    await tester.pumpAndSettle();

    expect(find.text('FUTPONTOS'), findsOneWidget);
    expect(find.text('Entre para acessar o aplicativo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Não tenho conta — cadastrar'), findsOneWidget);
    expect(find.text('Início'), findsNothing);
  });
}
