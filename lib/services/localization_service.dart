import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class LocalizationService {
  static const String boxName = 'localizationBox';
  static const String languageKey = 'selectedLanguage';
  
  static const Map<String, Map<String, String>> translations = {
    'en': {
      // Dashboard
      'dashboard': 'Dashboard',
      'safety_score': 'Safety Score',
      'current_location': 'Current Location',
      'nearby_zones': 'Nearby Zones',
      'active_alerts': 'Active Alerts',
      
      // Profile
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'country': 'Country',
      'emergency_contacts': 'Emergency Contacts',
      'member_since': 'Member Since',
      
      // Explore
      'explore': 'Explore',
      'nearby_places': 'Nearby Places',
      'categories': 'Categories',
      'all': 'All',
      'famous': 'Famous',
      'food': 'Food',
      'adventure': 'Adventure',
      'hidden_gems': 'Hidden Gems',
      
      // Emergency
      'emergency': 'Emergency',
      'sos': 'SOS',
      'press_and_hold': 'Press and Hold',
      'police': 'Police',
      'ambulance': 'Ambulance',
      'fire': 'Fire Department',
      'share_location': 'Share My Location',
      'call_police': 'Call Police',
      'report_incident': 'Report Incident',
      
      // Incident Report
      'incident_report': 'Report Incident',
      'incident_title': 'Incident Title',
      'category': 'Category',
      'urgency_level': 'Urgency Level',
      'description': 'Description',
      'location': 'Location',
      'submit_report': 'Submit Report',
      'incident_reported': 'Incident Reported',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'critical': 'Critical',
      
      // Settings
      'settings': 'Settings',
      'language': 'Language',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'dark_mode': 'Dark Mode',
      'location_tracking': 'Location Tracking',
      'enable_location_tracking': 'Enable Location Tracking',
      'about': 'About',
      'version': 'Version',
      'logout': 'Logout',
      
      // Common
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'no_data': 'No data available',
    },
    'hi': {
      // Dashboard
      'dashboard': 'डैशबोर्ड',
      'safety_score': 'सुरक्षा स्कोर',
      'current_location': 'वर्तमान स्थान',
      'nearby_zones': 'निकटवर्ती क्षेत्र',
      'active_alerts': 'सक्रिय अलर्ट',
      
      // Profile
      'profile': 'प्रोफाइल',
      'edit_profile': 'प्रोफाइल संपादित करें',
      'name': 'नाम',
      'email': 'ईमेल',
      'phone': 'फोन',
      'country': 'देश',
      'emergency_contacts': 'आपातकालीन संपर्क',
      'member_since': 'सदस्य बनने की तारीख',
      
      // Explore
      'explore': 'अन्वेषण करें',
      'nearby_places': 'निकटवर्ती स्थान',
      'categories': 'श्रेणियां',
      'all': 'सभी',
      'famous': 'प्रसिद्ध',
      'food': 'भोजन',
      'adventure': 'रोमांच',
      'hidden_gems': 'छिपे हुए रत्न',
      
      // Emergency
      'emergency': 'आपातकाल',
      'sos': 'एसओएस',
      'press_and_hold': 'दबाएं और होल्ड करें',
      'police': 'पुलिस',
      'ambulance': 'एम्बुलेंस',
      'fire': 'अग्निशमन विभाग',
      'share_location': 'अपना स्थान साझा करें',
      'call_police': 'पुलिस को कॉल करें',
      'report_incident': 'घटना की रिपोर्ट करें',
      
      // Incident Report
      'incident_report': 'घटना की रिपोर्ट करें',
      'incident_title': 'घटना का शीर्षक',
      'category': 'श्रेणी',
      'urgency_level': 'आपातकाल का स्तर',
      'description': 'विवरण',
      'location': 'स्थान',
      'submit_report': 'रिपोर्ट जमा करें',
      'incident_reported': 'घटना की सूचना दी गई',
      'low': 'कम',
      'medium': 'मध्यम',
      'high': 'अधिक',
      'critical': 'गंभीर',
      
      // Settings
      'settings': 'सेटिंग्स',
      'language': 'भाषा',
      'notifications': 'सूचनाएं',
      'enable_notifications': 'सूचनाओं को सक्षम करें',
      'dark_mode': 'डार्क मोड',
      'location_tracking': 'स्थान ट्रैकिंग',
      'enable_location_tracking': 'स्थान ट्रैकिंग को सक्षम करें',
      'about': 'के बारे में',
      'version': 'संस्करण',
      'logout': 'लॉग आउट',
      
      // Common
      'ok': 'ठीक है',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'close': 'बंद करें',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'no_data': 'कोई डेटा उपलब्ध नहीं',
    },
    'es': {
      // Dashboard
      'dashboard': 'Panel de control',
      'safety_score': 'Puntuación de seguridad',
      'current_location': 'Ubicación actual',
      'nearby_zones': 'Zonas cercanas',
      'active_alerts': 'Alertas activas',
      
      // Profile
      'profile': 'Perfil',
      'edit_profile': 'Editar perfil',
      'name': 'Nombre',
      'email': 'Correo electrónico',
      'phone': 'Teléfono',
      'country': 'País',
      'emergency_contacts': 'Contactos de emergencia',
      'member_since': 'Miembro desde',
      
      // Explore
      'explore': 'Explorar',
      'nearby_places': 'Lugares cercanos',
      'categories': 'Categorías',
      'all': 'Todos',
      'famous': 'Famoso',
      'food': 'Comida',
      'adventure': 'Aventura',
      'hidden_gems': 'Joyas ocultas',
      
      // Emergency
      'emergency': 'Emergencia',
      'sos': 'SOS',
      'press_and_hold': 'Presione y mantenga',
      'police': 'Policía',
      'ambulance': 'Ambulancia',
      'fire': 'Bomberos',
      'share_location': 'Compartir mi ubicación',
      'call_police': 'Llamar a la policía',
      'report_incident': 'Reportar incidente',
      
      // Incident Report
      'incident_report': 'Reportar incidente',
      'incident_title': 'Título del incidente',
      'category': 'Categoría',
      'urgency_level': 'Nivel de urgencia',
      'description': 'Descripción',
      'location': 'Ubicación',
      'submit_report': 'Enviar reporte',
      'incident_reported': 'Incidente reportado',
      'low': 'Bajo',
      'medium': 'Medio',
      'high': 'Alto',
      'critical': 'Crítico',
      
      // Settings
      'settings': 'Configuración',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'enable_notifications': 'Habilitar notificaciones',
      'dark_mode': 'Modo oscuro',
      'location_tracking': 'Seguimiento de ubicación',
      'enable_location_tracking': 'Habilitar seguimiento de ubicación',
      'about': 'Acerca de',
      'version': 'Versión',
      'logout': 'Cerrar sesión',
      
      // Common
      'ok': 'OK',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Añadir',
      'close': 'Cerrar',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'no_data': 'No hay datos disponibles',
    },
  };

  // Initialize localization
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  // Get current language
  static String getCurrentLanguage() {
    try {
      final box = Hive.box(boxName);
      return box.get(languageKey, defaultValue: 'en');
    } catch (e) {
      return 'en';
    }
  }

  // Set language
  static Future<void> setLanguage(String languageCode) async {
    try {
      final box = Hive.box(boxName);
      await box.put(languageKey, languageCode);
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // Get translated string
  static String translate(String key) {
    final currentLanguage = getCurrentLanguage();
    return translations[currentLanguage]?[key] ?? translations['en']?[key] ?? key;
  }

  // Get all available languages
  static List<String> getAvailableLanguages() {
    return translations.keys.toList();
  }

  // Get language name in English
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'es':
        return 'Spanish (Español)';
      default:
        return code;
    }
  }

  // Format date based on current language
  static String formatDate(DateTime date) {
    final currentLanguage = getCurrentLanguage();
    switch (currentLanguage) {
      case 'es':
        final formatter = DateFormat('dd/MM/yyyy', 'es_ES');
        return formatter.format(date);
      default:
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  // Format time based on current language
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Simple translation helper
String tr(String key) => LocalizationService.translate(key);
