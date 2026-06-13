import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/campaigns/models/campaign.dart';
import 'package:goodwill_circle/features/campaigns/campaign_repository.dart';

class CampaignState {
  final List<Campaign> campaigns;
  final bool isLoading;
  final String? error;

  CampaignState({
    this.campaigns = const [],
    this.isLoading = false,
    this.error,
  });

  CampaignState copyWith({
    List<Campaign>? campaigns,
    bool? isLoading,
    String? error,
  }) {
    return CampaignState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final campaignControllerProvider =
    NotifierProvider<CampaignController, CampaignState>(CampaignController.new);

class CampaignController extends Notifier<CampaignState> {
  CampaignRepository get _repository => ref.read(campaignRepositoryProvider);

  @override
  CampaignState build() {
    Future.microtask(loadCampaigns);
    return CampaignState();
  }

  Future<void> loadCampaigns() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final campaigns = await _repository.getActiveCampaigns();
      state = state.copyWith(campaigns: campaigns, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCampaign({
    required String title,
    required String description,
    required int goalAmount,
    DateTime? endDate,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createCampaign(
        title: title,
        description: description,
        goalAmount: goalAmount,
        endDate: endDate,
        imageUrl: imageUrl,
      );
      await loadCampaigns();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinCampaign(String campaignId, String role) async {
    state = state.copyWith(error: null);
    try {
      await _repository.joinCampaign(campaignId, role);
      await loadCampaigns();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> toggleSupport(String campaignId) async {
    state = state.copyWith(error: null);
    try {
      await _repository.toggleSupport(campaignId);
      await loadCampaigns();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Controller specifically for fetching details of a single campaign (updates, etc)
final campaignDetailsProvider = FutureProvider.family<Campaign, String>((
  ref,
  campaignId,
) async {
  final repository = ref.read(campaignRepositoryProvider);
  return repository.getCampaignDetails(campaignId);
});

final campaignUpdatesProvider = FutureProvider.family((
  ref,
  String campaignId,
) async {
  final repository = ref.read(campaignRepositoryProvider);
  return repository.getCampaignUpdates(campaignId);
});

final campaignDonationsProvider = FutureProvider.family((
  ref,
  String campaignId,
) async {
  final repository = ref.read(campaignRepositoryProvider);
  return repository.getCampaignDonations(campaignId);
});

final campaignCommentsProvider = FutureProvider.family((
  ref,
  String campaignId,
) async {
  final repository = ref.read(campaignRepositoryProvider);
  return repository.getCampaignComments(campaignId);
});
