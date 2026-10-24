import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventi_km0/main.dart';
import 'package:eventi_km0/screens/vicino_screen.dart';
import 'package:eventi_km0/state/app_state.dart';
import 'package:eventi_km0/state/archivio_eventi.dart';

void main() {
  testWidgets('senza chiave la schermata Vicino mostra gli eventi di esempio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final stato = AppState(prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: stato),
          ChangeNotifierProvider(create: (_) => ArchivioEventi(prefs, stato)),
        ],
        child: const EventiKm0App(),
      ),
    );

    expect(find.text('Eventi KM0'), findsOneWidget);
    expect(find.text('Prato · raggio 25 km'), findsOneWidget);
    expect(find.textContaining('eventi di esempio'), findsOneWidget);
    final listaVicino = find.descendant(of: find.byType(VicinoScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Sagra della castagna'), 200, scrollable: listaVicino);
    expect(find.text('Sagra della castagna'), findsOneWidget);
  });
}
