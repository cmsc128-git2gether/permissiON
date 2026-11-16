import 'package:permission_app/models/data_enums.dart';

class PermitFilter {
  const PermitFilter({
    this.status,
    this.type,
    this.from,
    this.to,
    this.floor,
    this.roomNum,
    this.searchText,
  });

  final PermitStatus? status;
  final PermitType? type;
  final DateTime? from;       // expected_time_in range, inclusive
  final DateTime? to;
  final int? floor;
  final String? roomNum;
  final String? searchText;   // student name; may be client-side at first
}