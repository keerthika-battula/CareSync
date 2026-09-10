import 'package:flutter/material.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Profiles')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFamilyCard('Myself', 'Self'),
          _buildFamilyCard('Sarah', 'Daughter'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.person_add),
        backgroundColor: const Color(0xFF4A6CF7),
      ),
    );
  }

  Widget _buildFamilyCard(String name, String relation) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text(relation),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
