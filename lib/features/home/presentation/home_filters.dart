import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/core/models/location_model.dart';
import 'package:tripsfactory/features/home/presentation/widgets/advanced_filters_dialog.dart';

class HomeFilters extends StatefulWidget {
  final bool isInternal;
  final String? selectedVehicleType;
  final String? selectedOrigin;
  final String? selectedDestination;
  final String? selectedOriginLocationId;
  final String? selectedDestLocationId;
  final double? minWeight;
  final DateTime? date;
  final String? selectedOriginProvince;
  final String? selectedDestProvince;
  // selectedCity removed, using LocationIds

  final List<Location> locations;

  final Function(String?) onVehicleTypeChanged;
  final Function(String?) onOriginChanged; // City name (External)
  final Function(String?) onDestinationChanged; // City name (External)
  final Function(String?) onOriginLocationIdChanged;
  final Function(String?) onDestLocationIdChanged;
  final Function(
    double?,
    DateTime?,
    String?,
    String?,
    String?,
    String?,
    String?,
  )
  onAdvancedFiltersChanged; // w, d, v, oP, dP, oL, dL

  const HomeFilters({
    super.key,
    required this.isInternal,
    required this.locations,
    this.selectedVehicleType,
    this.selectedOrigin,
    this.selectedDestination,
    this.selectedOriginLocationId,
    this.selectedDestLocationId,
    this.minWeight,
    this.date,
    this.selectedOriginProvince,
    this.selectedDestProvince,
    required this.onVehicleTypeChanged,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onOriginLocationIdChanged,
    required this.onDestLocationIdChanged,
    required this.onAdvancedFiltersChanged,
  });

  @override
  State<HomeFilters> createState() => HomeFiltersState();
}

class HomeFiltersState extends State<HomeFilters> {
  late final TextEditingController _originDropdownSearchController;
  late final TextEditingController _destDropdownSearchController;

  @override
  void initState() {
    super.initState();
    _originDropdownSearchController = TextEditingController();
    _destDropdownSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _originDropdownSearchController.dispose();
    _destDropdownSearchController.dispose();
    super.dispose();
  }

  void showAdvancedFiltersDialog() {
    AdvancedFiltersDialog.show(
      context,
      isInternal: widget.isInternal,
      locations: widget.locations,
      date: widget.date,
      minWeight: widget.minWeight,
      selectedVehicleType: widget.selectedVehicleType,
      selectedOriginProvince: widget.selectedOriginProvince,
      selectedDestProvince: widget.selectedDestProvince,
      selectedOriginLocationId: widget.selectedOriginLocationId,
      selectedDestLocationId: widget.selectedDestLocationId,
      selectedOrigin: widget.selectedOrigin,
      selectedDestination: widget.selectedDestination,
      onAdvancedFiltersChanged: widget.onAdvancedFiltersChanged,
      onOriginChanged: (val) => widget.onOriginChanged(val),
      onDestinationChanged: (val) => widget.onDestinationChanged(val),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Origin Filter (Expanded)
          Expanded(
            child: _buildLocationDropdown(
              hint: localizations.origin,
              // Internal: a province selection lives in originProvince (with
              // originLocationId == null). Bind to the 'prov#<province>' menu
              // value so the dropdown reflects it AND so picking "All origins"
              // (null) is a real change that fires onChanged and clears it.
              value: widget.isInternal
                  ? (widget.selectedOriginLocationId ??
                        (widget.selectedOriginProvince != null
                            ? 'prov#${widget.selectedOriginProvince}'
                            : null))
                  : widget.selectedOrigin,
              locations: widget.locations,
              onChanged: (val) {
                if (widget.isInternal) {
                  widget.onOriginLocationIdChanged(val);
                } else {
                  widget.onOriginChanged(val);
                }
              },
              isInternal: widget.isInternal,
              allLabel: localizations.allOrigins,
              searchController: _originDropdownSearchController,
            ),
          ),
          const SizedBox(width: 4),

          // Destination Filter (Expanded)
          Expanded(
            child: _buildLocationDropdown(
              hint: localizations.destination,
              // Internal: mirror the origin logic so a province selection is
              // reflected and "All destinations" can clear it.
              value: widget.isInternal
                  ? (widget.selectedDestLocationId ??
                        (widget.selectedDestProvince != null
                            ? 'prov#${widget.selectedDestProvince}'
                            : null))
                  : widget.selectedDestination,
              locations: widget.locations,
              onChanged: (val) {
                if (widget.isInternal) {
                  widget.onDestLocationIdChanged(val);
                } else {
                  widget.onDestinationChanged(val);
                }
              },
              isInternal: widget.isInternal,
              allLabel: localizations.allDestinations,
              searchController: _destDropdownSearchController,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String? _getVehicleLabel(String? type, AppLocalizations localizations) {
    switch (type) {
      case 'truck':
        return localizations.truck;
      case 'car':
        return localizations.car;
      case 'van':
        return localizations.van;
      default:
        return null;
    }
  }

  // ignore: unused_element
  Widget _buildDropdownFilter<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? allLabel,
  }) {
    final allItem = DropdownMenuItem<T>(
      value: null,
      child: Text(
        allLabel ?? 'All',
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
    );

    final allItems = [allItem, ...items];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced from 12
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? Colors.orange
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, size: 18),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            maxHeight: 300,
          ),
          menuItemStyleData: const MenuItemStyleData(height: 48),
          style: TextStyle(
            fontSize: 13,
            color: Colors.green[900],
            fontWeight: FontWeight.bold,
          ),
          items: allItems,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Safely get display string from a dropdown item child (Text or Padding->Text).
  String _dropdownItemLabel(Widget? child) {
    if (child == null) return '';
    if (child is Text) return child.data ?? '';
    if (child is Padding) return _dropdownItemLabel((child).child);
    return '';
  }

  Widget _buildLocationDropdown({
    required String hint,
    required String? value,
    required List<Location> locations,
    required ValueChanged<String?> onChanged,
    required TextEditingController searchController,
    bool isInternal = false,
    String? allLabel,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    List<DropdownMenuItem<String>> items;

    if (isInternal) {
      final internalLocs = locations
          .where(
            (l) =>
                l.isHomeCountry,
          )
          .toList();

      // Group by Province
      final Map<String, List<Location>> grouped = {};
      for (var loc in internalLocs) {
        final p = locale == 'ar' ? loc.provinceNameAr : loc.provinceNameEn;
        grouped.putIfAbsent(p, () => []).add(loc);
      }

      // Sort Provinces
      final sortedProvinces = grouped.keys.toList()..sort();

      items = [];
      for (var province in sortedProvinces) {
        final locs = grouped[province]!;
        // Sort cities within province
        locs.sort((a, b) {
          final cA = locale == 'ar' ? a.cityNameAr : a.cityNameEn;
          final cB = locale == 'ar' ? b.cityNameAr : b.cityNameEn;
          return cA.compareTo(cB);
        });

        // Add "All of Province" Item
        // We use a special prefix 'prov#' to identify this selection
        items.add(
          DropdownMenuItem(
            value: 'prov#$province',
            child: Text(
              localizations.allOfProvince(
                province,
              ), // We need to add this localization method/key
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        );

        // Add Cities
        items.addAll(
          locs.map((loc) {
            final city = loc.getLocalizedCity(locale);
            final town = locale == 'ar' ? loc.townNameAr : loc.townNameEn;

            // Format: Province - City - Town (Deduped)
            String fullLabel = '$province - $city';
            if (town != null && town.isNotEmpty && town != city) {
              fullLabel += ' - $town';
            }

            return DropdownMenuItem(
              value: loc.id,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12.0),
                child: Text(
                  fullLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          }),
        );
      }
    } else {
      // External Logic (Unchanged but ensuring items is assigned)
      final uniqueProvinces = <String, Location>{};
      for (var loc in locations) {
        final cEn = loc.countryNameEn;
        final pEn = loc.provinceNameEn;
        final k = locale == 'ar'
            ? '${loc.countryNameAr}-${loc.provinceNameAr}'
            : '$cEn-$pEn';
        if (!uniqueProvinces.containsKey(k)) uniqueProvinces[k] = loc;
      }

      items = uniqueProvinces.entries.map<DropdownMenuItem<String>>((entry) {
        final loc = entry.value;
        final country = loc.getLocalizedCountry(locale);
        final province = loc.getLocalizedProvince(locale);
        final label = locale == 'ar'
            ? '$country، $province'
            : '$country, $province';
        return DropdownMenuItem(
          value: province,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList();

      items.sort(
        (a, b) =>
            _dropdownItemLabel(a.child).compareTo(_dropdownItemLabel(b.child)),
      );
    }

    final allItem = DropdownMenuItem<String>(
      value: null,
      child: Text(
        allLabel ?? 'All',
        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
    );
    final allItems = [allItem, ...items];
    final currentValue = allItems.any((item) => item.value == value)
        ? value
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentValue != null
              ? Colors.orange
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          value: currentValue,
          hint: Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.keyboard_arrow_down, size: 18),
          ),
          dropdownStyleData: DropdownStyleData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            maxHeight: 500, // Increased height
            // Force width to be 75% of screen width to ensure it fits long text
            width:
                MediaQuery.of(context).size.width * (isInternal ? 0.75 : 0.60),
            offset: const Offset(0, -4),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 50, // Increased height for wrapped text
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: searchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                controller: searchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  hintText: localizations.search,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) {
              if (item.value == null) return true;
              // Skip headers if they don't match (or we can just skip them entirely from search results)
              if (item.value.toString().startsWith('prov_header_')) {
                return false;
              }

              final label = _dropdownItemLabel(item.child);
              return label.toLowerCase().contains(searchValue.toLowerCase());
            },
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) searchController.clear();
          },
          selectedItemBuilder: (context) {
            return allItems.map((item) {
              if (item.value == null) return Text(allLabel ?? 'All');
              if (item.value.toString().startsWith('prov_header_')) {
                return const SizedBox.shrink();
              }

              Location? loc;
              if (isInternal) {
                if (item.value.toString().startsWith('prov#')) {
                  // It's the "All of Province" selection
                  final parts = item.value.toString().split('#');
                  final prov = parts.length > 1 ? parts[1] : '';
                  return Text(
                    prov,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[900],
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }

                final matches = locations.where((l) => l.id == item.value);
                if (matches.isNotEmpty) {
                  loc = matches.first;
                } else {
                  debugPrint(
                    'Home filters: location not found for ${item.value}',
                  );
                  loc = null;
                }
              } else {
                return Text(
                  item.value!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                );
              }

              String label = loc != null
                  ? (locale == 'ar' ? loc.cityNameAr : loc.cityNameEn)
                  : (localizations.unknown);
              if (loc != null &&
                  loc.townNameAr != null &&
                  loc.townNameAr != loc.cityNameAr) {
                label = locale == 'ar' ? loc.townNameAr! : loc.townNameEn!;
              }

              return Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green[900],
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }).toList();
          },
          items: allItems,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
