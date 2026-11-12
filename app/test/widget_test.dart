import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futpontos1/core/api_client.dart';
import 'package:futpontos1/pages/auth_page.dart';

void main() {
  testWidgets('exibe a tela de autenticação antes do aplicativo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(api: ApiClient(), onAuthenticated: () {}),
      ),
    );

    expect(find.text('FUTPONTOS'), findsOneWidget);
    expect(find.text('Entre para acessar o aplicativo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Não tenho conta — cadastrar'), findsOneWidget);
  });

  testWidgets('permite abrir o formulário de cadastro', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthPage(api: ApiClient(), onAuthenticated: () {}),
      ),
    );

    await tester.tap(find.text('Não tenho conta — cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua conta no aplicativo'), findsOneWidget);
    expect(find.text('Nome completo'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}
