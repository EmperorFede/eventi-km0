import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/archivio_eventi.dart';
import '../widgets/lista_eventi.dart';
import '../widgets/stato_sezione.dart';

class ItaliaScreen extends StatelessWidget {
  const ItaliaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archivio = context.watch<ArchivioEventi>();
    return Scaffold(
      appBar: AppBar(title: const Text('In Italia')),
      body: ListaEventi(
        eventi: archivio.eventiItalia,
        onAggiorna: archivio.usaEsempi ? null : archivio.aggiornaItalia,
        intestazione: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Eventi da non perdere, anche lontani dalla tua zona',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            StatoSezione(
              sezione: archivio.italia,
              usaEsempi: archivio.usaEsempi,
              onAggiorna: archivio.aggiornaItalia,
            ),
          ],
        ),
      ),
    );
  }
}
