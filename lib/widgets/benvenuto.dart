import 'package:flutter/material.dart';

import 'campo_chiave.dart';

/// Mostrato finché manca la chiave IA: senza chiave l'app non può cercare eventi veri.
class Benvenuto extends StatelessWidget {
  const Benvenuto({super.key});

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final secondario = TextStyle(color: schema.onSurfaceVariant, height: 1.45);

    Widget passo(int n, String titolo, String testo) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: schema.primary.withValues(alpha: 0.2),
                child: Text('$n', style: TextStyle(fontSize: 13, color: schema.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titolo, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(testo, style: secondario),
                  ],
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.travel_explore, size: 36, color: schema.primary),
            const SizedBox(height: 10),
            const Text('Benvenuto in Eventi KM0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              "Gli eventi li cerca l'IA sul web, uno per uno, con il link alla fonte. "
              'Per farla lavorare serve una chiave, da inserire una volta sola.',
              style: secondario,
            ),
            const SizedBox(height: 18),
            passo(1, 'Controlla la zona', 'In alto: tocca per cambiare città e raggio.'),
            passo(2, 'Aggiungi la chiave IA', 'La crei sulla console di Anthropic caricando un po\' di credito.'),
            passo(3, 'Fatto', "L'app cerca subito gli eventi veri e li aggiorna da sola ogni giorno."),
            const SizedBox(height: 4),
            FilledButton.icon(
              icon: const Icon(Icons.key),
              label: const Text('Aggiungi la chiave IA'),
              onPressed: () => mostraCampoChiave(context),
            ),
          ],
        ),
      ),
    );
  }
}
