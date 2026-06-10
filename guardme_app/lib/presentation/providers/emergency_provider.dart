import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/data/repositories/emergency_repository.dart';
import 'package:guardme_app/domain/entities/emergency_alert.dart';

class EmergencyState {
  final List<EmergencyAlert> alerts;
  final bool isLoading;
  final String? error;

  const EmergencyState({
    this.alerts = const [],
    this.isLoading = false,
    this.error,
  });

  EmergencyState copyWith({
    List<EmergencyAlert>? alerts,
    bool? isLoading,
    String? error,
  }) {
    return EmergencyState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  final Ref _ref;

  EmergencyNotifier(this._ref) : super(const EmergencyState());

  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(emergencyRepositoryProvider);
      final alerts = await repo.getAlerts();
      state = EmergencyState(alerts: alerts);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createAlert(EmergencyAlert alert) async {
    try {
      final repo = _ref.read(emergencyRepositoryProvider);
      final created = await repo.createAlert(alert);
      state = state.copyWith(alerts: [created, ...state.alerts]);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resolveAlert(int id) async {
    try {
      final repo = _ref.read(emergencyRepositoryProvider);
      final resolved = await repo.resolveAlert(id);
      final list = state.alerts.map((a) {
        return a.id == id ? resolved : a;
      }).toList();
      state = state.copyWith(alerts: list);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>((ref) {
  return EmergencyNotifier(ref);
});
