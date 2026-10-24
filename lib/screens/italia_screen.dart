import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/archivio_eventi.dart';
import '../widgets/benvenuto.dart';
import '../widgets/lista_eventi.dart';
import '../widgets/stato_sezione.dart';

class ItaliaScreen extends StatelessWidget {
  const ItaliaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final archivio = context.watch<ArchivioEventi>();
    final sottotitolo = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Eventi da non perdere, anche lontani dalla tua zona',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('In Italia')),
      body: archivio.mancaChiave
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [sottotitolo, const Benvenuto()],
            )
          : ListaEventi(
              eventi: archivio.eventiItalia,
              onAggiorna: archivio.aggiornaItalia,
              intestazione: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sottotitolo,
                  StatoSezione(sezione: archivio.italia, onAggiorna: archivio.aggiornaItalia),
                ],
              ),
            ),
    );
  }
}
