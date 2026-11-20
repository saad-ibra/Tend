import '../models/mood_energy_checkin.dart';

abstract class CheckInRepository {
  Future<List<MoodEnergyCheckIn>> getCheckIns();
  Future<MoodEnergyCheckIn?> getCheckInForDate(String dateKey);
  Future<void> saveCheckIn(MoodEnergyCheckIn checkIn);
  Future<void> deleteCheckIn(String id);
}
