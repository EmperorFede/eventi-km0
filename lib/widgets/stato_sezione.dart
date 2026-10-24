import 'package:flutter/material.dart';

import '../state/archivio_eventi.dart';

/// Riga sopra la lista: ricerca in corso, errore o ultimo aggiornamento.
class StatoSezione extends StatelessWidget {
  const StatoSezione({
    super.key,
    required this.sezione,
    required this.onAggiorna,
  });

  final Sezione sezione;
  final VoidCallback onAggiorna;

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    final secondario = TextStyle(fontSize: 13, color: schema.onSurfaceVariant);

    Widget riquadro(IconData icona, Color colore, String testo, {Widget? azione}) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            color: colore.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icona, size: 20, color: colore),
              const SizedBox(width: 10),
              Expanded(child: Text(testo, style: const TextStyle(fontSize: 13, height: 1.35))),
              ?azione,
            ],
          ),
        );

    if (sezione.inCaricamento) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text('Sto cercando eventi sul web… può volerci un minuto o due.', style: secondario),
          ],
        ),
      );
    }
    final errore = sezione.errore;
    if (errore != null) {
      return riquadro(
        Icons.error_outline,
        schema.error,
        errore,
        azione: TextButton(onPressed: onAggiorna, child: const Text('Riprova')),
      );
    }
    final quando = sezione.aggiornataIl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((sezione.messaggio ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(sezione.messaggio!, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  quando == null ? 'Non ancora aggiornato' : 'Aggiornato ${_fa(quando)}',
                  style: secondario,
                ),
              ),
              TextButton.icon(
                onPressed: onAggiorna,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Aggiorna'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fa(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'ora';
    if (diff.inHours < 1) return '${diff.inMinutes} min fa';
    if (diff.inDays < 1) return '${diff.inHours} ore fa';
    return diff.inDays == 1 ? 'ieri' : '${diff.inDays} giorni fa';
  }
}
