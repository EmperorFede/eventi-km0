import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eventi_km0/services/aggiornamenti.dart';

MockClient _github(Map<String, dynamic> release, [int stato = 200]) =>
    MockClient((_) async => http.Response(jsonEncode(release), stato));

final _release = {
  'tag_name': 'v1.1.0',
  'body': 'Nuova barra del raggio',
  'assets': [
    {'name': 'note.txt', 'browser_download_url': 'https://example.com/note.txt'},
    {
      'name': 'eventi_km0-1.1.0.apk',
      'browser_download_url': 'https://github.com/x/y/releases/download/v1.1.0/eventi_km0-1.1.0.apk',
      'digest': 'sha256:abc123',
    },
  ],
};

void main() {
  test('confronta le versioni numero per numero', () {
    expect(ControlloAggiornamenti.eSuccessiva('1.1.0', '1.0.9'), isTrue);
    expect(ControlloAggiornamenti.eSuccessiva('1.10.0', '1.9.0'), isTrue);
    expect(ControlloAggiornamenti.eSuccessiva('1.0.0', '1.0.0'), isFalse);
    expect(ControlloAggiornamenti.eSuccessiva('1.0.0', '1.0.1'), isFalse);
    expect(ControlloAggiornamenti.eSuccessiva('2.0', '1.9.9'), isTrue);
  });

  test('trova la nuova versione con il suo APK', () async {
    final nuova = await ControlloAggiornamenti(client: _github(_release)).cerca('1.0.0');
    expect(nuova, isNotNull);
    expect(nuova!.versione, '1.1.0');
    expect(nuova.urlApk, endsWith('.apk'));
    expect(nuova.sha256, 'abc123');
    expect(nuova.novita, 'Nuova barra del raggio');
  });

  test('nessun aggiornamento se la versione installata è già quella', () async {
    expect(await ControlloAggiornamenti(client: _github(_release)).cerca('1.1.0'), isNull);
  });

  test('nessun aggiornamento se non è ancora stata pubblicata una versione', () async {
    expect(await ControlloAggiornamenti(client: _github({}, 404)).cerca('1.0.0'), isNull);
  });
}
