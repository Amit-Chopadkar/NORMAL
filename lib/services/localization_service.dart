import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class LocalizationService {
  static const String boxName = 'localizationBox';
  static const String languageKey = 'selectedLanguage';

  /// Notifies listeners when the active language changes so the UI can rebuild.
  static final ValueNotifier<String> languageNotifier =
      ValueNotifier<String>('en');
  
  static const Map<String, Map<String, String>> translations = {
    'en': {
      // Dashboard
      'dashboard': 'Dashboard',
      'safety_score': 'Safety Score',
      'current_location': 'Current Location',
      'nearby_zones': 'Nearby Zones',
      'active_alerts': 'Active Alerts',
      'tourist_safety_score': 'Tourist Safety Score',
      'out_of_100': 'Out of 100',
      'current_zone': 'Current Zone',
      'time': 'Time',
      'crowd_density': 'Crowd Density',
      'weather': 'Weather',
      'your_location_nearby_zones': 'Your Location & Nearby Zones',
      
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
      'explore_nashik': 'Explore Nashik',
      'nearby_places': 'Nearby Places',
      'categories': 'Categories',
      'all': 'All',
      'famous': 'Famous',
      'food': 'Food',
      'adventure': 'Adventure',
      'hidden_gems': 'Hidden Gems',
      
      // Emergency
      'emergency': 'Emergency',
      'emergency_contacts_title': 'Emergency Contacts',
      'sos': 'SOS',
      'alert_sent': 'ALERT SENT',
      'emergency_services_notified': 'Emergency Services Notified',
      'press_to_send_alert': 'Press to Send Alert',
      'sos_alert': 'SOS Alert',
      'sos_alert_message':
          'Are you in immediate danger? This will send an alert to emergency services and your emergency contacts with your current location.',
      'send_sos_alert': 'Send SOS Alert',
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
      'incident_title_hint': 'Brief title of the incident',
      'category': 'Category',
      'urgency_level': 'Urgency Level',
      'description': 'Description',
      'description_hint': 'Provide detailed description of the incident',
      'location': 'Location',
      'update_location': 'Update Location',
      'submit_report': 'Submit Report',
      'incident_reported': 'Incident Reported',
      'incident_id': 'Incident ID',
      'incident_success_message':
          'Your incident has been reported and authorities have been notified.',
      'low': 'Low',
      'medium': 'Medium',
      'high': 'High',
      'critical': 'Critical',
      'incident_info_box':
          'Your report will be immediately sent to local authorities. They may contact you for additional information. Keep your incident ID for reference.',
      
      // Settings
      'settings': 'Settings',
      'safety_monitoring': 'Safety & Monitoring',
      'incident_tracking': 'Incident Tracking',
      'family_contacts': 'Family & Contacts',
      'language_region': 'Language & Region',
      'my_incident_reports': 'My Incident Reports',
      'view_and_track_reports': 'View and track your reports',
      'family_tracking': 'Family Tracking',
      'share_location_family': 'Share Location with Family',
      'language': 'Language',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable Notifications',
      'dark_mode': 'Dark Mode',
      'location_tracking': 'Location Tracking',
      'enable_location_tracking': 'Enable Location Tracking',
      'about': 'About',
      'version': 'Version',
      'logout': 'Logout',
      'logout_confirm_message': 'Are you sure you want to logout?',
      'logged_out_successfully': 'Logged out successfully',
      
      // Common
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'close': 'Close',
      'language_changed': 'Language updated successfully',
      'add_emergency_contact': 'Add Emergency Contact',
      'no_incidents_yet': 'No incidents reported yet',
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
      'tourist_safety_score': 'पर्यटक सुरक्षा स्कोर',
      'out_of_100': '100 में से',
      'current_zone': 'वर्तमान ज़ोन',
      'time': 'समय',
      'crowd_density': 'भीड़ घनत्व',
      'weather': 'मौसम',
      'your_location_nearby_zones': 'आपका स्थान और पास के क्षेत्र',
      
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
      'explore_nashik': 'नासिक घूमें',
      'nearby_places': 'निकटवर्ती स्थान',
      'categories': 'श्रेणियां',
      'all': 'सभी',
      'famous': 'प्रसिद्ध',
      'food': 'भोजन',
      'adventure': 'रोमांच',
      'hidden_gems': 'छिपे हुए रत्न',
      
      // Emergency
      'emergency': 'आपातकाल',
      'emergency_contacts_title': 'आपातकालीन संपर्क',
      'sos': 'एसओएस',
      'alert_sent': 'अलर्ट भेजा गया',
      'emergency_services_notified': 'आपातकालीन सेवाओं को सूचित किया गया',
      'press_to_send_alert': 'अलर्ट भेजने के लिए दबाएं',
      'sos_alert': 'एसओएस अलर्ट',
      'sos_alert_message':
          'क्या आप तत्काल खतरे में हैं? यह आपकी वर्तमान लोकेशन के साथ आपातकालीन सेवाओं और आपके आपातकालीन संपर्कों को अलर्ट भेजेगा।',
      'send_sos_alert': 'एसओएस अलर्ट भेजें',
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
      'incident_title_hint': 'घटना का संक्षिप्त शीर्षक',
      'category': 'श्रेणी',
      'urgency_level': 'आपातकाल का स्तर',
      'description': 'विवरण',
      'description_hint': 'घटना का विस्तृत विवरण प्रदान करें',
      'location': 'स्थान',
      'update_location': 'स्थान अपडेट करें',
      'submit_report': 'रिपोर्ट जमा करें',
      'incident_reported': 'घटना की सूचना दी गई',
      'incident_id': 'घटना आईडी',
      'incident_success_message':
          'आपकी घटना की रिपोर्ट की जा चुकी है और अधिकारियों को सूचित किया गया है।',
      'low': 'कम',
      'medium': 'मध्यम',
      'high': 'उच्च',
      'critical': 'गंभीर',
      'incident_info_box':
          'आपकी रिपोर्ट तुरंत स्थानीय अधिकारियों को भेजी जाएगी। वे अतिरिक्त जानकारी के लिए आपसे संपर्क कर सकते हैं। कृपया अपने संदर्भ के लिए घटना आईडी सुरक्षित रखें।',
      
      // Settings
      'settings': 'सेटिंग्स',
      'safety_monitoring': 'सुरक्षा और मॉनिटरिंग',
      'incident_tracking': 'घटना ट्रैकिंग',
      'family_contacts': 'परिवार और संपर्क',
      'language_region': 'भाषा और क्षेत्र',
      'my_incident_reports': 'मेरी घटना रिपोर्ट्स',
      'view_and_track_reports': 'अपनी रिपोर्ट देखें और ट्रैक करें',
      'family_tracking': 'परिवार ट्रैकिंग',
      'share_location_family': 'परिवार के साथ स्थान साझा करें',
      'language': 'भाषा',
      'notifications': 'सूचनाएं',
      'enable_notifications': 'सूचनाओं को सक्षम करें',
      'dark_mode': 'डार्क मोड',
      'location_tracking': 'स्थान ट्रैकिंग',
      'enable_location_tracking': 'स्थान ट्रैकिंग को सक्षम करें',
      'about': 'के बारे में',
      'version': 'संस्करण',
      'logout': 'लॉग आउट',
      'logout_confirm_message': 'क्या आप वाकई लॉग आउट करना चाहते हैं?',
      'logged_out_successfully': 'सफलतापूर्वक लॉग आउट हो गए',
      
      // Common
      'ok': 'ठीक है',
      'cancel': 'रद्द करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'add': 'जोड़ें',
      'close': 'बंद करें',
      'language_changed': 'भाषा सफलतापूर्वक बदल दी गई',
      'add_emergency_contact': 'आपातकालीन संपर्क जोड़ें',
      'no_incidents_yet': 'अभी तक कोई घटना रिपोर्ट नहीं की गई',
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
      'tourist_safety_score': 'Puntuación de seguridad turística',
      'out_of_100': 'De 100',
      'current_zone': 'Zona actual',
      'time': 'Hora',
      'crowd_density': 'Densidad de gente',
      'weather': 'Clima',
      'your_location_nearby_zones': 'Tu ubicación y zonas cercanas',
      
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
      'explore_nashik': 'Explora Nashik',
      'nearby_places': 'Lugares cercanos',
      'categories': 'Categorías',
      'all': 'Todos',
      'famous': 'Famoso',
      'food': 'Comida',
      'adventure': 'Aventura',
      'hidden_gems': 'Joyas ocultas',
      
      // Emergency
      'emergency': 'Emergencia',
      'emergency_contacts_title': 'Contactos de emergencia',
      'sos': 'SOS',
      'alert_sent': 'ALERTA ENVIADA',
      'emergency_services_notified': 'Servicios de emergencia notificados',
      'press_to_send_alert': 'Presiona para enviar alerta',
      'sos_alert': 'Alerta SOS',
      'sos_alert_message':
          '¿Estás en peligro inmediato? Esto enviará una alerta a los servicios de emergencia y a tus contactos de emergencia con tu ubicación actual.',
      'send_sos_alert': 'Enviar alerta SOS',
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
      'incident_title_hint': 'Título breve del incidente',
      'category': 'Categoría',
      'urgency_level': 'Nivel de urgencia',
      'description': 'Descripción',
      'description_hint': 'Proporciona una descripción detallada del incidente',
      'location': 'Ubicación',
      'update_location': 'Actualizar ubicación',
      'submit_report': 'Enviar reporte',
      'incident_reported': 'Incidente reportado',
      'incident_id': 'ID de incidente',
      'incident_success_message':
          'Tu incidente ha sido reportado y las autoridades han sido notificadas.',
      'low': 'Bajo',
      'medium': 'Medio',
      'high': 'Alto',
      'critical': 'Crítico',
      'incident_info_box':
          'Tu reporte se enviará inmediatamente a las autoridades locales. Pueden contactarte para más información. Guarda tu ID de incidente para referencia.',
      
      // Settings
      'settings': 'Configuración',
      'safety_monitoring': 'Seguridad y monitoreo',
      'incident_tracking': 'Seguimiento de incidentes',
      'family_contacts': 'Familia y contactos',
      'language_region': 'Idioma y región',
      'my_incident_reports': 'Mis reportes de incidentes',
      'view_and_track_reports': 'Ver y seguir tus reportes',
      'family_tracking': 'Seguimiento familiar',
      'share_location_family': 'Compartir ubicación con la familia',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'enable_notifications': 'Habilitar notificaciones',
      'dark_mode': 'Modo oscuro',
      'location_tracking': 'Seguimiento de ubicación',
      'enable_location_tracking': 'Habilitar seguimiento de ubicación',
      'about': 'Acerca de',
      'version': 'Versión',
      'logout': 'Cerrar sesión',
      'logout_confirm_message': '¿Seguro que deseas cerrar sesión?',
      'logged_out_successfully': 'Cierre de sesión exitoso',
      
      // Common
      'ok': 'OK',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'add': 'Añadir',
      'close': 'Cerrar',
      'language_changed': 'Idioma actualizado correctamente',
      'add_emergency_contact': 'Agregar contacto de emergencia',
      'no_incidents_yet': 'Aún no se han reportado incidentes',
      'loading': 'Cargando...',
      'error': 'Error',
      'success': 'Éxito',
      'no_data': 'No hay datos disponibles',
    },
    'pa': {
      // Punjabi (Gurmukhi)
      'dashboard': 'ਡੈਸ਼ਬੋਰਡ',
      'safety_score': 'ਸੁਰੱਖਿਆ ਸਕੋਰ',
      'current_location': 'ਮੌਜੂਦਾ ਸਥਿਤੀ',
      'nearby_zones': 'ਨੇੜਲੇ ਖੇਤਰ',
      'active_alerts': 'ਸਕ੍ਰਿਆ ਚੇਤਾਵਨੀਆਂ',
      'profile': 'ਪ੍ਰੋਫ਼ਾਈਲ',
      'explore': 'ਖੋਜੋ',
      'emergency': 'ਐਮਰਜੈਂਸੀ',
      'settings': 'ਸੈਟਿੰਗਾਂ',
      'language': 'ਭਾਸ਼ਾ',
      'emergency_contacts': 'ਐਮਰਜੈਂਸੀ ਸੰਪਰਕ',
      'incident_report': 'ਘਟਨਾ ਰਿਪੋਰਟ',
      'sos': 'SOS',
      'share_location': 'ਮੇਰਾ ਸਥਾਨ ਸਾਂਝਾ ਕਰੋ',
      'call_police': 'ਪੁਲਿਸ ਨੂੰ ਕਾਲ ਕਰੋ',
      'report_incident': 'ਘਟਨਾ ਦੀ ਰਿਪੋਰਟ ਕਰੋ',
      'ok': 'ਠੀਕ ਹੈ',
      'cancel': 'ਰੱਦ ਕਰੋ',
      'save': 'ਸੰਭਾਲੋ',
      'logout': 'ਲਾਗ ਆਉਟ',
    },
    'gu': {
      // Gujarati
      'dashboard': 'ડેશબોર્ડ',
      'safety_score': 'સુરક્ષા સ્કોર',
      'current_location': 'હાલનું સ્થાન',
      'nearby_zones': 'આસપાસના ઝોન',
      'active_alerts': 'સક્રિય એલર્ટ',
      'profile': 'પ્રોફાઇલ',
      'explore': 'શોધો',
      'emergency': 'ઇમરજન્સી',
      'settings': 'સેટિંગ્સ',
      'language': 'ભાષા',
      'emergency_contacts': 'ઇમરજન્સી સંપર્કો',
      'incident_report': 'ઘટના રિપોર્ટ',
      'sos': 'SOS',
      'share_location': 'મારું લોકેશન શેર કરો',
      'call_police': 'પોલીસને કૉલ કરો',
      'report_incident': 'ઘટનાની જાણ કરો',
      'ok': 'ઓકે',
      'cancel': 'રદ્દ કરો',
      'save': 'સેવ કરો',
      'logout': 'લોગ આઉટ',
    },
    'kn': {
      // Kannada
      'dashboard': 'ಡ್ಯಾಶ್ಬೋರ್ಡ್',
      'safety_score': 'ಭದ್ರತಾ ಅಂಕ',
      'current_location': 'ಪ್ರಸ್ತುತ ಸ್ಥಳ',
      'nearby_zones': 'ಸಮೀಪದ ವಲಯಗಳು',
      'active_alerts': 'ಸಕ್ರಿಯ ಎಚ್ಚರಿಕೆಗಳು',
      'profile': 'ಪ್ರೊಫೈಲ್',
      'explore': 'ಅನ್ವೇಷಿಸಿ',
      'emergency': 'ತುರ್ತು',
      'settings': 'ಸೆಟ್ಟಿಂಗ್ಗಳು',
      'language': 'ಭಾಷೆ',
      'emergency_contacts': 'ತುರ್ತು ಸಂಪರ್ಕಗಳು',
      'incident_report': 'ಘಟನೆ ವರದಿ',
      'sos': 'SOS',
      'share_location': 'ನನ್ನ ಸ್ಥಳ ಹಂಚಿಕೊಳ್ಳಿ',
      'call_police': 'ಪೊಲಿಸರಿಗೆ ಕರೆ ಮಾಡಿ',
      'report_incident': 'ಘಟನೆಯನ್ನು ವರದಿ ಮಾಡಿ',
      'ok': 'ಸರಿ',
      'cancel': 'ರದ್ದು ಮಾಡಿ',
      'save': 'ಉಳಿಸು',
      'logout': 'ಲಾಗ್ ಔಟ್',
    },
    'bn': {
      // Bengali
      'dashboard': 'ড্যাশবোর্ড',
      'safety_score': 'নিরাপত্তা স্কোর',
      'current_location': 'বর্তমান অবস্থান',
      'nearby_zones': 'কাছাকাছি অঞ্চল',
      'active_alerts': 'সক্রিয় সতর্কতা',
      'profile': 'প্রোফাইল',
      'explore': 'অন্বেষণ',
      'emergency': 'জরুরি',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'emergency_contacts': 'জরুরি যোগাযোগ',
      'incident_report': 'ঘটনা রিপোর্ট',
      'sos': 'SOS',
      'share_location': 'আমার অবস্থান শেয়ার করুন',
      'call_police': 'পুলিশকে কল করুন',
      'report_incident': 'ঘটনা রিপোর্ট করুন',
      'ok': 'ঠিক আছে',
      'cancel': 'বাতিল',
      'save': 'সংরক্ষণ',
      'logout': 'লগ আউট',
    },
    'ml': {
      // Malayalam
      'dashboard': 'ഡാഷ്ബോർഡ്',
      'safety_score': 'സുരക്ഷാ സ്കോർ',
      'current_location': 'നിലവിലെ സ്ഥലം',
      'nearby_zones': 'അടുത്തുള്ള മേഖലകൾ',
      'active_alerts': 'സജ്ജമായ മുന്നറിയിപ്പുകൾ',
      'profile': 'പ്രൊഫൈൽ',
      'explore': 'അന്വേഷിക്കുക',
'emergency': 'ആപത് സ്ഥിതി',
      'settings': 'സെറ്റിംഗ്സ്',
      'language': 'ഭാഷ',
      'emergency_contacts': 'ആപത് കോൺടാക്ടുകൾ',
      'incident_report': 'സംഭവ റിപ്പോർട്ട്',
      'sos': 'SOS',
      'share_location': 'എന്റെ ലൊക്കേഷൻ ഷെയർ ചെയ്യുക',
      'call_police': 'പോലീസിനെ വിളിക്കുക',
      'report_incident': 'സംഭവം റിപ്പോർട്ട് ചെയ്യുക',
      'ok': 'ശരി',
      'cancel': 'റദ്ദാക്കുക',
      'save': 'സംരക്ഷിക്കുക',
      'logout': 'ലോഗ് ഔട്ട്',
    },
    'ur': {
      // Urdu
      'dashboard': 'ڈیش بورڈ',
      'safety_score': 'حفاظتی اسکور',
      'current_location': 'موجودہ مقام',
      'nearby_zones': 'قریبی زونز',
      'active_alerts': 'فعال انتباہات',
      'profile': 'پروفائل',
      'explore': 'ایکسپلور کریں',
      'emergency': 'ایمرجنسی',
      'settings': 'سیٹنگز',
      'language': 'زبان',
      'emergency_contacts': 'ہنگامی رابطے',
      'incident_report': 'واقعہ رپورٹ',
      'sos': 'SOS',
      'share_location': 'میرا لوکیشن شیئر کریں',
      'call_police': 'پولیس کو کال کریں',
      'report_incident': 'واقعہ رپورٹ کریں',
      'ok': 'ٹھیک ہے',
      'cancel': 'منسوخ کریں',
      'save': 'محفوظ کریں',
      'logout': 'لاگ آؤٹ',
    },
    'te': {
      // Telugu
'dashboard': 'డాష్‌బోర్డ్',
      'safety_score': 'సురక్షా స్కోర్',
      'current_location': 'ప్రస్తుత స్థానం',
      'nearby_zones': 'సమీప ప్రాంతాలు',
      'active_alerts': 'సక్రియ హెచ్చరికలు',
      'profile': 'ప్రొఫైల్',
      'explore': 'అన్వేషించండి',
      'emergency': 'అత్యవసర',
      'settings': 'సెట్టింగ్లు',
      'language': 'భాష',
      'emergency_contacts': 'అత్యవసర సంప్రదింపులు',
      'incident_report': 'ఘటన నివేదిక',
      'sos': 'SOS',
      'share_location': 'నా స్థలాన్ని షేర్ చేయండి',
      'call_police': 'పోలీసులను కాల్ చేయండి',
      'report_incident': 'ఘటనను నివేదించండి',
      'ok': 'సరే',
      'cancel': 'రద్దు చేయండి',
      'save': 'సేవ్ చేయండి',
      'logout': 'లాగ్ అవుట్',
    },
  };

  // Initialize localization
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    // Seed the notifier from persisted value so the UI starts with
    // the last-selected language.
    languageNotifier.value = getCurrentLanguage();
  }

  // Get current language
  static String getCurrentLanguage() {
    try {
      final box = Hive.box(boxName);
      return box.get(languageKey, defaultValue: 'en') as String;
    } catch (_) {
      return languageNotifier.value;
    }
  }

// Set language
  static Future<void> setLanguage(String languageCode) async {
    // Update the in-memory language immediately so the UI reacts without delay.
    languageNotifier.value = languageCode;
    try {
      final box = Hive.box(boxName);
      await box.put(languageKey, languageCode);
    } catch (e) {
      // Persisting is best-effort; even if this fails, the current session
      // still reflects the newly selected language.
      // ignore: avoid_print
      print('Error setting language: $e');
    }
  }
 
  // Get translated string
  static String translate(String key) {
    // Use the in-memory notifier value so language changes are instant and
    // do not wait on Hive I/O.
    final currentLanguage = languageNotifier.value;
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
      case 'pa':
        return 'Punjabi (ਪੰਜਾਬੀ)';
      case 'gu':
        return 'Gujarati (ગુજરાતી)';
      case 'kn':
        return 'Kannada (ಕನ್ನಡ)';
      case 'bn':
        return 'Bengali (বাংলা)';
      case 'ml':
        return 'Malayalam (മലയാളം)';
      case 'ur':
        return 'Urdu (اردو)';
      case 'te':
        return 'Telugu (తెలుగు)';
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
