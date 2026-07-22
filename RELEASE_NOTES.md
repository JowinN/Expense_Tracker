# Release Notes — SpendWise

---

## v2.0.0 — Major Feature Release: Recurring Engine, 3-Day Upcoming Due Carousel, Net Worth Timeframe Selector & System Notifications

> **Build**: `2.0.0+3` · **Released**: July 2026

SpendWise v2.0.0 is a major update introducing an automated Recurring Transactions engine, a unified 3-day Upcoming Due dashboard carousel, embedded timeframe controls in the Net Worth card, native Android system notifications, and production Firestore security rules.

### 🚀 New Features & Enhancements

#### 🔄 Advanced Recurring Transactions Engine
- **Automated Scheduling**: Create recurring expense and income transaction rules with Daily, Weekly, Monthly, or Yearly frequencies.
- **Future Start Date Schedule Enforcement**: Setting a future start date schedules the recurrence without deducting funds today. Template rules (`isRecurring: true`) are isolated from immediate account balance subtractions.
- **Optional End Date**: Set optional end dates (`recurringEndDate`) with automatic pause/stop when the end date is reached.
- **Redesigned Compact Cards**: Sleek, compact card UI with **Run Now**, **Pause/Resume**, and **Delete** quick action buttons.

#### 📌 Unified 3-Day "Upcoming Due" Dashboard Carousel
- **Combined Carousel**: Merges unpaid **Bill Reminders** and active **Recurring Transactions** due in the next 3 days into a single horizontal carousel.
- **Badging & Labels**: Distinct `BILL` (amber) and `RECURRING` (primary) badges with due status indicators (`Due Today`, `Overdue by Xd`, `Due in X days`).
- **Inline Actions**: Perform instant operations directly from the card (**Mark Paid**, **Run Now**, **Snooze 1 Day**, **Snooze 1 Week**, **Pause**).

#### 📊 Embedded Net Worth Timeframe Selector
- **Glass Pill Dropdown**: Embedded a frosted glass timeframe dropdown pill (`PopupMenuButton`) directly inside the top-right of the **Net Worth Balance Card** on the Dashboard.
- **Clean Navigation**: Supports switching preset time periods (`Today`, `This Week`, `This Month`, `Last Month`, `This Year`, `Custom`) cleanly without cluttering the app bar.

#### 🔔 Native Android System Notifications & Control Center
- **Upcoming Recurring Reminder**: Added a setting to receive high-priority Android system notifications **1 day before** a recurring transaction is scheduled to execute.
- **Native System Dispatcher**: Implemented `showLocalNotification` in `MainActivity.kt` delivering system notifications with sound and vibration for bills, recurring executions, and budget alerts.
- **Notification Settings Cleanup**: Removed test SMS parser UI for a clean, streamlined notification control center.

#### 💰 Savings & Investment Category Selector
- **Custom Expense Category Selector**: Select specific expense categories used for investments/savings in Settings, automatically calculating and displaying total savings on the Dashboard.

#### 🔒 Production Cloud Firestore Security Rules
- **Production Rules (`firestore.rules`)**: Enforces strict user authentication (`request.auth != null`), data validation, and owner-isolated document access for `users`, `categories`, `accounts`, `transactions`, `budgets`, `bill_reminders`, and `settings`.

---

## Technical Details
| Field | v2.0.0 | v1.1.0 | v1.0.0 |
|---|---|---|---|
| Build Signature | `2.0.0+3` | `1.1.0+2` | `1.0.0+1` |
| Target Platforms | Android, iOS, Web | Android, iOS, Web | Android, iOS, Web |
| Database Backend | Firebase Cloud Firestore | Firebase Cloud Firestore | Firebase Cloud Firestore |
| Min Android SDK | 21 | 21 | 21 |
| Target Android SDK | 35 | 35 | 35 |

---

## Previous Releases

### v1.1.0 — SMS Transaction Reliability Fix
> **Build**: `1.1.0+2` · **Released**: July 2026
- Fixed SMS-detected transactions not appearing after notification dismissal.
- Resolved file path mismatch in `SmsReceiver.kt` and added app-resume lifecycle refresh.

### v1.0.0 — Initial Release
> **Build**: `1.0.0+1` · **Released**: July 2026
- Core account management, internal fund transfers, PDF & Excel financial statement exporters, and SDK 35 build configuration.
