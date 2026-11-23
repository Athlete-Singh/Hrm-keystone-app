import 'package:flutter/material.dart';

import 'data/repositories/hrm_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/device_capabilities_service.dart';
import 'ui/core/theme/keystone_theme.dart';
import 'ui/core/widgets/keystone_ui.dart';
import 'ui/features/auth/login_screen.dart';
import 'ui/shell/employee_shell.dart';
import 'ui/viewmodels/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  await apiClient.init();

  final repository = HrmRepository(apiClient: apiClient);
  final deviceService = DefaultDeviceCapabilitiesService();
  final appState = AppState(repository: repository, deviceService: deviceService);
  await appState.initialize();

  runApp(KeystoneEmployeeApp(appState: appState));
}

class KeystoneEmployeeApp extends StatelessWidget {
  const KeystoneEmployeeApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keystone Employee',
      debugShowCheckedModeBanner: false,
      theme: KeystoneTheme.light(),
      home: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          if (appState.isInitializing) {
            return const Scaffold(
              body: KeystoneBackdrop(
                warmAccent: true,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KeystoneAppBadge(size: 64, radius: 18),
                      SizedBox(height: 16),
                      KeystoneLogo(size: 22),
                      SizedBox(height: 18),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: KeystoneColors.pine,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          if (!appState.isAuthenticated) {
            return LoginScreen(appState: appState);
          }
          return EmployeeShell(appState: appState);
        },
      ),
    );
  }
}
