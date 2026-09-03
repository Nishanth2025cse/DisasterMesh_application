import 'dart:async';
import '../models/sos_model.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/classification_service.dart';
import '../services/priority_service.dart';
import '../utils/helpers.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  final StorageService _storage = StorageService();
  final ClassificationService _classifier = ClassificationService();
  final PriorityService _prioritizer = PriorityService();

  final StreamController<List<SosModel>> _sosStreamController = StreamController<List<SosModel>>.broadcast();
  Stream<List<SosModel>> get sosStream => _sosStreamController.stream;

  /// Creates a new SOS alert
  Future<SosModel> createSos({
    required UserModel user,
    required String message,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    final existingList = await _storage.getAllSos();
    final String sosId = Helpers.generateSosId(sequentialNumber: existingList.length + 1);

    final String category = _classifier.classifyMessage(message);
    final String priority = _prioritizer.calculatePriority(category, message);

    final newSos = SosModel(
      sosId: sosId,
      userId: user.id,
      victimName: user.name,
      victimPhone: user.phone,
      message: message,
      category: category,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      status: 'Pending',
      ttl: 5,
      originDeviceId: deviceId,
      version: 1,
      updateHistory: [
        SosUpdateEntry(
          message: message,
          category: category,
          priority: priority,
          timestamp: DateTime.now(),
        ),
      ],
    );

    await _storage.saveSos(newSos);
    await refreshSosList();
    return newSos;
  }

  /// Updates an existing SOS alert while PRESERVING the original sosId!
  Future<SosModel> updateExistingSos({
    required String sosId,
    required String updatedMessage,
    double? newLatitude,
    double? newLongitude,
  }) async {
    final existingSos = await _storage.getSosById(sosId);
    if (existingSos == null) {
      throw Exception("SOS Alert with ID $sosId not found.");
    }

    final String newCategory = _classifier.classifyMessage(updatedMessage);
    final String newPriority = _prioritizer.calculatePriority(newCategory, updatedMessage);

    final newHistoryEntry = SosUpdateEntry(
      message: updatedMessage,
      category: newCategory,
      priority: newPriority,
      timestamp: DateTime.now(),
    );

    final updatedHistory = List<SosUpdateEntry>.from(existingSos.updateHistory)..add(newHistoryEntry);

    final updatedSos = existingSos.copyWith(
      message: updatedMessage,
      category: newCategory,
      priority: newPriority,
      latitude: newLatitude ?? existingSos.latitude,
      longitude: newLongitude ?? existingSos.longitude,
      version: existingSos.version + 1,
      updateHistory: updatedHistory,
    );

    await _storage.saveSos(updatedSos);
    await refreshSosList();
    return updatedSos;
  }

  /// Updates Rescue Status (Pending -> Accepted -> Responding -> Rescued)
  Future<void> updateStatus(String sosId, String newStatus) async {
    await _storage.updateSosStatus(sosId, newStatus);
    await refreshSosList();
  }

  Future<List<SosModel>> getAllSosAlerts() async {
    return await _storage.getSosByPriority();
  }

  Future<void> refreshSosList() async {
    final list = await getAllSosAlerts();
    _sosStreamController.add(list);
  }
}
