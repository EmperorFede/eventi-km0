import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../services/ricerca_ia.dart';
import '../state/archivio_eventi.dart';
import '../widgets/evento_card.dart';

class _Messaggio {
  const _Messaggio(this.testo, {required this.mio, this.eventi = const [], this.errore = false});
  final String testo;
  final bool mio;
  final List<Evento> eventi;
  final bool errore;
}

/// Chat con l'IA per richieste specifiche.
class ChiediScreen extends StatefulWidget {
  const ChiediScreen({super.key});

  @override
  State<ChiediScreen> createState() => _ChiediScreenState();
}

class _ChiediScreenState extends State<ChiediScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _attesa = false;
  final _messaggi = <_Messaggio>[
    const _Messaggio(
      'Ciao! Dimmi cosa cerchi, per esempio: "una cena con delitto sabato sera vicino a Prato per 2".',
      mio: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scorriInFondo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _invia() async {
    final testo = _controller.text.trim();
    if (testo.isEmpty || _attesa) return;
    _controller.clear();
    setState(() {
      _messaggi.add(_Messaggio(testo, mio: true));
      _attesa = true;
    });
    _scorriInFondo();

    _Messaggio risposta;
    try {
      final r = await context.read<ArchivioEventi>().chiedi(testo);
      risposta = _Messaggio(
        r.messaggio.isEmpty ? 'Ecco cosa ho trovato.' : r.messaggio,
        mio: false,
        eventi: r.eventi,
      );
    } on ErroreRicerca catch (e) {
      risposta = _Messaggio(e.messaggio, mio: false, errore: true);
    } catch (e) {
      risposta = _Messaggio('Qualcosa è andato storto: $e', mio: false, errore: true);
    }
    if (!mounted) return;
    setState(() {
      _messaggi.add(risposta);
      _attesa = false;
    });
    _scorriInFondo();
  }

  @override
  Widget build(BuildContext context) {
    final schema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text("Chiedi all'IA")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in _messaggi) ...[
                  Align(
                    alignment: m.mio ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.mio
                            ? schema.primary.withValues(alpha: 0.25)
                            : m.errore
                                ? schema.error.withValues(alpha: 0.15)
                                : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m.testo, style: const TextStyle(height: 1.4)),
                    ),
                  ),
                  for (final e in m.eventi) EventoCard(evento: e),
                ],
                if (_attesa)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text('Sto cercando sul web…', style: TextStyle(color: schema.onSurfaceVariant)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_attesa,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _invia(),
                      decoration: InputDecoration(
                        hintText: 'Scrivi cosa cerchi…',
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(tooltip: 'Invia', onPressed: _attesa ? null : _invia, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
