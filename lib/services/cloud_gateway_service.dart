import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sos_model.dart';

/// Cloud Gateway Service
/// Bridges offline DisasterMesh nodes to the Central Rescue Web Dashboard (disastermesh-app.web.app/rescue)
/// when internet / cellular connectivity is available.
class CloudGatewayService {
  static const String ntfyUrl = 'https://ntfy.sh/disastermesh_rescue_alerts_channel';

  /// Asynchronously uplinks an SOS alert to the central Web Command Dashboard.
  /// If the phone is completely offline (disaster off-grid), it fails silently without interrupting the local mesh.
  static Future<bool> uplinkSosToCloud(SosModel sos) async {
    try {
      final payload = {
        'sosId': sos.sosId,
        'victimName': sos.victimName,
        'victimPhone': sos.victimPhone ?? '',
        'message': sos.message,
        'category': sos.category,
        'priority': sos.priority,
        'latitude': sos.latitude,
        'longitude': sos.longitude,
        'timestamp': sos.timestamp.toIso8601String(),
        'status': sos.status,
        'originDeviceId': sos.originDeviceId,
      };

      final response = await http.post(
        Uri.parse(ntfyUrl),
        headers: {
          'Title': 'SOS: ${sos.victimName} (${sos.category})',
          'Priority': sos.priority.toUpperCase() == 'HIGH' ? 'urgent' : 'default',
          'Tags': 'rotating_light,sos,emergency',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) print('[CloudGateway] Uplink success for ${sos.sosId}');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[CloudGateway] Offline / uplink skipped: $e');
    }
    return false;
  }
}
