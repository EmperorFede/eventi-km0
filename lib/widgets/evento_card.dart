import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../screens/dettaglio_screen.dart';
import '../state/archivio_eventi.dart';
import '../utils/date_it.dart';

class EventoCard extends StatelessWidget {
  const EventoCard({super.key, required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final secondario = TextStyle(fontSize: 13, color: schema.onSurfaceVariant);
    final salvato = context.select<ArchivioEventi, bool>((a) => a.eSalvato(evento.id));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DettaglioScreen(evento: evento)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(evento.categoria,
                      style: TextStyle(fontSize: 12, color: schema.primary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${evento.distanzaKm.round()} km', style: secondario),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: salvato ? 'Rimuovi dai salvati' : 'Salva',
                    icon: Icon(salvato ? Icons.star : Icons.star_outline,
                        color: salvato ? schema.primary : schema.onSurfaceVariant),
                    onPressed: () => context.read<ArchivioEventi>().alternaSalvato(evento),
                  ),
                ],
              ),
              Text(evento.titolo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${formattaPeriodo(evento.inizio, evento.fine)} · ${evento.citta}', style: secondario),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final c in evento.conChi)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Tooltip(
                        message: c.etichetta,
                        child: Icon(c.icona, size: 18, color: schema.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
