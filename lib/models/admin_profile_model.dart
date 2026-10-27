enum AdminPosition {
  dormManager('Dorm Manager'),
  dormStaff('Dorm Staff'),
  residentHallAssistant('Resident Hall Assistant');

  final String label;
  const AdminPosition(this.label);

  static AdminPosition? fromLabel(String? value) {
    for (final p in AdminPosition.values) {
      if (p.label == value) return p;
    }
    return null;
  }
}

class AdminProfileModel {
  final String userId;
  final String surname;
  final String givenName;
  final String? displayPhoto;
  final AdminPosition? position;
  final bool onDuty;

  const AdminProfileModel({
    required this.userId,
    required this.surname,
    required this.givenName,
    this.displayPhoto,
    this.position,
    this.onDuty = false,
  });

  factory AdminProfileModel.fromJson(Map<String, dynamic> json,
          {required String id}) =>
      AdminProfileModel(
        userId: id,
        surname: json['surname'] as String? ?? '',
        givenName: json['given_name'] as String? ?? '',
        displayPhoto: json['display_photo'] as String?,
        position: AdminPosition.fromLabel(json['position'] as String?),
        onDuty: json['on_duty'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'surname': surname,
        'given_name': givenName,
        'display_photo': displayPhoto,
        'position': position?.label,
        'on_duty': onDuty,
      };
}