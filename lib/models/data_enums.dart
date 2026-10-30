// types enums matching string literals in schema

// access level of user
enum AccessLevel {
    // enums of access level with their 
    // string literals from database
    endUser('end_user'),
    admin('admin');

    // constructor storing the string passed to value
    const AccessLevel(this.value);
    final String value; // to firestore

    // returns the matching enum case
    // db is the string read from the database ('end_user', 'admin')
    // fromString is not nullable
    static AccessLevel fromString(String db) => values.firstWhere(
        // test of args matching enums with string literals
        // whether the stored value == db
        (e) => e.value == db, 
        orElse: () => throw ArgumentError('Invalid Access Level: "$db"'),
    );
}

// permit types
enum PermitType {
    // enums of permit types  with their 
    // string literals from database
    late('LATE'),
    overnight('OVERNIGHT'),
    weekend('WEEKEND');

    // constructor storing the string passed to value
    const PermitType(this.value); 
    final String value; // to firestore

    // returns the matching enum case
    // db is the string read from the database ('LATE', 'OVERNIGHT', 'WEEKEND')
    // fromString is not nullable
    static PermitType fromString(String db) => values.firstWhere(
        // test of args matching enums with string literals
        // whether the stored value == db
        (e) => e.value == db, 
        orElse: () => throw ArgumentError('Invalid Permit Type: "$db"'),
    );
}

// permit status
enum PermitStatus {
    // enums of permit status  with their 
    // string literals from database
    pending('PENDING'),
    cancelled('CANCELLED'),
    active('ACTIVE'),
    denied('DENIED'),
    completed('COMPLETED'),
    overdue('OVERDUE');

    // constructor storing the string passed to value
    const PermitStatus(this.value); 
    final String value; // to firestore

    // returns the matching enum case
    // db is the string read from the database 
    // ('PENDING', 'CANCELLED', 'ACTIVE', 'DENIED', 'COMPLETED', 'OVERDUE')
    // fromString is not nullable
    static PermitStatus fromString(String db) => values.firstWhere(
        // test of args matching enums with string literals
        // whether the stored value == db
        (e) => e.value == db, 
        orElse: () => throw ArgumentError('Invalid Permit Status: "$db"'),
    );
}

// qr status
enum QrStatus {
    // enums of QR status  with their 
    // string literals from database
    active('ACTIVE'),
    scanned('SCANNED'),
    cancelled('CANCELLED');

    // constructor storing the string passed to value
    const QrStatus(this.value);
    final String value; // to firestore

    // returns the matching enum case
    // db is the string read from the database ('ACTIVE', 'SCANNED', 'CANCELLED')
    // fromString is not nullable
    static QrStatus fromString(String db) => values.firstWhere(
        // test of args matching enums with string literals
        // whether the stored value == db
        (e) => e.value == db, 
        orElse: () => throw ArgumentError('Invalid QR Status: "$db"'),
    );
}

// violation types
enum ViolationType {
    noFiledPermit('NO FILED PERMIT'),
    lateCheckIn('LATE CHECK IN');

    // constructor storing the string passed to value
    const ViolationType(this.value);
    final String value; // to firestore

    // returns the matching enum case
    // db is the string read from the database ('LATE CHECK IN', 'NO FILED PERMIT')
    // fromString is not nullable
    static ViolationType fromString(String db) => values.firstWhere(
        // test of args matching enums with string literals
        // whether the stored value == db
        (e) => e.value == db, 
        orElse: () => throw ArgumentError('Invalid Violation Type: "$db"'),
    );
}
