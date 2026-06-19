import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tripship/features/trips/presentation/providers/post_trip_provider.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/enums/app_enums.dart';
import 'package:tripship/features/trips/data/trip_model.dart';
import 'package:tripship/core/utils/error_utils.dart';

class PostTripScreen extends ConsumerStatefulWidget {
  final String? transportMode;
  final Trip? initialTrip;
  const PostTripScreen({super.key, this.transportMode, this.initialTrip});

  @override
  ConsumerState<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends ConsumerState<PostTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(postTripProvider.notifier)
          .initialize(
            initialTrip: widget.initialTrip,
            transportMode: widget.transportMode,
          );
      if (widget.initialTrip != null) {
        _weightController.text =
            widget.initialTrip!.maxWeightKg?.toString() ?? '';
        _descriptionController.text = widget.initialTrip!.notes ?? '';
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final state = ref.read(postTripProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      ref.read(postTripProvider.notifier).onDateChanged(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final state = ref.read(postTripProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: state.selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      ref.read(postTripProvider.notifier).onTimeChanged(picked);
    }
  }

  void _showRepeatDialog() async {
    final state = ref.read(postTripProvider);
    if (state.selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectDate)),
      );
      return;
    }

    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final availableDates = List.generate(
      30,
      (index) => state.selectedDate!.add(Duration(days: index + 1)),
    );

    List<DateTime> tempSelected = List.from(state.repeatDates);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(localizations.selectRepeatDays),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableDates.length,
              itemBuilder: (context, index) {
                final date = availableDates[index];
                final isSelected = tempSelected.any(
                  (d) =>
                      d.year == date.year &&
                      d.month == date.month &&
                      d.day == date.day,
                );
                final dayName = DateFormat('EEEE', locale).format(date);
                final dateStr = DateFormat('d/M/y').format(date);
                return CheckboxListTile(
                  title: Text(
                    "$dayName $dateStr",
                    style: const TextStyle(fontSize: 14),
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        tempSelected.add(date);
                      } else {
                        tempSelected.removeWhere(
                          (d) =>
                              d.year == date.year &&
                              d.month == date.month &&
                              d.day == date.day,
                        );
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(postTripProvider.notifier)
                    .onRepeatDatesChanged(tempSelected);
                Navigator.pop(context);
              },
              child: Text(localizations.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final localizations = AppLocalizations.of(context)!;
    final weight = double.tryParse(_weightController.text.trim());
    final notes = _descriptionController.text.trim();

    try {
      final success = await ref
          .read(postTripProvider.notifier)
          .submit(weight: weight, notes: notes.isEmpty ? null : notes);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.tripPosted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(e, localizations.unexpectedError, context),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postTripProvider);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (state.isLoadingLocations && state.countries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.postTrip)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTypeToggle(localizations),
                const SizedBox(height: 8),
                _buildRouteCard(localizations, context),
                const SizedBox(height: 8),
                _buildDateTimeSection(localizations),
                const SizedBox(height: 12),
                _buildRepeatSection(localizations, theme),
                const SizedBox(height: 8),
                _buildDetailsCard(localizations, isArabic),
                const SizedBox(height: 8),
                _buildSubmitButton(localizations, theme),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations localizations) {
    final state = ref.watch(postTripProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                localizations.shippingType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [
                state.transportType == TransportType.internal,
                state.transportType == TransportType.external,
              ],
              onPressed: (index) => ref
                  .read(postTripProvider.notifier)
                  .setTransportType(
                    index == 0
                        ? TransportType.internal
                        : TransportType.external,
                  ),
              borderRadius: BorderRadius.circular(8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(localizations.internalShipping),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(localizations.externalShipping),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildRouteCard(AppLocalizations localizations, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationPicker(isOrigin: true, localizations: localizations),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Center(
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.grey.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            ),
            _buildLocationPicker(isOrigin: false, localizations: localizations),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 300.ms);
  }

  Widget _buildDateTimeSection(AppLocalizations localizations) {
    final state = ref.watch(postTripProvider);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(context),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              state.selectedDate == null
                  ? localizations.date
                  : DateFormat.yMMMd().format(state.selectedDate!),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectTime(context),
            icon: const Icon(Icons.access_time),
            label: Text(
              state.selectedTime == null
                  ? localizations.time
                  : state.selectedTime!.format(context),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildRepeatSection(AppLocalizations localizations, ThemeData theme) {
    final state = ref.watch(postTripProvider);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: _showRepeatDialog,
        icon: Icon(
          Icons.repeat,
          size: 20,
          color: state.repeatDates.isNotEmpty
              ? theme.primaryColor
              : Colors.grey,
        ),
        label: Text(
          state.repeatDates.isEmpty
              ? localizations.repeatTrip
              : "${localizations.repeatTrip} (${state.repeatDates.length})",
          style: TextStyle(
            color: state.repeatDates.isNotEmpty
                ? theme.primaryColor
                : Colors.grey[700],
            fontWeight: state.repeatDates.isNotEmpty
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildDetailsCard(AppLocalizations localizations, bool isArabic) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText:
                    "${localizations.availableWeight} (${localizations.kg})",
                prefixIcon: const Icon(Icons.fitness_center),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final w = double.tryParse(value);
                return (w == null || w <= 0)
                    ? localizations.invalidWeight
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: isArabic ? 'ملاحظات' : 'Remarks',
                hintText: isArabic
                    ? 'معلومات إضافية، ملاحظات، إلخ...'
                    : 'Additional information, remarks, etc...',
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: 2,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSubmitButton(AppLocalizations localizations, ThemeData theme) {
    final state = ref.watch(postTripProvider);
    return ElevatedButton(
      onPressed: state.isSaving ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      child: state.isSaving
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              localizations.createTrip,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildLocationPicker({
    required bool isOrigin,
    required AppLocalizations localizations,
  }) {
    final state = ref.watch(postTripProvider);
    final localeCode = Localizations.localeOf(context).languageCode;
    final nameKey = localeCode == 'ar' ? 'name_ar' : 'name_en';
    final isInternal = state.transportType == TransportType.internal;
    final notifier = ref.read(postTripProvider.notifier);

    InputDecoration fieldDecoration(
      String label, {
      bool smallPadding = false,
    }) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: smallPadding ? 8 : 12,
        vertical: 8,
      ),
      isDense: true,
    );

    final countries = state.countries;
    final itemsProvince = isOrigin
        ? state.originProvinces
        : state.destProvinces;
    final itemsCity = isOrigin ? state.originCities : state.destCities;
    final itemsTown = isOrigin ? state.originTowns : state.destTowns;

    final selectedCountry = isOrigin
        ? state.selectedOriginCountry
        : state.selectedDestCountry;
    final selectedProvince = isOrigin
        ? state.selectedOriginProvince
        : state.selectedDestProvince;
    final selectedCity = isOrigin
        ? state.selectedOriginCity
        : state.selectedDestCity;
    final selectedTown = isOrigin
        ? state.selectedOriginTown
        : state.selectedDestTown;

    return Column(
      children: [
        if (!isInternal) ...[
          DropdownButtonFormField<String>(
            initialValue: selectedCountry != null
                ? selectedCountry['name_ar'] as String
                : null,
            decoration: fieldDecoration(localizations.country),
            isExpanded: true,
            items: countries
                .map(
                  (c) => DropdownMenuItem(
                    value: c['name_ar'] as String,
                    child: Text(c[nameKey] ?? c['name_ar'] ?? '?'),
                  ),
                )
                .toList(),
            onChanged: (val) {
              final model = val == null
                  ? null
                  : countries.firstWhere((c) => c['name_ar'] == val);
              if (isOrigin) {
                notifier.onOriginCountryChanged(model);
              } else {
                notifier.onDestCountryChanged(model);
              }
            },
            validator: (v) => v == null ? localizations.fieldRequired : null,
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          initialValue: selectedProvince != null
              ? selectedProvince['name_ar'] as String
              : null,
          decoration: fieldDecoration(localizations.province),
          isExpanded: true,
          items: itemsProvince
              .map(
                (c) => DropdownMenuItem(
                  value: c['name_ar'] as String,
                  child: Text(c[nameKey] ?? c['name_ar'] ?? '?'),
                ),
              )
              .toList(),
          onChanged: (val) {
            final model = val == null
                ? null
                : itemsProvince.firstWhere((c) => c['name_ar'] == val);
            if (isOrigin) {
              notifier.onOriginProvinceChanged(model);
            } else {
              notifier.onDestProvinceChanged(model);
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedCity != null
                    ? selectedCity['name_ar'] as String
                    : null,
                decoration: fieldDecoration(
                  localizations.city,
                  smallPadding: isInternal,
                ),
                isExpanded: true,
                items: itemsCity
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['name_ar'] as String,
                        child: Text(c[nameKey] ?? c['name_ar'] ?? '?'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  final model = val == null
                      ? null
                      : itemsCity.firstWhere((c) => c['name_ar'] == val);
                  if (isOrigin) {
                    notifier.onOriginCityChanged(model);
                  } else {
                    notifier.onDestCityChanged(model);
                  }
                },
                validator: (v) =>
                    v == null ? localizations.fieldRequired : null,
              ),
            ),
            if (isInternal) ...[
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedTown != null
                      ? selectedTown['name_ar'] as String
                      : null,
                  decoration: fieldDecoration(
                    localizations.town,
                    smallPadding: true,
                  ),
                  isExpanded: true,
                  items: itemsTown
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['name_ar'] as String,
                          child: Text(c[nameKey] ?? c['name_ar'] ?? '?'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    final model = val == null
                        ? null
                        : itemsTown.firstWhere((c) => c['name_ar'] == val);
                    if (isOrigin) {
                      notifier.onOriginTownChanged(model);
                    } else {
                      notifier.onDestTownChanged(model);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
