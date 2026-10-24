import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Raggio di ricerca: da 5 a 100 km, a passi di 5.
const raggioMinKm = 5;
const raggioMaxKm = 100;
const passoRaggioKm = 5;

Future<void> mostraSelettoreZona(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SelettoreZona(),
  );
}

class _SelettoreZona extends StatefulWidget {
  const _SelettoreZona();

  @override
  State<_SelettoreZona> createState() => _SelettoreZonaState();
}

class _SelettoreZonaState extends State<_SelettoreZona> {
  late final TextEditingController _citta;
  late int _raggio;
  String? _errore;

  @override
  void initState() {
    super.initState();
    final stato = context.read<AppState>();
    _citta = TextEditingController(text: stato.zona);
    _raggio = stato.raggioKm.clamp(raggioMinKm, raggioMaxKm);
  }

  @override
  void dispose() {
    _citta.dispose();
    super.dispose();
  }

  void _conferma() {
    final citta = _citta.text.trim();
    if (citta.isEmpty) {
      setState(() => _errore = 'Scrivi una città o usa la tua posizione');
      return;
    }
    context.read<AppState>().impostaZona(citta, _raggio);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dove cerchi?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Usa la mia posizione'),
            // Il GPS viene collegato nel prossimo passo.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La posizione GPS arriva nel prossimo passo')),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _citta,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Oppure scrivi una città',
              hintText: 'Prato',
              errorText: _errore,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _errore = null),
            onSubmitted: (_) => _conferma(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Raggio di ricerca'),
              const Spacer(),
              Text('$_raggio km', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: _raggio.toDouble(),
            min: raggioMinKm.toDouble(),
            max: raggioMaxKm.toDouble(),
            divisions: (raggioMaxKm - raggioMinKm) ~/ passoRaggioKm,
            label: '$_raggio km',
            onChanged: (v) => setState(() => _raggio = v.round()),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _conferma, child: const Text('Conferma')),
        ],
      ),
    );
  }
}
