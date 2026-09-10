import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
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
            onPressed: () => ref.read(medicineProvider.notifier).loadMedicines(),
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
                  onPressed: () => ref.read(medicineProvider.notifier).loadMedicines(),
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
                        return _buildMedCard(med);
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

  Widget _buildMedCard(MedicineModel med) {
    final isLow = med.isLowStock;
    final color = isLow ? Colors.amber : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLow ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        softWrap: true,
                      ),
                    ),
                    if (isLow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                  ],
                ),
                if (med.dosage != null && med.dosage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          med.dosage!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${med.currentQuantity} units (Refill at <= ${med.refillThreshold})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLow ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (med.notes != null && med.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    med.notes!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
            onSelected: (val) {
              if (val == 'edit') {
                _showAddEditMedicineDialog(existing: med);
              } else if (val == 'delete') {
                _confirmDeleteMedicine(med);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Edit Medicine'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
