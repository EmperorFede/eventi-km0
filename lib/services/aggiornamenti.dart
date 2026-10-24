import 'dart:convert';

import 'package:http/http.dart' as http;

/// Repository GitHub dove vengono pubblicate le nuove versioni (APK nelle Release).
const repositoryAggiornamenti = 'EmperorFede/eventi-km0';

class NuovaVersione {
  const NuovaVersione({required this.versione, required this.novita, required this.urlApk, this.sha256});

  final String versione;
  final String novita;
  final String urlApk;

  /// Impronta del file, per controllare che il download non sia rovinato.
  final String? sha256;
}

/// Controlla su GitHub se c'è una versione più nuova di quella installata.
class ControlloAggiornamenti {
  ControlloAggiornamenti({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  /// Restituisce la nuova versione, oppure null se l'app è già aggiornata.
  Future<NuovaVersione?> cerca(String versioneInstallata) async {
    final r = await _http.get(
      Uri.https('api.github.com', '/repos/$repositoryAggiornamenti/releases/latest'),
      headers: {'accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 15));
    // 404: nessuna versione pubblicata ancora.
    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) throw Exception('GitHub ha risposto ${r.statusCode}');

    final dati = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final versione = (dati['tag_name'] as String).replaceFirst(RegExp('^v'), '');
    if (!eSuccessiva(versione, versioneInstallata)) return null;

    final apk = (dati['assets'] as List).cast<Map<String, dynamic>>().where(
          (a) => (a['name'] as String).toLowerCase().endsWith('.apk'),
        );
    if (apk.isEmpty) return null;
    final digest = apk.first['digest'] as String?;
    return NuovaVersione(
      versione: versione,
      novita: (dati['body'] as String?)?.trim() ?? '',
      urlApk: apk.first['browser_download_url'] as String,
      sha256: digest != null && digest.startsWith('sha256:') ? digest.substring(7) : null,
    );
  }

  /// true se [nuova] (es. "1.2.0") viene dopo [attuale] (es. "1.1.3").
  static bool eSuccessiva(String nuova, String attuale) {
    List<int> parti(String v) => v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parti(nuova), b = parti(attuale);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
