import 'package:flutter_test/flutter_test.dart';
import 'package:wear_os_sos/main.dart';
import 'package:wear_os_sos/services/zone_service.dart';
import 'package:wear_os_sos/services/sos_service.dart';

void main() {
  testWidgets('TourGuard Watch app loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TourGuardWatchApp());

    // Verify that SOS text is present
    expect(find.text('SOS'), findsOneWidget);

    // Cleanup
    ZoneService.dispose();
    SOSService.dispose();
  });
}
