import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'data/news_provider.dart';
import 'screens/today_screen.dart';
import 'services/session_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init session (device ID, funny name, read history, last index)
  await SessionService.init();

  // Request location on first launch only; subsequent launches use cached label
  if (!LocationService.permissionAlreadyAsked) {
    await LocationService.requestAndResolve();
  }

  runApp(const KiezlinkApp());
}

class KiezlinkApp extends StatelessWidget {
  const KiezlinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NewsProvider(),
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
