import '../models/permit_model.dart';

/// One table row on the Room Check screen. Built by the roster stream, never stored.
class RoomCheckRow {
  const RoomCheckRow({
    required this.userId,
    required this.surname,
    required this.givenName,
    required this.roomNum,
    this.floor,
    this.permit, // null means "No permit"
    this.present, // null means not marked yet
    this.checkedAt,
  });

  final String userId, surname, givenName, roomNum;
  final int? floor;
  final PermitModel? permit;
  final bool? present;
  final DateTime? checkedAt;

  bool get hasPermit => permit != null;

  /// "Carreon, Angel Mae"
  String get fullName => givenName.isEmpty ? surname : '$surname, $givenName';
}