# SpendWise - Premium Financial Expense Tracker

SpendWise is a modern, premium Flutter application designed to track personal finances, manage bank accounts and credit cards, record transaction histories, execute internal transfers, and export comprehensive financial statements. Integrated with Firebase for secure authentication and real-time cloud data synchronization.

---

## Key Features

### 📊 Interactive Financial Dashboard
* **Dynamic Net Worth Tracking**: Automatic calculations aggregating starting balances, standard income/expense streams, credit card usage, and internal transfers.
* **Aggregated Summaries**: At-a-glance cards detailing total income and total expenses.
* **Dynamic Analytics Charts**: Colorful charts visualizing category-wise spending habits.
* **Account Cards List**: A swipeable horizontal list displaying bank accounts and credit cards (detailing available cash balances or credit limit utilization).

### 💳 Complete Account & Credit Card Management
* **Bank Accounts**: Create accounts with initial balances.
* **Credit Cards**: Track total limits, current debt, and available credit headroom.
* **Drag-and-Drop Reordering**: Rearrange accounts and cards under Settings using an intuitive drag handle; changes instantly re-sort displays across the entire app.

### 📝 Smart Transactions & Budgeting
* **Chronological Logging**: Add, edit, or delete transactions with titles, category icons, and amounts.
* **Categorization System**: Dynamic categories with custom color-coded badges and icons.
* **Overflow Layout Protection**: Ellipsis truncation and fitted layouts prevent visual breakage even under extremely long user-supplied descriptions or massive account numbers.

### 🔄 Internal Fund Transfers
* **Double-Count Prevention**: Safely execute transfers between accounts without skewing dashboard income or expense statistics.
* **Dedicated Transfers Screen**: A focused ledger to log, view, and manage internal funds movement.
* **Credit Card Optimization**: Form fields automatically display the available credit limit instead of utilized balance.

### 📂 Financial Exporter
* **PDF Financial Report**: Generates a professional statement containing a financial summary block, accounts ledger, and detailed transactions list using custom brand colors.
* **Excel / CSV Sheet**: Formats detailed statements into tabular data ready to open in Microsoft Excel or Google Sheets.
* **Native Share Integration**: Instantly save, email, or send exported files.

---

## Technology Stack

* **Frontend Framework**: Flutter (Dart)
* **Backend Database**: Cloud Firestore
* **Authentication**: Firebase Auth
* **State Management**: Provider
* **Charts**: fl_chart
* **Document Exporters**: pdf, share_plus, path_provider

---

## Getting Started

### Prerequisites
* Flutter SDK (Version 3.3.0 or higher)
* Android SDK (Compile SDK 35 configured)
* Firebase Project credentials (`google-services.json` for Android, `GoogleService-Info.plist` for iOS)

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/JowinN/Expense_Tracker.git
   cd "Expense Tracker"
   ```

2. **Configure Firebase**:
   - Place your `google-services.json` inside the [android/app/](file:///C:/Users/RemoteUser/Desktop/Expense%20Tracker/android/app) folder.
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
