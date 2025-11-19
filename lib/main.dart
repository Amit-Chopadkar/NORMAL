import 'package:flutter/material.dart';
import 'package:tourist_safety_hub/screens/dashboard_screen.dart';
// geofence_demo is available in the project but not set as the home screen.
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
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, languageCode, _) {
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
          home: const MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, languageCode, _) {
        final screens = [
          DashboardScreen(key: ValueKey('dashboard-$languageCode')),
          ProfileScreen(key: ValueKey('profile-$languageCode')),
          ExploreScreen(key: ValueKey('explore-$languageCode')),
          EmergencyScreen(key: ValueKey('emergency-$languageCode')),
          SettingsScreen(key: ValueKey('settings-$languageCode')),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: tr('dashboard'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                label: tr('profile'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined),
                label: tr('explore'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.warning_amber_rounded),
                label: tr('emergency'),
                backgroundColor: Colors.blue[800],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                label: tr('settings'),
                backgroundColor: Colors.blue[800],
              ),
            ],
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}