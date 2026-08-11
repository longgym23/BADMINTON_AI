import 'package:badminton_ai/domain/entities/court.dart';

abstract class CourtRepository {
  Stream<List<Court>> getCourtsStream();
  
  Future<Court?> getCourtById(String courtId);
  
  Future<void> addCourt(Court court);
  
  Future<void> updateCourt(Court court);
  
  Future<void> deleteCourt(String courtId);
}