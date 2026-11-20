import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/end_user_profile_model.dart';
import 'package:permission_app/services/end_user_profile_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late EndUserProfileService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = EndUserProfileService(firestore: fakeDb);
  });

  test('getProfile returns null when document does not exist', () async {
    final result = await service.getProfile('missing_user');
    expect(result, isNull);
  });

  test('getProfile parses fields and applies defaults for missing keys', () async {
    await fakeDb.collection('end_user_profiles').doc('user_1').set({
      'surname': 'Dela Cruz',
      'given_name': 'Juan',
      // room_num, floor, and phone_num intentionally omitted
    });

    final profile = await service.getProfile('user_1');

    expect(profile, isNotNull);
    expect(profile!.userId, 'user_1');
    expect(profile.surname, 'Dela Cruz');
    expect(profile.givenName, 'Juan');
    expect(profile.roomNum, '');
    expect(profile.phoneNum, '');
    expect(profile.floor, 1); // matches ?? 1 default
  });

  test('listenToProfile emits updates when document changes', () async {
  final stream = service.listenToProfile('user_2');
  final emissions = <EndUserProfileModel?>[];

  final sub = stream.listen(emissions.add);

  // Wait briefly for initial null snapshot
  await Future<void>.delayed(Duration.zero);
  expect(emissions.last, isNull);

  // Add document -> triggers snapshot update
  await fakeDb.collection('end_user_profiles').doc('user_2').set({
    'surname': 'Reyes',
    'given_name': 'Maria',
    'room_num': '304',
    'floor': 3,
    'phone_num': '09171234567',
  });

  // Wait for stream listener callback to process the write
  await Future<void>.delayed(Duration.zero);

  final updated = emissions.last;
  expect(updated, isNotNull);
  expect(updated?.givenName, 'Maria');
  expect(updated?.roomNum, '304');
  expect(updated?.floor, 3);

  await sub.cancel();
});
}