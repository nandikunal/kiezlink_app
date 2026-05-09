# KiezLink App - Deployment & Configuration Guide

## Overview
This guide covers Android and iOS-specific configurations to ensure optimal performance and compatibility.

## Android Configuration

### Network Security
The app is configured to allow cleartext (HTTP) traffic for local development API servers.

**File**: `android/app/src/main/res/xml/network_security_config.xml`

This configuration allows:
- Android Emulator: 10.0.2.2 (special alias for host machine)
- Physical Devices: Add your machine's IP address (e.g., 192.168.1.x)

#### To configure for physical devices:
1. Find your machine's IP address: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Update `network_security_config.xml`:
   ```xml
   <domain includeSubdomains="true">YOUR_MACHINE_IP</domain>
   ```
3. Update API URL in `lib/config/constants.dart`:
   ```dart
   static const String apiUrlDevices = 'http://YOUR_MACHINE_IP:8000/v1/today?page=1&per_page=20';
   ```

### Required Permissions
The following permissions are already configured in `AndroidManifest.xml`:
- `INTERNET`: For HTTP requests to API
- `ACCESS_NETWORK_STATE`: For connectivity checks

### Build Configuration
- Minimum SDK: 21 (Android 5.0)
- Target SDK: Latest stable
- Supports both ARM and x86 architectures

#### Building for Android:
```bash
flutter build apk --release              # APK for sideloading
flutter build appbundle --release        # AAB for Google Play
```

## iOS Configuration

### Network Configuration
iOS allows cleartext traffic by default during development. For production, consider using HTTPS.

#### To configure App Transport Security:
1. Open `ios/Runner/Info.plist`
2. For local development HTTP, add:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSExceptionDomains</key>
       <dict>
           <key>localhost</key>
           <dict>
               <key>NSIncludesSubdomains</key>
               <true/>
               <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
           <key>YOUR_MACHINE_IP</key>
           <dict>
               <key>NSIncludesSubdomains</key>
               <true/>
               <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
       </dict>
   </dict>
   ```

### Required Capabilities
The app requires the following capabilities on iOS:
- Network access (already default)
- URL Scheme handling (for opening links)

#### Configuring URL Schemes:
The app uses `url_launcher` which requires proper configuration.
No additional configuration needed for standard HTTP/HTTPS URLs.

### Building for iOS:
```bash
flutter build ios --release              # Build for physical devices
flutter build ios --simulator            # Build for iOS Simulator
```

## API Configuration

### Environment Variables
Configure your API endpoint in `lib/config/constants.dart`:

```dart
// For Android Emulator
static const String apiUrlAndroid = 'http://10.0.2.2:8000/v1/today?page=1&per_page=20';

// For physical devices (update with your IP)
static const String apiUrlDevices = 'http://192.168.1.100:8000/v1/today?page=1&per_page=20';
```

### API Authentication
The app uses API Key authentication. Update in `constants.dart`:
```dart
static const String apiKey = 'your-api-key-here';
```

## Performance Optimization

### Image Caching
- The app uses `cached_network_image` for automatic image caching
- Cache is stored locally and valid for 5 minutes by default

### HTTP Caching
- HTTP responses are cached for 5 minutes
- Clear cache: `RssService.clearCache()`

### Search Optimization
- Search queries are debounced (300ms) to reduce unnecessary filtering
- Only triggers UI updates after typing stops

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Specific Test File
```bash
flutter test test/utils_test.dart
flutter test test/news_provider_test.dart
```

## Troubleshooting

### Android Emulator Cannot Reach API
- Ensure API is running: `python manage.py runserver 0.0.0.0:8000`
- Use 10.0.2.2 instead of localhost for emulator
- Check firewall settings

### iOS Simulator Cannot Reach API
- Use `localhost` or `127.0.0.1` for iOS simulator
- Ensure API is running locally
- Check App Transport Security configuration

### SSL/TLS Certificate Errors
- For local development, HTTP (not HTTPS) is configured
- For production, use HTTPS with valid certificates
- Update network security config accordingly

### Memory Usage
- If experiencing memory issues:
  - Clear image cache: `CachedNetworkImage` provides built-in garbage collection
  - Reduce number of pre-loaded items
  - Monitor with DevTools Performance tab

## Production Deployment

### Security Checklist
- [ ] Change API key to production key
- [ ] Remove debug logging (set log level appropriately)
- [ ] Enable HTTPS for all API requests
- [ ] Update App Transport Security for iOS
- [ ] Remove cleartext traffic exceptions
- [ ] Add proper error handling for API failures
- [ ] Implement analytics/crash reporting

### Code Obfuscation
```bash
flutter build apk --obfuscate --split-debug-info=./debug_symbols
```

### App Store Submission
1. Update version in `pubspec.yaml`
2. Update app icons and splash screens
3. Configure signing certificates
4. Test thoroughly on physical devices
5. Submit to respective app stores

## Support & Documentation

- Flutter: https://flutter.dev/docs
- Dart: https://dart.dev/guides
- HTTP Package: https://pub.dev/packages/http
- Provider Package: https://pub.dev/packages/provider
