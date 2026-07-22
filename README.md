# SpendWise - Premium Financial Expense Tracker (v2.0.0)

SpendWise is a modern, premium Flutter application designed to track personal finances, manage bank accounts and credit cards, record recurring transactions, execute internal transfers, receive Android system notifications, and export comprehensive financial statements. Integrated with Firebase for secure authentication and real-time cloud data synchronization.

---

## Key Features

### 📊 Interactive Financial Dashboard & Net Worth Card
* **Embedded Timeframe Selector**: Integrated a frosted glass dropdown pill inside the Net Worth card to toggle preset periods (`Today`, `This Week`, `This Month`, `Last Month`, `This Year`, `Custom`).
* **Dynamic Net Worth Tracking**: Automatic calculations aggregating starting balances, standard income/expense streams, credit card usage, and internal transfers.
* **3-Day "Upcoming Due" Carousel**: A unified carousel merging unpaid **Bill Reminders** and active **Recurring Transactions** due in the next 3 days, complete with `BILL` and `RECURRING` badges and instant inline action buttons (`Mark Paid`, `Run Now`, `Snooze`, `Pause`).
* **Savings Tracking Card**: Tracks investments and savings categories with real-time totals.

### 🔄 Advanced Recurring Transactions Engine
* **Automated Execution**: Set up daily, weekly, monthly, or yearly recurring income and expense rules.
* **Future Start Date Support**: Setting a start date in the future schedules the transaction without deducting funds today.
* **Optional End Date**: Add optional expiration dates with automatic termination when the end date is reached.
* **Compact Management UI**: Clean card view with `Run Now`, `Pause/Resume`, and `Delete` actions.

### 💳 Complete Account & Credit Card Management
* **Bank Accounts**: Create accounts with initial balances.
* **Credit Cards**: Track total limits, current debt, and available credit headroom.
* **Drag-and-Drop Reordering**: Rearrange accounts and cards under Settings using an intuitive drag handle; changes instantly re-sort displays across the entire app.

### 🔔 Native Android Notifications & Alert Center
* **1-Day Before Recurring Reminders**: Receive high-priority status bar notifications 1 day before a recurring payment executes.
* **Bill Due & Overdue Alerts**: Android system notifications with sound/vibration for upcoming and overdue bills.
* **Bank SMS Receiver Integration**: Automatically detects bank transaction SMS messages and posts instant notification alerts.

### 📝 Smart Transactions & Budgeting
* **Chronological Logging**: Add, edit, or delete transactions with titles, category icons, and amounts.
* **Categorization System**: Dynamic categories with custom color-coded badges and icons.
* **Budget Limits**: Define budgets with auto-calculated progress bars and threshold warnings.

### 🔄 Internal Fund Transfers
* **Double-Count Prevention**: Safely execute transfers between accounts without skewing dashboard income or expense statistics.
* **Credit Card Optimization**: Form fields automatically display available credit limit instead of utilized balance.

### 📂 Financial Exporter
* **PDF Financial Report**: Generates a professional statement containing a financial summary block, accounts ledger, and detailed transactions list using custom brand colors.
* **Excel / CSV Sheet**: Formats detailed statements into tabular data ready to open in Microsoft Excel or Google Sheets.
* **Native Share Integration**: Instantly save, email, or send exported files.

---

## Technology Stack

* **Frontend Framework**: Flutter (Dart)
* **Backend Database**: Cloud Firestore (Production Security Rules)
* **Authentication**: Firebase Auth
* **State Management**: Provider
* **Charts**: fl_chart
* **Document Exporters**: pdf, share_plus, path_provider

---

## Getting Started

### Prerequisites
* Flutter SDK (Version 3.12 or higher)
* Android SDK (Compile SDK 35 configured)
* Firebase Project credentials (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/JowinN/Expense_Tracker.git
   cd "Expense Tracker"
   ```

2. **Configure Firebase**:
   - Place your `google-services.json` inside the [android/app/](file:///c:/Users/RemoteUser/Desktop/Expense%20Tracker/android/app) folder.
   - Place your `GoogleService-Info.plist` inside the `ios/Runner/` folder.

3. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

5. **Build Release APK**:
   ```bash
   flutter build apk
   ```

---

## Release Notes

Detailed release notes and version history can be found in [RELEASE_NOTES.md](file:///c:/Users/RemoteUser/Desktop/Expense%20Tracker/RELEASE_NOTES.md).
