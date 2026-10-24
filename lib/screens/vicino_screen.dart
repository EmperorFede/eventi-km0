import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../state/archivio_eventi.dart';
import '../widgets/lista_eventi.dart';
import '../widgets/selettore_zona.dart';
import '../widgets/stato_sezione.dart';

class VicinoScreen extends StatelessWidget {
  const VicinoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stato = context.watch<AppState>();
    final archivio = context.watch<ArchivioEventi>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventi KM0'),
        actions: [
          IconButton(
            tooltip: 'Avvisi',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gli avvisi arrivano nella prossima versione')),
            ),
          ),
        ],
      ),
      body: ListaEventi(
        eventi: archivio.eventiVicino,
        onAggiorna: archivio.usaEsempi ? null : archivio.aggiornaVicino,
        intestazione: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => mostraSelettoreZona(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('${stato.zona} · raggio ${stato.raggioKm} km'),
                        const Spacer(),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            StatoSezione(
              sezione: archivio.vicino,
              usaEsempi: archivio.usaEsempi,
              onAggiorna: archivio.aggiornaVicino,
            ),
          ],
        ),
      ),
    );
  }
}
