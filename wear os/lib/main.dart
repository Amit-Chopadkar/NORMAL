import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved backend URL
  final prefs = await SharedPreferences.getInstance();
  final savedUrl = prefs.getString('backend_url');
  if (savedUrl != null) {
    ApiService.setBaseUrl(savedUrl);
  }
  
  runApp(const TourGuardWatchApp());
}

class TourGuardWatchApp extends StatelessWidget {
  const TourGuardWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TourGuard Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}
