/// Formatos de fecha y hora en español, sin dependencias externas.
class Fmt {
  Fmt._();

  static const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  static String dosDigitos(int n) => n.toString().padLeft(2, '0');

  /// 05 oct 2026
  static String date(DateTime d) => '${dosDigitos(d.day)} ${_months[d.month - 1]} ${d.year}';

  /// 05 oct
  static String dayMonth(DateTime d) => '${dosDigitos(d.day)} ${_months[d.month - 1]}';

  static const _weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  /// Lunes, 18 nov. 2026
  static String weekdayDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${dosDigitos(d.day)} ${_months[d.month - 1]}. ${d.year}';

  /// 18 nov. 2026 – 14:32
  static String dateTime24(DateTime d) =>
      '${dosDigitos(d.day)} ${_months[d.month - 1]}. ${d.year} – ${time24(d)}';

  /// 08 / 10 / 2026
  static String dateNumeric(DateTime d) => '${dosDigitos(d.day)} / ${dosDigitos(d.month)} / ${d.year}';

  /// 10:35 a. m.
  static String time(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$h:${dosDigitos(d.minute)} ${d.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  /// 10:35 (24 h)
  static String time24(DateTime d) => '${dosDigitos(d.hour)}:${dosDigitos(d.minute)}';

  /// "Hoy, 08 oct 2026" o "01 oct 2026"
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final same = d.year == now.year && d.month == now.month && d.day == now.day;
    return same ? 'Hoy, ${date(d)}' : date(d);
  }

  /// 08 OCT (línea de tiempo)
  static String dayMonthUpper(DateTime d) => dayMonth(d).toUpperCase();

  /// "Hoy", "Ayer", "Hace 3 días"
  static String ago(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    return 'Hace $days días';
  }

  /// 0,35 · 1,2 · 850 (coma decimal, sin ceros sobrantes)
  static String decimal(num v, {int maxDecimals = 2}) {
    var s = v.toStringAsFixed(maxDecimals);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return s.replaceAll('.', ',');
  }

  /// 0,36 (siempre con el número de decimales indicado)
  static String fixed(num v, int decimals) => v.toStringAsFixed(decimals).replaceAll('.', ',');
}