import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_model.dart';
// lib/services/qr_service.dart
class QrService {
  QrService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// Live QR for a permit; null if none exists.
  Stream<QrCodeModel?> listenToQrForPermit(String permitId) =>
      Stream.value(null);

  /// QR must be ACTIVE and unexpired. In one transaction: QR -> SCANNED,
  /// write actual_time_in, permit -> COMPLETED.
  /// Throws StateError if missing, expired, already scanned, or cancelled.
  Future<void> scan(String scannerId, String qrId) async =>
      throw UnimplementedError('scan');
}

// lib/services/archive_service.dart
class ArchiveService {
  ArchiveService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// CSV text of permits with expected_time_in in [from]..[to].
  Future<String> exportPermitsCsv(DateTime from, DateTime to) async =>
      throw UnimplementedError('exportPermitsCsv');

  /// Hard delete, in chunks of 500, also deleting linked qr docs.
  /// Throws StateError if the range contains PENDING or ACTIVE permits.
  /// Returns the number deleted. The UI must export and confirm first.
  Future<int> deletePermits(String adminId, DateTime from, DateTime to) async =>
      throw UnimplementedError('deletePermits');
}

// lib/services/notification_service.dart
class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  ///in-app inbox, newest first. Docs are written inside the
  /// updatePermitStatus transaction (issue #22).
  // Stream<List<NotificationModel>> listenToNotifications(String userId) =>
  //     Stream.value(const []);

  Future<void> markRead(String userId, String notificationId) async =>
      throw UnimplementedError('markRead');
}