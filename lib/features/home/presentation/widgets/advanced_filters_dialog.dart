import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/core/theme/tripship_design_tokens.dart';

class AdvancedFiltersDialog extends StatefulWidget {
  final bool isInternal;
  final List<Location> locations;
  final DateTime? date;
  final double? minWeight;
  final String? selectedVehicleType;
  final String? selectedOriginProvince;
  final String? selectedDestProvince;
  final String? selectedOriginLocationId;
  final String? selectedDestLocationId;
  final String? selectedOrigin;
  final String? selectedDestination;
  final Function(
    double? minWeight,
    DateTime? date,
    String? vehicleType,
    String? originProvince,
    String? destProvince,
    String? originLocationId,
    String? destLocationId,
  )
  onAdvancedFiltersChanged;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestinationChanged;

  const AdvancedFiltersDialog({
    super.key,
    required this.isInternal,
    required this.locations,
    this.date,
    this.minWeight,
    this.selectedVehicleType,
    this.selectedOriginProvince,
    this.selectedDestProvince,
    this.selectedOriginLocationId,
    this.selectedDestLocationId,
    this.selectedOrigin,
    this.selectedDestination,
    required this.onAdvancedFiltersChanged,
    required this.onOriginChanged,
    required this.onDestinationChanged,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();

  static void show(
    BuildContext context, {
    required bool isInternal,
    required List<Location> locations,
    DateTime? date,
    double? minWeight,
    String? selectedVehicleType,
    String? selectedOriginProvince,
    String? selectedDestProvince,
    String? selectedOriginLocationId,
    String? selectedDestLocationId,
    String? selectedOrigin,
    String? selectedDestination,
    required Function(
      double? minWeight,
      DateTime? date,
      String? vehicleType,
      String? originProvince,
      String? destProvince,
      String? originLocationId,
      String? destLocationId,
    )
    onAdvancedFiltersChanged,
    required ValueChanged<String> onOriginChanged,
    required ValueChanged<String> onDestinationChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TripShipDesignTokens.borderRadiusLarge.topLeft.x),
        ),
      ),
      builder: (context) {
        return AdvancedFiltersDialog(
          isInternal: isInternal,
          locations: locations,
          date: date,
          minWeight: minWeight,
          selectedVehicleType: selectedVehicleType,
          selectedOriginProvince: selectedOriginProvince,
          selectedDestProvince: selectedDestProvince,
          selectedOriginLocationId: selectedOriginLocationId,
          selectedDestLocationId: selectedDestLocationId,
          selectedOrigin: selectedOrigin,
          selectedDestination: selectedDestination,
          onAdvancedFiltersChanged: onAdvancedFiltersChanged,
          onOriginChanged: onOriginChanged,
          onDestinationChanged: onDestinationChanged,
        );
      },
    );
  }
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  DateTime? _tempDate;
  double? _tempMinWeight;
  String? _tempVehicleType;
  String? _tempOriginProvince;
  String? _tempDestProvince;
  String? _tempOriginLocationId;
  String? _tempDestLocationId;

  final List<double> _weightSteps = [
    10,
    50,
    100,
    200,
    500,
    1000,
    2000,
    5000,
    10000,
    25000,
    50000,
    100000,
  ];

  @override
  void initState() {
    super.initState();
    _tempDate = widget.date;
    _tempMinWeight = widget.minWeight;
    _tempVehicleType = widget.selectedVehicleType;
    _tempOriginProvince = widget.selectedOriginProvince;
    _tempDestProvince = widget.selectedDestProvince;
    _tempOriginLocationId = widget.selectedOriginLocationId;
    _tempDestLocationId = widget.selectedDestLocationId;
  }

  List<String> _getUniqueProvinces(List<Location> locations, bool isArabic) {
    final provinces = <String>{};
    for (var loc in locations) {
      if (loc.isHomeCountry) {
        provinces.add(isArabic ? loc.provinceNameAr : loc.provinceNameEn);
      }
    }
    return provinces.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final uniqueProvinces = _getUniqueProvinces(widget.locations, isArabic);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.moreFilters,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Vehicle Type Filter
          Text(
            localizations.vehicleType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: TripShipDesignTokens.borderRadiusSmall,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _tempVehicleType,
                hint: Text(
                  localizations.allVehicles,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      localizations.allVehicles,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'truck',
                    child: Text(localizations.truck),
                  ),
                  DropdownMenuItem(
                    value: 'car',
                    child: Text(localizations.car),
                  ),
                  DropdownMenuItem(
                    value: 'van',
                    child: Text(localizations.van),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _tempVehicleType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Date Filter
          Text(
            localizations.filters,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() => _tempDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    _tempDate != null
                        ? DateFormat.yMMMd().format(_tempDate!)
                        : localizations.date,
                  ),
                  if (_tempDate != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _tempDate = null),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            localizations.availableWeight,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<double>(
                value: _tempMinWeight,
                hint: Text(
                  localizations.weight,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: [
                  DropdownMenuItem<double>(
                    value: null,
                    child: Text(
                      localizations.all,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  ..._weightSteps.map(
                    (w) => DropdownMenuItem<double>(
                      value: w.toDouble(),
                      child: Text('$w ${localizations.kg}'),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() => _tempMinWeight = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Origin Filter (Hierarchical)
          Text(
            localizations.origin,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isInternal) ...[
            // Province
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _tempOriginProvince,
                  hint: Text(
                    localizations.selectProvince,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        localizations.all,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    ...uniqueProvinces.map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tempOriginProvince = val;
                      _tempOriginLocationId = null; // Reset City
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // City (Dependent on Province)
            Opacity(
              opacity: _tempOriginProvince == null ? 0.5 : 1.0,
              child: AbsorbPointer(
                absorbing: _tempOriginProvince == null,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value:
                          widget.locations
                              .where(
                                (l) =>
                                    l.isHomeCountry,
                              )
                              .where(
                                (l) =>
                                    (isArabic
                                        ? l.provinceNameAr
                                        : l.provinceNameEn) ==
                                    _tempOriginProvince,
                              )
                              .toList()
                              .any((l) => l.id == _tempOriginLocationId)
                          ? _tempOriginLocationId
                          : null,
                      hint: Text(
                        localizations.selectCity,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            localizations.all,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        ...() {
                          final sortedList = widget.locations
                              .where(
                                (l) =>
                                    l.isHomeCountry,
                              )
                              .where(
                                (l) =>
                                    (isArabic
                                        ? l.provinceNameAr
                                        : l.provinceNameEn) ==
                                    _tempOriginProvince,
                              )
                              .toList();
                          sortedList.sort((a, b) {
                            final cA = isArabic ? a.cityNameAr : a.cityNameEn;
                            final cB = isArabic ? b.cityNameAr : b.cityNameEn;
                            return cA.compareTo(cB);
                          });
                          return sortedList.map((l) {
                            final city = isArabic ? l.cityNameAr : l.cityNameEn;
                            final town = isArabic ? l.townNameAr : l.townNameEn;
                            String label = city;
                            if (town != null &&
                                town.isNotEmpty &&
                                town != city) {
                              label += ' ($town)';
                            }
                            return DropdownMenuItem(
                              value: l.id,
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          });
                        }(),
                      ],
                      onChanged: (val) {
                        setState(() => _tempOriginLocationId = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // External (Simple City Name)
            TextFormField(
              initialValue: widget.selectedOrigin,
              decoration: InputDecoration(
                hintText: localizations.enterCity,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) => widget.onOriginChanged(val),
            ),
          ],

          const SizedBox(height: 16),

          // Destination Filter (Hierarchical)
          Text(
            localizations.destination,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.isInternal) ...[
            // Province
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _tempDestProvince,
                  hint: Text(
                    localizations.selectProvince,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        localizations.all,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                    ...uniqueProvinces.map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tempDestProvince = val;
                      _tempDestLocationId = null; // Reset City
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // City (Dependent on Province)
            Opacity(
              opacity: _tempDestProvince == null ? 0.5 : 1.0,
              child: AbsorbPointer(
                absorbing: _tempDestProvince == null,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value:
                          widget.locations
                              .where(
                                (l) =>
                                    l.isHomeCountry,
                              )
                              .where(
                                (l) =>
                                    (isArabic
                                        ? l.provinceNameAr
                                        : l.provinceNameEn) ==
                                    _tempDestProvince,
                              )
                              .toList()
                              .any((l) => l.id == _tempDestLocationId)
                          ? _tempDestLocationId
                          : null,
                      hint: Text(
                        localizations.selectCity,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            localizations.all,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                        ...() {
                          final sortedList = widget.locations
                              .where(
                                (l) =>
                                    l.isHomeCountry,
                              )
                              .where(
                                (l) =>
                                    (isArabic
                                        ? l.provinceNameAr
                                        : l.provinceNameEn) ==
                                    _tempDestProvince,
                              )
                              .toList();
                          sortedList.sort((a, b) {
                            final cA = isArabic ? a.cityNameAr : a.cityNameEn;
                            final cB = isArabic ? b.cityNameAr : b.cityNameEn;
                            return cA.compareTo(cB);
                          });
                          return sortedList.map((l) {
                            final city = isArabic ? l.cityNameAr : l.cityNameEn;
                            final town = isArabic ? l.townNameAr : l.townNameEn;
                            String label = city;
                            if (town != null &&
                                town.isNotEmpty &&
                                town != city) {
                              label += ' ($town)';
                            }
                            return DropdownMenuItem(
                              value: l.id,
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          });
                        }(),
                      ],
                      onChanged: (val) {
                        setState(() => _tempDestLocationId = val);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // External (Simple City Name)
            TextFormField(
              initialValue: widget.selectedDestination,
              decoration: InputDecoration(
                hintText: localizations.enterCity,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (val) => widget.onDestinationChanged(val),
            ),
          ],

          const SizedBox(height: 24),

          // Apply Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onAdvancedFiltersChanged(
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                      null,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(localizations.clearFilters),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAdvancedFiltersChanged(
                      _tempMinWeight,
                      _tempDate,
                      _tempVehicleType,
                      _tempOriginProvince,
                      _tempDestProvince,
                      _tempOriginLocationId,
                      _tempDestLocationId,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(localizations.apply),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
