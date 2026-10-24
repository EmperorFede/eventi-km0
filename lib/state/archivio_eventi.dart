import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/eventi_esempio.dart';
import '../models/evento.dart';
import '../services/ricerca_ia.dart';
import 'app_state.dart';

/// Una sezione dell'app (Vicino o In Italia) con i suoi eventi salvati in memoria.
class Sezione {
  Sezione({this.eventi = const [], this.aggiornataIl, this.zona});

  List<Evento> eventi;
  DateTime? aggiornataIl;

  /// Zona e raggio per cui sono stati cercati gli eventi (es. "Prato|25").
  String? zona;

  bool inCaricamento = false;
  String? errore;
  String? messaggio;

  Map<String, dynamic> toJson() => {
        'eventi': [for (final e in eventi) e.toJson()],
        'aggiornataIl': aggiornataIl?.toIso8601String(),
        'zona': zona,
        'messaggio': messaggio,
      };

  static Sezione daJson(String? testo) {
    if (testo == null) return Sezione();
    final j = jsonDecode(testo) as Map<String, dynamic>;
    return Sezione(
      eventi: [for (final e in j['eventi'] as List) Evento.fromJson(e as Map<String, dynamic>)],
      aggiornataIl: j['aggiornataIl'] == null ? null : DateTime.parse(j['aggiornataIl'] as String),
      zona: j['zona'] as String?,
    )..messaggio = j['messaggio'] as String?;
  }
}

/// Eventi trovati dall'IA, salvati sul telefono per non ripetere ricerche (che costano).
/// Senza chiave IA mostra gli eventi di esempio.
class ArchivioEventi extends ChangeNotifier {
  ArchivioEventi(this._prefs, this._stato, {RicercaIA Function(String chiave, List<String> categorie)? creaRicerca})
      : _creaRicerca = creaRicerca ?? ((chiave, categorie) => RicercaIA(chiave, categoriePersonali: categorie)) {
    vicino = Sezione.daJson(_prefs.getString('sezione_vicino'));
    italia = Sezione.daJson(_prefs.getString('sezione_italia'));
    final salvati = [
      for (final j in (jsonDecode(_prefs.getString('salvati_eventi') ?? '[]') as List))
        Evento.fromJson(j as Map<String, dynamic>),
    ];
    _salvati = {for (final e in salvati) e.id: e};
    _stato.addListener(aggiornaSeServe);
    aggiornaSeServe();
  }

  final SharedPreferences _prefs;
  final AppState _stato;
  final RicercaIA Function(String chiave, List<String> categorie) _creaRicerca;

  RicercaIA _ricerca() => _creaRicerca(_stato.chiave, _stato.categoriePersonali);

  late Sezione vicino;
  late Sezione italia;
  late Map<String, Evento> _salvati;

  /// Ogni quanto rifare la ricerca da sola.
  static const validitaVicino = Duration(hours: 24);
  static const validitaItalia = Duration(days: 7);

  bool get usaEsempi => !_stato.haChiave;

  String get _chiaveZona => '${_stato.zona}|${_stato.raggioKm}';

  List<Evento> get eventiVicino => usaEsempi
      ? eventiEsempio.where((e) => !e.lontano && e.distanzaKm <= _stato.raggioKm).toList()
      : _futuri(vicino.eventi);

  List<Evento> get eventiItalia => usaEsempi ? eventiEsempio.where((e) => e.lontano).toList() : _futuri(italia.eventi);

  List<Evento> get salvati => _futuri(_salvati.values.toList());

  bool eSalvato(String id) => _salvati.containsKey(id);

  void alternaSalvato(Evento e) {
    if (_salvati.remove(e.id) == null) _salvati[e.id] = e;
    _prefs.setString('salvati_eventi', jsonEncode([for (final s in _salvati.values) s.toJson()]));
    notifyListeners();
  }

  /// Rifà le ricerche scadute o fatte per un'altra zona.
  void aggiornaSeServe() {
    if (usaEsempi) {
      notifyListeners();
      return;
    }
    final ora = DateTime.now();
    final v = vicino.aggiornataIl;
    if (!vicino.inCaricamento && (v == null || vicino.zona != _chiaveZona || ora.difference(v) > validitaVicino)) {
      aggiornaVicino();
    }
    final i = italia.aggiornataIl;
    if (!italia.inCaricamento && (i == null || ora.difference(i) > validitaItalia)) {
      aggiornaItalia();
    }
  }

  Future<void> aggiornaVicino() => _aggiorna(
        vicino,
        'sezione_vicino',
        (r) => r.cercaVicino(zona: _stato.zona, raggioKm: _stato.raggioKm),
      );

  Future<void> aggiornaItalia() => _aggiorna(
        italia,
        'sezione_italia',
        (r) => r.cercaItalia(zona: _stato.zona),
      );

  /// Domanda libera della schermata Chiedi.
  Future<RisultatoRicerca> chiedi(String domanda) {
    if (usaEsempi) {
      throw const ErroreRicerca('Aggiungi la chiave IA nella schermata Stile per fare domande.');
    }
    return _ricerca().chiedi(domanda: domanda, zona: _stato.zona, raggioKm: _stato.raggioKm);
  }

  Future<void> _aggiorna(
    Sezione s,
    String chiavePrefs,
    Future<RisultatoRicerca> Function(RicercaIA r) cerca,
  ) async {
    if (usaEsempi || s.inCaricamento) return;
    final zona = _chiaveZona;
    s
      ..inCaricamento = true
      ..errore = null;
    notifyListeners();
    try {
      final risultato = await cerca(_ricerca());
      s
        ..eventi = risultato.eventi
        ..messaggio = risultato.messaggio
        ..aggiornataIl = DateTime.now()
        ..zona = zona;
      await _prefs.setString(chiavePrefs, jsonEncode(s.toJson()));
    } on ErroreRicerca catch (e) {
      s.errore = e.messaggio;
    } catch (e) {
      s.errore = 'Qualcosa è andato storto: $e';
    } finally {
      s.inCaricamento = false;
      notifyListeners();
    }
  }

  static List<Evento> _futuri(List<Evento> eventi) {
    final ora = DateTime.now();
    return eventi.where((e) => (e.fine ?? e.inizio.add(const Duration(hours: 3))).isAfter(ora)).toList();
  }

  @override
  void dispose() {
    _stato.removeListener(aggiornaSeServe);
    super.dispose();
  }
}
