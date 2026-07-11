import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/agenda/agenda_repository.dart';
import 'package:goodwill_circle/features/agenda/models/nonprofit_agenda_item.dart';

class AgendaState {
  final List<NonprofitAgendaItem> items;
  final bool isLoading;
  final String? error;

  AgendaState({this.items = const [], this.isLoading = false, this.error});

  AgendaState copyWith({
    List<NonprofitAgendaItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return AgendaState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final agendaControllerProvider =
    NotifierProvider<AgendaController, AgendaState>(AgendaController.new);

class AgendaController extends Notifier<AgendaState> {
  AgendaRepository get _repository => ref.read(agendaRepositoryProvider);

  @override
  AgendaState build() {
    Future.microtask(loadAgendaItems);
    return AgendaState();
  }

  Future<void> loadAgendaItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repository.getOpenAgendaItems();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createAgendaItem({
    required String ngoName,
    required String title,
    required String description,
    required String skillArea,
    required String location,
    required int seatsNeeded,
    required String rewardBadgeId,
    required String certificateTitle,
    required String certificateIssuer,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createAgendaItem(
        ngoName: ngoName,
        title: title,
        description: description,
        skillArea: skillArea,
        location: location,
        seatsNeeded: seatsNeeded,
        rewardBadgeId: rewardBadgeId,
        certificateTitle: certificateTitle,
        certificateIssuer: certificateIssuer,
        imageUrl: imageUrl,
      );
      await loadAgendaItems();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinAgendaItem(String agendaItemId, String role) async {
    try {
      await _repository.joinAgendaItem(agendaItemId, role);
      await loadAgendaItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleSupport(String agendaItemId) async {
    try {
      await _repository.toggleSupport(agendaItemId);
      await loadAgendaItems();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
