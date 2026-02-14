# SavvySpend 💰

A modern, feature-rich Flutter application for tracking personal finances, managing budgets, and handling shared expenses with ease. Built with performance and user experience in mind, utilizing local storage for privacy and speed.

## ✨ Features

- **Expense Tracking**: Easily add and categorize your daily expenses.
- **Smart Analytics**: Visualize your spending habits with interactive charts and graphs (powered by `fl_chart`).
- **Budget Management**: Set monthly budgets and get real-time tracking of your remaining balance.
- **People & Splitting**: Manage a list of people and track expenses shared with them.
- **Local Storage**: All data is stored locally on your device using **Hive**, ensuring privacy and offline availability.
- **Dark Mode**: Beautifully designed UI with seamless light and dark theme switching.
- **Export & Share**: Share expense details or summaries with others.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [Hive](https://pub.dev/packages/hive) (Fast, NoSQL)
- **Charting**: [fl_chart](https://pub.dev/packages/fl_chart)
- **Utils**: `intl` (formatting), `uuid` (unique IDs), `logger` (debugging), `share_plus` (sharing).

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- An IDE (VS Code, Android Studio, etc.) with Flutter plugins.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/savvvy48/expenses-app.git
    cd expenses-app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    # Run on a connected device or emulator
    flutter run
    ```

## 📂 Project Structure

The project follows a clean architecture approach:

```
lib/
├── core/
│   ├── constants/      # App-wide constants (colors, strings)
│   ├── data/           # Repositories and Hive implementation
│   ├── services/       # Helper services (Logger, Validation)
│   ├── theme/          # App theme definitions
│   └── widgets/        # Reusable UI components
├── models/             # Data models (Expense, Budget, Person)
├── providers/          # State management (ViewModels)
├── screens/            # UI Screens (Home, Add Expense, Analytics, etc.)
└── main.dart           # Entry point
```

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve the app.

---

Made with ❤️ using Flutter.