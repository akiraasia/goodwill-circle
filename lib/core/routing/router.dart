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
import 'package:goodwill_circle/features/growth_os/presentation/wish_screen.dart';
import 'package:goodwill_circle/features/profile/profile_screen.dart';
import 'package:goodwill_circle/features/trust/trust_screen.dart';
import 'package:goodwill_circle/features/confessions/confessions_screen.dart';
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
