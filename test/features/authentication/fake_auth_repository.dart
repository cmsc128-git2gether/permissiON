import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:permission_app/features/authentication/data/auth_repository.dart';

// A controllable AuthRepository for tests
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository({MockFirebaseAuth? auth, this.onSignIn, this.onReset})
    : super(
        // Fake Firebase and Firestore, so tests never touch the real ones
        auth: auth ?? MockFirebaseAuth(),
        firestore: FakeFirebaseFirestore(),
      );

  final Future<void> Function(String email, String password)? onSignIn;
  final Future<void> Function(String email)? onReset;

  @override
  Future<void> signIn({required String email, required String password}) =>
      onSignIn?.call(email, password) ?? Future.value();
}
