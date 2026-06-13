import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goodwill_circle/features/landing/landing_screen.dart';
import 'package:goodwill_circle/features/auth/auth_screen.dart';
import 'package:goodwill_circle/features/auth/reset_password_screen.dart';
import 'package:goodwill_circle/core/layout/app_scaffold.dart';
import 'package:goodwill_circle/features/requests/requests_screen.dart';
import 'package:goodwill_circle/features/requests/create_request_screen.dart';
import 'package:goodwill_circle/features/agenda/agenda_screen.dart';
import 'package:goodwill_circle/features/agenda/create_agenda_screen.dart';
import 'package:goodwill_circle/features/campaigns/campaigns_screen.dart';
import 'package:goodwill_circle/features/campaigns/create_campaign_screen.dart';
import 'package:goodwill_circle/features/campaigns/campaign_details_screen.dart';
import 'package:goodwill_circle/features/confessions/confessions_screen.dart';
import 'package:goodwill_circle/features/profile/profile_screen.dart';
import 'package:goodwill_circle/features/trust/trust_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isProtectedRoute =
          state.matchedLocation.startsWith('/campaigns') ||
          state.matchedLocation.startsWith('/agenda') ||
          state.matchedLocation.startsWith('/trust') ||
          state.matchedLocation.startsWith('/confessions') ||
          state.matchedLocation.startsWith('/profile') ||
          state.matchedLocation.startsWith('/create-request') ||
          state.matchedLocation.startsWith('/create-agenda') ||
          state.matchedLocation.startsWith('/create-campaign') ||
          state.matchedLocation.startsWith('/campaign/');

      if (session == null && isProtectedRoute) {
        return '/auth';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return AuthScreen(
            initialSignUp: query['mode'] == 'signup',
            initialName: query['name'],
            initialEmail: query['email'],
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppScaffold(body: child);
        },
        routes: [
          GoRoute(
            path: '/app',
            builder: (context, state) => const RequestsScreen(),
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignsScreen(),
          ),
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const AgendaScreen(),
          ),
          GoRoute(
            path: '/trust',
            builder: (context, state) => const TrustScreen(),
          ),
          GoRoute(
            path: '/confessions',
            builder: (context, state) => const ConfessionsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              return ProfileScreen(
                promptVerification: state.uri.queryParameters['verify'] == '1',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/create-request',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/create-agenda',
        builder: (context, state) => const CreateAgendaScreen(),
      ),
      GoRoute(
        path: '/create-campaign',
        builder: (context, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: '/campaign/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CampaignDetailsScreen(campaignId: id);
        },
      ),
    ],
  );
});
