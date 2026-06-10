import 'package:guardme_app/domain/entities/trip.dart';

abstract class TripRepositoryInterface {
  Future<List<Trip>> getTrips();
  Future<Trip> getTrip(int id);
  Future<Trip> createTrip(Trip trip);
  Future<Trip> updateTrip(int id, Trip trip);
  Future<void> deleteTrip(int id);
  Future<Trip> endTrip(int id);
  Future<Trip> triggerEmergency(int id);
}
