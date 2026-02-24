# OASTH - Thessaloniki Public Transport App

<p align="center">
  <strong>Your smart companion for public transport in Thessaloniki</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.2+-blue.svg" alt="Dart Version">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey.svg" alt="Platform">
</p>

## About

OASTH is a mobile application for navigating Thessaloniki's public transportation system. Built with Flutter, it provides real-time bus tracking, offline A* route planning, live arrival times, and an intuitive interface in both Greek and English.

## Features

### Real-time Bus Tracking
- Live bus positions on the map with vehicle numbers
- Auto-refreshing arrival times at stops (30s interval)
- 10-second polling for bus locations in fullscreen map view

### Offline Route Planner (A* Algorithm)
- Graph-based pathfinding across 3,694 stops and 31,000+ edges
- Composite A* state `(stopCode|lastBusRouteCode)` for smart transfer detection
- Same-line backtracking prevention (3x penalty for taking the same line in opposite direction)
- Walking transfer edges (up to 500m, configurable)
- Transfer penalty that correctly persists through walking segments
- Disk caching of the route graph for instant startup
- Results include: distance, transfer count, stop count, journey segments

### Interactive Maps
- Trimmed polylines showing only the segment you ride
- Ghost polyline (35% opacity) showing the full bus route for context
- Live bus markers with vehicle numbers on the route map
- Walking segments shown as dotted lines
- Transfer point markers at bus change locations
- Start/end markers with distinct colors
- Multiple map types: OpenStreetMap, Google Maps, Satellite
- Dark mode tile support
- Offline map tile caching

### Smart Search & Geocoding
- Native phone geocoding on mobile (no API rate limits)
- Nominatim fallback for web platform
- Debounced search (800ms) with generation counter for stale result cancellation
- Stop search results shown immediately while address search loads
- Thessaloniki bounding box filtering

### Lines & Stops
- Browse all bus lines with search and filtering
- Favorite lines system with persistent storage
- Stop search by name or 5-digit code
- Real-time arrival predictions per stop
- Route details with stop listings

### Nearby Stops
- GPS-based nearby stop discovery
- Distance filtering
- Tap-to-navigate to stop details
- Clustered map markers

### News & Updates
- Latest announcements from OASTH
- Search and filter functionality

### UI/UX
- Shimmer loading placeholders (replaced all spinners)
- Material 3 design system
- Light, Dark, and System theme modes
- Greek and English localization
- Smooth animated transitions

## Architecture

### Project Structure

```
lib/
├── api/
│   ├── api/                    # HTTP client with cookie/CSRF handling, retry logic
│   └── responses/              # 16 response models (lines, stops, routes, bus locations, news)
├── data/
│   ├── oasth_repository.dart   # Single data source wrapping all API calls
│   ├── route_planner.dart      # A* pathfinding algorithm with composite state
│   ├── route_planner_models.dart # RouteEdge, OfflineRouteResult, RouteSegment, etc.
│   └── favorites_service.dart  # Singleton managing favorite lines
├── enums/
│   └── map_type.dart           # OSM, Google, Satellite
├── helpers/
│   ├── app_routes.dart         # GoRouter route definitions (11 routes)
│   ├── geocoding_helper.dart   # Native + Nominatim geocoding
│   ├── location_helper.dart    # GPS permission & location retrieval
│   ├── shared_preferences_helper.dart # Cache management
│   ├── theme_mode_controller.dart     # Theme state (ValueNotifier)
│   ├── theme_mode_helper.dart         # Theme persistence
│   ├── tile_layer_helper.dart         # Map tile layer with caching & dark mode
│   ├── map_type_helper.dart           # Map type persistence
│   └── ...                     # Language, formatting, color helpers
├── screens/
│   ├── home_page.dart          # Tab navigation (Stations, Lines, Best Route, More)
│   ├── welcome_page.dart       # Dashboard with map, quick actions, news carousel
│   ├── stops_page.dart         # Stop search
│   ├── stop_page.dart          # Stop details with live arrivals
│   ├── lines_page.dart         # Lines listing with favorites
│   ├── line_page.dart          # Line details
│   ├── line_info_page.dart     # Master line info
│   ├── line_route_page.dart    # Route display for a line
│   ├── best_route_page.dart    # Route planner orchestrator
│   ├── best_route/
│   │   ├── input_step.dart     # From/To input with address autocomplete
│   │   ├── results_step.dart   # Route results with arrival times
│   │   └── route_map.dart      # Inline + fullscreen maps with live bus tracking
│   ├── more_screen.dart        # Settings (theme, language, map type)
│   ├── news_screen.dart        # News listing
│   └── map_with_nearby_stations_widget.dart # Nearby stops map
└── widgets/
    ├── shimmer_loading.dart    # Shimmer placeholder system
    └── language_toggle.dart    # Greek/English flag toggle
```

### Key Patterns

- **Repository pattern** - `OasthRepository` as single data source
- **Singleton pattern** - `FavoritesService`, `RoutePlanner`, `PackageInfoPlusHelper`
- **ValueNotifier** - Theme mode state management
- **InheritedWidget** - Shimmer animation coordination
- **GoRouter** - Declarative navigation with typed extras

## Route Planner Algorithm

The route planner uses an A* algorithm with a composite state `(stopCode|lastBusRouteCode)` to correctly handle transfers:

1. **Graph Construction**: Builds edges from all OASTH routes (16,570 bus edges) plus walking transfers between nearby stops (14,508 walking edges within 400m radius)
2. **Composite State**: Each A* node carries both the current stop and the last bus route taken. This context persists through walking edges, enabling accurate transfer detection.
3. **Transfer Penalties**:
   - Legitimate transfer (different line): 800m equivalent penalty
   - Backtracking (same line, opposite direction): 2400m penalty (3x)
   - Walking: distance * 3.0 penalty factor
4. **Polyline Trimming**: Route details polylines are trimmed to only the boarding-to-alighting segment by finding nearest polyline points to each stop and slicing forward (never reversing - each route has its own directional polyline).

## API Integration

### OASTH Telematics API

- **Base URL**: `https://telematics.oasth.gr/api`
- **Authentication**: Session-based with PHPSESSID and CSRF tokens
- **Cookie Handling**: Custom `CookieClient` with Greece timezone support
- **Retry Logic**: Up to 3 retries with 15s timeout
- **Web Proxy**: `web/api-proxy.php` for CORS handling on web platform

### Key Endpoints

| Endpoint | Cache | Description |
|----------|-------|-------------|
| `webGetLines` | 30 min | All bus lines |
| `getStopArrivals` | 30 sec | Real-time arrivals at a stop |
| `getBusLocation` | None (10s timeout) | Live bus GPS positions |
| `webGetRoutesDetailsAndStops` | 30 min | Route geometry + stops |
| `webGetStops` | 30 min | All stops for a route |
| `getStopNameAndXY` | 30 min | Stop coordinates by code |

### Caching Strategy

- **Route details & lines**: 30-minute cache (rarely change)
- **Stop arrivals**: 30-second cache (frequently updated)
- **Bus locations**: No cache (real-time, polled every 10s)
- **Route planner graph**: Disk-cached, built once from API data

## Dependencies

```yaml
dependencies:
  flutter: sdk
  go_router: ^14.6.1          # Navigation
  http: ^1.6.0                # HTTP client
  flutter_map: ^8.2.2         # OpenStreetMap maps
  flutter_map_cache: ^1.0.2   # Offline tile caching
  flutter_map_marker_cluster: ^8.2.2   # Marker clustering
  flutter_map_location_marker: ^10.2.0 # User location marker
  latlong2: ^0.9.1            # Coordinate math
  geolocator: ^14.0.2         # GPS location
  geocoding: ^4.0.0           # Native address lookup
  location: ^8.0.1            # Location services
  easy_localization: ^3.0.8   # i18n (Greek/English)
  shared_preferences: ^2.5.4  # Local storage
  carousel_slider: ^5.1.2     # News carousel
  bottom_navy_bar: ^6.1.0     # Bottom navigation
  url_launcher: ^6.3.2        # External links
  maps_launcher: ^3.0.0+1     # Open in maps app
  package_info_plus: ^8.0.3   # App version info
  path_provider: ^2.1.4       # File system paths
  crypto: ^3.0.7              # Hashing utilities
  dio_cache_interceptor: ^3.5.0         # Cache layer
  dio_cache_interceptor_file_store: ^1.2.2  # File-based cache
```

## Getting Started

### Prerequisites
- Flutter SDK 3.2+
- Dart SDK 3.2+
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Installation

```bash
git clone <repository-url>
cd oasth
flutter pub get
flutter run
```

### Configuration

- **API URLs**: Configured in `lib/api/api/api.dart`
- **Translations**: `assets/translations/en-US.json` and `assets/translations/el-GR.json`
- **Map tiles**: Managed via `lib/helpers/tile_layer_helper.dart` (OSM, Google, Satellite)
- **Location permissions**: Platform-specific configuration in `android/` and `ios/`

## Localization

| Language | File | Status |
|----------|------|--------|
| Greek (el-GR) | `assets/translations/el-GR.json` | Primary |
| English (en-US) | `assets/translations/en-US.json` | Full support |

Language can be switched at runtime from the More screen without restarting the app.

## Building

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Acknowledgments

- **OASTH** - Thessaloniki Urban Transport Organization for the telematics API
- **OpenStreetMap** - Map tiles and Nominatim geocoding
- **Flutter** - Cross-platform framework

---

<p align="center">
  Made for Thessaloniki
</p>
