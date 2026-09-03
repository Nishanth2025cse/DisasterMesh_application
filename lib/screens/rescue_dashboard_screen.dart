import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import '../services/sos_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/sos_card.dart';
import 'sos_details_screen.dart';

class RescueDashboardScreen extends StatefulWidget {
  const RescueDashboardScreen({super.key});

  @override
  State<RescueDashboardScreen> createState() => _RescueDashboardScreenState();
}

class _RescueDashboardScreenState extends State<RescueDashboardScreen> {
  final StorageService _storage = StorageService();
  final SosService _sosService = SosService();

  List<SosModel> _allSosAlerts = [];
  String _selectedPriorityFilter = 'ALL';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final list = await _storage.getSosByPriority();
    if (mounted) {
      setState(() {
        _allSosAlerts = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(SosModel sos, String newStatus) async {
    await _sosService.updateStatus(sos.sosId, newStatus);
    await _loadAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Rescue Status for ${sos.sosId} set to $newStatus")),
      );
    }
  }

  List<SosModel> get _filteredAlerts {
    if (_selectedPriorityFilter == 'ALL') return _allSosAlerts;
    return _allSosAlerts.where((s) => s.priority == _selectedPriorityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Text("🚨 RESCUE DASHBOARD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accentBlue),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Priority Filter Chips Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _filterChip("ALL", "All (${_allSosAlerts.length})", Colors.white),
                      _filterChip("HIGH", "🔴 HIGH", AppColors.priorityHigh),
                      _filterChip("MEDIUM", "🟠 MEDIUM", AppColors.priorityMedium),
                      _filterChip("LOW", "🟢 LOW", AppColors.priorityLow),
                    ],
                  ),
                ),

                Expanded(
                  child: _filteredAlerts.isEmpty
                      ? const Center(
                          child: Text(
                            "No emergency alerts in this category.",
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredAlerts.length,
                          itemBuilder: (context, index) {
                            final sos = _filteredAlerts[index];
                            return Column(
                              children: [
                                SosCard(
                                  sos: sos,
                                  index: index,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SosDetailsScreen(sosId: sos.sosId),
                                      ),
                                    );
                                  },
                                ),
                                // Rescue Status Action Bar
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.surfaceLight,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Set Status:", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                      Row(
                                        children: [
                                          _statusBtn(sos, "Pending", AppColors.statusPending),
                                          _statusBtn(sos, "Accepted", AppColors.statusAccepted),
                                          _statusBtn(sos, "Responding", AppColors.statusResponding),
                                          _statusBtn(sos, "Rescued", AppColors.statusRescued),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String filter, String label, Color color) {
    bool isSelected = _selectedPriorityFilter == filter;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: AppColors.surfaceLight,
      onSelected: (selected) {
        if (selected) setState(() => _selectedPriorityFilter = filter);
      },
    );
  }

  Widget _statusBtn(SosModel sos, String status, Color color) {
    bool isCurrent = sos.status == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: InkWell(
        onTap: () => _changeStatus(sos, status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isCurrent ? color : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isCurrent ? Colors.black : color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}
