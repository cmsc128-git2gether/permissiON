import 'package:cloud_firestore/cloud_firestore.dart';

// safe DateTime? parsing
// reading from firestore field value
DateTime? parseTimestamp(dynamic db) {
    if (db == null) return null;                    // missing field
    if (db is Timestamp) return db.toDate();        // fs Timestamp to dart DateTime
    if (db is DateTime) return db;                  // dart DateTime, no conversion
    if (db is String) return DateTime.tryParse(db); // stored as string in fs to dart DateTime

    return null; // fail safely with null
}

// write to firestore
Timestamp? toTimestamp(DateTime? date) =>
    // returns Timestamp conversion unless null
    date == null ? null : Timestamp.fromDate(date);