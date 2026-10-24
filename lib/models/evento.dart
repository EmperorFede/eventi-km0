import 'package:flutter/material.dart';

/// Con chi è consigliato fare un evento.
enum ConChi {
  famiglia('Famiglia', Icons.family_restroom),
  amici('Amici', Icons.groups),
  coppia('Coppia', Icons.favorite_border),
  solo('Da solo', Icons.person_outline),
  cane('Con il cane', Icons.pets);

  const ConChi(this.etichetta, this.icona);
  final String etichetta;
  final IconData icona;

  static ConChi? daNome(String nome) {
    for (final c in values) {
      if (c.name == nome) return c;
    }
    return null;
  }
}

class Evento {
  const Evento({
    required this.id,
    required this.titolo,
    required this.categoria,
    required this.descrizione,
    required this.inizio,
    this.fine,
    required this.luogo,
    required this.citta,
    required this.distanzaKm,
    required this.prezzo,
    required this.conChi,
    required this.fonteUrl,
    this.lontano = false,
  });

  final String id;
  final String titolo;
  final String categoria;
  final String descrizione;
  final DateTime inizio;
  final DateTime? fine;
  final String luogo;
  final String citta;
  final double distanzaKm;
  final String prezzo;
  final List<ConChi> conChi;

  /// Link diretto alla fonte dell'informazione: deve esserci sempre.
  final String fonteUrl;

  /// true se l'evento appartiene alla sezione "In Italia".
  final bool lontano;

  String get dominioFonte => Uri.tryParse(fonteUrl)?.host.replaceFirst('www.', '') ?? fonteUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'titolo': titolo,
        'categoria': categoria,
        'descrizione': descrizione,
        'inizio': inizio.toIso8601String(),
        'fine': fine?.toIso8601String(),
        'luogo': luogo,
        'citta': citta,
        'distanzaKm': distanzaKm,
        'prezzo': prezzo,
        'conChi': [for (final c in conChi) c.name],
        'fonteUrl': fonteUrl,
        'lontano': lontano,
      };

  factory Evento.fromJson(Map<String, dynamic> j) => Evento(
        id: j['id'] as String,
        titolo: j['titolo'] as String,
        categoria: j['categoria'] as String,
        descrizione: j['descrizione'] as String,
        inizio: DateTime.parse(j['inizio'] as String),
        fine: j['fine'] == null ? null : DateTime.parse(j['fine'] as String),
        luogo: j['luogo'] as String,
        citta: j['citta'] as String,
        distanzaKm: (j['distanzaKm'] as num).toDouble(),
        prezzo: j['prezzo'] as String,
        conChi: [for (final n in (j['conChi'] as List)) ?ConChi.daNome(n as String)],
        fonteUrl: j['fonteUrl'] as String,
        lontano: j['lontano'] as bool? ?? false,
      );
}
