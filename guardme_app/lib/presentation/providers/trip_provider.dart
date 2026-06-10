import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/data/repositories/trip_repository.dart';
import 'package:guardme_app/domain/entities/trip.dart';

class TripState {
  final List<Trip> trips;
  final Trip? currentTrip;
  final bool isLoading;
  final String? error;

  const TripState({
    this.trips = const [],
    this.currentTrip,
    this.isLoading = false,
    this.error,
  });

  TripState copyWith({
    List<Trip>? trips,
    Trip? currentTrip,
    bool? isLoading,
    String? error,
  }) {
    return TripState(
      trips: trips ?? this.trips,
      currentTrip: currentTrip ?? this.currentTrip,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  final Ref _ref;

  TripNotifier(this._ref) : super(const TripState());

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(tripRepositoryProvider);
      final trips = await repo.getTrips();
      final active = trips.where((t) => t.isActive).toList();
      state = TripState(
        trips: trips,
        currentTrip: active.isNotEmpty ? active.first : null,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createTrip(Trip trip) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(tripRepositoryProvider);
      final created = await repo.createTrip(trip);
      state = TripState(
        trips: [created, ...state.trips],
        currentTrip: created,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> endTrip(int id) async {
    try {
      final repo = _ref.read(tripRepositoryProvider);
      final ended = await repo.endTrip(id);
      final updatedTrips =
          state.trips.map((t) => t.id == id ? ended : t).toList();
      state = TripState(
        trips: updatedTrips,
        currentTrip: null,
      );
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> triggerEmergency(int id) async {
    try {
      final repo = _ref.read(tripRepositoryProvider);
      final alert = await repo.triggerEmergency(id);
      final updatedTrips =
          state.trips.map((t) => t.id == id ? alert : t).toList();
      state = state.copyWith(trips: updatedTrips, currentTrip: alert);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setCurrentTrip(Trip? trip) {
    state = state.copyWith(currentTrip: trip);
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier(ref);
});
