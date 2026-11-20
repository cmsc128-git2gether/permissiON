## Seeded Demo Accounts
Credentials (email + password)

## Authentication
Create accounts in Firebase Console > Security > Authentication, or just search the Authentication in search tab.

## users/{uid}
| Doc ID | access_level |
|---|---|
| <admin uid> | admin |
| <dormer uid> | end_user |

| Field | Type | Example |
|---|---|---|
| email | string | veritylim@example.com |
| access_level | string | end_user
| created_at | timestamp | 11/20/2026 |
| updated_at | null | MM/DD/YYYY HH:MM |
| deleted_at | null | MM/DD/YYYY HH:MM |

## end_user_profiles/{uid}
| Field | Type | Example |
|---|---|---|
| surname | string | Lim |
| given_name | string | Verity |
| phone_num | string | 09676767670 |
| room_num | string | 12 |
| floor | int64 | 2 |
| created_at | timestamp | 11/20/2026 |
| updated_at | null | MM/DD/YYYY HH:MM |
| deleted_at | null | MM/DD/YYYY HH:MM |

## admin_profiles/{uid}
| Field | Type | Example |
|---|---|---|
| name | string | Balay Gumamela Admin |
| created_at | timestamp | 11/20/2026 |
| updated_at | null | MM/DD/YYYY HH:MM |
| deleted_at | null | MM/DD/YYYY HH:MM |

## permits/{permitId}
| Field | Type | Example |
|---|---|---|
| user_id | string | <dormer uid> |
| surname | string | Lim |
| given_name | string | Verity |
| room_num | string | 12 |
| permit_type | string | WEEKEND |
| destination | string | Oton |
| purpose | string | Home |
| emergency_contact_person | string | Vill Aidjer Lim |
| emergency_contact_num | string | 09123456767 |
| expected_time_in | timestamp | 12/01/2026 10:00 AM |
| actual_time_in | null | MM/DD/YYYY HH:MM |
| permit_status | PENDING |
| approved_by | string | <admin uid> |
| approved_at | null | MM/DD/YYYY HH:MM |
| created_at | timestamp | MM/DD/YYYY HH:MM |
| is_late_file | boolean | false |
| late_filing_reason | null | --- |

## checkin_codes/{permitId}
| Field | Type | Example |
|---|---|---|
| code_status | string |  |
| checkin_at | null | MM/DD/YYYY HH:MM |
| checkin_by | null | <dormer uid> |
| expires_at | null | MM/DD/YYYY HH:MM |

## delinquency_logs/{delinquencyId}
| Field | Type | Example |
|---|---|---|
| user_id | string | <dormer uid> |
| permit_id | string | <permitId> |
| violation_type | string | LATE CHECK IN |
| violation_description | string | Only entered the dorm premises beyond permit duration |
| created_at | null | MM/DD/YYYY HH:MM |
| created_by | string | <admin name> |

## Verifcation
1. Sign-in as each user
2. Confirm the correct home page (dormer or admin)