import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goodwill_circle/features/requests/models/help_request.dart';
import 'package:goodwill_circle/features/requests/request_repository.dart';

class RequestState {
  final List<HelpRequest> requests;
  final bool isLoading;
  final String? error;

  RequestState({this.requests = const [], this.isLoading = false, this.error});

  RequestState copyWith({
    List<HelpRequest>? requests,
    bool? isLoading,
    String? error,
  }) {
    return RequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final requestControllerProvider =
    NotifierProvider<RequestController, RequestState>(RequestController.new);

class RequestController extends Notifier<RequestState> {
  RequestRepository get _repository => ref.read(requestRepositoryProvider);

  @override
  RequestState build() {
    Future.microtask(loadRequests);
    return RequestState();
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requests = await _repository.getOpenRequests();
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createRequest({
    required String title,
    required String description,
    required String category,
    required int reward,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final requestId = await _repository.createRequest(
        title: title,
        description: description,
        category: category,
        reward: reward,
        imageUrl: imageUrl,
      );
      await loadRequests();
      return requestId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> volunteerForRequest(String requestId) async {
    try {
      await _repository.volunteerForRequest(requestId);
      await loadRequests(); // Reload to get updated volunteer count
    } catch (e) {
      // Handle silently or update state error
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> completeRequest(String requestId) async {
    try {
      await _repository.completeRequest(requestId);
      await loadRequests(); // It will disappear from 'open' requests
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> requestCompletionReview({
    required String requestId,
    String? message,
  }) async {
    try {
      await _repository.requestCompletionReview(
        requestId: requestId,
        message: message,
      );
      await loadRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
