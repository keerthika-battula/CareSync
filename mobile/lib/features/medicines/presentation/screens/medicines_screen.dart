import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:caresync/features/reminders/presentation/widgets/medicine_dose_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicinesScreen extends ConsumerStatefulWidget {
  const MedicinesScreen({super.key});

  @override
  ConsumerState<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends ConsumerState<MedicinesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final remindersAsync = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Medicines', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh medicines',
            onPressed: () {
              ref.read(medicineProvider.notifier).loadMedicines();
              ref.read(reminderProvider.notifier).loadTodayDoses();
            },
          ),
        ],
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load medicines: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(medicineProvider.notifier).loadMedicines();
                    ref.read(reminderProvider.notifier).loadTodayDoses();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (medicines) {
          final filtered = medicines.where((med) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final name = med.name.toLowerCase();
            final notes = (med.notes ?? '').toLowerCase();
            final dosage = (med.dosage ?? '').toLowerCase();
            return name.contains(q) || notes.contains(q) || dosage.contains(q);
          }).toList();

          final doses = remindersAsync.valueOrNull ?? [];

          return CustomScrollView(
            slivers: [
              // Search Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search medicines by name, dosage, or notes...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ),

              // Medicines List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          medicines.isEmpty ? 'No medicines added yet' : 'No medicines match your search',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (medicines.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Click the button below to add your first medicine',
                            style: TextStyle(fontSize: 13, color: AppColors.textLight),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = filtered[index];
                        // Find today's dose for this medicine if available
                        final matchingDose = doses.cast<ReminderOccurrenceModel?>().firstWhere(
                              (d) => d?.medicineId == med.id,
                              orElse: () => null,
                            );

                        if (matchingDose != null) {
                          return MedicineDoseCard(
                            dose: matchingDose,
                            onEdit: () => _showAddEditMedicineDialog(existing: med),
                            onDelete: () => _confirmDeleteMedicine(med),
                          );
                        }

                        // Fallback synthesized dose card representation
                        final fallbackDose = ReminderOccurrenceModel(
                          id: med.id,
                          medicineId: med.id,
                          medicineName: med.name,
                          dosage: med.dosage,
                          currentStock: med.currentQuantity,
                          refillThreshold: med.refillThreshold,
                          scheduledTime: DateTime.now().toIso8601String(),
                          status: 'PENDING',
                          snoozeCount: 0,
                        );

                        return MedicineDoseCard(
                          dose: fallbackDose,
                          onEdit: () => _showAddEditMedicineDialog(existing: med),
                          onDelete: () => _confirmDeleteMedicine(med),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditMedicineDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddEditMedicineDialog({MedicineModel? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final dosageController = TextEditingController(text: existing?.dosage ?? '');
    final stockController = TextEditingController(text: existing != null ? existing.currentQuantity.toString() : '30');
    final refillController = TextEditingController(text: existing != null ? existing.refillThreshold.toString() : '7');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Medicine' : 'Add Medicine',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name *',
                        hintText: 'e.g., Paracetamol, Amoxicillin',
                        prefixIcon: Icon(Icons.medication),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage / Schedule',
                        hintText: 'e.g., 500mg • Once daily after breakfast',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Current Stock',
                              hintText: 'e.g., 30',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (int.tryParse(v.trim()) == null) return 'Must be integer';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: refillController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Refill Threshold',
                              hintText: 'e.g., 7',
                              prefixIcon: Icon(Icons.warning_amber_rounded),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (int.tryParse(v.trim()) == null) return 'Must be integer';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Notes',
                        hintText: 'e.g., Take with plenty of water',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final name = nameController.text.trim();
                        final dosage = dosageController.text.trim();
                        final stock = int.tryParse(stockController.text.trim()) ?? 0;
                        final refill = int.tryParse(refillController.text.trim()) ?? 7;
                        final notes = notesController.text.trim();

                        if (isEditing) {
                          await ref.read(medicineProvider.notifier).updateMedicine(
                                id: existing.id,
                                name: name,
                                dosage: dosage.isNotEmpty ? dosage : null,
                                currentQuantity: stock,
                                refillThreshold: refill,
                                notes: notes.isNotEmpty ? notes : null,
                              );
                        } else {
                          await ref.read(medicineProvider.notifier).addMedicine(
                                name: name,
                                dosage: dosage.isNotEmpty ? dosage : null,
                                currentQuantity: stock,
                                refillThreshold: refill,
                                notes: notes.isNotEmpty ? notes : null,
                              );
                        }
                        ref.read(reminderProvider.notifier).loadTodayDoses();
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Medicine updated successfully' : 'Medicine added successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Save Changes' : 'Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedicine(MedicineModel med) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${med.name}" from your active medicines?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref.read(medicineProvider.notifier).deleteMedicine(med.id);
                ref.read(reminderProvider.notifier).loadTodayDoses();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine removed successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
