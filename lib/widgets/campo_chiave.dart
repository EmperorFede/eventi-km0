import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';

/// Pagina della console di Anthropic dove si crea la chiave.
final consoleChiavi = Uri.parse('https://platform.claude.com/');

Future<void> mostraCampoChiave(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _CampoChiave(),
  );
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Apri la console per creare la chiave'),
              onPressed: () => launchUrl(consoleChiavi, mode: LaunchMode.externalApplication),
            ),
          ),
          const SizedBox(height: 8),
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
