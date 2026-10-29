class EndUserProfileModel {
  final String userId;
  final String surname;
  final String givenName;
  final String? displayPhoto;
  final String phoneNum;
  final String roomNum;

  // No delinquency_count, permit_history, or active_permits:
  // those are queried from the delinquency logs and permits collections.

  const EndUserProfileModel({
    required this.userId,
    required this.surname,
    required this.givenName,
    this.displayPhoto,
    required this.phoneNum,
    required this.roomNum,
  });

  factory EndUserProfileModel.fromJson(Map<String, dynamic> json,
          {required String id}) =>
      EndUserProfileModel(
        userId: id,
        surname: json['surname'] as String? ?? '',
        givenName: json['given_name'] as String? ?? '',
        displayPhoto: json['display_photo'] as String?,
        phoneNum: json['phone_num'] as String? ?? '',
        roomNum: json['room_num'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'surname': surname,
        'given_name': givenName,
        'display_photo': displayPhoto,
        'phone_num': phoneNum,
        'room_num': roomNum,
      };
}