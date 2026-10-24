import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/aggiornamenti.dart';

/// Cerca un aggiornamento e, se c'è, chiede se installarlo.
/// Con [silenzioso] (all'avvio) non mostra nulla se l'app è aggiornata o se manca internet.
Future<void> controllaAggiornamenti(BuildContext context, {bool silenzioso = false}) async {
  // Nell'anteprima nel browser non c'è niente da installare.
  if (kIsWeb) {
    if (!silenzioso) _avviso(context, 'Gli aggiornamenti funzionano solo sul telefono');
    return;
  }
  final NuovaVersione? nuova;
  try {
    final info = await PackageInfo.fromPlatform();
    nuova = await ControlloAggiornamenti().cerca(info.version);
  } catch (_) {
    if (!silenzioso && context.mounted) _avviso(context, 'Non riesco a controllare gli aggiornamenti. Riprova più tardi.');
    return;
  }
  if (!context.mounted) return;
  if (nuova == null) {
    if (!silenzioso) _avviso(context, "Hai già l'ultima versione");
    return;
  }

  final aggiorna = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Nuova versione ${nuova!.versione}'),
      content: SingleChildScrollView(
        child: Text(
          '${nuova.novita.isEmpty ? '' : '${nuova.novita}\n\n'}'
          'I tuoi eventi salvati, le categorie e le impostazioni restano come sono.',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Più tardi')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aggiorna')),
      ],
    ),
  );
  if (aggiorna == true && context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoDownload(nuova!),
    );
  }
}

void _avviso(BuildContext context, String testo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(testo)));
}

class _DialogoDownload extends StatefulWidget {
  const _DialogoDownload(this.versione);
  final NuovaVersione versione;

  @override
  State<_DialogoDownload> createState() => _DialogoDownloadState();
}

class _DialogoDownloadState extends State<_DialogoDownload> {
  StreamSubscription<OtaEvent>? _ascolto;
  double? _progresso;
  String _stato = 'Download in corso…';
  bool _finito = false;

  @override
  void initState() {
    super.initState();
    try {
      _ascolto = OtaUpdate()
          .execute(
            widget.versione.urlApk,
            destinationFilename: 'eventi_km0.apk',
            sha256checksum: widget.versione.sha256,
          )
          .listen(_evento, onError: (Object e) => _errore('Download non riuscito: $e'));
    } catch (e) {
      _errore('Download non riuscito: $e');
    }
  }

  void _evento(OtaEvent e) {
    if (!mounted) return;
    setState(() {
      switch (e.status) {
        case OtaStatus.DOWNLOADING:
          _progresso = (double.tryParse(e.value ?? '') ?? 0) / 100;
        case OtaStatus.INSTALLING:
        case OtaStatus.INSTALLATION_DONE:
          _progresso = 1;
          _stato = 'Conferma l\'installazione nella finestra di Android.';
          _finito = true;
        case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
          _stato = 'Android chiede il permesso di installare app da Eventi KM0: '
              'attivalo nella finestra che si apre e poi tocca di nuovo Aggiorna.';
          _finito = true;
        case OtaStatus.CHECKSUM_ERROR:
          _stato = 'Il file scaricato è rovinato. Riprova.';
          _finito = true;
        default:
          _stato = 'Aggiornamento non riuscito${e.value == null ? '' : ': ${e.value}'}';
          _finito = true;
      }
    });
  }

  void _errore(String testo) {
    if (!mounted) return;
    setState(() {
      _stato = testo;
      _finito = true;
    });
  }

  @override
  void dispose() {
    _ascolto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aggiornamento ${widget.versione.versione}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: _progresso),
          const SizedBox(height: 12),
          Text(_stato),
        ],
      ),
      actions: [
        if (_finito) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
      ],
    );
  }
}
