import 'package:caresync/core/constants/app_colors.dart';
import 'package:caresync/core/errors/app_error_formatter.dart';
import 'package:caresync/features/medicines/data/models/medicine_models.dart';
import 'package:caresync/features/medicines/presentation/providers/medicine_provider.dart';
import 'package:caresync/features/reminders/data/models/reminder_models.dart';
import 'package:caresync/features/reminders/presentation/providers/reminder_provider.dart';
import 'package:caresync/features/reminders/presentation/widgets/medicine_dose_card.dart';
import 'package:caresync/shared/widgets/app_logo.dart';
import 'package:caresync/shared/widgets/pwa_install_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MedicinesScreen extends ConsumerStatefulWidget {
  const MedicinesScreen({super.key});

  @override
  ConsumerState<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends ConsumerState<MedicinesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'ALL'; // ALL, TODAY, LOW_STOCK

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final remindersAsync = ref.watch(reminderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const AppLogo(size: 28),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          const PwaInstallButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh medicines',
            onPressed: () {
              ref.read(medicineProvider.notifier).loadMedicines();
              ref.read(reminderProvider.notifier).loadTodayDoses();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: medicinesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Loading medication schedule...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 52, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  AppErrorFormatter.format(err),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(medicineProvider.notifier).loadMedicines();
                    ref.read(reminderProvider.notifier).loadTodayDoses();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (medicines) {
          final doses = remindersAsync.valueOrNull ?? [];
          final lowStockCount = medicines.where((m) => m.isLowStock).length;

          // Apply filters
          final filtered = medicines.where((med) {
            // Category filter
            if (_activeFilter == 'LOW_STOCK' && !med.isLowStock) return false;
            if (_activeFilter == 'TODAY') {
              final hasTodayDose = doses.any((d) => d.medicineId == med.id);
              if (!hasTodayDose) return false;
            }

            // Search filter
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            final name = med.name.toLowerCase();
            final notes = (med.notes ?? '').toLowerCase();
            final dosage = (med.dosage ?? '').toLowerCase();
            return name.contains(q) || notes.contains(q) || dosage.contains(q);
          }).toList();

          return CustomScrollView(
            slivers: [
              // Header & Overview Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title & subtitle
                      const Text(
                        'My Medications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track your prescriptions, daily doses, and refill inventory.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Highlights
                      _buildSummaryRow(medicines.length, doses.length, lowStockCount),
                      const SizedBox(height: 16),

                      // Product Search Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicines by name or dosage...',
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                            prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All (${medicines.length})', 'ALL'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Today\'s Schedule (${doses.length})', 'TODAY'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Low Stock ($lowStockCount)', 'LOW_STOCK', isWarning: lowStockCount > 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Medicines List
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.medication_rounded, size: 52, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            medicines.isEmpty
                                ? 'No medicines added yet'
                                : 'No medicines match your filter',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            medicines.isEmpty
                                ? 'Add your active prescriptions to receive automated reminders and refill tracking.'
                                : 'Try searching with a different keyword or resetting filters.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          if (medicines.isEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditMedicineDialog(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Your First Medicine'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          else
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _activeFilter = 'ALL';
                                });
                              },
                              child: const Text('Reset Filters'),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = filtered[index];
                        final matchingDose = doses.cast<ReminderOccurrenceModel?>().firstWhere(
                              (d) => d?.medicineId == med.id,
                              orElse: () => null,
                            );

                        if (matchingDose != null) {
                          return MedicineDoseCard(
                            dose: matchingDose,
                            scheduleSummary: med.scheduleDisplaySummary,
                            allScheduleTimes: med.formattedScheduleTimes,
                            onEdit: () => _showAddEditMedicineDialog(existing: med),
                            onDelete: () => _confirmDeleteMedicine(med),
                          );
                        }

                        final String fallbackTimeStr;
                        if (med.schedules.isNotEmpty &&
                            med.schedules.first.scheduledTimes.isNotEmpty) {
                          final firstTime = med.schedules.first.scheduledTimes.first;
                          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                          fallbackTimeStr = '${todayStr}T$firstTime:00';
                        } else {
                          fallbackTimeStr = DateTime.now().toIso8601String();
                        }

                        final fallbackDose = ReminderOccurrenceModel(
                          id: med.id,
                          medicineId: med.id,
                          medicineName: med.name,
                          dosage: med.dosage,
                          currentStock: med.currentQuantity,
                          refillThreshold: med.refillThreshold,
                          scheduledTime: fallbackTimeStr,
                          status: 'PENDING',
                          snoozeCount: 0,
                        );

                        return MedicineDoseCard(
                          dose: fallbackDose,
                          scheduleSummary: med.scheduleDisplaySummary,
                          allScheduleTimes: med.formattedScheduleTimes,
                          onEdit: () => _showAddEditMedicineDialog(existing: med),
                          onDelete: () => _confirmDeleteMedicine(med),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditMedicineDialog(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Add Medicine', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildSummaryRow(int totalMeds, int todayDoses, int lowStockCount) {
    return Row(
      children: [
        _buildMetricItem(
          label: 'Prescriptions',
          value: '$totalMeds',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFEFF6FF),
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          label: 'Today\'s Doses',
          value: '$todayDoses',
          icon: Icons.calendar_today_rounded,
          color: Colors.indigo,
          bg: const Color(0xFFEEF2FF),
        ),
        const SizedBox(width: 10),
        _buildMetricItem(
          label: 'Refill Alerts',
          value: '$lowStockCount',
          icon: Icons.inventory_rounded,
          color: lowStockCount > 0 ? Colors.amber.shade800 : AppColors.success,
          bg: lowStockCount > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey, {bool isWarning = false}) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isWarning ? Colors.amber.shade800 : AppColors.primary)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isWarning ? Colors.amber.shade800 : AppColors.primary)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isWarning ? Colors.amber.shade900 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  TimeOfDay _parseTimeString(String s) {
    try {
      final parts = s.trim().split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$minute $period';
  }

  String _timeOfDayTo24h(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<TimeOfDay> _getDefaultTimesForFrequency(String freq) {
    switch (freq) {
      case 'ONCE_DAILY':
        return [const TimeOfDay(hour: 8, minute: 0)];
      case 'TWICE_DAILY':
        return [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)];
      case 'THREE_TIMES_DAILY':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 13, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)
        ];
      case 'FOUR_TIMES_DAILY':
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)
        ];
      case 'WEEKLY':
        return [const TimeOfDay(hour: 9, minute: 0)];
      case 'AS_NEEDED':
      default:
        return [];
    }
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

    String selectedFrequency = 'ONCE_DAILY';
    List<TimeOfDay> selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];

    if (existing != null && existing.schedules.isNotEmpty) {
      final sch = existing.schedules.first;
      selectedFrequency = sch.frequency ?? 'ONCE_DAILY';
      if (sch.scheduledTimes.isNotEmpty) {
        selectedTimes = sch.scheduledTimes.map(_parseTimeString).toList();
      } else {
        selectedTimes = _getDefaultTimesForFrequency(selectedFrequency);
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Medicine' : 'Add New Medicine',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
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
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage / Strength',
                        hintText: 'e.g., 500mg, 1 tablet',
                        prefixIcon: Icon(Icons.vaccines_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency *',
                        prefixIcon: Icon(Icons.repeat_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ONCE_DAILY', child: Text('Once daily (1 dose)')),
                        DropdownMenuItem(value: 'TWICE_DAILY', child: Text('Twice daily (2 doses)')),
                        DropdownMenuItem(value: 'THREE_TIMES_DAILY', child: Text('Three times daily (3 doses)')),
                        DropdownMenuItem(value: 'FOUR_TIMES_DAILY', child: Text('Four times daily (4 doses)')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                        DropdownMenuItem(value: 'AS_NEEDED', child: Text('As needed (PRN)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedFrequency = val;
                            selectedTimes = _getDefaultTimesForFrequency(val);
                          });
                        }
                      },
                    ),
                    if (selectedFrequency != 'AS_NEEDED') ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reminder Schedule Times',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                final nextHour = selectedTimes.isEmpty
                                    ? 8
                                    : (selectedTimes.last.hour + 4) % 24;
                                selectedTimes.add(TimeOfDay(hour: nextHour, minute: 0));
                              });
                            },
                            icon: const Icon(Icons.add_alarm_rounded, size: 16),
                            label: const Text('Add Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (selectedTimes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('No reminder times configured.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => setDialogState(() => selectedTimes.add(const TimeOfDay(hour: 8, minute: 0))),
                                child: const Text('Add Default (8:00 AM)'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(selectedTimes.length, (idx) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    selectedTimes.length == 1 ? 'Reminder Time' : 'Dose ${idx + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTimes[idx],
                                      );
                                      if (picked != null) {
                                        setDialogState(() {
                                          selectedTimes[idx] = picked;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTimeOfDay(selectedTimes[idx]),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primary),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (selectedTimes.length > 1) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                      tooltip: 'Remove time',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedTimes.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                    const SizedBox(height: 14),
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
                              labelText: 'Refill Alert Level',
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Instructions & Notes (Optional)',
                        hintText: 'e.g., Take with plenty of water. Do not take on empty stomach.',
                        prefixIcon: Icon(Icons.notes_rounded),
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
                      final times24h = selectedTimes.map(_timeOfDayTo24h).toList();
                      if (selectedFrequency != 'AS_NEEDED' && times24h.toSet().length != times24h.length) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select different reminder times for each dose (no duplicates).'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

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
                                frequency: selectedFrequency,
                                scheduledTimes: times24h.isNotEmpty ? times24h : null,
                              );
                        } else {
                          await ref.read(medicineProvider.notifier).addMedicine(
                                name: name,
                                dosage: dosage.isNotEmpty ? dosage : null,
                                currentQuantity: stock,
                                refillThreshold: refill,
                                notes: notes.isNotEmpty ? notes : null,
                                frequency: selectedFrequency,
                                scheduledTimes: times24h.isNotEmpty ? times24h : null,
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
                            SnackBar(content: Text(AppErrorFormatter.format(e)), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
        content: Text('Are you sure you want to remove "${med.name}" from your active medications?'),
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
