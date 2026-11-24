import 'package:permission_app/models/data_enums.dart';

/// The student's details, taken from the profile.
class PermitFiler {
  const PermitFiler({
    required this.surname,
    required this.givenName,
    required this.roomNum,
    required this.floor,
  });

  final String surname;
  final String givenName;
  final String roomNum;
  final int floor;
}

class NewPermitRequest {
  const NewPermitRequest({
    required this.userId,
    required this.filer,
    required this.type,
    required this.purpose,
    required this.destination,
    this.startDate,
    required this.expectedReturn,
    required this.contactPerson,
    required this.contactNumber,
  });

  final String userId;
  final PermitFiler filer;
  final PermitType type;
  final String purpose;
  final String destination;

  /// Manila wall-clock time, as picked. Use [expectedReturnUtc] when storing.
  final DateTime? startDate;
  final DateTime expectedReturn;
  final String contactPerson;
  final String contactNumber;


//for weekend permits, the number of nights the student will be away. Returns null if startDate is null.
  int? get nights {
    final s = startDate;
    if (s == null) return null;
    return DateTime.utc(expectedReturn.year, expectedReturn.month, expectedReturn.day)
        .difference(DateTime.utc(s.year, s.month, s.day))
        .inDays;
  }

  /// The real instant, for Firestore (Manila is UTC+8, no daylight saving).
  DateTime get expectedReturnUtc => DateTime.utc(expectedReturn.year, expectedReturn.month,
          expectedReturn.day, expectedReturn.hour, expectedReturn.minute)
      .subtract(const Duration(hours: 8));
}

extension PermitTypeLabel on PermitType {
  String get label => switch (this) {
        PermitType.late => 'Late',
        PermitType.overnight => 'Overnight',
        PermitType.weekend => 'Weekend',
      };
}