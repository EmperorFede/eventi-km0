import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/evento.dart';
import '../state/archivio_eventi.dart';
import '../utils/date_it.dart';

class DettaglioScreen extends StatelessWidget {
  const DettaglioScreen({super.key, required this.evento});

  final Evento evento;

  Future<void> _apri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non riesco ad aprire il link')),
      );
    }
  }

  String get _testoCondivisione => [
        evento.titolo,
        '📅 ${formattaPeriodo(evento.inizio, evento.fine)}',
        '📍 ${evento.luogo}, ${evento.citta}',
        '💶 ${evento.prezzo}',
        '🔗 ${evento.fonteUrl}',
      ].join('\n');

  Uri get _mappa => Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${evento.luogo}, ${evento.citta}',
      });

  /// Apre Google Calendar con l'evento già compilato.
  Uri get _calendario {
    String f(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}'
        'T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}00';
    final fine = evento.fine ?? evento.inizio.add(const Duration(hours: 3));
    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': evento.titolo,
      'dates': '${f(evento.inizio)}/${f(fine)}',
      'location': '${evento.luogo}, ${evento.citta}',
      'details': 'Fonte: ${evento.fonteUrl}',
    });
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final salvato = context.select<ArchivioEventi, bool>((a) => a.eSalvato(evento.id));

    Widget riga(IconData icona, String testo) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icona, size: 20, color: schema.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(child: Text(testo, style: const TextStyle(fontSize: 15))),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(evento.categoria, style: TextStyle(color: schema.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(evento.titolo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          riga(Icons.calendar_today_outlined, formattaPeriodo(evento.inizio, evento.fine)),
          riga(Icons.place_outlined, '${evento.luogo}, ${evento.citta} · ${evento.distanzaKm.round()} km'),
          riga(Icons.confirmation_number_outlined, evento.prezzo),
          const SizedBox(height: 6),
          Text(evento.descrizione, style: TextStyle(fontSize: 15, height: 1.5, color: schema.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: const Text('Apri nella mappa'),
            onPressed: () => _apri(context, _mappa),
          ),
          const SizedBox(height: 20),
          const Text('Consigliato con', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in evento.conChi) Chip(avatar: Icon(c.icona, size: 18), label: Text(c.etichetta)),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.link, color: schema.primary),
              title: const Text('Fonte'),
              subtitle: Text(evento.dominioFonte),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _apri(context, Uri.parse(evento.fonteUrl)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Azione(
                  icona: salvato ? Icons.star : Icons.star_outline,
                  etichetta: salvato ? 'Salvato' : 'Salva',
                  onTap: () => context.read<ArchivioEventi>().alternaSalvato(evento),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Azione(
                  icona: Icons.share_outlined,
                  etichetta: 'Condividi',
                  onTap: () => SharePlus.instance.share(ShareParams(text: _testoCondivisione)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Azione(
                  icona: Icons.event_available_outlined,
                  etichetta: 'Calendario',
                  onTap: () => _apri(context, _calendario),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Azione extends StatelessWidget {
  const _Azione({required this.icona, required this.etichetta, required this.onTap});

  final IconData icona;
  final String etichetta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icona, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(etichetta, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
