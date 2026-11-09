---
name: leave-fixes-and-task-manager-live
description: Leave system fixes, employee dynamic directory, employee task manager, and production Vercel deployment completed
metadata:
  type: project
---

**Leave Fixes & Task Manager Deployment - Complete**

*Live Production URL:*
- `https://worknest-alpha-ebon.vercel.app`

*Leave System & Options Enhancements:*
- ChoiceChip leave type selection displaying entitlements (e.g. `Annual • 20 days/yr`, `Sick • 10 days/yr`, `Unpaid`).
- Rejection dialog with optional comment/reasoning.
- Approval confirmation modal dialog.
- Title and allowance information explicitly displayed on `LeaveBalanceCard`.
- Redundant subtitle text cleaned up on leave request tiles.
- Cleaned status parameter casing in `api_client.dart` (`status.name`).
- Real dynamic workforce directory in `_EmployeeManagementContent` powered by `api.listUsers()`.

*Employee Task Manager System:*
- Added `_NavPage.tasks` to navigation for all self-service employee roles.
- Status filters (`All`, `To do`, `In progress`, `Done`) and category tags (`Operations`, `Compliance`, `Security`, `Goals`, `Profile`).
- State transition controls (`Start` -> `Finish` -> `Reopen`) and toggle checkboxes.
- Task metrics cards: Total, In progress, Completed, High priority.
- Create Task modal dialog with title, description, category selector, priority badges, and due date picker.

*Quality & Deployment:*
- `flutter analyze` completed with 0 errors and 0 warnings.
- `flutter build web --release` compiled successfully.
- Deployed to Vercel production at `https://worknest-alpha-ebon.vercel.app` (HTTP 200 OK verified).
