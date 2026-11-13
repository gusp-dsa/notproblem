import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/actions/presentation/pages/action_follow_up_page.dart';
import '../features/auth/data/supabase_auth_repository.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/auth_configuration_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/auth/presentation/pages/sign_up_page.dart';
import '../features/auth/presentation/widgets/auth_scope.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/history/presentation/pages/history_page.dart';
import '../features/investigations/presentation/pages/investigation_page.dart';
import '../features/occurrences/presentation/pages/new_occurrence_page.dart';
import '../features/occurrences/presentation/pages/occurrences_page.dart';
import 'app_routes.dart';

class AgileKnowledgeApp extends StatefulWidget {
  const AgileKnowledgeApp({this.authRepository, super.key});

  final AuthRepository? authRepository;

  @override
  State<AgileKnowledgeApp> createState() => _AgileKnowledgeAppState();
}

class _AgileKnowledgeAppState extends State<AgileKnowledgeApp> {
  AuthController? _authController;

  @override
  void initState() {
    super.initState();

    final repository = widget.authRepository;
    if (repository != null) {
      _authController = AuthController(repository);
    } else if (AppConfig.hasSupabaseCredentials) {
      _authController = AuthController(
        SupabaseAuthRepository(
          Supabase.instance.client,
          emailRedirectTo: AppConfig.emailConfirmationRedirectUrl,
        ),
      );
    }
  }

  @override
  void dispose() {
    _authController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _authController;

    return MaterialApp(
      title: 'Agile Knowledge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: controller == null
          ? const AuthConfigurationPage()
          : AuthScope(
              controller: controller,
              child: _AuthGate(controller: controller),
            ),
      onGenerateRoute: controller == null
          ? null
          : (settings) => _buildRoute(settings, controller),
    );
  }

  Route<void> _buildRoute(
    RouteSettings settings,
    AuthController controller,
  ) {
    final publicPage = switch (settings.name) {
      AppRoutes.signIn => SignInPage(controller: controller),
      AppRoutes.signUp => SignUpPage(controller: controller),
      _ => null,
    };

    if (publicPage != null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthScope(controller: controller, child: publicPage),
      );
    }

    final privatePage = switch (settings.name) {
      AppRoutes.dashboard => const DashboardPage(),
      AppRoutes.occurrences => const OccurrencesPage(),
      AppRoutes.newOccurrence => const NewOccurrencePage(),
      AppRoutes.investigations => const InvestigationPage(),
      AppRoutes.actions => const ActionFollowUpPage(),
      AppRoutes.history => const HistoryPage(),
      _ => const DashboardPage(),
    };

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthScope(
        controller: controller,
        child: _PrivateRoute(
          controller: controller,
          child: privatePage,
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoadingSession) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!controller.isAuthenticated) {
          return SignInPage(controller: controller);
        }

        return const DashboardPage();
      },
    );
  }
}

class _PrivateRoute extends StatelessWidget {
  const _PrivateRoute({required this.controller, required this.child});

  final AuthController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isAuthenticated) {
          return SignInPage(controller: controller);
        }

        return child;
      },
    );
  }
}
