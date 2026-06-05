import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/confessions/confession_repository.dart';
import 'package:goodwill_circle/features/confessions/models/confession.dart';

class ConfessionState {
  final List<Confession> confessions;
  final bool isLoading;
  final String? error;

  ConfessionState({
    this.confessions = const [],
    this.isLoading = false,
    this.error,
  });

  ConfessionState copyWith({
    List<Confession>? confessions,
    bool? isLoading,
    String? error,
  }) {
    return ConfessionState(
      confessions: confessions ?? this.confessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final confessionControllerProvider =
    NotifierProvider<ConfessionController, ConfessionState>(
      ConfessionController.new,
    );

class ConfessionController extends Notifier<ConfessionState> {
  ConfessionRepository get _repository =>
      ref.read(confessionRepositoryProvider);

  @override
  ConfessionState build() {
    Future.microtask(loadConfessions);
    return ConfessionState();
  }

  Future<void> loadConfessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final confessions = await _repository.getConfessions();
      state = state.copyWith(confessions: confessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createConfession({
    required String content,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createConfession(content: content, imageUrl: imageUrl);
      await loadConfessions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> supportConfession(String confessionId) async {
    state = state.copyWith(error: null);
    try {
      await _repository.supportConfession(confessionId);
      await loadConfessions();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
