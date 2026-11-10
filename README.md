# PeopleHub (WorkNest) — Modern Workforce & HR Management

[![Live Web Demo](https://img.shields.io/badge/Production-Live%20Demo-2A9A75?style=for-the-badge&logo=vercel)](https://worknest-alpha-ebon.vercel.app)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.9-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.7-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![Backend Status](https://img.shields.io/badge/Backend-Render%20ASP.NET-103A48?style=for-the-badge)](https://hrm-api-tjfa.onrender.com/health)
[![Tests Passing](https://img.shields.io/badge/Tests-16%2F16%20Passing-success?style=for-the-badge)](https://github.com/ProdiptoPantho/figma_worknest)

A responsive, production-ready **Human Resource Management (HRM) and Employee Operations Web Application** built with Flutter. Designed with a calm corporate aesthetic (Navy `#103A48`, Teal `#59CDB6`, and Mint `#2A9A75`), PeopleHub connects directly to a live RESTful API backend to handle attendance, leave management, employee task tracking, and role-based workforce governance.

---

## 🌐 Live Deployments

- **Live Production App:** [https://worknest-alpha-ebon.vercel.app](https://worknest-alpha-ebon.vercel.app)
- **Backend API Base:** `https://hrm-api-tjfa.onrender.com`
- **Health Check Endpoint:** [https://hrm-api-tjfa.onrender.com/health](https://hrm-api-tjfa.onrender.com/health)

---

## ✨ Core Features & Modules

### 1. 🕒 Live Attendance & Working Hours
- **One-Tap Check-In / Check-Out:** Real-time clock-in and clock-out with server timestamp validation.
- **Break Time Tracking:** Toggle break states with live elapsed work counters.
- **Attendance History:** Personal attendance logs with on-time, late, absent, and leave metrics.
- **Admin Daily & Monthly Reports:** Managers can inspect company-wide attendance breakdowns, punctuality rates, and department coverage.

### 2. 🌴 Leave & Time-Off Management
- **Entitlement Cards:** Visual ChoiceChip cards for leave categories (`Annual • 20 days/yr`, `Sick • 10 days/yr`, `Casual • 5 days/yr`, `Unpaid`).
- **Interactive Leave Balances:** Real-time remaining balance and used-days progress tracking per category.
- **Approval Flow:** Inline confirmation modal dialog for managers before approving leave requests.
- **Rejection Flow with Comments:** Managers can provide explicit reasons/comments on rejected requests.
- **Cancellation:** Employees can cancel their own pending requests with one click.

### 3. ✅ Employee Task Manager
- **Workflow State Progression:** Move tasks seamlessly across `To do` ➔ `In progress` ➔ `Done` or reopen with one click.
- **Priorities & Categories:** Color-coded priority badges (**High**, **Medium**, **Low**) and category filtering (`Operations`, `Compliance`, `Security`, `Goals`, `Profile`, `Projects`).
- **Deadline Monitoring:** Due-date selector with automated overdue tracking and status chips.
- **Task Analytics:** Live metric badges for Total, In Progress, Completed, and High-Priority tasks.

### 4. 👥 Dynamic Employee Directory & RBAC
- **Live User Directory:** Synced directly with `GET /api/rbac/users` from the live backend.
- **Role-Based Access Control:** Strict permission matrix for **Super Admin**, **HR Manager**, **Department Manager**, **Payroll Officer**, and **Employee**.
- **Role Assignments:** Super admins can inspect and reassign user roles dynamically.
- **Live Search & Filter:** Instant search across employee email, assigned roles, and account status.

### 5. 🔒 Authentication & Account Recovery
- **JWT Bearer Session:** Secure token storage with automated token refresh cycles.
- **Password Reset:** Tokenized forgot-password and reset link handler with deep-linking support (`/reset-password`).
- **Role Enforcement:** UI navigation adapts dynamically according to decoded session permissions.

### 6. 🌙 Dark Theme & Accessible UI
- **One-Click Theme Toggle:** Seamlessly switch between Light and Dark mode from the sidebar or mobile header.
- **Tailored Contrast Palette:** Custom deep slate surfaces (#0F172A, #1E293B, #334155) paired with high-contrast typography and subtle tinted overlays.
- **Adaptive Components:** All panels, metric cards, leave request tiles, employee task cards, and summary counters automatically restyle to match the active theme.

---

## 🛠️ Technology Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend Framework** | **Flutter Web (Stable)** | Target: Web SPA (CanvasKit & HTML) |
| **Language** | **Dart 3.x** | Strong-mode typing, pattern matching, records |
| **Hosting & CDN** | **Vercel** | SPA rewrites, strict caching rules, SSL |
| **Networking** | **`http: ^1.2.2`** | Typed API client with auto-refresh & timeout safety |
| **Design System** | **Material 3 Custom** | Inter font, PeopleHub corporate palette |
| **Backend API** | **ASP.NET Core (Kestrel)** | Hosted on Render with MongoDB persistence |

---

## 🏗️ Architecture

```
figma_worknest/
├── lib/
│   ├── main.dart             # Entire UI system (Auth, Dashboard, Tasks, Leave, Reports, Directory)
│   └── api_client.dart       # Typed REST API Client (Auth, Attendance, Leave, RBAC)
├── web/
│   ├── index.html            # Flutter Web HTML5 shell
│   ├── manifest.json         # PWA metadata
│   └── vercel.json           # Vercel SPA routing and cache control headers
├── test/
│   └── widget_test.dart      # Comprehensive widget tests (Auth, Attendance, Leave dialogs)
└── build/web/                # Compiled production distribution for Vercel
```

---

## 🚀 Getting Started Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.0`)
- Google Chrome browser (for local web debugging)

### 1. Clone the repository
```bash
git clone https://github.com/ProdiptoPantho/figma_worknest.git
cd figma_worknest
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run on Chrome
```bash
flutter run -d chrome
```

---

## 🧪 Running Quality Checks & Tests

Run static analysis:
```bash
flutter analyze
```

Run the automated test suite:
```bash
flutter test
```
*Current test suite: **16/16 tests passing**.*

---

## 📦 Building & Deploying to Production

### 1. Build the release bundle
```bash
flutter build web --release
```

### 2. Deploy to Vercel
```bash
cd build/web
vercel --prod --yes
```

---

## 📄 License

This project is proprietary and built for PeopleHub (WorkNest) employee management operations. All rights reserved.
