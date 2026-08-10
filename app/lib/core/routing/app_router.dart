import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../domain/models/enums.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/admin/admin_catalog_screens.dart';
import '../../features/admin/admin_content_screens.dart';
import '../../features/admin/admin_home_screen.dart';
import '../../features/approvals/approvals_screen.dart';
import '../../features/bloodbank/blood_bank_screen.dart';
import '../../features/centres/centres_screen.dart';
import '../../features/clinics/clinics_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/content/content_screens.dart';
import '../../features/content/home_care_screen.dart';
import '../../features/diagnostics/diagnostics_screens.dart';
import '../../features/home/home_screen.dart';
import '../../features/medical_file/medical_file_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/surgery/surgery_request_screen.dart';
import '../../features/surgery/surgery_screen.dart';
import '../../features/theatre/theatre_availability_screen.dart';
import '../../features/visiting/visiting_screen.dart';

/// Routes are declared as paths so that Universal Links and App Links map onto
/// them directly (PROMPT.md section 12.3).
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/contact', builder: (_, _) => const ContactScreen()),

      // Detail routes pushed above the shell.
      GoRoute(
        path: '/clinics',
        builder: (_, _) => const ClinicsScreen(),
        routes: [
          GoRoute(
            path: ':clinicId',
            builder: (_, state) => ClinicDetailScreen(
              clinicId: state.pathParameters['clinicId']!,
            ),
          ),
        ],
      ),
      GoRoute(path: '/radiology', builder: (_, _) => const RadiologyScreen()),
      GoRoute(path: '/lab', builder: (_, _) => const LabScreen()),
      GoRoute(
        path: '/surgery',
        builder: (_, _) => const SurgeryScreen(),
        routes: [
          GoRoute(
            path: 'request/:procedureId',
            builder: (_, state) => SurgeryRequestScreen(
              procedureId: state.pathParameters['procedureId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/centres',
        builder: (_, _) => const CentresScreen(),
        routes: [
          GoRoute(
            path: ':centreId',
            builder: (_, state) => CentreDetailScreen(
              centreId: state.pathParameters['centreId']!,
            ),
          ),
        ],
      ),
      GoRoute(path: '/visiting', builder: (_, _) => const VisitingScreen()),
      GoRoute(path: '/home-care', builder: (_, _) => const HomeCareScreen()),
      GoRoute(path: '/complaints', builder: (_, _) => const ComplaintsScreen()),
      GoRoute(path: '/offers', builder: (_, _) => const OffersScreen()),
      GoRoute(path: '/tips', builder: (_, _) => const TipsScreen()),
      GoRoute(path: '/blood-bank', builder: (_, _) => const BloodBankScreen()),
      GoRoute(path: '/approvals', builder: (_, _) => const ApprovalsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen()),
      GoRoute(
          path: '/theatre',
          builder: (_, _) => const TheatreAvailabilityScreen()),

      // Admin console. Same app, same codebase, revealed by the role.
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminHomeScreen(),
        routes: [
          GoRoute(
              path: 'classifications',
              builder: (_, _) => const ClassificationsAdminScreen()),
          GoRoute(
              path: 'procedures',
              builder: (_, _) => const ProceduresAdminScreen()),
          GoRoute(
              path: 'clinics',
              builder: (_, _) => const ClinicsAdminScreen()),
          GoRoute(
              path: 'doctors',
              builder: (_, _) => const DoctorsAdminScreen()),
          GoRoute(
              path: 'theatres',
              builder: (_, _) => const TheatresAdminScreen()),
          GoRoute(
              path: 'offers',
              builder: (_, _) => const OffersAdminScreen()),
          GoRoute(
              path: 'tips', builder: (_, _) => const TipsAdminScreen()),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/services', builder: (_, _) => const ServicesScreen()),
          ]),
          StatefulShellBranch(routes: [
            // One branch, two destinations: patients see their medical file,
            // doctors see the theatre grid. The role decides, not the client.
            GoRoute(path: '/file', builder: (_, _) => const _FileOrPractice()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
    ],
  );
}

class _FileOrPractice extends StatelessWidget {
  const _FileOrPractice();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppState>().session;
    return switch (session.role) {
      UserRole.admin => const AdminHomeScreen(),
      UserRole.doctor => const TheatreAvailabilityScreen(),
      UserRole.surgeryApprover => const ApprovalsScreen(),
      _ => const MedicalFileScreen(),
    };
  }
}
