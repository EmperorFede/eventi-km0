import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../state/app_state.dart';
import '../widgets/aggiornamento.dart';
import '../widgets/selettore_zona.dart';

class StileScreen extends StatelessWidget {
  const StileScreen({super.key});

  Future<void> _mostraChiave(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CampoChiave(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stato = context.watch<AppState>();
    final titolo = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13);

    return Scaffold(
      appBar: AppBar(title: const Text('Personalizza')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('Tema', style: titolo),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Scuro'), icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: ThemeMode.light, label: Text('Chiaro'), icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_outlined)),
            ],
            selected: {stato.tema},
            onSelectionChanged: (s) => stato.impostaTema(s.first),
          ),
          const SizedBox(height: 24),
          Text('Colore principale', style: titolo),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < coloriPrincipali.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => stato.impostaColore(i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: coloriPrincipali[i],
                        shape: BoxShape.circle,
                        border: stato.indiceColore == i
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: stato.indiceColore == i ? const Icon(Icons.check, color: Colors.black87) : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Zona predefinita', style: titolo),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(stato.zona),
              subtitle: Text('Raggio ${stato.raggioKm} km'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => mostraSelettoreZona(context),
            ),
          ),
          const SizedBox(height: 16),
          Text('Ricerca con l\'IA', style: titolo),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(stato.haChiave ? Icons.key : Icons.key_off_outlined),
              title: Text(stato.haChiave ? 'Chiave IA inserita' : 'Aggiungi la chiave IA'),
              subtitle: Text(stato.haChiave
                  ? '••••${stato.chiave.substring(stato.chiave.length < 4 ? 0 : stato.chiave.length - 4)} · tocca per cambiarla'
                  : 'Senza chiave vedi solo eventi di esempio'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _mostraChiave(context),
            ),
          ),
          const SizedBox(height: 16),
          Text('Avvisi', style: titolo),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Ogni mercoledì alle 18:00'),
              subtitle: Text('Eventi del weekend e promemoria dei salvati · in arrivo'),
            ),
          ),
          const SizedBox(height: 16),
          Text('App', style: titolo),
          const SizedBox(height: 8),
          Card(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, info) => ListTile(
                leading: const Icon(Icons.system_update_outlined),
                title: const Text('Controlla aggiornamenti'),
                subtitle: Text(info.hasData ? 'Versione ${info.data!.version}' : ' '),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => controllaAggiornamenti(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoChiave extends StatefulWidget {
  const _CampoChiave();

  @override
  State<_CampoChiave> createState() => _CampoChiaveState();
}

class _CampoChiaveState extends State<_CampoChiave> {
  final _controller = TextEditingController();
  bool _visibile = false;
  String? _errore;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _salva() {
    final chiave = _controller.text.trim();
    if (!chiave.startsWith('sk-ant-')) {
      setState(() => _errore = 'La chiave inizia con "sk-ant-". Incollala di nuovo.');
      return;
    }
    context.read<AppState>().impostaChiave(chiave);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final stato = context.watch<AppState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chiave IA', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Incolla la chiave creata nella console di Anthropic. Resta salvata solo su questo telefono.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: !_visibile,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Chiave',
              hintText: 'sk-ant-…',
              errorText: _errore,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _visibile ? 'Nascondi' : 'Mostra',
                icon: Icon(_visibile ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _visibile = !_visibile),
              ),
            ),
            onChanged: (_) => setState(() => _errore = null),
            onSubmitted: (_) => _salva(),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _salva, child: const Text('Salva chiave')),
          if (stato.haChiave) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                stato.impostaChiave('');
                Navigator.pop(context);
              },
              child: const Text('Rimuovi chiave'),
            ),
          ],
        ],
      ),
    );
  }
}
