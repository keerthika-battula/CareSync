import 'package:flutter/material.dart';

class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMedCard('Aspirin', '10mg', '120 tablets left'),
          _buildMedCard('Vitamin C', '500mg', '45 tablets left'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
    );
  }

  Widget _buildMedCard(String name, String dosage, String stock) {
    return Card(
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Dosage: $dosage\nStock: $stock'),
        isThreeLine: true,
        trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
      ),
    );
  }
}
