import 'dart:async';

import 'package:flutter/material.dart';
import '../models/sos_model.dart';
import '../services/sos_service.dart';
import '../services/storage_service.dart';
import 'map_screen.dart';
import 'sos_details_screen.dart';

class RescueDashboardScreen extends StatefulWidget {
  const RescueDashboardScreen({super.key});

  @override
  State<RescueDashboardScreen> createState() => _RescueDashboardScreenState();
}

class _RescueDashboardScreenState extends State<RescueDashboardScreen> {
  final StorageService _storage = StorageService();
  final SosService _sosService = SosService();

  List<SosModel> _alerts = [];
  String _selectedFilter = 'ALL';
  bool _isLoading = true;
  StreamSubscription<List<SosModel>>? _sosSubscription;

  @override
  void initState() {
    super.initState();
    _sosSubscription = _sosService.sosStream.listen(_replaceAlerts);
    _loadAlerts();
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    super.dispose();
  }

  void _replaceAlerts(List<SosModel> alerts) {
    if (!mounted) return;
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _loadAlerts() async {
    final alerts = await _storage.getSosByPriority();
    _replaceAlerts(alerts);
  }

  Future<void> _updateStatus(SosModel sos, String status) async {
    await _sosService.updateStatus(sos.sosId, status);
    await _loadAlerts();
  }

  List<SosModel> get _filteredAlerts {
    if (_selectedFilter == 'ALL') return _alerts;
    return _alerts.where((sos) {
      if (_selectedFilter == 'ACTIVE') return sos.status != 'Rescued';
      return sos.priority == _selectedFilter;
    }).toList();
  }

  int _countWhere(bool Function(SosModel) test) => _alerts.where(test).length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _loadAlerts,
                            child: _buildDashboardContent(isWide),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFF102B4E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 22, 16, 26),
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text('Rescue Team',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
              ],
            ),
          ),
          _navItem(Icons.dashboard_rounded, 'Dashboard', selected: true),
          _navItem(Icons.warning_amber_rounded, 'Incidents'),
          _navItem(Icons.groups_2_rounded, 'Rescue Teams'),
          _navItem(Icons.person_pin_circle_outlined, 'Victims'),
          _navItem(Icons.inventory_2_outlined, 'Resources'),
          _navItem(Icons.assessment_outlined, 'Reports'),
          const Spacer(),
          _navItem(Icons.settings_outlined, 'Settings'),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String title, {bool selected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1D5DA5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 19, color: Colors.white.withOpacity(0.9)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4EAF1))),
      ),
      child: Row(
        children: [
          if (MediaQuery.sizeOf(context).width < 900)
            const Icon(Icons.shield_rounded,
                color: Color(0xFF1D5DA5), size: 25),
          if (MediaQuery.sizeOf(context).width < 900) const SizedBox(width: 9),
          const Text('DisasterMesh  /  Rescue Operations',
              style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF16A36A)),
                const SizedBox(width: 6),
                Text(
                  'Dashboard online',
                  style: const TextStyle(
                      color: Color(0xFF147D54),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Refresh alerts',
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh, color: Color(0xFF52657A)),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE7EFF8),
            child: Icon(Icons.person, color: Color(0xFF1D5DA5), size: 19),
          ),
          const SizedBox(width: 8),
          const Text('Rescue Admin',
              style: TextStyle(
                  color: Color(0xFF26384D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isWide) {
    final content = [
      _buildWelcome(),
      const SizedBox(height: 18),
      _buildSummaryCards(isWide),
      const SizedBox(height: 18),
      if (isWide)
        SizedBox(
          height: 410,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _buildMapPanel()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildRecentPanel()),
            ],
          ),
        )
      else ...[
        SizedBox(height: 320, child: _buildMapPanel()),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: _buildRecentPanel()),
      ],
      const SizedBox(height: 16),
      _buildIncidentTable(),
      const SizedBox(height: 24),
    ];

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 26 : 16, vertical: 22),
      children: content,
    );
  }

  Widget _buildWelcome() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, Rescue Team',
                  style: TextStyle(
                      color: Color(0xFF1C2B3D),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Live incident monitoring and response coordination',
                  style: TextStyle(color: Color(0xFF77879A), fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.calendar_today_outlined,
            color: Color(0xFF68788B), size: 15),
        const SizedBox(width: 7),
        Text(_formatDate(DateTime.now()),
            style: const TextStyle(
                color: Color(0xFF52657A),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildSummaryCards(bool isWide) {
    final cards = [
      _Metric(
          'Active Incidents',
          _countWhere((s) => s.status != 'Rescued'),
          Icons.warning_rounded,
          const Color(0xFFE14B55),
          const Color(0xFFFFF1F1)),
      _Metric(
          'High Priority',
          _countWhere((s) => s.priority == 'HIGH' && s.status != 'Rescued'),
          Icons.priority_high_rounded,
          const Color(0xFFE78422),
          const Color(0xFFFFF7EB)),
      _Metric(
          'Teams Responding',
          _countWhere((s) => s.status == 'Responding'),
          Icons.groups_rounded,
          const Color(0xFF2D71BD),
          const Color(0xFFEEF6FF)),
      _Metric(
          'People Rescued',
          _countWhere((s) => s.status == 'Rescued'),
          Icons.volunteer_activism_rounded,
          const Color(0xFF23976A),
          const Color(0xFFEDFAF4)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isWide ? 4 : (constraints.maxWidth < 520 ? 2 : 4);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((metric) {
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 12) / columns;
            return SizedBox(
              width: cardWidth,
              child: _buildMetricCard(metric),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(_Metric metric) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: metric.background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: metric.color.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(metric.icon, color: metric.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${metric.value}',
                    style: TextStyle(
                        color: metric.color,
                        fontSize: 25,
                        height: 1,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 7),
                Text(metric.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF516174),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
      {required String title, required Widget child, Widget? action}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Color(0xFF24364B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                if (action != null) action,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F5)),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildMapPanel() {
    final locatedAlerts = _alerts.where((s) {
      return (s.latitude != 0 || s.longitude != 0);
    }).length;

    return _panel(
      title: 'Incident Locations',
      action: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: const Text('Open map', style: TextStyle(fontSize: 11)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFFEAF2E8),
            child: CustomPaint(painter: _MapPainter(_alerts)),
          ),
          const Positioned(
            top: 10,
            left: 12,
            child: Text(
              'SCHEMATIC • GPS positions',
              style: TextStyle(
                color: Color(0xFF647A68),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.93),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$locatedAlerts incident location${locatedAlerts == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: Color(0xFF405268),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_alerts.isEmpty)
            const Center(
              child: Text('Waiting for nearby SOS alerts',
                  style: TextStyle(
                      color: Color(0xFF52657A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentPanel() {
    final recent = [..._alerts]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return _panel(
      title: 'Recent Alerts',
      action: TextButton(
        onPressed: () => setState(() => _selectedFilter = 'ALL'),
        child: const Text('View all', style: TextStyle(fontSize: 11)),
      ),
      child: recent.isEmpty
          ? const Center(
              child: Text('No alerts received yet',
                  style: TextStyle(color: Color(0xFF8492A3), fontSize: 12)),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: recent.length.clamp(0, 5),
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEF1F5)),
              itemBuilder: (context, index) {
                final sos = recent[index];
                final color = _priorityColor(sos.priority);
                return InkWell(
                  onTap: () => _openDetails(sos),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(Icons.circle, size: 9, color: color),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sos.category} • ${sos.victimName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF293A4E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sos.priority} priority • ${sos.status}',
                                style: const TextStyle(
                                    color: Color(0xFF8190A1), fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Text(_timeAgo(sos.timestamp),
                            style: const TextStyle(
                                color: Color(0xFF8794A3), fontSize: 9)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildIncidentTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Recent Incidents',
                      style: TextStyle(
                          color: Color(0xFF24364B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                _filterDropdown(),
                IconButton(
                  tooltip: 'Open incident map',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                  icon: const Icon(Icons.map_outlined,
                      color: Color(0xFF52708F), size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF1F5)),
          if (_filteredAlerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Text('No incidents match this filter.',
                  style: TextStyle(color: Color(0xFF8492A3), fontSize: 12)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 56,
                horizontalMargin: 16,
                columnSpacing: 28,
                headingTextStyle: const TextStyle(
                    color: Color(0xFF8794A3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                dataTextStyle:
                    const TextStyle(color: Color(0xFF35475B), fontSize: 11),
                columns: const [
                  DataColumn(label: Text('INCIDENT ID')),
                  DataColumn(label: Text('VICTIM / TYPE')),
                  DataColumn(label: Text('PRIORITY')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('RECEIVED')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: _filteredAlerts
                    .map((sos) => _buildIncidentRow(sos))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildIncidentRow(SosModel sos) {
    return DataRow(
      onSelectChanged: (_) => _openDetails(sos),
      cells: [
        DataCell(Text(sos.sosId,
            style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(
          SizedBox(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sos.victimName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sos.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF8794A3), fontSize: 9)),
              ],
            ),
          ),
        ),
        DataCell(_pill(sos.priority, _priorityColor(sos.priority))),
        DataCell(_pill(sos.status, _statusColor(sos.status))),
        DataCell(Text(_timeAgo(sos.timestamp))),
        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Update incident status',
            onSelected: (status) => _updateStatus(sos, status),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Pending', child: Text('Mark Pending')),
              PopupMenuItem(value: 'Accepted', child: Text('Accept incident')),
              PopupMenuItem(
                  value: 'Responding', child: Text('Team responding')),
              PopupMenuItem(value: 'Rescued', child: Text('Mark rescued')),
            ],
            child: const Icon(Icons.more_horiz, color: Color(0xFF61758C)),
          ),
        ),
      ],
    );
  }

  Widget _filterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedFilter,
        isDense: true,
        style: const TextStyle(color: Color(0xFF52657A), fontSize: 11),
        items: const [
          DropdownMenuItem(value: 'ALL', child: Text('All incidents')),
          DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
          DropdownMenuItem(value: 'HIGH', child: Text('High priority')),
          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium priority')),
          DropdownMenuItem(value: 'LOW', child: Text('Low priority')),
        ],
        onChanged: (filter) {
          if (filter != null) setState(() => _selectedFilter = filter);
        },
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _openDetails(SosModel sos) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SosDetailsScreen(sosId: sos.sosId)),
    );
  }

  String _timeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  static Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFD64245);
      case 'MEDIUM':
        return const Color(0xFFE39123);
      default:
        return const Color(0xFF25885E);
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return const Color(0xFF3479C5);
      case 'Responding':
        return const Color(0xFF7654BB);
      case 'Rescued':
        return const Color(0xFF25885E);
      default:
        return const Color(0xFFCB8419);
    }
  }
}

class _Metric {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  const _Metric(this.label, this.value, this.icon, this.color, this.background);
}

class _MapPainter extends CustomPainter {
  final List<SosModel> alerts;

  const _MapPainter(this.alerts);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    paint
      ..color = const Color(0xFFD9E6D5)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    paint
      ..color = const Color(0xFFBBD7EA)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final river = Path()
      ..moveTo(size.width * 0.93, -20)
      ..cubicTo(size.width * 0.70, size.height * 0.25, size.width * 1.08,
          size.height * 0.45, size.width * 0.57, size.height * 0.63)
      ..cubicTo(size.width * 0.27, size.height * 0.78, size.width * 0.58,
          size.height * 0.87, size.width * 0.20, size.height + 20);
    canvas.drawPath(river, paint);

    paint
      ..color = Colors.white
      ..strokeWidth = 4;
    final road = Path()
      ..moveTo(-10, size.height * 0.32)
      ..cubicTo(size.width * 0.32, size.height * 0.25, size.width * 0.58,
          size.height * 0.48, size.width + 10, size.height * 0.25)
      ..moveTo(size.width * 0.08, size.height + 10)
      ..cubicTo(size.width * 0.28, size.height * 0.68, size.width * 0.73,
          size.height * 0.57, size.width * 0.95, -10);
    canvas.drawPath(road, paint);

    final areas = [
      (Offset(size.width * 0.22, size.height * 0.25), 'NORTH ZONE'),
      (Offset(size.width * 0.72, size.height * 0.37), 'EAST ZONE'),
      (Offset(size.width * 0.34, size.height * 0.72), 'SOUTH ZONE'),
    ];
    for (final area in areas) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: area.$2,
          style: const TextStyle(
              color: Color(0xFF728775),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, area.$1);
    }

    final locatedAlerts =
        alerts.where((sos) => sos.latitude != 0 || sos.longitude != 0).toList();
    final latitudes = locatedAlerts.map((sos) => sos.latitude).toList();
    final longitudes = locatedAlerts.map((sos) => sos.longitude).toList();
    final minLat =
        latitudes.isEmpty ? 0.0 : latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat =
        latitudes.isEmpty ? 0.0 : latitudes.reduce((a, b) => a > b ? a : b);
    final minLng =
        longitudes.isEmpty ? 0.0 : longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng =
        longitudes.isEmpty ? 0.0 : longitudes.reduce((a, b) => a > b ? a : b);

    for (final sos in locatedAlerts) {
      final latRange = maxLat - minLat;
      final lngRange = maxLng - minLng;
      final point = Offset(
        size.width *
            (0.14 +
                (lngRange == 0 ? 0.5 : (sos.longitude - minLng) / lngRange) *
                    0.72),
        size.height *
            (0.18 +
                (latRange == 0 ? 0.5 : (maxLat - sos.latitude) / latRange) *
                    0.68),
      );
      final color = _RescueDashboardScreenState._priorityColor(sos.priority);
      canvas.drawCircle(point, 13, Paint()..color = color.withOpacity(0.18));
      canvas.drawCircle(point, 7, Paint()..color = color);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }

    if (alerts.isNotEmpty) {
      final point = Offset(size.width * 0.50, size.height * 0.50);
      canvas.drawCircle(
          point, 14, Paint()..color = const Color(0xFF2D71BD).withOpacity(0.2));
      canvas.drawCircle(point, 7, Paint()..color = const Color(0xFF2D71BD));
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.alerts != alerts;
}
