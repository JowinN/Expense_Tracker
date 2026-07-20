# Release Notes - SpendWise v1.0.0

We are excited to release **SpendWise v1.0.0**, a major release featuring core account management, interactive budgeting tools, financial statement exporters, and platform stability fixes.

---

## What's New in v1.0.0

### 🔄 Internal Fund Transfers
* **Safe Transfers Ledger**: Created a dedicated Transfers ledger screen to perform and log fund movements between bank accounts and credit cards.
* **Double-Count Prevention**: Transfers are completely excluded from dashboard graphs and standard income/expense statistics to preserve transaction accuracy.
* **Credit Card Headroom check**: In the transfer sheet, credit card entries dynamically calculate and display your available credit limit (`limit - utilized`) rather than the utilized balance.

### 💳 Drag-and-Drop Account Reordering
* **Custom Priority Order**: Added a drag handle to accounts and credit cards in the Settings tab, allowing you to prioritize the order of your assets.
* **Real-time Synchronization**: Reordering is saved dynamically back to Cloud Firestore and instantly updates the horizontal cards list on the Dashboard.

### 📂 Financial Exporters (PDF & Excel/CSV)
* **Custom PDF Report**: Generates a professional statement detailing net worth, total income/expense cards, account balance summaries, and chronological transaction tables matching the SpendWise color scheme.
* **Excel-Compatible CSV**: Outputs tabular transactions data ready to load in Microsoft Excel, Google Sheets, or Apple Numbers.
* **Native System Sharing**: Exports integrate with your device's native share sheet, allowing you to save to files, email, or send statements immediately.

### 🎨 UI polish & Layout Safeguards
* **Text Ellipsis**: Applied `maxLines: 1` and `TextOverflow.ellipsis` on transaction titles, creator tags, and profile metadata.
* **Dynamic Amount Scaling**: Wrapped balances, limits, and income/expense values inside `FittedBox` to scale font size down dynamically on narrow screens or under huge balance figures.
* **Dropdown Layout Fixes**: Expanded custom dropdown option layouts to prevent screen overflow.

### ⚙️ Android Build Configuration (SDK 35)
* **API Level 35 Support**: Upgraded `compileSdk` and `targetSdk` configuration to version `35` inside the application Gradle settings.
* **Subproject Override Hook**: Implemented a dynamic reflection and lifecycle state check inside the root build script. This ensures all plugins (such as `share_plus`) are successfully configured for SDK 35 at compile time.

---

## Technical Details
* **Build Signature**: `1.0.0+1`
* **Target Platforms**: Android (APK release built), iOS, Web
* **Database Backend**: Firebase Cloud Firestore
* **Min Android SDK**: 21
* **Target Android SDK**: 35
