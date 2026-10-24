import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/categorie.dart';
import '../models/evento.dart';

/// Errore mostrabile all'utente, già scritto in italiano.
class ErroreRicerca implements Exception {
  const ErroreRicerca(this.messaggio);
  final String messaggio;

  @override
  String toString() => messaggio;
}

/// Risultato di una ricerca: un breve messaggio dell'IA più gli eventi trovati.
class RisultatoRicerca {
  const RisultatoRicerca({required this.messaggio, required this.eventi});
  final String messaggio;
  final List<Evento> eventi;
}

/// Cerca eventi reali sul web tramite l'API di Claude (strumento web_search)
/// e li riceve in forma strutturata tramite lo strumento `salva_eventi`.
class RicercaIA {
  RicercaIA(this.chiave, {this.categoriePersonali = const [], http.Client? client})
      : _http = client ?? http.Client();

  final String chiave;

  /// Categorie aggiunte dall'utente (es. "Partite di calcio"): l'IA le cerca apposta.
  final List<String> categoriePersonali;
  final http.Client _http;

  static const _modello = 'claude-opus-5-5';
  static final _url = Uri.parse('https://api.anthropic.com/v1/messages');

  /// Quante volte il modello può riprendere un turno lungo (stop_reason "pause_turn").
  static const _maxRiprese = 4;

  Future<RisultatoRicerca> cercaVicino({required String zona, required int raggioKm}) {
    return _cerca(
      zona: zona,
      maxRicerche: 8,
      lontano: false,
      richiesta: 'Trova eventi e iniziative nei prossimi 30 giorni entro $raggioKm km da $zona. '
          'Cerca in modo ampio: sagre, feste di paese, concerti, serate, teatro, cene con delitto, '
          'mostre, mercatini, fiere, eventi di motori (raduni, rally, esposizioni), sport, '
          'eventi per bambini e famiglie, attività all\'aperto, eventi a cui portare il cane, '
          'promozioni e giornate speciali nei negozi. Punta a 10-25 eventi diversi.',
    );
  }

  Future<RisultatoRicerca> cercaItalia({required String zona}) {
    return _cerca(
      zona: zona,
      maxRicerche: 6,
      lontano: true,
      richiesta: 'Trova gli eventi più belli e importanti in tutta Italia nei prossimi 60 giorni, '
          'quelli per cui vale la pena viaggiare: grandi mercatini, fiere famose, festival, '
          'sagre storiche, grandi raduni ed esposizioni. Calcola la distanza da $zona. '
          'Punta a 10-20 eventi di regioni diverse.',
    );
  }

  /// Domanda libera dalla schermata "Chiedi".
  Future<RisultatoRicerca> chiedi({required String domanda, required String zona, required int raggioKm}) {
    return _cerca(
      zona: zona,
      maxRicerche: 5,
      lontano: false,
      richiesta: 'La mia zona è $zona (raggio abituale $raggioKm km). Richiesta: $domanda',
    );
  }

  Future<RisultatoRicerca> _cerca({
    required String zona,
    required int maxRicerche,
    required bool lontano,
    required String richiesta,
  }) async {
    final oggi = DateTime.now();
    final personali = categoriePersonali.isEmpty
        ? ''
        : ' Cerca apposta anche eventi per queste mie categorie, usando esattamente questi nomi: '
            '${categoriePersonali.map((c) => '"$c"').join(', ')}.';
    final messaggi = <Map<String, dynamic>>[
      {
        'role': 'user',
        'content': 'Oggi è ${_dataIso(oggi)}. $richiesta$personali',
      },
    ];

    for (var ripresa = 0; ripresa <= _maxRiprese; ripresa++) {
      final risposta = await _invia(messaggi, zona: zona, maxRicerche: maxRicerche);
      final contenuto = (risposta['content'] as List).cast<Map<String, dynamic>>();

      switch (risposta['stop_reason']) {
        case 'tool_use':
          final chiamata = contenuto.lastWhere(
            (b) => b['type'] == 'tool_use' && b['name'] == 'salva_eventi',
            orElse: () => const {},
          );
          if (chiamata.isEmpty) throw const ErroreRicerca('Risposta inattesa dall\'IA. Riprova.');
          return _leggiRisultato(chiamata['input'] as Map<String, dynamic>, lontano: lontano);
        case 'pause_turn':
          // Il turno è lungo (molte ricerche): si rimanda il contenuto così com'è per continuare.
          messaggi.add({'role': 'assistant', 'content': contenuto});
          continue;
        case 'refusal':
          throw const ErroreRicerca('L\'IA non ha potuto rispondere a questa richiesta.');
        case 'max_tokens':
          throw const ErroreRicerca('La risposta era troppo lunga. Prova a restringere la ricerca.');
        default:
          // Nessun evento salvato: si mostra comunque il testo dell'IA, se c'è.
          final testo = contenuto.where((b) => b['type'] == 'text').map((b) => b['text']).join('\n').trim();
          return RisultatoRicerca(messaggio: testo.isEmpty ? 'Nessun evento trovato.' : testo, eventi: const []);
      }
    }
    throw const ErroreRicerca('La ricerca ci sta mettendo troppo. Riprova tra poco.');
  }

  Future<Map<String, dynamic>> _invia(
    List<Map<String, dynamic>> messaggi, {
    required String zona,
    required int maxRicerche,
  }) async {
    final corpo = {
      'model': _modello,
      'max_tokens': 16000,
      // Se il modello rifiuta per un falso allarme dei filtri, l'API riprova da sola con un altro modello.
      'fallbacks': 'default',
      'output_config': {'effort': 'medium'},
      'system': _istruzioni,
      'tools': [
        {
          'type': 'web_search_20260209',
          'name': 'web_search',
          'max_uses': maxRicerche,
          'user_location': {
            'type': 'approximate',
            'city': zona,
            'country': 'IT',
            'timezone': 'Europe/Rome',
          },
        },
        _strumentoSalvaEventi,
      ],
      'messages': messaggi,
    };

    final http.Response r;
    try {
      r = await _http
          .post(
            _url,
            headers: {
              'content-type': 'application/json',
              'x-api-key': chiave,
              'anthropic-version': '2023-06-01',
              'anthropic-beta': 'server-side-fallback-2026-07-01',
            },
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(minutes: 5));
    } on Exception {
      throw const ErroreRicerca('Connessione non riuscita. Controlla internet e riprova.');
    }

    final dati = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode == 200) return dati;

    final dettaglio = (dati['error'] as Map?)?['message'] ?? '';
    throw ErroreRicerca(switch (r.statusCode) {
      401 => 'Chiave IA non valida. Controllala nella schermata Stile.',
      402 || 403 => 'Credito esaurito o accesso negato. Controlla il credito nella console di Anthropic.',
      429 => 'Troppe richieste in poco tempo. Riprova tra un minuto.',
      >= 500 => 'Il servizio IA non è disponibile al momento. Riprova più tardi.',
      _ => 'Errore ${r.statusCode}: $dettaglio',
    });
  }

  RisultatoRicerca _leggiRisultato(Map<String, dynamic> input, {required bool lontano}) {
    final eventi = <Evento>[];
    for (final e in (input['eventi'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final inizio = DateTime.tryParse(e['data_inizio'] as String? ?? '');
      final fonte = e['fonte_url'] as String? ?? '';
      // Senza data o senza link alla fonte l'evento non si mostra.
      if (inizio == null || !fonte.startsWith('http')) continue;
      final fine = DateTime.tryParse(e['data_fine'] as String? ?? '');
      final titolo = e['titolo'] as String;
      eventi.add(Evento(
        id: '${titolo.toLowerCase()}|${inizio.toIso8601String()}'.hashCode.toRadixString(36),
        titolo: titolo,
        categoria: e['categoria'] as String,
        descrizione: e['descrizione'] as String,
        inizio: inizio,
        fine: fine,
        luogo: e['luogo'] as String,
        citta: e['citta'] as String,
        distanzaKm: (e['distanza_km'] as num).toDouble(),
        prezzo: e['prezzo'] as String,
        conChi: [for (final c in (e['con_chi'] as List)) ?ConChi.daNome(c as String)],
        fonteUrl: fonte,
        lontano: lontano,
      ));
    }
    return RisultatoRicerca(messaggio: input['messaggio'] as String? ?? '', eventi: eventi);
  }

  static String _dataIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static final _elencoCategorie = categorieBase.join(', ');

  static final _istruzioni = '''
Sei il motore di ricerca dell'app "Eventi KM0", che aiuta a scoprire cosa fare nella propria zona o in Italia.

Come lavori:
1. Usa la ricerca web per trovare eventi REALI e attuali: siti dei comuni, pro loco, organizzatori, teatri, locali, negozi, testate locali, pagine ufficiali delle fiere.
2. Includi solo eventi che hai trovato in questa ricerca e la cui data cade nel periodo richiesto. Se una data o un dettaglio non è chiaro dalla fonte, scarta l'evento: è meglio un evento in meno che uno inventato o dell'anno scorso.
3. Per ogni evento, fonte_url deve essere il link diretto alla pagina che hai letto e che conferma l'evento (preferisci la pagina dell'organizzatore o la fonte ufficiale). Mai link inventati o generici.
4. Assegna una categoria breve in italiano, al plurale e con la maiuscola, riusando sempre questi nomi: $_elencoCategorie. "Cene" raggruppa tutti gli eventi con una cena: cene con delitto, cene a tema, degustazioni, serate gastronomiche nei ristoranti. Creane una nuova solo se nessuna va bene. Se l'utente ha chiesto categorie in più, usa per quegli eventi esattamente il nome che ha scritto.
5. con_chi indica con chi è consigliato: famiglia, amici, coppia, solo, cane (cane solo se gli animali sono ammessi o l'evento è all'aperto e adatto).
6. distanza_km è la distanza stradale approssimativa dalla zona dell'utente.
7. Date nel formato AAAA-MM-GGTHH:MM:SS, ora locale italiana. Se l'orario non è indicato usa 10:00 per eventi di giorno. data_fine è null per eventi di una sola serata.
8. prezzo: breve, per esempio "Ingresso libero", "15 €", "Da 22 €", "Prezzo non indicato".

Alla fine chiama sempre lo strumento salva_eventi una sola volta con tutti gli eventi trovati, e nel campo messaggio scrivi 1-3 frasi in italiano per l'utente (per esempio cosa hai trovato di più interessante). Se non trovi nulla, chiamalo con una lista vuota e spiega il motivo nel messaggio.''';

  static const _strumentoSalvaEventi = {
    'name': 'salva_eventi',
    'description': 'Salva nell\'app gli eventi reali trovati con la ricerca web, con un breve messaggio per l\'utente. '
        'Va chiamato una sola volta, alla fine della ricerca.',
    'strict': true,
    'input_schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['messaggio', 'eventi'],
      'properties': {
        'messaggio': {'type': 'string', 'description': '1-3 frasi in italiano per l\'utente.'},
        'eventi': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'titolo', 'categoria', 'descrizione', 'data_inizio', 'data_fine', 'luogo',
              'citta', 'distanza_km', 'prezzo', 'con_chi', 'fonte_url',
            ],
            'properties': {
              'titolo': {'type': 'string'},
              'categoria': {'type': 'string'},
              'descrizione': {'type': 'string', 'description': '1-2 frasi su cosa si fa.'},
              'data_inizio': {'type': 'string', 'description': 'AAAA-MM-GGTHH:MM:SS, ora italiana'},
              'data_fine': {
                'anyOf': [
                  {'type': 'string'},
                  {'type': 'null'},
                ],
              },
              'luogo': {'type': 'string', 'description': 'Locale, piazza o indirizzo'},
              'citta': {'type': 'string', 'description': 'Città con sigla della provincia, es. "Vaiano (PO)"'},
              'distanza_km': {'type': 'number'},
              'prezzo': {'type': 'string'},
              'con_chi': {
                'type': 'array',
                'items': {
                  'type': 'string',
                  'enum': ['famiglia', 'amici', 'coppia', 'solo', 'cane'],
                },
              },
              'fonte_url': {'type': 'string', 'description': 'Link diretto alla pagina che conferma l\'evento'},
            },
          },
        },
      },
    },
  };
}
