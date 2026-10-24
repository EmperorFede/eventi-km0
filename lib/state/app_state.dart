import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Colori principali tra cui scegliere nella schermata Stile.
const coloriPrincipali = <Color>[
  Color(0xFF5DCAA5),
  Color(0xFFEF9F27),
  Color(0xFFED93B1),
  Color(0xFF85B7EB),
  Color(0xFFAFA9EC),
];

/// Preferenze dell'utente, salvate sul telefono.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _tema = ThemeMode.values[_prefs.getInt('tema') ?? ThemeMode.dark.index];
    _colore = _prefs.getInt('colore') ?? 0;
    _zona = _prefs.getString('zona') ?? 'Prato';
    _raggioKm = _prefs.getInt('raggio') ?? 25;
    _chiave = _prefs.getString('chiave_ia') ?? '';
    _categoriePersonali = _prefs.getStringList('categorie_personali') ?? [];
  }

  final SharedPreferences _prefs;

  late ThemeMode _tema;
  late int _colore;
  late String _zona;
  late int _raggioKm;
  late String _chiave;
  late List<String> _categoriePersonali;

  ThemeMode get tema => _tema;
  Color get colore => coloriPrincipali[_colore];
  int get indiceColore => _colore;
  String get zona => _zona;
  int get raggioKm => _raggioKm;

  /// Chiave dell'API di Anthropic. Resta solo su questo telefono.
  String get chiave => _chiave;
  bool get haChiave => _chiave.isNotEmpty;

  /// Categorie aggiunte dall'utente con il tasto "+".
  List<String> get categoriePersonali => List.unmodifiable(_categoriePersonali);

  /// Restituisce false se la categoria c'era già.
  bool aggiungiCategoria(String nome) {
    final pulito = nome.trim();
    if (pulito.isEmpty) return false;
    final nuovo = pulito[0].toUpperCase() + pulito.substring(1);
    if (_categoriePersonali.any((c) => c.toLowerCase() == nuovo.toLowerCase())) return false;
    _categoriePersonali.add(nuovo);
    _prefs.setStringList('categorie_personali', _categoriePersonali);
    notifyListeners();
    return true;
  }

  void rimuoviCategoria(String nome) {
    _categoriePersonali.remove(nome);
    _prefs.setStringList('categorie_personali', _categoriePersonali);
    notifyListeners();
  }

  void impostaTema(ThemeMode t) {
    _tema = t;
    _prefs.setInt('tema', t.index);
    notifyListeners();
  }

  void impostaColore(int i) {
    _colore = i;
    _prefs.setInt('colore', i);
    notifyListeners();
  }

  void impostaZona(String zona, int raggioKm) {
    _zona = zona;
    _raggioKm = raggioKm;
    _prefs.setString('zona', zona);
    _prefs.setInt('raggio', raggioKm);
    notifyListeners();
  }

  void impostaChiave(String chiave) {
    _chiave = chiave.trim();
    _prefs.setString('chiave_ia', _chiave);
    notifyListeners();
  }
}
