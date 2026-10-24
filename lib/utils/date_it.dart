const _giorni = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
const _mesi = ['gen', 'feb', 'mar', 'apr', 'mag', 'giu', 'lug', 'ago', 'set', 'ott', 'nov', 'dic'];

String _ora(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

String _giorno(DateTime d) => '${_giorni[d.weekday - 1]} ${d.day} ${_mesi[d.month - 1]}';

/// Es. "Sab 25 ott · 20:30" oppure "Sab 25 ott – Dom 26 ott".
String formattaPeriodo(DateTime inizio, DateTime? fine) {
  if (fine == null || _stessoGiorno(inizio, fine)) {
    return '${_giorno(inizio)} · ${_ora(inizio)}';
  }
  return '${_giorno(inizio)} – ${_giorno(fine)}';
}

bool _stessoGiorno(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
