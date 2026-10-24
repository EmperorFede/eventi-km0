import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:eventi_km0/models/evento.dart';
import 'package:eventi_km0/services/ricerca_ia.dart';

http.Response _json(Object corpo, [int stato = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      stato,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _chiamataSalva(List<Map<String, dynamic>> eventi) => {
      'stop_reason': 'tool_use',
      'content': [
        {'type': 'text', 'text': 'Ecco cosa ho trovato.'},
        {
          'type': 'tool_use',
          'id': 'toolu_1',
          'name': 'salva_eventi',
          'input': {'messaggio': 'Weekend pieno di sagre!', 'eventi': eventi},
        },
      ],
    };

final _sagra = {
  'titolo': 'Sagra della castagna',
  'categoria': 'Sagre',
  'descrizione': 'Caldarroste e necci.',
  'data_inizio': '2026-10-24T12:00:00',
  'data_fine': '2026-10-25T22:00:00',
  'luogo': 'Piazza del Comune',
  'citta': 'Vaiano (PO)',
  'distanza_km': 9,
  'prezzo': 'Ingresso libero',
  'con_chi': ['famiglia', 'cane'],
  'fonte_url': 'https://www.comune.vaiano.po.it/sagra',
};

void main() {
  test('invia la richiesta giusta e legge gli eventi da salva_eventi', () async {
    late Map<String, dynamic> inviato;
    late Map<String, String> intestazioni;
    final client = MockClient((req) async {
      inviato = jsonDecode(req.body) as Map<String, dynamic>;
      intestazioni = req.headers;
      return _json(_chiamataSalva([_sagra]));
    });

    final r = await RicercaIA('sk-ant-prova', client: client).cercaVicino(zona: 'Prato', raggioKm: 25);

    expect(intestazioni['x-api-key'], 'sk-ant-prova');
    expect(intestazioni['anthropic-version'], '2023-06-01');
    expect(inviato['model'], 'claude-opus-5-5');
    final tools = (inviato['tools'] as List).cast<Map<String, dynamic>>();
    expect(tools.first['type'], 'web_search_20260209');
    expect(tools.last['name'], 'salva_eventi');

    expect(r.messaggio, 'Weekend pieno di sagre!');
    expect(r.eventi, hasLength(1));
    final e = r.eventi.single;
    expect(e.titolo, 'Sagra della castagna');
    expect(e.inizio, DateTime(2026, 10, 24, 12));
    expect(e.fine, DateTime(2026, 10, 25, 22));
    expect(e.conChi, [ConChi.famiglia, ConChi.cane]);
    expect(e.lontano, isFalse);
  });

  test('chiede all\'IA di cercare apposta le categorie personali', () async {
    late String testoUtente;
    final client = MockClient((req) async {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      testoUtente = ((corpo['messages'] as List).first as Map)['content'] as String;
      return _json(_chiamataSalva([]));
    });
    await RicercaIA('k', categoriePersonali: ['Partite di calcio'], client: client)
        .cercaVicino(zona: 'Prato', raggioKm: 30);
    expect(testoUtente, contains('entro 30 km da Prato'));
    expect(testoUtente, contains('"Partite di calcio"'));
  });

  test('scarta gli eventi senza link alla fonte o senza data valida', () async {
    final client = MockClient((_) async => _json(_chiamataSalva([
          {..._sagra, 'fonte_url': ''},
          {..._sagra, 'titolo': 'Senza data', 'data_inizio': 'presto'},
          _sagra,
        ])));
    final r = await RicercaIA('k', client: client).cercaItalia(zona: 'Prato');
    expect(r.eventi.map((e) => e.titolo), ['Sagra della castagna']);
    expect(r.eventi.single.lontano, isTrue);
  });

  test('dopo pause_turn rimanda il contenuto e continua', () async {
    final richieste = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      richieste.add(jsonDecode(req.body) as Map<String, dynamic>);
      if (richieste.length == 1) {
        return _json({
          'stop_reason': 'pause_turn',
          'content': [
            {'type': 'server_tool_use', 'id': 'srv_1', 'name': 'web_search', 'input': {'query': 'sagre Prato'}},
          ],
        });
      }
      return _json(_chiamataSalva([_sagra]));
    });

    final r = await RicercaIA('k', client: client).chiedi(domanda: 'sagre?', zona: 'Prato', raggioKm: 25);
    expect(r.eventi, hasLength(1));
    final secondi = (richieste[1]['messages'] as List).cast<Map<String, dynamic>>();
    expect(secondi, hasLength(2));
    expect(secondi.last['role'], 'assistant');
  });

  test('una chiave sbagliata dà un messaggio chiaro', () async {
    final client = MockClient((_) async => _json({
          'type': 'error',
          'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'},
        }, 401));
    expect(
      RicercaIA('sbagliata', client: client).cercaVicino(zona: 'Prato', raggioKm: 25),
      throwsA(isA<ErroreRicerca>().having((e) => e.messaggio, 'messaggio', contains('Chiave IA non valida'))),
    );
  });
}
