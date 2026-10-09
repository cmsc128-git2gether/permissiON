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

| Layer         | Choice |
| ------------- | ------ |
| Frontend      | _TBD_  |
| Backend       | _TBD_  |
| Database      | _TBD_  |
| Auth / OTP    | _TBD_  |
| Notifications | _TBD_  |
| Hosting / CI  | _TBD_  |

## Data Model

## Project Structure

```
.
├── docs/
│   ├── wireframes/
│   ├── validation
│   └── requirements.md
│
├── frontend/
├── backend/
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
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

- [Wireframes (Figma)]()
- [Data model / ERD](docs/erd.png)
- [Requirements and validation notes](docs/requirements.md)
- [PACT analysis](docs/pact.md)
- [User flows](docs/flows.md)

## Sprint Progress

| Sprint | Focus                              | Status      | Notes                                   |
| ------ | ---------------------------------- | ----------- | --------------------------------------- |
| 1      | Wireframes, data model, user flows | In progress | [sprint-1.md](docs/sprints/sprint-1.md) |
| 2      | _TBD_                              | Planned     |                                         |
| 3      | _TBD_                              | Planned     |                                         |

## Team

| Name   | Role   | Focus  |
| ------ | ------ | ------ |
| _name_ | _role_ | _area_ |

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
