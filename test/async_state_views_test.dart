import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lol_nova/presentation/shared/widgets/async_state_views.dart';

void main() {
  testWidgets('AppLoadingView muestra el mensaje', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoadingView(message: 'Cargando prueba')),
      ),
    );

    expect(find.text('Cargando prueba'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppErrorView dispara el reintento', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorView(
            title: 'Fallo de prueba',
            message: 'detalle',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Fallo de prueba'), findsOneWidget);
    expect(find.text('detalle'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(retries, 1);
  });

  testWidgets('AppEmptyView muestra el mensaje', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppEmptyView(message: 'Nada por aquí')),
      ),
    );

    expect(find.text('Nada por aquí'), findsOneWidget);
  });
}
