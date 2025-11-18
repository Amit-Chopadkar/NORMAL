import 'package:flutter/material.dart';
import 'package:tourist_safety_hub/screens/splash_screen.dart';
import 'package:tourist_safety_hub/screens/dashboard_screen.dart';
import 'package:tourist_safety_hub/screens/profile_screen.dart';
import 'package:tourist_safety_hub/screens/explore_screen.dart';
import 'package:tourist_safety_hub/screens/emergency_screen.dart';
import 'package:tourist_safety_hub/screens/settings_screen_v2.dart';
import 'package:tourist_safety_hub/screens/incident_report_screen.dart';
import 'package:tourist_safety_hub/services/notification_service.dart';
import 'package:tourist_safety_hub/services/api_service.dart';
import 'package:tourist_safety_hub/services/chat_service.dart';
import 'package:tourist_safety_hub/services/incident_service.dart';
import 'package:tourist_safety_hub/services/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await NotificationService.initialize();
  await ApiService.initCache();
  await ChatService.initialize();
  await IncidentService.initIncidents();
  await LocalizationService.initialize();
  
  runApp(const TouristSafetyHub());
}

class TouristSafetyHub extends StatelessWidget {
  const TouristSafetyHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tourist Safety Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const MainNavigationScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProfileScreen(),
    ExploreScreen(),
    EmergencyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Dashboard',
            backgroundColor: Colors.blue[800],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: 'Profile',
            backgroundColor: Colors.blue[800],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            label: 'Explore',
            backgroundColor: Colors.blue[800],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.warning_amber_rounded),
            label: 'Emergency',
            backgroundColor: Colors.blue[800],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: 'Settings',
            backgroundColor: Colors.blue[800],
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },//ppp
      ),
    );
  }
}