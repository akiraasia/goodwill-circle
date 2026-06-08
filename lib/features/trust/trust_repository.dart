import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  return TrustRepository(Supabase.instance.client);
});

final platformImpactProvider = FutureProvider<List<ImpactMetric>>((ref) async {
  return ref.read(trustRepositoryProvider).getPlatformImpact();
});

class TrustRepository {
  final SupabaseClient _client;

  TrustRepository(this._client);

  Future<List<ImpactMetric>> getPlatformImpact() async {
    final data = await _client.rpc('get_platform_impact_summary');
    return (data as List<dynamic>)
        .map((item) => ImpactMetric.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TrustedInvite> createTrustedInvite() async {
    final data = await _client.rpc('create_trusted_connection_invite');
    final row = (data as List<dynamic>).first as Map<String, dynamic>;
    return TrustedInvite.fromJson(row);
  }

  Future<void> redeemTrustedInvite(String code) async {
    await _client.rpc(
      'redeem_trusted_connection_invite',
      params: {'p_invite_code': code},
    );
  }

  Future<ScamCheckup> runScamCheck({
    required String targetType,
    String? targetId,
    required String message,
  }) async {
    final checkId = await _client.rpc(
      'run_scam_checkup',
      params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_message': message,
      },
    );

    final row = await _client
        .from('scam_checkups')
        .select()
        .eq('id', checkId as String)
        .single();
    return ScamCheckup.fromJson(row);
  }

  Future<String> submitFinancialHelpVerification({
    required String requestId,
    required String note,
    String? evidenceUrl,
  }) async {
    final id = await _client.rpc(
      'submit_financial_help_verification',
      params: {
        'p_request_id': requestId,
        'p_note': note,
        'p_evidence_url': evidenceUrl,
      },
    );
    return id as String;
  }
}

class ImpactMetric {
  final String metric;
  final int value;

  const ImpactMetric({required this.metric, required this.value});

  factory ImpactMetric.fromJson(Map<String, dynamic> json) {
    return ImpactMetric(
      metric: json['metric'] as String,
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

class TrustedInvite {
  final String inviteCode;
  final String qrPayload;
  final DateTime expiresAt;

  const TrustedInvite({
    required this.inviteCode,
    required this.qrPayload,
    required this.expiresAt,
  });

  factory TrustedInvite.fromJson(Map<String, dynamic> json) {
    return TrustedInvite(
      inviteCode: json['invite_code'] as String,
      qrPayload: json['qr_payload'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class ScamCheckup {
  final int riskScore;
  final String status;
  final List<String> signals;

  const ScamCheckup({
    required this.riskScore,
    required this.status,
    required this.signals,
  });

  factory ScamCheckup.fromJson(Map<String, dynamic> json) {
    return ScamCheckup(
      riskScore: json['risk_score'] as int? ?? 0,
      status: json['status'] as String? ?? 'low_risk',
      signals: (json['signals'] as List<dynamic>? ?? const [])
          .map((signal) => signal.toString())
          .toList(),
    );
  }
}
