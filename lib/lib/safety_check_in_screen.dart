import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/trail.dart';

class SafetyCheckInScreen extends StatefulWidget {
  final Trail trail;
  const SafetyCheckInScreen({super.key, required this.trail});

  @override
  State<SafetyCheckInScreen> createState() => _SafetyCheckInScreenState();
}

class _SafetyCheckInScreenState extends State<SafetyCheckInScreen> {
  DateTime expectedEndTime = DateTime.now().add(const Duration(hours: 4));

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(expectedEndTime),
    );
    if (picked != null) {
      setState(() {
        expectedEndTime = DateTime(
          expectedEndTime.year,
          expectedEndTime.month,
          expectedEndTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Check-in")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You're about to start:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.green.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.withOpacity(0.3)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: widget.trail.color.withOpacity(0.2),
                  child: Text(widget.trail.emoji),
                ),
                title: Text(widget.trail.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${widget.trail.distanceKm} km • ${widget.trail.difficulty} • ${widget.trail.formattedEstTime}"),
              ),
            ),
            const SizedBox(height: 30),

            const Text("Expected Finish Time", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  "${expectedEndTime.hour.toString().padLeft(2, '0')}:${expectedEndTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.access_time_filled, color: Colors.green),
                onTap: () => _selectTime(context),
              ),
            ),

            const SizedBox(height: 30),
            const Text("Emergency Contacts", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text("Emergency Contact (Mom)"),
                subtitle: Text("012-345 6789"),
                trailing: Icon(Icons.verified_user, color: Colors.blue, size: 20),
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: () {
                  context.push('/active-hike', extra: widget.trail);
                },
                child: const Text("CONFIRM & START HIKE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Your location will be shared if you are overdue.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
