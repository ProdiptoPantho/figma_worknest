# PeopleHub

PeopleHub is a responsive Flutter HR workspace prototype based on the Figma design. It includes role-aware navigation, attendance tracking, leave review, reports, an interactive attendance calendar, and a protected demo login flow.

## Features

- Responsive desktop and mobile layouts
- HR dashboard with attendance, working time, leave balance, and activity
- Team overview and attendance calendar
- Calendar hover details on web and tap/click day details
- Attendance, time-off, and reports views
- Role-aware navigation for:
  - Super Admin / Owner
  - HR Manager
  - Payroll Officer / Accountant
  - Department Manager
  - Employee
- Demo login and logout
- Interactions for clock in/out, breaks, approvals, exports, and requests

## Requirements

- Flutter SDK
- Dart SDK compatible with the version in `pubspec.yaml`

## Run locally

```powershell
cd "F:\Projects\HR app\figma_worknest"
flutter pub get
flutter run -d chrome
```

## Demo login

```text
Email: alex@company.com
Password: securepass
```

Any valid email and password with at least eight characters is accepted by the current demo-only login flow.

## Validate

```powershell
flutter analyze
flutter test
flutter build web
```

## Production web build

```powershell
flutter build web --release
```

The generated site is written to `build/web`.

To preview the production build locally:

```powershell
python -m http.server 5173 --directory build/web
```

Open `http://localhost:5173`.

## Vercel deployment

Authenticate with Vercel, build the release site, and deploy the generated web directory:

```powershell
vercel login
flutter build web --release
vercel deploy build\web --prod
```

## Security note

The current login is a client-side demo flow. It keeps authentication state in memory and clears it on logout; it does not persist passwords or tokens. Production use requires a backend authentication service to validate credentials, issue short-lived tokens, enforce role permissions server-side, and protect every HR API endpoint.

## Project structure

```text
lib/main.dart       Flutter application and UI
test/widget_test.dart
web/                Flutter web shell and metadata
windows/            Windows runner
```
