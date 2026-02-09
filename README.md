# 🚌 BusLink

A modern Flutter application for bus ticket booking and management, featuring real-time seat selection, Firebase authentication, and cross-platform support.

# Logins

Customer:
buslink@gmail.com
12345678

Conductor:
conductor@buslink.com
123456

Admin:
admin@buslink.com
123456

## ✨ Features

- 🔐 **Authentication**
  - Email/Password sign-up and login
  - Google Sign-In integration
  - Secure Firebase Authentication

- 🎫 **Ticket Booking**
  - Browse available bus trips
  - Real-time seat selection
  - Interactive seat map with availability status
  - Booking confirmation and management

- 📱 **Cross-Platform**
  - Android
  - iOS
  - Web
  - Windows (Desktop)

- 🎨 **Modern UI**
  - Clean, intuitive interface
  - Material Design 3
  - Responsive layout for all screen sizes

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.35.4 or higher)
- [Firebase Account](https://firebase.google.com/)
- Android Studio or VS Code
- For iOS: Xcode (macOS only)
- For Android: Java 11 or higher

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/buslink.git
   cd buslink
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup** ⚠️ **REQUIRED**

   This app requires Firebase configuration. Follow these steps:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Download configuration files:
     - Android: `google-services.json` → place in `android/app/`
     - iOS: `GoogleService-Info.plist` → place in `ios/Runner/`

   **For detailed setup instructions, see [SETUP.md](SETUP.md)**

4. **Environment Variables**

   Create a `.env` file in the project root:

   ```env
   WEB_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
   SERVER_CLIENT_ID=your_web_client_id.apps.googleusercontent.com
   ```

   See `.env.example` for reference.

5. **Run the app**

   ```bash
   # Android/iOS
   flutter run

   # Web
   flutter run -d chrome

   # Windows
   flutter run -d windows
   ```

## 📁 Project Structure

```
buslink/
├── lib/
│   ├── controllers/       # Business logic controllers
│   ├── models/           # Data models
│   ├── services/         # API and authentication services
│   │   ├── auth_service.dart
│   │   └── firestore_service.dart
│   ├── views/            # UI screens
│   │   ├── auth/        # Login & signup screens
│   │   ├── home/        # Home screen
│   │   ├── booking/     # Seat selection & booking
│   │   └── placeholder/ # My tickets screen
│   └── main.dart        # App entry point
├── android/             # Android-specific code
├── ios/                 # iOS-specific code
├── web/                 # Web-specific code
└── windows/            # Windows-specific code
```

## 🔧 Configuration

### Android

- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: 36
- **Requires**: SHA-1 fingerprint added to Firebase

### iOS

- **Minimum Version**: iOS 12.0
- **Requires**: GoogleService-Info.plist configuration

### Web

- **Requires**: Web client ID meta tag in `index.html`

## 🛠️ Technologies Used

- **Framework**: Flutter 3.35.4
- **Language**: Dart 3.9.2
- **Backend**: Firebase
  - Firebase Auth
  - Cloud Firestore
- **State Management**: Provider
- **Authentication**:
  - Firebase Auth
  - Google Sign-In 7.2.0

## 📦 Key Dependencies

```yaml
firebase_core: ^4.2.1
firebase_auth: ^6.1.2
cloud_firestore: ^6.1.0
google_sign_in: ^7.2.0
provider: ^6.0.0
qr_flutter: ^4.1.0
intl: ^0.20.2
```

## 🔐 Security

- Sensitive configuration files (API keys, certificates) are excluded from version control
- See `.gitignore` for protected files
- Never commit:
  - `google-services.json`
  - `GoogleService-Info.plist`
  - `.env` files
  - `*.keystore` files

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- Your Name - Initial work

## 🐛 Known Issues

- Google Sign-In requires proper SHA-1 configuration for Android
- iOS requires additional Xcode setup for Google Sign-In

## 📞 Support

For setup help or issues:

- Open an issue on GitHub
- Check [SETUP.md](SETUP.md) for detailed configuration guide

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who help improve this project

---

**Note**: This app requires Firebase configuration to run. Please follow the setup instructions in [SETUP.md](SETUP.md) before running the app.
