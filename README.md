# Dorm Permit System

Web app for filing and managing dorm permits at Balay Gumamela. Residents file permits from their phones; staff review, track, and log them from a desktop.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Sprint Progress](#sprint-progress)
- [Team](#team)
- [Contributing](#contributing)

## Overview

Short paragraph: the problem (paper permits, manual logs), who it's for (residents, dorm staff), and what the system replaces.

**Users**
| Role | Device | Access |
|---|---|---|
| Resident | Mobile | File, cancel, extend permits; view history and notifications; QR check in |
| Staff / Admin | Desktop | Approve permits, view logs, manage accounts, delinquency tracker, archives |

## Features

| #   | Feature                                                  | Status |
| --- | -------------------------------------------------------- | ------ |
| 1   | Remote permit filing                                     | ☐      |
| 2   | Resident and staff login (auto-generated accounts)       | ☐      |
| 3   | Role-based dashboards                                    | ☐      |
| 4   | Permit forms with OTP verification                       | ☐      |
| 5   | Deadline enforcement (flag after 6 PM)                   | ☐      |
| 6   | Permit logs (filter, search, staff override)             | ☐      |
| 7   | One active permit per day, cancel and extension requests | ☐      |
| 8   | Status notifications and reminders                       | ☐      |
| 9   | QR check in/out (one-time use)                           | ☐      |
| 10  | Delinquency tracker                                      | ☐      |
| 11  | Downloadable archive of past logs                        | ☐      |

## Tech Stack

| Layer         | Choice          |
| ------------- | --------------- |
| Frontend      | Flutter         |
| Backend       | Firebase        |
| Database      | Cloud Firestore |
| Auth / OTP    | _TBD_           |
| Notifications | _TBD_           |
| Hosting / CI  | _TBD_           |

## Data Model

_Firebase stores databases as collections and documents. No need for tables and normalization for the relationships of entities._

### Schema

```
users/{user_id}
	email, access_level: "end_user" | "admin"
	updated_at: TIMESTAMP | NULL, deleted_at: TIMESTAMP | NULL

admin_profiles/{user_id}
	full_name, display_photo, position, on_duty: BOOL

end_user_profiles/{user_id}
	full_name, display_photo, phone_num, room_num
	active_permits, permit_history (QUERIES ONLY)
	delinquency_count (QUERIES ONLY)

permits/{permit_id}
	user_id, full_name, room_num
	permit_type: "LATE" | "OVERNIGHT" | "WEEKEND"
	destination, purpose, emergency_contact_person, emergency_contact_num
	expected_time_in: TIMESTAMP
	actual_time_in: TIMESTAMP | NULL (QUERIES FROM SCANNED QR)
	permit_status: "PENDING" | "ACTIVE" | "CANCELLED" | "COMPLETED" | "OVERDUE" | "DENIED"
	approved_by: admin_id, approved_at: TIMESTAMP | NULL
	qr_id: STRING | NULL
	created_at: TIMESTAMP

qr/{qr_id}
	permit_id, admin_id
	status: "ACTIVE" | "SCANNED" | "CANCELLED"
	created_at: TIMESTAMP, expires_at: TIMESTAMP
	scanned_at: TIMESTAMP | NULL, scanned_by: user_id | NULL

delinquency_logs/{delinquency_id}
	user_id, permit_id
	violation_type: "LATE CHECK IN" | "NO FILED PERMIT"
	violation_description
	reported_by: admin_id | NULL, created_at: TIMESTAMP | NULL
```

### Flow

- A user can only have one profile– either as an admin or as an end user.
- An end user can file only one permit.
- An admin user can approve or disapprove one or many permits.
- An end user can have zero or many delinquencies.
- A permit can only have one valid QR.

## Project Structure

```
permissiON
├── android/
├── ios/
├── assets/                 
│   ├── images/
│   ├── icons/
│   └── fonts/
├── build/                 
├── lib/                    
├── test/                  
├── .gitignore              
├── pubspec.yaml           
└── README.md                

```

## Getting Started

### Prerequisites

- _runtime and version_
- _database_

### Setup

```bash
git clone <repo-url>
cd <repo>
cp .env.example .env   # fill in values
# install dependencies
# run migrations / seed
# start dev server
```

### Environment Variables

| Variable           | Description                |
| ------------------ | -------------------------- |
| `DATABASE_URL`     | Database connection string |
| `OTP_PROVIDER_KEY` | Email/SMS provider key     |
| `JWT_SECRET`       | Session signing secret     |

### Test Accounts

| Role     | Username | Password |
| -------- | -------- | -------- |
| Resident | _seeded_ | _seeded_ |
| Admin    | _seeded_ | _seeded_ |

## Documentation

- [Software Specifications I - Interview Report & Project Proposal](https://docs.google.com/document/d/1sJFH7OkI7XbVuXOBWC1f7jiuwu5QSNnitTlRYMTITdc/edit?tab=t.0)
- [Software Specifications II - Requirements List & Validation Report](https://docs.google.com/document/d/1sJFH7OkI7XbVuXOBWC1f7jiuwu5QSNnitTlRYMTITdc/edit?tab=t.kt23onxkd7b)
- [PACT Analysis](https://docs.google.com/document/d/1sJFH7OkI7XbVuXOBWC1f7jiuwu5QSNnitTlRYMTITdc/edit?tab=t.c9z0pzict9xh)
- [Wireframes (Figma)](https://www.figma.com/design/GflfbKiRYpEubelCggKP6t/-CMSC-128--git2gether?node-id=21-2&p=f&t=76yiqz6goeVUMVay-0)

## Sprint Progress

| Sprint | Focus                              | Status      | Notes                                                                                                                           |
| ------ | ---------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Wireframes, data model, user flows | In progress | [User Stories](https://docs.google.com/spreadsheets/d/1ttPp9L5IGLKUVZ3a-sBnqR2AKmY9hZ4rxIdNRENLatc/edit?usp=sharingsprint-1.md) |
| 2      | _TBD_                              | Planned     |                                                                                                                                 |
| 3      | _TBD_                              | Planned     |                                                                                                                                 |

## Team

| Name      | Role                     | Focus    |
| --------- | ------------------------ | -------- |
| De Guzman | Product Owner, Developer | Frontend |
| Cambel    | Scrum Master, Developer  | Frontend |
| Carreon   | Developer                | Backend  |
| Melicor   | Developer                | Backend  |
| Gelvezon  | Developer                | Backend  |

## Contributing

### Workflow

1. Pull `main`, then branch from it.
2. Code and commit using the commit convention below.
3. Push and open a PR. At least one other person must review and merge it.
4. Merge to `main`, delete the branch, repeat.

### Definition of Done (draft)

- [ ] Meets the user story's acceptance criteria
- [ ] Reviewed and approved by another person
- [ ] Local checks pass: `flutter analyze` and `flutter test`
- [ ] CI workflow (`.github/workflows/ci.yml`) is green
- [ ] PR template and README.md updated

### Commit Messages

Format: `<type>: <short description>`

| Type       | Use for                                          | Example                                                   |
| ---------- | ------------------------------------------------ | --------------------------------------------------------- |
| `docs`     | Documentation                                    | `docs: explain the language's string escape rules`        |
| `feat`     | New features or functionality                    | `feat: scan string and number literals`                   |
| `refactor` | Restructuring without changing behavior          | `refactor: extract parser precedence helpers`             |
| `fix`      | Bug fixes and corrections                        | `fix: report an unterminated string at its starting line` |
| `ux`       | User experience, interface, or usability changes | `ux: include the token and line in syntax errors`         |
| `meta`     | Repo maintenance, build config, tooling          | `meta: pin the test harness version in GitHub Actions`    |
| `test`     | Adding or modifying tests                        | `test: add parser associativity cases`                    |

## Data Privacy

Resident personal information is handled in compliance with applicable data privacy regulations. Briefly state what is collected, why, and retention (archives are deleted with prior notice).

## License

_TBD (course project)_
