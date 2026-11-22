import 'package:intl/intl.dart';

///"11/10/2026 6:07 AM"
String formatDateTime(DateTime t) => DateFormat('MM/dd/yyyy h:mm a').format(t);

// ""11/10/2026"
String formatNumericDate(DateTime t) => DateFormat('MM/dd/yy').format(t);

///"October 10, 2026", used for the archive group headers.
String formatDate(DateTime t) => DateFormat('MMMM d, y').format(t);