import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CARESYNC'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Good Morning!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),
            const Text("Today's Medicines", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMedicineCard('Aspirin', '08:00 AM', true),
            _buildMedicineCard('Vitamin C', '01:00 PM', false),
            const SizedBox(height: 24),
            const Text("Upcoming Appointment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildAppointmentCard('Dr. Smith', 'Tomorrow, 10:30 AM'),
            const SizedBox(height: 24),
            const Text("Refill Alerts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRefillCard('Ibuprofen', 'Approx 6 days remaining'),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(String name, String time, bool taken) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.medication, color: taken ? Colors.green : Colors.grey),
        title: Text(name),
        subtitle: Text(time),
        trailing: taken ? const Icon(Icons.check_circle, color: Colors.green) : ElevatedButton(onPressed: (){}, child: const Text('Mark Taken')),
      ),
    );
  }

  Widget _buildAppointmentCard(String doc, String time) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month, color: Color(0xFF4A6CF7)),
        title: Text(doc),
        subtitle: Text(time),
      ),
    );
  }

  Widget _buildRefillCard(String name, String status) {
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(name),
        subtitle: Text(status),
        trailing: ElevatedButton(onPressed: (){}, child: const Text('Refilled')),
      ),
    );
  }
}
