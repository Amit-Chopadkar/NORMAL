import 'package:flutter/widgets.dart';

import '../services/localization_service.dart';

extension LocalizationContextExtension on BuildContext {
  String loc(String text) => LocalizationService.translate(text);
}

