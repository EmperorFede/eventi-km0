import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/archivio_eventi.dart';
import '../widgets/evento_card.dart';

class SalvatiScreen extends StatelessWidget {
  const SalvatiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventi = context.watch<ArchivioEventi>().salvati..sort((a, b) => a.inizio.compareTo(b.inizio));
    final secondario = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Salvati')),
      body: eventi.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_outline, size: 48, color: secondario),
                    const SizedBox(height: 12),
                    const Text('Salva gli eventi che ti interessano', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Tocca la stellina su un evento per ritrovarlo qui.',
                        textAlign: TextAlign.center, style: TextStyle(color: secondario)),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [for (final e in eventi) EventoCard(evento: e)],
            ),
    );
  }
}
