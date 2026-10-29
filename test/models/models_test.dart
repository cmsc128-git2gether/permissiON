import 'package:flutter_test/flutter_test.dart';
import 'package:permission_app/models/admin_profile_model.dart';
import 'package:permission_app/models/end_user_profile_model.dart';

void main() {
  test('AdminProfileModel reads and writes spec fields', () {
    final model = AdminProfileModel.fromJson({
      'surname': 'Cruz',
      'given_name': 'Ana',
      'position': 'Dorm Manager',
      'on_duty': true,
    }, id: 'abc123');

    expect(model.userId, 'abc123');
    expect(model.position, AdminPosition.dormManager);
    expect(model.toJson()['on_duty'], true);
  });

  test('EndUserProfileModel handles missing fields', () {
    final model = EndUserProfileModel.fromJson({}, id: 'x');
    expect(model.surname, '');
    expect(model.roomNum, '');
  });

  test('EndUserProfileModel has no dynamic fields', () {
    final json = EndUserProfileModel.fromJson({}, id: 'x').toJson();
    expect(json.containsKey('active_permits'), false);
    expect(json.containsKey('permit_history'), false);
    expect(json.containsKey('delinquency_count'), false);
  });
}