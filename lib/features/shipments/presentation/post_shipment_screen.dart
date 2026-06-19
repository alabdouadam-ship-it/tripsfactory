import 'package:dropdown_button2/dropdown_button2.dart'; // Ensure this is imported or use standard Dropdown
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/shipments/data/shipment_service.dart';
import 'package:tripship/features/bookings/data/repositories/booking_repository_impl.dart';
import 'package:tripship/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/models/location_model.dart';
import 'package:tripship/core/config/geography_config.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/features/shipments/presentation/widgets/prohibited_items_dialog.dart';
import 'package:tripship/core/widgets/tripship_section_card.dart';
import 'package:tripship/core/theme/tripship_design_tokens.dart';

import 'package:tripship/features/shipments/data/shipment_model.dart';

class PostShipmentScreen extends ConsumerStatefulWidget {
  final String? transportMode; // 'internal' or 'external'
  final String? tripId;
  final String? driverId;

  /// When non-null the screen enters edit mode — form is pre-populated and
  /// submitted via [ShipmentService.updateShipment] instead of [createShipment].
  final Shipment? initialShipment;

  const PostShipmentScreen({
    super.key,
    this.transportMode,
    this.tripId,
    this.driverId,
    this.initialShipment,
  });

  @override
  ConsumerState<PostShipmentScreen> createState() => _PostShipmentScreenState();
}

class _PostShipmentScreenState extends ConsumerState<PostShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _pickupController = TextEditingController(); // Removed
  // final _dropoffController = TextEditingController(); // Removed
  final _weightController = TextEditingController();
  final _descController = TextEditingController();

  bool _isSaving = false;

  // Locations State
  List<Location> _locations = [];
  bool _isLoadingLocations = true;
  String? _selectedPickupId;
  String? _selectedDropoffId;
  String? _pickupCityName;
  String? _dropoffCityName;

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _weightController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLocations();
    // Pre-populate form when editing an existing shipment
    final s = widget.initialShipment;
    if (s != null) {
      _weightController.text = s.weightKg > 0 ? s.weightKg.toString() : '';
      _descController.text = s.description ?? '';
      _selectedPickupId = s.pickupLocationId;
      _selectedDropoffId = s.dropoffLocationId;
      // City names are resolved after _loadLocations via _syncCityNamesFromLocations()
    }
  }

  Future<void> _loadLocations() async {
    try {
      final result = await ref.read(tripRepositoryProvider).getLocations();
      final locs = result.fold((value) => value, (error) => throw error);
      if (mounted) {
        setState(() {
          _locations = locs;
          _isLoadingLocations = false;
          _syncCityNamesFromLocations();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  /// Resolves display names for pre-selected location IDs (edit mode).
  void _syncCityNamesFromLocations() {
    final isArabic =
        false; // resolved from context in build — use English as fallback
    if (_selectedPickupId != null) {
      _pickupCityName = _getCityName(_selectedPickupId!, isArabic);
    }
    if (_selectedDropoffId != null) {
      _dropoffCityName = _getCityName(_selectedDropoffId!, isArabic);
    }
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context)!;

    // Validate custom fields
    if (_selectedPickupId == null || _selectedDropoffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseSelectPickupDropoff,
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Route Validation based on mode
    final pickupLoc = _locations.cast<Location?>().firstWhere(
      (l) => l?.id == _selectedPickupId,
      orElse: () => null,
    );
    final dropoffLoc = _locations.cast<Location?>().firstWhere(
      (l) => l?.id == _selectedDropoffId,
      orElse: () => null,
    );

    if (pickupLoc == null || dropoffLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseSelectPickupDropoff)),
      );
      return;
    }

    final isPickupHome = pickupLoc.isHomeCountry;
    final isDropoffHome = dropoffLoc.isHomeCountry;
    final localeCode = Localizations.localeOf(context).languageCode;
    final homeCountry = GeographyConfig.homeCountryName(localeCode);

    if (widget.transportMode == 'internal') {
      if (!isPickupHome || !isDropoffHome) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.errorInternalOnlyHomeCountry(homeCountry))),
        );
        return;
      }
    } else if (widget.transportMode == 'external') {
      if (isPickupHome && isDropoffHome) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.errorExternalMustBeOutside(homeCountry)),
          ),
        );
        return;
      } else if (GeographyConfig.externalRequiresHomeCountryOnOneSide &&
          !isPickupHome &&
          !isDropoffHome) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.errorExternalMustInvolveHomeCountry(homeCountry),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final weightStr = _weightController.text.trim();
      final weight = weightStr.isEmpty ? null : double.tryParse(weightStr);
      final description = _descController.text.trim();

      if (widget.initialShipment != null) {
        // ── Edit mode ────────────────────────────────────────────────
        await ref
            .read(shipmentServiceProvider)
            .updateShipment(
              shipmentId: widget.initialShipment!.id,
              pickupLocationId: _selectedPickupId!,
              dropoffLocationId: _selectedDropoffId!,
              weightKg: weight,
              description: description.isEmpty ? null : description,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.shipmentUpdated),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        // ── Create mode ───────────────────────────────────────────────
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          try {
            await ref
                .read(shipmentServiceProvider)
                .createShipment(
                  senderId: user.id,
                  pickupCity: _pickupCityName ?? '',
                  dropoffCity: _dropoffCityName ?? '',
                  pickupLocationId: _selectedPickupId,
                  dropoffLocationId: _selectedDropoffId,
                  weightKg: weight,
                  description: description,
                  transportType: widget.transportMode,
                  pickupLatitude: null,
                  pickupLongitude: null,
                  dropoffLatitude: null,
                  dropoffLongitude: null,
                );

            // Auto-book on the trip if trip info is provided
            if (widget.tripId != null && widget.driverId != null) {
              final userId = ref.read(authServiceProvider).currentUser!.id;
              final bookingResult = await ref
                  .read(bookingRepositoryProvider)
                  .createDirectBooking(
                    userId: userId,
                    driverId: widget.driverId!,
                    tripId: widget.tripId!,
                  );
              bookingResult.fold((_) {}, (error) => throw error);
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.tripId != null
                        ? localizations.requestSent
                        : localizations.shipmentPosted,
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    getUserFriendlyMessage(
                      e,
                      AppLocalizations.of(context)!.errorCreatingShipment,
                      context,
                    ),
                  ),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.errorCreatingShipment,
                context,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Reuse similar logic to HomeScreen for Dropdown Item building
  List<DropdownMenuItem<String>> _buildLocationItems(bool isArabic) {
    final mode = widget.transportMode;

    final filteredLocations = _locations.where((loc) {
      // Validation logic for internal/external routes
      if (mode == 'internal') {
        return loc.isHomeCountry;
      } else if (mode == 'external') {
        // For external, we show all locations; the route rule is enforced on
        // submit (home country on one side, per GeographyConfig).
        return true;
      }
      return true;
    }).toList();

    final isExternal = mode == 'external';

    if (!isExternal) {
      // Internal mode (home country only): keep all granular details
      return filteredLocations.map((loc) {
        final label = loc.formatLabel(isArabic, isExternal: false);
        return DropdownMenuItem<String>(
          value: loc.id,
          child: Text(label, overflow: TextOverflow.ellipsis),
        );
      }).toList()..sort(
        (a, b) => ((a.child as Text).data ?? '').compareTo(
          (b.child as Text).data ?? '',
        ),
      );
    }

    // External mode: Deduplicate by "Country, Province" label
    final Map<String, Location> deduped = {};

    for (var loc in filteredLocations) {
      final label = loc.formatLabel(isArabic, isExternal: true);

      // Priority selection: Prefer record where Province == City
      final provAr = loc.provinceNameAr;
      final cityAr = loc.cityNameAr;
      final provEn = loc.provinceNameEn.toLowerCase();
      final cityEn = loc.cityNameEn.toLowerCase();

      final isMatch =
          (provAr.isNotEmpty && provAr == cityAr) ||
          (provEn.isNotEmpty && provEn == cityEn);

      if (!deduped.containsKey(label) || isMatch) {
        deduped[label] = loc;
      }
    }

    final items = deduped.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.value.id,
        child: Text(entry.key, overflow: TextOverflow.ellipsis),
      );
    }).toList();

    items.sort((a, b) {
      final tA = (a.child as Text).data ?? '';
      final tB = (b.child as Text).data ?? '';
      return tA.compareTo(tB);
    });
    return items;
  }

  // Helper to get name from ID
  String _getCityName(String id, bool isArabic) {
    if (_locations.isEmpty) return '';

    final matches = _locations.where((l) => l.id == id);
    if (matches.isEmpty) return '';

    final loc = matches.first;
    return loc.formatLabel(
      isArabic,
      isExternal: widget.transportMode == 'external',
    );
  }

  Widget _buildSearchableDropdown({
    required String labelText,
    required IconData prefixIcon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      validator: validator,
      initialValue: value,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                hint: Row(
                  children: [
                    Icon(prefixIcon, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(labelText, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                items: items,
                value: value,
                onChanged: (val) {
                  onChanged(val);
                  formFieldState.didChange(val);
                },
                buttonStyleData: ButtonStyleData(
                  height: 56,
                  padding: const EdgeInsets.only(left: 14, right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: formFieldState.hasError ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                  height: 48,
                  padding: EdgeInsets.only(left: 14, right: 14),
                ),
                dropdownSearchData: DropdownSearchData(
                  searchController: _searchController,
                  searchInnerWidgetHeight: 50,
                  searchInnerWidget: Container(
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        hintText: AppLocalizations.of(context)!.search,
                        border: OutlineInputBorder(
                          borderRadius: TripShipDesignTokens.borderRadiusSmall,
                        ),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    final child = item.child;
                    if (child is Text) {
                      return child.data!.toLowerCase().contains(
                        searchValue.toLowerCase(),
                      );
                    }
                    return false;
                  },
                ),
                onMenuStateChange: (isOpen) {
                  if (!isOpen) {
                    _searchController.clear();
                  }
                },
              ),
            ),
            if (formFieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  formFieldState.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialShipment != null
              ? localizations.editShipment
              : localizations.postShipment,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Route Section
                TripShipSectionCard(
                  title: '${localizations.pickup} & ${localizations.dropoff}',
                  icon: Icons.route_outlined,
                  child: _isLoadingLocations
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            // Pickup Dropdown
                            _buildSearchableDropdown(
                              labelText: localizations.pickup,
                              prefixIcon: Icons.location_on_outlined,
                              value: _selectedPickupId,
                              items: _buildLocationItems(isArabic),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPickupId = val;
                                  if (val != null) {
                                    _pickupCityName = _getCityName(
                                      val,
                                      isArabic,
                                    );
                                  }
                                });
                              },
                              validator: (val) => val == null
                                  ? localizations.fieldRequired
                                  : null,
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Icon(
                                Icons.arrow_downward,
                                color: Colors.grey,
                              ),
                            ),

                            // Dropoff Dropdown
                            _buildSearchableDropdown(
                              labelText: localizations.dropoff,
                              prefixIcon: Icons.flag_outlined,
                              value: _selectedDropoffId,
                              items: _buildLocationItems(isArabic),
                              onChanged: (val) {
                                setState(() {
                                  _selectedDropoffId = val;
                                  if (val != null) {
                                    _dropoffCityName = _getCityName(
                                      val,
                                      isArabic,
                                    );
                                  }
                                });
                              },
                              validator: (val) => val == null
                                  ? localizations.fieldRequired
                                  : null,
                            ),
                          ],
                        ),
                ).animate().slideY(begin: 0.1, duration: 300.ms),

                const SizedBox(height: 16),

                // Details
                TripShipSectionCard(
                  title: localizations.packageDetails,
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final w = double.tryParse(value);
                          if (w == null || w <= 0) {
                            return localizations.invalidWeight;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: localizations.description,
                          prefixIcon: const Icon(Icons.description),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        // Optional description
                        validator: (value) =>
                            value!.isEmpty ? localizations.fieldRequired : null,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const ProhibitedItemsDialog(),
                          ),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          label: Text(
                            localizations.viewProhibitedItems,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          localizations.createRequest,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
