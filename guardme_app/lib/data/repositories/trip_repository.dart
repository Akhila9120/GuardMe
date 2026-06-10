import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardme_app/core/dio_client.dart';
import 'package:guardme_app/core/exceptions.dart';
import 'package:guardme_app/domain/entities/trip.dart';
import 'package:guardme_app/domain/repositories/trip_repository_interface.dart';

final tripRepositoryProvider = Provider<TripRepositoryInterface>((ref) {
  final dio = ref.read(dioClientProvider);
  return TripRepository(dio: dio);
});

class TripRepository implements TripRepositoryInterface {
  final Dio dio;

  TripRepository({required this.dio});

  @override
  Future<List<Trip>> getTrips() async {
    try {
      final response = await dio.get('/api/trips');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to load trips',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Trip> getTrip(int id) async {
    try {
      final response = await dio.get('/api/trips/$id');
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to load trip',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Trip> createTrip(Trip trip) async {
    try {
      final response = await dio.post('/api/trips', data: trip.toJson());
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to create trip',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Trip> updateTrip(int id, Trip trip) async {
    try {
      final response = await dio.put('/api/trips/$id', data: trip.toJson());
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to update trip',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<void> deleteTrip(int id) async {
    try {
      await dio.delete('/api/trips/$id');
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to delete trip',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Trip> endTrip(int id) async {
    try {
      final response = await dio.put('/api/trips/$id/end');
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to end trip',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<Trip> triggerEmergency(int id) async {
    try {
      final response = await dio.post('/api/trips/$id/emergency');
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: 'Failed to trigger emergency',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
