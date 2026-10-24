import 'package:flutter/material.dart';

import '../widgets/aggiornamento.dart';
import 'chiedi_screen.dart';
import 'italia_screen.dart';
import 'salvati_screen.dart';
import 'stile_screen.dart';
import 'vicino_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    // All'apertura controlla se su GitHub c'è una versione nuova.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controllaAggiornamenti(context, silenzioso: true);
    });
  }

  static const _schermate = [
    VicinoScreen(),
    ItaliaScreen(),
    ChiediScreen(),
    SalvatiScreen(),
    StileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _schermate),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.place_outlined), selectedIcon: Icon(Icons.place), label: 'Vicino'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'In Italia'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chiedi'),
          NavigationDestination(icon: Icon(Icons.star_outline), selectedIcon: Icon(Icons.star), label: 'Salvati'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Stile'),
        ],
      ),
    );
  }
}
