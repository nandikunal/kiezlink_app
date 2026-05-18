import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'data/news_provider.dart';
import 'screens/today_screen.dart';
import 'services/prefs_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init prefs before anything else
  await PrefsService.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Request location on first launch (fire-and-forget; UI doesn't block)
  if (!PrefsService.getLocationAsked()) {
    LocationService.requestAndResolveLocation();
  }

  // Ensure display name is set
  LocationService.getOrCreateDisplayName();

  runApp(const KiezlinkApp());
}

class KiezlinkApp extends StatelessWidget {
  const KiezlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = NewsProvider();
        provider.initTopics();
        return provider;
      },
      child: MaterialApp(
        title: AppConfig.textAppTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppConfig.backgroundColor,
          colorScheme: const ColorScheme.dark(primary: AppConfig.primaryColor),
        ),
        home: const TodayScreen(),
      ),
    );
  }
}
