//time helpers to convert to manila

/// Manila wall-clock time as a DateTime whose fields read as Manila time.
DateTime manilaWall(DateTime t) => t.toUtc().add(const Duration(hours: 8));

/// "2026-11-03", the Manila calendar day of [t]. Used in doc ids.
String manilaDayKey(DateTime t) {
  final m = manilaWall(t);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${m.year}-${two(m.month)}-${two(m.day)}';
}

/// 12:00 AM Manila of [t]'s Manila day, as a UTC instant.
DateTime manilaDayStart(DateTime t) {
  final m = manilaWall(t);
  return DateTime.utc(m.year, m.month, m.day).subtract(const Duration(hours: 8));
}