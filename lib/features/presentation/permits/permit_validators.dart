import 'package:permission_app/models/data_enums.dart';

/// file validates the student's input in the permit wizard.
class PermitValidators {
  static String? notBlank(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  static final _phone = RegExp(r'^\d{7,15}$');

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Contact number is required';
    return _phone.hasMatch(v.trim()) ? null : 'Enter 7 to 15 digits, numbers only';
  }

  /// "Now" as a Manila wall-clock time (a plain DateTime), so it compares
  /// correctly with the wall-clock values the student picks.
  static DateTime manilaWall(DateTime now) {
    final m = now.toUtc().add(const Duration(hours: 8));
    return DateTime(m.year, m.month, m.day, m.hour, m.minute, m.second);
  }

  static String? returnBy(DateTime? value, DateTime now) {
    if (value == null) return 'Return time is required';
    return value.isAfter(manilaWall(now)) ? null : 'Return time must be in the future';
  }

  static String? dates(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Select your dates';
    return end.isAfter(start) ? null : 'Pick at least one night';
  }
}

/// Works out the return date and time from what the student entered.
class PermitSchedule {
  static DateTime? returnAt(
    PermitType type, {
    required DateTime now,
    required int? hour,
    required int? minute,
    DateTime? endDate,
  }) {
    if (hour == null || minute == null) return null;
    final today = PermitValidators.manilaWall(now);
    final DateTime? day = switch (type) {
      PermitType.late => DateTime(today.year, today.month, today.day),
      PermitType.overnight => DateTime(today.year, today.month, today.day + 1),
      PermitType.weekend =>
        endDate == null ? null : DateTime(endDate.year, endDate.month, endDate.day),
    };
    return day == null ? null : DateTime(day.year, day.month, day.day, hour, minute);
  }
}