import 'package:flutter_test/flutter_test.dart';
import 'tier1_feature_test.dart' as tier1;
import 'tier2_boundary_test.dart' as tier2;
import 'tier3_combination_test.dart' as tier3;
import 'tier4_application_test.dart' as tier4;

void main() {
  group('HouseholdStratagem Master E2E Test Suite (Tiers 1–4)', () {
    tier1.main();
    tier2.main();
    tier3.main();
    tier4.main();
  });
}
