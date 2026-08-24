import 'package:flutter/material.dart';
import '../../../models/hike_record.dart';
import '../../../services/trail_service.dart';
import '../../../services/unit_service.dart';
import '../../../core/theme/app_theme.dart';

class HikeHistoryScreen extends StatefulWidget {
  const HikeHistoryScreen({super.key});

  @override
  State<HikeHistoryScreen> createState() => _HikeHistoryScreenState();
}

class _HikeHistoryScreenState extends State<HikeHistoryScreen> {
  final _trailService = TrailService();
  List<HikeRecord> _records = [];
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final records = await _trailService.getHikeHistory();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgColor,
      body: RefreshIndicator(
        color: theme.primaryAccent,
        backgroundColor: theme.cardColor,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: theme.cardColor,
              foregroundColor: theme.textColor,
              pinned: true,
              expandedHeight: 110,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 14),
                title: Text(
                  'Hike History',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: theme.textColor,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: theme.borderColor),
              ),
            ),

            // ── Summary header ────────────────────────────────────────────
            if (!_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SummaryHeader(records: _records),
                ),
              ),

            // ── Loading ───────────────────────────────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2ECC71),
                    strokeWidth: 2,
                  ),
                ),
              )

            // ── Empty state ───────────────────────────────────────────────
            else if (_records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )

            // ── List ──────────────────────────────────────────────────────
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _HikeCard(
                      record: _records[i],
                      isExpanded: _expandedIndex == i,
                      onTap: () => setState(() {
                        _expandedIndex = _expandedIndex == i ? null : i;
                      }),
                    ),
                    childCount: _records.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Header ────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final List<HikeRecord> records;
  const _SummaryHeader({required this.records});

  @override
  Widget build(BuildContext context) {
    final totalDist = records.fold<double>(0, (s, r) => s + r.distanceKm);
    final totalCals = records.fold<int>(0, (s, r) => s + r.calories);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3E2E), Color(0xFF112D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          // Hike count
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hiking, color: Color(0xFF2ECC71), size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${records.length}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                records.length == 1 ? 'Trail Completed' : 'Trails Completed',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
          const Spacer(),
          // Right-side stats column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ValueListenableBuilder<DistanceUnit>(
                valueListenable: UnitService.distanceUnitNotifier,
                builder: (context, _, __) {
                  return _HeaderStat(
                    value: UnitService.formatDistance(totalDist),
                    label: 'Distance',
                    color: const Color(0xFF2ECC71),
                  );
                },
              ),
              const SizedBox(height: 6),
              _HeaderStat(
                value: '$totalCals cal',
                label: 'Burned',
                color: Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _HeaderStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}

// ── Hike Card ─────────────────────────────────────────────────────────────────

class _HikeCard extends StatelessWidget {
  final HikeRecord record;
  final bool isExpanded;
  final VoidCallback onTap;

  const _HikeCard({
    required this.record,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? theme.primaryAccent.withValues(alpha: 0.4)
                : theme.borderColor,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: theme.primaryAccent.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.forest_outlined,
                    color: Color(0xFF2ECC71),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.trailName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.parkName,
                        style: TextStyle(fontSize: 12, color: theme.subTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Quick stats ───────────────────────────────────────────────
            Row(
              children: [
                ValueListenableBuilder<DistanceUnit>(
                  valueListenable: UnitService.distanceUnitNotifier,
                  builder: (context, _, __) {
                    return _QuickStat(
                      icon: Icons.straighten_rounded,
                      value: UnitService.formatDistance(record.distanceKm, decimals: 2),
                    );
                  },
                ),
                const SizedBox(width: 20),
                _QuickStat(
                  icon: Icons.timer_outlined,
                  value: record.formattedDuration,
                ),
              ],
            ),

            // ── Expanded detail ───────────────────────────────────────────
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Column(
                        children: [
                          const SizedBox(height: 14),
                          Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _DetailStat(label: 'Avg Pace', value: record.formattedPace),
                              _DetailStat(label: 'Elev Gain', value: '${record.elevationGain} m'),
                              _DetailStat(label: 'Calories', value: '${record.calories}'),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.terrain_outlined,
                color: Color(0xFF2ECC71),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hikes yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your first Borneo adventure\nand your trail history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Stat Widgets ───────────────────────────────────────────────────────

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _QuickStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF2ECC71)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
