import 'package:artemis_work_planner/src/navigation/app_router.dart';
import 'package:artemis_work_planner/src/services/api_service.dart';
import 'package:artemis_work_planner/src/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummel_blue_theme/rummel_blue_theme.dart';

import 'fake_services.dart';

// ---------------------------------------------------------------------------
// Service locator setup
// ---------------------------------------------------------------------------

FakeAuthService fakeAuth = FakeAuthService(authenticated: true);
FakeGoalRepository fakeGoals = FakeGoalRepository();
FakePlanRepository fakePlans = FakePlanRepository();
FakePlannerRepository fakePlanners = FakePlannerRepository();
FakeExternalTaskService fakeExternalTasks = FakeExternalTaskService();

void initTestServices({bool authenticated = true}) {
  fakeAuth = FakeAuthService(authenticated: authenticated);
  fakeGoals = FakeGoalRepository();
  fakePlans = FakePlanRepository();
  fakePlanners = FakePlannerRepository();
  fakeExternalTasks = FakeExternalTaskService();

  ServiceLocator.init(
    authService: fakeAuth,
    apiService: ApiService(fakeAuth),
    goalRepo: fakeGoals,
    planRepo: fakePlans,
    plannerRepo: fakePlanners,
    externalTaskService: fakeExternalTasks,
  );
}

// ---------------------------------------------------------------------------
// flutter_secure_storage channel mock (needed for any test that creates
// AuthService or calls a method that touches the platform channel)
// ---------------------------------------------------------------------------

void mockSecureStorage() {
  final storage = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          switch (call.method) {
            case 'read':
              return storage[call.arguments['key'] as String];
            case 'write':
              storage[call.arguments['key'] as String] =
                  call.arguments['value'] as String? ?? '';
              return null;
            case 'delete':
              storage.remove(call.arguments['key'] as String);
              return null;
            case 'readAll':
              return Map<String, String>.from(storage);
            case 'deleteAll':
              storage.clear();
              return null;
            case 'containsKey':
              return storage.containsKey(call.arguments['key'] as String);
            default:
              return null;
          }
        },
      );
}

// ---------------------------------------------------------------------------
// Test widget wrapper
// ---------------------------------------------------------------------------

Widget testApp({String initialRoute = AppRouter.home}) {
  return MaterialApp(
    theme: RummelBlueTheme.light(),
    darkTheme: RummelBlueTheme.dark(),
    initialRoute: initialRoute,
    onGenerateRoute: AppRouter.generateRoute,
  );
}

Widget testWidget(Widget child) {
  return MaterialApp(theme: RummelBlueTheme.light(), home: child);
}
