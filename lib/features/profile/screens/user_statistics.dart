import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/hike_record.dart';
import '../../../services/trail_service.dart';
import '../../../services/unit_service.dart';
import '../../../core/theme/app_theme.dart';

// ── Period filter ─────────────────────────────────────────────────────────────
enum _Period { week, month, allTime }

class UserStatisticsScreen extends StatefulWidget {
  const UserStatisticsScreen({super.key});

  @override
  State<UserStatisticsScreen> createState() => _UserStatisticsScreenState();
}

class _UserStatisticsScreenState extends State<UserStatisticsScreen>
    with SingleTickerProviderStateMixin {
  final _trailService = TrailService();
  List<HikeRecord> _records = [];
  bool _isLoading = true;
  _Period _period = _Period.week;

  late final AnimationController _animController;
  late final Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final records = await _trailService.getHikeHistory();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  void _setPeriod(_Period p) {
    if (_period == p) return;
    setState(() => _period = p);
    _animController.forward(from: 0);
  }

  // ── Chart data ──────────────────────────────────────────────────────────────

  List<_BarData> get _chartData {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        // Last 7 days (today inclusive), labelled with weekday initial
        const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return List.generate(7, (i) {
          final day = DateTime(
            now.year, now.month, now.day - (6 - i),
          );
          final count = _records.where((r) {
            if (r.timestamp == null) return false;
            final t = r.timestamp!;
            return t.year == day.year && t.month == day.month && t.day == day.day;
          }).length;
          return _BarData(label: dayLabels[day.weekday - 1], count: count);
        });

      case _Period.month:
        // Last 4 complete calendar weeks (Mon → Sun), newest on the right
        final mondayThisWeek = DateTime(
          now.year, now.month, now.day - (now.weekday - 1),
        );
        return List.generate(4, (i) {
          final weekStart = DateTime(
            mondayThisWeek.year,
            mondayThisWeek.month,
            mondayThisWeek.day - (3 - i) * 7,
          );
          final weekEnd = DateTime(
            weekStart.year, weekStart.month, weekStart.day + 6,
            23, 59, 59,
          );
          final count = _records.where((r) {
            if (r.timestamp == null) return false;
            return !r.timestamp!.isBefore(weekStart) &&
                !r.timestamp!.isAfter(weekEnd);
          }).length;
          return _BarData(label: 'W${i + 1}', count: count);
        });

      case _Period.allTime:
        // Last 6 calendar months (oldest → newest)
        const monthAbbr = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return List.generate(6, (i) {
          final month = DateTime(now.year, now.month - (5 - i), 1);
          final count = _records.where((r) {
            if (r.timestamp == null) return false;
            return r.timestamp!.year == month.year &&
                r.timestamp!.month == month.month;
          }).length;
          return _BarData(label: monthAbbr[month.month - 1], count: count);
        });
    }
  }

  // ── Period-filtered records ─────────────────────────────────────────────────

  List<HikeRecord> get _periodRecords {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        final start = DateTime(now.year, now.month, now.day - 6);
        return _records.where((r) => r.timestamp != null && !r.timestamp!.isBefore(start)).toList();
      case _Period.month:
        final start = DateTime(now.year, now.month, now.day - 27);
        return _records.where((r) => r.timestamp != null && !r.timestamp!.isBefore(start)).toList();
      case _Period.allTime:
        return _records;
    }
  }

  // ── Derived stats ───────────────────────────────────────────────────────────

  int get _weekHikeCount {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return _records.where((r) => r.timestamp != null && !r.timestamp!.isBefore(monday)).length;
  }

  String get _avgDuration {
    final pr = _periodRecords;
    if (pr.isEmpty) return '--';
    final avgSecs = pr.fold<int>(0, (s, r) => s + r.elapsedSeconds) ~/ pr.length;
    final d = Duration(seconds: avgSecs);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.primaryAccent,
                strokeWidth: 2,
              ),
            )
          : CustomScrollView(
              slivers: [
                // ── App Bar ─────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: theme.cardColor,
                  foregroundColor: theme.textColor,
                  pinned: true,
                  expandedHeight: 110,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 14),
                    title: Text(
                      'Statistics',
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
                    child: Container(
                      height: 1,
                      color: theme.borderColor,
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Period selector ──────────────────────────────
                      _PeriodSelector(
                        current: _period,
                        onChanged: _setPeriod,
                      ),

                      const SizedBox(height: 16),

                      // ── Bar chart ────────────────────────────────────
                      _ChartCard(
                        data: _chartData,
                        animation: _barAnim,
                        periodLabel: _periodLabel,
                        periodCount: _periodRecords.length,
                      ),

                      const SizedBox(height: 16),

                      // ── Highlight cards ──────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _HighlightCard(
                              icon: Icons.calendar_today_rounded,
                              value: '$_weekHikeCount',
                              label: 'Hikes This Week',
                              accent: const Color(0xFF2ECC71),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HighlightCard(
                              icon: Icons.timer_outlined,
                              value: _avgDuration,
                              label: 'Avg Duration',
                              accent: const Color(0xFF58D68D),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Lifetime section ─────────────────────────────
                      const _SectionLabel(text: 'Lifetime'),
                      const SizedBox(height: 12),
                      _LifetimeGrid(records: _records),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.week:
        return 'Last 7 days';
      case _Period.month:
        return 'Last 4 weeks';
      case _Period.allTime:
        return 'Last 6 months';
    }
  }
}

// ── Period Selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChanged;

  const _PeriodSelector({required this.current, required this.onChanged});

  static const _labels = {
    _Period.week: 'Week',
    _Period.month: 'Month',
    _Period.allTime: 'All Time',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF112D24),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: _Period.values.map((p) {
          final selected = current == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF2ECC71) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _labels[p]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.black : Colors.grey[400],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Bar Chart Card ────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<_BarData> data;
  final Animation<double> animation;
  final String periodLabel;
  final int periodCount;

  const _ChartCard({
    required this.data,
    required this.animation,
    required this.periodLabel,
    required this.periodCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF112D24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hike Frequency',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    periodLabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$periodCount hike${periodCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: _BarChartPainter(
                  data: data,
                  progress: animation.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar Chart Painter ─────────────────────────────────────────────────────────

class _BarData {
  final String label;
  final int count;
  const _BarData({required this.label, required this.count});
}

class _BarChartPainter extends CustomPainter {
  final List<_BarData> data;
  final double progress;

  const _BarChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const barGap = 8.0;
    const labelAreaH = 26.0;
    const countAreaH = 18.0;
    final chartH = size.height - labelAreaH - countAreaH;
    final barW = (size.width - (data.length - 1) * barGap) / data.length;

    final maxCount = data.map((d) => d.count).fold<int>(0, math.max);
    final effectiveMax = maxCount < 1 ? 1 : maxCount;

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.04);

    for (int i = 0; i < data.length; i++) {
      final x = i * (barW + barGap);
      final barH = (data[i].count / effectiveMax) * chartH * progress;
      final barTop = countAreaH + (chartH - barH);

      // Background track
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, countAreaH, barW, chartH),
          const Radius.circular(7),
        ),
        bgPaint,
      );

      // Filled bar
      if (data[i].count > 0 && barH > 0) {
        final fgPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2ECC71), Color(0xFF1A9E54)],
          ).createShader(Rect.fromLTWH(x, barTop, barW, barH));

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, barTop, barW, barH),
            const Radius.circular(7),
          ),
          fgPaint,
        );

        // Count above bar (only if bar is tall enough)
        if (barH > 20 && progress > 0.6) {
          final opacity = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
          _drawText(
            canvas,
            '${data[i].count}',
            TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: opacity),
            ),
            Offset(x + barW / 2, math.max(0, barTop - 16)),
            centered: true,
          );
        }
      }

      // Day label below
      _drawText(
        canvas,
        data[i].label,
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
        Offset(x + barW / 2, size.height - labelAreaH + 6),
        centered: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset position, {
    bool centered = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      centered
          ? Offset(position.dx - tp.width / 2, position.dy)
          : position,
    );
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.progress != progress || old.data != data;
}

// ── Highlight Cards ───────────────────────────────────────────────────────────

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _HighlightCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.textColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.subTextColor),
          ),
        ],
      ),
    );
  }
}

// ── Lifetime Stats Grid ───────────────────────────────────────────────────────

class _LifetimeGrid extends StatelessWidget {
  final List<HikeRecord> records;
  const _LifetimeGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final totalHikes = records.length;
    final totalDist = records.fold<double>(0, (s, r) => s + r.distanceKm);
    final totalElev = records.fold<int>(0, (s, r) => s + r.elevationGain);
    final totalCals = records.fold<int>(0, (s, r) => s + r.calories);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _LifetimeTile(
          icon: Icons.hiking,
          label: 'Total Hikes',
          value: '$totalHikes',
          unit: '',
        ),
        ValueListenableBuilder<DistanceUnit>(
          valueListenable: UnitService.distanceUnitNotifier,
          builder: (context, _, __) {
            return _LifetimeTile(
              icon: Icons.straighten_rounded,
              label: 'Total Distance',
              value: UnitService.formatDistanceValue(totalDist),
              unit: UnitService.distanceSymbol,
            );
          },
        ),
        _LifetimeTile(
          icon: Icons.landscape_outlined,
          label: 'Total Elevation',
          value: '$totalElev',
          unit: 'm',
        ),
        _LifetimeTile(
          icon: Icons.local_fire_department_outlined,
          label: 'Total Calories',
          value: '$totalCals',
          unit: 'cal',
        ),
      ],
    );
  }
}

class _LifetimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _LifetimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: theme.primaryAccent, size: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                        height: 1,
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
    );
  }
}
