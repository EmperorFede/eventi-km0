import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventi_km0/main.dart';
import 'package:eventi_km0/state/app_state.dart';
import 'package:eventi_km0/state/archivio_eventi.dart';

void main() {
  testWidgets('senza chiave IA mostra il benvenuto e nessun evento finto', (tester) async {
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

    expect(find.text('Prato · raggio 25 km'), findsOneWidget);
    // Il benvenuto c'è sia in Vicino sia in In Italia.
    expect(find.text('Benvenuto in Eventi KM0'), findsWidgets);
    expect(find.text('Aggiungi la chiave IA'), findsWidgets);
    expect(find.text('Sagra della castagna'), findsNothing);
  });
}
