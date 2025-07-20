# 🚌 OASTH - Thessaloniki Public Transport App

<p align="center">
  <img src="assets/icons/app_icon.png" alt="OASTH App Logo" width="120" height="120">
</p>

<p align="center">
  <strong>Your smart companion for public transport in Thessaloniki</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.0+-blue.svg" alt="Dart Version">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

## 📱 About

OASTH is a comprehensive mobile application for navigating Thessaloniki's public transportation system. Built with Flutter, it provides real-time bus information, route planning, and an intuitive interface for both Greek and English users.

### ✨ Key Features

- 🚍 **Real-time Bus Arrivals** - Live arrival times for all bus stops
- 🗺️ **Interactive Maps** - Detailed route maps with live bus tracking
- 🔍 **Smart Search** - Find lines, stops, and routes instantly
- 📍 **Nearby Stops** - Discover bus stops near your location
- 🧭 **Route Planning** - Get directions using Google Maps integration
- 🌐 **Multilingual** - Full support for Greek and English
- ❤️ **Favorites** - Save your frequently used lines and stops
- 📱 **Offline Cache** - Access data even with poor connectivity
- ♿ **Accessibility** - Clear indicators for wheelchair-accessible stops

## 🏗️ Architecture

### Core Structure

```
lib/
├── api/                    # API layer
│   ├── api/               # API client and endpoints
│   └── responses/         # Response models
├── helpers/               # Utility classes
├── screens/               # UI screens
└── widgets/               # Reusable components
```

### Key Components

- **API Layer**: Optimized HTTP client with caching and retry mechanisms
- **State Management**: StatefulWidget with proper resource management
- **Localization**: Easy Localization for Greek/English support
- **Maps Integration**: Flutter Map with real-time data overlay
- **Navigation**: Material Design bottom navigation

## 🚀 Features Breakdown

### 🏠 Welcome Screen
- Quick access to nearby stops
- Featured news from OASTH
- Direct navigation to main features
- Location-based suggestions

### 🚌 Lines Browser
- Browse all available bus lines
- Filter by line number or alphabetically
- Favorites system for quick access
- Search functionality across all lines

### 📍 Stops Finder
- Search stops by name or 5-digit code
- QR code scanner integration
- Accessibility information
- Real-time arrival predictions

### 🗺️ Interactive Maps
- Live bus tracking on routes
- Nearby stops with distance filtering
- Tap-to-navigate to stop details
- Offline map support

### 🧭 Route Planning
- Integration with Google Maps
- Multiple travel modes (transit, walking, driving)
- Current location detection
- Recent searches history

### 📰 News & Updates
- Latest news from OASTH
- Search through announcements
- Share functionality
- Offline reading support

## 🛠️ Technical Stack

### Frontend
- **Flutter** 3.0+ - Cross-platform UI framework
- **Dart** 3.0+ - Programming language
- **Material Design** - UI/UX guidelines

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Networking & Data
  http: ^1.1.0
  json_annotation: ^4.8.1
  
  # Maps & Location
  flutter_map: ^6.1.0
  flutter_map_location_marker: ^8.0.0
  flutter_map_marker_cluster: ^1.3.4
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # UI Components
  carousel_slider: ^4.2.1
  bottom_navy_bar: ^6.0.0
  
  # Localization
  easy_localization: ^3.0.3
  
  # Storage
  shared_preferences: ^2.2.2
  
  # Utilities
  url_launcher: ^6.2.2
  maps_launcher: ^2.2.1
```

### Backend Integration
- **OASTH Telematics API** - Real-time transport data
- **Google Maps API** - Route planning and navigation
- **REST Architecture** - HTTP-based API communication

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-org/oasth-app.git
cd oasth-app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code (if needed)**
```bash
flutter packages pub run build_runner build
```

4. **Run the app**
```bash
flutter run
```

### Configuration

1. **API Configuration**
   - Update base URLs in `lib/api/api/api.dart`
   - Configure timeout settings in `ApiConfig`

2. **Localization Setup**
   - Translation files located in `assets/translations/`
   - Supported languages: `en.json`, `el.json`

3. **Maps Setup**
   - Configure map tiles URL in map widgets
   - Set up location permissions in platform files

## 📱 Screenshots

<p align="center">
  <img src="screenshots/welcome_screen.png" alt="Welcome Screen" width="200">
  <img src="screenshots/lines_browser.png" alt="Lines Browser" width="200">
  <img src="screenshots/stop_details.png" alt="Stop Details" width="200">
  <img src="screenshots/route_map.png" alt="Route Map" width="200">
</p>

## 🔧 API Integration

### OASTH Telematics API

The app integrates with OASTH's real-time telematics system:

- **Base URL**: `https://telematics.oasth.gr/api`
- **Authentication**: Session-based with PHPSESSID
- **Rate Limiting**: Built-in request throttling
- **Caching**: Intelligent caching for optimal performance

### Key Endpoints

```dart
// Get all bus lines
GET /?act=webGetLines

// Get real-time arrivals
GET /?act=getStopArrivals&p1={stopId}

// Get bus locations
GET /?act=getBusLocation&p1={routeCode}

// Get route details
GET /?act=webGetRoutesDetailsAndStops&p1={routeCode}
```

## 🌐 Localization

### Supported Languages
- **🇬🇷 Greek (el)** - Primary language
- **🇺🇸 English (en)** - Full translation support

### Adding New Languages

1. Create translation file: `assets/translations/{locale}.json`
2. Add translations for all keys
3. Update `supportedLocales` in main app configuration
4. Test thoroughly with new locale

## 🎨 Design System

### Theme Support
- **Light Theme** - Clean, modern interface
- **Dark Theme** - Eye-friendly dark mode
- **System Theme** - Follows device preferences

### Color Scheme
- **Primary**: Blue (#2196F3) - OASTH brand color
- **Secondary**: Various accent colors per feature
- **Error**: Red for warnings and errors
- **Success**: Green for confirmations

### Typography
- **Headlines**: Bold, clear hierarchy
- **Body Text**: Readable, accessible sizing
- **Captions**: Subtle, informative text

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Building for Production

### Android
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Build Configuration
- **App signing** configured in `android/app/build.gradle`
- **iOS certificates** managed through Xcode
- **Build flavors** for different environments

## 🚀 Performance Optimizations

### API Optimizations
- **Smart Caching**: Different cache durations per data type
- **Parallel Processing**: Concurrent API requests where appropriate
- **Request Limiting**: Prevents server overload
- **Retry Logic**: Exponential backoff for failed requests

### UI Optimizations
- **Lazy Loading**: Lists load items as needed
- **Image Caching**: Efficient image loading and caching
- **Animations**: Smooth, performant transitions
- **Memory Management**: Proper disposal of resources

## 🔒 Privacy & Security

### Data Handling
- **Location Data**: Only used for nearby stops feature
- **No Personal Data**: App doesn't collect personal information
- **Local Storage**: Preferences and cache stored locally
- **API Security**: HTTPS communication with certificate validation

### Permissions
- **Location**: For finding nearby stops (optional)
- **Internet**: For real-time data (required)
- **Storage**: For offline caching (minimal)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart)
- Use `flutter format` for consistent formatting
- Run `flutter analyze` before committing
- Write meaningful commit messages

## 📋 Roadmap

### Upcoming Features
- [ ] 🔔 **Push Notifications** - Service alerts and arrival notifications
- [ ] 🎫 **Digital Tickets** - Mobile ticketing integration
- [ ] 📊 **Usage Analytics** - Personal travel statistics
- [ ] 🌙 **Auto Dark Mode** - Time-based theme switching
- [ ] 🔄 **Offline Mode** - Enhanced offline capabilities
- [ ] 🎯 **Smart Suggestions** - AI-powered route recommendations

### Long-term Goals
- Integration with other transport modes (metro, taxi)
- Multi-city support for other Greek cities
- Advanced accessibility features
- Community features (stop ratings, crowdsourced data)

## 🐛 Known Issues

- Map performance on older devices may be limited
- Offline mode requires initial data download
- Some translations may need refinement

See [Issues](https://github.com/your-org/oasth-app/issues) for full list and reporting new bugs.

## 📞 Support

### Getting Help
- 📧 **Email**: support@oasth-app.com
- 💬 **Discord**: [Join our community](https://discord.gg/oasth-app)
- 📖 **Documentation**: [Full docs](https://docs.oasth-app.com)
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-org/oasth-app/issues)

### Feedback
We love hearing from users! Feel free to:
- Rate the app on app stores
- Submit feature requests
- Share your experience
- Contribute to translations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **OASTH** - For providing the public transport API
- **Flutter Team** - For the amazing framework
- **OpenStreetMap** - For map tiles and data
- **Community Contributors** - For translations and improvements

---

<p align="center">
  <strong>Made with ❤️ for Thessaloniki</strong>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.oasth.app">
    <img src="https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white" alt="Get it on Google Play">
  </a>
  <a href="https://apps.apple.com/app/oasth/id123456789">
    <img src="https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white" alt="Download on the App Store">
  </a>
</p>