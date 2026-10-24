import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/evento.dart';
import '../state/app_state.dart';
import 'evento_card.dart';

enum Periodo {
  tutto('Tutto'),
  stasera('Stasera'),
  weekend('Weekend'),
  settimana('7 giorni'),
  mese('30 giorni');

  const Periodo(this.etichetta);
  final String etichetta;

  /// Finestra di tempo [da, a) coperta dal periodo, a partire da [ora].
  (DateTime, DateTime)? finestra(DateTime ora) {
    final oggi = DateTime(ora.year, ora.month, ora.day);
    switch (this) {
      case Periodo.tutto:
        return null;
      case Periodo.stasera:
        return (ora, oggi.add(const Duration(days: 1)));
      case Periodo.weekend:
        // Il weekend in corso o il prossimo: da venerdì sera a domenica.
        final giorniAVenerdi = (DateTime.friday - ora.weekday) % 7;
        final inCorso = ora.weekday == DateTime.saturday || ora.weekday == DateTime.sunday;
        final venerdi = inCorso
            ? oggi.subtract(Duration(days: ora.weekday - DateTime.friday))
            : oggi.add(Duration(days: giorniAVenerdi));
        return (venerdi.add(const Duration(hours: 17)), venerdi.add(const Duration(days: 3)));
      case Periodo.settimana:
        return (ora, oggi.add(const Duration(days: 8)));
      case Periodo.mese:
        return (ora, oggi.add(const Duration(days: 31)));
    }
  }
}

/// Filtri per periodo e categoria + elenco di schede evento.
class ListaEventi extends StatefulWidget {
  const ListaEventi({super.key, required this.eventi, this.intestazione, this.onAggiorna});

  final List<Evento> eventi;
  final Widget? intestazione;

  /// Se presente, trascinando la lista verso il basso si aggiornano gli eventi.
  final Future<void> Function()? onAggiorna;

  @override
  State<ListaEventi> createState() => _ListaEventiState();
}

class _ListaEventiState extends State<ListaEventi> {
  Periodo _periodo = Periodo.tutto;
  String? _categoria;

  bool _nelPeriodo(Evento e) {
    final f = _periodo.finestra(DateTime.now());
    if (f == null) return true;
    final fine = e.fine ?? e.inizio.add(const Duration(hours: 3));
    return e.inizio.isBefore(f.$2) && fine.isAfter(f.$1);
  }

  /// Categorie con eventi (le più piene prima), poi quelle personali ancora vuote.
  List<String> _categorie(List<String> personali) {
    final conteggio = <String, int>{};
    for (final e in widget.eventi) {
      conteggio[e.categoria] = (conteggio[e.categoria] ?? 0) + 1;
    }
    final conEventi = conteggio.keys.toList()
      ..sort((a, b) {
        final differenza = conteggio[b]! - conteggio[a]!;
        return differenza != 0 ? differenza : a.compareTo(b);
      });
    return [...conEventi, ...personali.where((p) => !conteggio.containsKey(p))];
  }

  Future<void> _aggiungiCategoria() async {
    final nome = await showDialog<String>(context: context, builder: (_) => const _DialogoCategoria());
    if (nome == null || !mounted) return;
    final stato = context.read<AppState>();
    final aggiunta = stato.aggiungiCategoria(nome);
    final messaggero = ScaffoldMessenger.of(context);
    messaggero.hideCurrentSnackBar();
    if (!aggiunta) {
      messaggero.showSnackBar(const SnackBar(content: Text('Questa categoria c\'è già')));
      return;
    }
    final onAggiorna = widget.onAggiorna;
    messaggero.showSnackBar(SnackBar(
      content: Text(stato.haChiave
          ? 'Categoria aggiunta: la cerco alla prossima ricerca'
          : 'Categoria aggiunta: verrà cercata quando inserisci la chiave IA'),
      action: onAggiorna == null ? null : SnackBarAction(label: 'Cerca ora', onPressed: onAggiorna),
    ));
  }

  Future<void> _rimuoviCategoria(String nome) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rimuovere "$nome"?'),
        content: const Text("L'IA smetterà di cercare apposta questa categoria."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rimuovi')),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    context.read<AppState>().rimuoviCategoria(nome);
    if (_categoria == nome) setState(() => _categoria = null);
  }

  @override
  Widget build(BuildContext context) {
    final personali = context.select<AppState, List<String>>((s) => s.categoriePersonali);
    final categorie = _categorie(personali);
    final visibili = widget.eventi
        .where((e) => _categoria == null || e.categoria == _categoria)
        .where(_nelPeriodo)
        .toList()
      ..sort((a, b) => a.inizio.compareTo(b.inizio));

    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        ?widget.intestazione,
        _RigaChip(
          children: [
            for (final p in Periodo.values)
              ChoiceChip(
                label: Text(p.etichetta),
                selected: _periodo == p,
                onSelected: (_) => setState(() => _periodo = p),
              ),
          ],
        ),
        _RigaChip(
          children: [
            ChoiceChip(
              label: const Text('Tutte'),
              selected: _categoria == null,
              onSelected: (_) => setState(() => _categoria = null),
            ),
            for (final c in categorie)
              GestureDetector(
                // Tenendo premuto su una categoria personale la si può togliere.
                onLongPress: personali.contains(c) ? () => _rimuoviCategoria(c) : null,
                child: ChoiceChip(
                  avatar: personali.contains(c) ? const Icon(Icons.bookmark_outline, size: 18) : null,
                  label: Text(c),
                  selected: _categoria == c,
                  onSelected: (_) => setState(() => _categoria = c),
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Aggiungi'),
              tooltip: 'Aggiungi una categoria da far cercare all\'IA',
              onPressed: _aggiungiCategoria,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibili.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              'Nessun evento in questo periodo.\nProva a cambiare filtro o ad allargare il raggio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        for (final e in visibili) EventoCard(evento: e),
      ],
    );
    final onAggiorna = widget.onAggiorna;
    return onAggiorna == null ? lista : RefreshIndicator(onRefresh: onAggiorna, child: lista);
  }
}

class _DialogoCategoria extends StatefulWidget {
  const _DialogoCategoria();

  @override
  State<_DialogoCategoria> createState() => _DialogoCategoriaState();
}

class _DialogoCategoriaState extends State<_DialogoCategoria> {
  final _controller = TextEditingController();
  String? _errore;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _conferma() {
    final nome = _controller.text.trim();
    if (nome.isEmpty) {
      setState(() => _errore = 'Scrivi il nome della categoria');
      return;
    }
    Navigator.pop(context, nome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Scrivila come la diresti a un amico: l'IA capisce cosa intendi e la cerca apposta."),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Partite di calcio',
              errorText: _errore,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _errore = null),
            onSubmitted: (_) => _conferma(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _conferma, child: const Text('Aggiungi')),
      ],
    );
  }
}

class _RigaChip extends StatelessWidget {
  const _RigaChip({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [for (final c in children) Padding(padding: const EdgeInsets.only(right: 8), child: c)],
      ),
    );
  }
}
