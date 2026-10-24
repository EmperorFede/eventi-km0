import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'state/archivio_eventi.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final stato = AppState(prefs);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: stato),
        ChangeNotifierProvider(create: (_) => ArchivioEventi(prefs, stato)),
      ],
      child: const EventiKm0App(),
    ),
  );
}

class EventiKm0App extends StatelessWidget {
  const EventiKm0App({super.key});

  @override
  Widget build(BuildContext context) {
    final stato = context.watch<AppState>();
    return MaterialApp(
      title: 'Eventi KM0',
      debugShowCheckedModeBanner: false,
      themeMode: stato.tema,
      theme: creaTema(stato.colore, Brightness.light),
      darkTheme: creaTema(stato.colore, Brightness.dark),
      home: const HomeShell(),
    );
  }
}
