import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trail.dart';

class SafetyCheckInScreen extends StatefulWidget {
  final Trail trail;
  const SafetyCheckInScreen({super.key, required this.trail});

  @override
  State<SafetyCheckInScreen> createState() => _SafetyCheckInScreenState();
}

class _SafetyCheckInScreenState extends State<SafetyCheckInScreen> {
  DateTime _expectedEndTime = DateTime.now().add(const Duration(hours: 4));

  String _formattedTime() {
    final h = _expectedEndTime.hour.toString().padLeft(2, '0');
    final m = _expectedEndTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Safety Check-in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trail summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF112D24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.trail.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.terrain_rounded,
                        color: widget.trail.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trail.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.trail.parkName}  •  ${widget.trail.distanceKm} km  •  ${widget.trail.difficulty}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionLabel('Expected Finish Time'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_expectedEndTime),
                );
                if (picked != null) {
                  setState(() {
                    _expectedEndTime = DateTime(
                      _expectedEndTime.year,
                      _expectedEndTime.month,
                      _expectedEndTime.day,
                      picked.hour,
                      picked.minute,
                    );
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF112D24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: Color(0xFF2ECC71), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _formattedTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey[700], size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            _sectionLabel('Emergency Contacts'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF112D24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.phone_outlined,
                      color: Colors.redAccent, size: 18),
                ),
                title: const Text('Emergency Contact',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text('Not configured',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Icon(Icons.add_rounded,
                    color: Colors.grey[700], size: 20),
                onTap: () {},
              ),
            ),

            const SizedBox(height: 16),

            // Safety reminder
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ensure your emergency contacts know your plan. Carry sufficient water, first aid supplies, and a fully charged phone.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400], height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/active-hike', extra: widget.trail),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm & Start Hike',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
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
