import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tripship/core/config/geography_config.dart';
import 'package:tripship/features/auth/data/auth_service.dart';
import 'package:tripship/features/trips/data/route_alert_model.dart';
import 'package:tripship/features/trips/data/route_alert_service.dart';
import 'package:tripship/features/trips/data/location_service.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/exceptions/tripship_exception.dart';
import 'package:tripship/core/utils/logger.dart';

class MyAlertsScreen extends ConsumerStatefulWidget {
  const MyAlertsScreen({super.key});

  @override
  ConsumerState<MyAlertsScreen> createState() => _MyAlertsScreenState();
}

class _MyAlertsScreenState extends ConsumerState<MyAlertsScreen> {
  List<RouteAlert> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Defer to after first frame so context/locale is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAlerts());
  }

  Future<void> _loadAlerts() async {
    final user = ref.read(authServiceProvider).currentUser;
    StructuredLogger.info(
      'MyAlertsScreen',
      'Loading alerts for user: ${user?.id}',
    );
    if (user == null) {
      setState(() {
        _isLoading = false;
        _alerts = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      StructuredLogger.info(
        'MyAlertsScreen',
        'Fetching alerts for ${user.id}, locale=$locale',
      );
      final alerts = await ref
          .read(routeAlertServiceProvider)
          .getMyAlerts(user.id, locale: locale);
      StructuredLogger.info('MyAlertsScreen', 'Got ${alerts.length} alerts');
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e, stack) {
      StructuredLogger.error(
        'MyAlertsScreen',
        'Failed to load alerts',
        e,
        stack,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = getUserFriendlyMessage(
            e,
            AppLocalizations.of(context)!.unexpectedError,
            context,
          );
        });
      }
    }
  }

  Future<void> _showAddAlertDialog() async {
    final profile = ref.read(currentUserProfileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;
    final limit = 3;

    if (_alerts.length >= limit && !isAdmin) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.maxAlertsReachedTitle),
          content: Text(
            AppLocalizations.of(context)!.alertsLimitReached(limit),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
      return;
    }

    // Pass necessary data to a separate widget or handle here
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddAlertDialog(
        onSuccess: () {
          Navigator.pop(ctx, true);
        },
      ),
    );

    if (result == true) {
      _loadAlerts();
    }
  }

  Future<void> _deleteAlert(RouteAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAlert),
        content: Text(AppLocalizations.of(context)!.confirmDeleteAlert),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(routeAlertServiceProvider).deleteAlert(alert.id);
      if (mounted) {
        setState(() => _alerts.removeWhere((a) => a.id == alert.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.alertDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
                context,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.myAlerts)),
        body: Center(child: Text(localizations.pleaseLogin)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.myAlerts)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAlerts,
                    child: Text(localizations.retry),
                  ),
                ],
              ),
            )
          : _alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.noAlertsYet,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  return _AlertCard(
                    alert: alert,
                    onDelete: () => _deleteAlert(alert),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAlertDialog,
        tooltip: localizations.add,
        child: const Icon(Icons.add_alert),
      ),
    );
  }
}

class _AddAlertDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _AddAlertDialog({required this.onSuccess});

  @override
  ConsumerState<_AddAlertDialog> createState() => _AddAlertDialogState();
}

class _AddAlertDialogState extends ConsumerState<_AddAlertDialog> {
  bool _isInternal = true;
  bool _isSaving = false;

  Map<String, dynamic>? _selectedOriginCountry;
  Map<String, dynamic>? _selectedOriginProvince;
  Map<String, dynamic>? _selectedOriginCity;
  Map<String, dynamic>? _selectedOriginTown;

  Map<String, dynamic>? _selectedDestCountry;
  Map<String, dynamic>? _selectedDestProvince;
  Map<String, dynamic>? _selectedDestCity;
  Map<String, dynamic>? _selectedDestTown;

  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _originProvinces = [];
  List<Map<String, dynamic>> _originCities = [];
  List<Map<String, dynamic>> _originTowns = [];

  List<Map<String, dynamic>> _destProvinces = [];
  List<Map<String, dynamic>> _destCities = [];
  List<Map<String, dynamic>> _destTowns = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_countries.isNotEmpty) {
      if (_isInternal) {
        _setInitialHomeCountry();
      }
      return;
    }

    final locService = ref.read(locationServiceProvider);
    try {
      final countries = await locService.getCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          if (_isInternal) {
            _setInitialHomeCountry();
          }
        });
      }
    } catch (e) {
      StructuredLogger.error(
        'MyAlertsScreen',
        'Error loading countries: $e',
        e,
      );
    }
  }

  void _setInitialHomeCountry() {
    if (_countries.isEmpty) return;

    final home = _countries.firstWhere(
      (c) => GeographyConfig.isHomeCountry(
        code: c['country_code']?.toString(),
        nameEn: c['name_en']?.toString(),
        nameAr: c['name_ar']?.toString(),
      ),
      orElse: () => _countries.first,
    );

    if (home.isNotEmpty) {
      setState(() {
        _selectedOriginCountry = home;
        _selectedDestCountry = home;
      });
      _loadProvinces(true, home['name_ar']);
      _loadProvinces(false, home['name_ar']);
    }
  }

  Future<void> _loadProvinces(bool isOrigin, String countryName) async {
    final locService = ref.read(locationServiceProvider);
    final provs = await locService.getProvinces(countryName);
    if (!mounted) {
      return;
    }
    setState(() {
      if (isOrigin) {
        _originProvinces = provs;
        _selectedOriginProvince = null;
        _selectedOriginCity = null;
        _selectedOriginTown = null;
      } else {
        _destProvinces = provs;
        _selectedDestProvince = null;
        _selectedDestCity = null;
        _selectedDestTown = null;
      }
    });
  }

  Future<void> _loadCities(bool isOrigin, String provinceName) async {
    final locService = ref.read(locationServiceProvider);
    final cities = await locService.getCities(provinceName);
    if (!mounted) {
      return;
    }
    setState(() {
      if (isOrigin) {
        _originCities = cities;
        _selectedOriginCity = null;
        _selectedOriginTown = null;
      } else {
        _destCities = cities;
        _selectedDestCity = null;
        _selectedDestTown = null;
      }
    });
  }

  Future<void> _loadTowns(bool isOrigin, String cityName) async {
    final locService = ref.read(locationServiceProvider);
    final towns = await locService.getTowns(cityName);
    if (!mounted) {
      return;
    }
    setState(() {
      if (isOrigin) {
        _originTowns = towns;
        _selectedOriginTown = null;
      } else {
        _destTowns = towns;
        _selectedDestTown = null;
      }
    });
  }

  Future<void> _save() async {
    final locService = ref.read(locationServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    // Validate
    bool originIncomplete =
        _selectedOriginProvince == null || _selectedOriginCity == null;
    bool destIncomplete =
        _selectedDestProvince == null || _selectedDestCity == null;

    if (!_isInternal) {
      if (_selectedOriginCountry == null) {
        originIncomplete = true;
      }
      if (_selectedDestCountry == null) {
        destIncomplete = true;
      }
    }

    if (originIncomplete || destIncomplete) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectAllFields)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (!_isInternal) {
        final originCode = _selectedOriginCountry?['country_code']?.toString();
        final destCode = _selectedDestCountry?['country_code']?.toString();
        final originNameEn = _selectedOriginCountry?['name_en']?.toString();
        final destNameEn = _selectedDestCountry?['name_en']?.toString();
        final originNameAr = _selectedOriginCountry?['name_ar']?.toString();
        final destNameAr = _selectedDestCountry?['name_ar']?.toString();

        final bool originIsHome = GeographyConfig.isHomeCountry(
          code: originCode,
          nameEn: originNameEn,
          nameAr: originNameAr,
        );
        final bool destIsHome = GeographyConfig.isHomeCountry(
          code: destCode,
          nameEn: destNameEn,
          nameAr: destNameAr,
        );
        final homeCountry = GeographyConfig.homeCountryName(
          Localizations.localeOf(context).languageCode,
        );

        if (originIsHome && destIsHome) {
          throw TripShipException(l10n.errorExternalMustBeOutside(homeCountry));
        }

        if (GeographyConfig.externalRequiresHomeCountryOnOneSide &&
            !originIsHome &&
            !destIsHome) {
          throw TripShipException(
            l10n.errorExternalMustInvolveHomeCountry(homeCountry),
          );
        }
      }

      final originId = await locService.findLocationId(
        countryAr: _selectedOriginCountry!['name_ar'],
        provinceAr: _selectedOriginProvince!['name_ar'],
        cityAr: _selectedOriginCity!['name_ar'],
        townAr: _selectedOriginTown?['name_ar'],
      );

      final destId = await locService.findLocationId(
        countryAr: _selectedDestCountry!['name_ar'],
        provinceAr: _selectedDestProvince!['name_ar'],
        cityAr: _selectedDestCity!['name_ar'],
        townAr: _selectedDestTown?['name_ar'],
      );

      String? oProv;
      if (originId == null) {
        oProv = _selectedOriginProvince?['name_ar']?.toString();
      }
      String? dProv;
      if (destId == null) {
        dProv = _selectedDestProvince?['name_ar']?.toString();
      }
      String? oCity;
      if (originId == null) {
        oCity = _selectedOriginCity?['name_ar']?.toString();
      }
      String? dCity;
      if (destId == null) {
        dCity = _selectedDestCity?['name_ar']?.toString();
      }

      final userId = ref.read(authServiceProvider).currentUser!.id;
      await ref
          .read(routeAlertServiceProvider)
          .createAlert(
            userId: userId,
            originLocationId: originId,
            destLocationId: destId,
            originProvince: oProv,
            destProvince: dProv,
            originCity: oCity,
            destCity: dCity,
            isInternal: _isInternal,
          );

      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.unexpectedError,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final nameKey = locale == 'ar' ? 'name_ar' : 'name_en';

    return AlertDialog(
      title: Text(l10n.add),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Internal/External toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: Text(l10n.internalTrips),
                  selected: _isInternal,
                  onSelected: (val) {
                    if (val && !_isInternal) {
                      setState(() {
                        _isInternal = true;
                        _setInitialHomeCountry();
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: Text(l10n.externalTrips),
                  selected: !_isInternal,
                  onSelected: (val) {
                    if (val && _isInternal) {
                      setState(() {
                        _isInternal = false;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Origin Picker
            _buildLocationSection(
              title: l10n.origin,
              isOrigin: true,
              nameKey: nameKey,
            ),

            const Divider(height: 32),

            // Destination Picker
            _buildLocationSection(
              title: l10n.destination,
              isOrigin: false,
              nameKey: nameKey,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.add),
        ),
      ],
    );
  }

  Widget _buildLocationSection({
    required String title,
    required bool isOrigin,
    required String nameKey,
  }) {
    final l10n = AppLocalizations.of(context)!;

    final selectedCountry = isOrigin
        ? _selectedOriginCountry
        : _selectedDestCountry;
    final provinces = isOrigin ? _originProvinces : _destProvinces;
    final selectedProvince = isOrigin
        ? _selectedOriginProvince
        : _selectedDestProvince;
    final cities = isOrigin ? _originCities : _destCities;
    final selectedCity = isOrigin ? _selectedOriginCity : _selectedDestCity;
    final towns = isOrigin ? _originTowns : _destTowns;
    final selectedTown = isOrigin ? _selectedOriginTown : _selectedDestTown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Country (if external)
        if (!_isInternal) ...[
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: selectedCountry,
            decoration: InputDecoration(labelText: l10n.country),
            isExpanded: true,
            items: _countries
                .map(
                  (c) =>
                      DropdownMenuItem(value: c, child: Text(c[nameKey] ?? '')),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  if (isOrigin) {
                    _selectedOriginCountry = val;
                  } else {
                    _selectedDestCountry = val;
                  }
                });
                _loadProvinces(isOrigin, val['name_ar']);
              }
            },
          ),
          const SizedBox(height: 8),
        ],

        // Province
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: selectedProvince,
          decoration: InputDecoration(labelText: l10n.province),
          isExpanded: true,
          items: provinces
              .map(
                (p) =>
                    DropdownMenuItem(value: p, child: Text(p[nameKey] ?? '')),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isOrigin) {
                  _selectedOriginProvince = val;
                } else {
                  _selectedDestProvince = val;
                }
              });
              _loadCities(isOrigin, val['name_ar']);
            }
          },
        ),
        const SizedBox(height: 8),

        // City
        DropdownButtonFormField<Map<String, dynamic>>(
          initialValue: selectedCity,
          decoration: InputDecoration(labelText: l10n.city),
          isExpanded: true,
          items: cities
              .map(
                (c) =>
                    DropdownMenuItem(value: c, child: Text(c[nameKey] ?? '')),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isOrigin) {
                  _selectedOriginCity = val;
                } else {
                  _selectedDestCity = val;
                }
              });
              _loadTowns(isOrigin, val['name_ar']);
            }
          },
        ),

        // Town (Optional)
        if (_isInternal && towns.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: selectedTown,
            decoration: InputDecoration(labelText: l10n.town),
            isExpanded: true,
            items: towns
                .map(
                  (t) =>
                      DropdownMenuItem(value: t, child: Text(t[nameKey] ?? '')),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                if (isOrigin) {
                  _selectedOriginTown = val;
                } else {
                  _selectedDestTown = val;
                }
              });
            },
          ),
        ],
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final RouteAlert alert;
  final VoidCallback onDelete;

  const _AlertCard({required this.alert, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final origin = alert.effectiveOrigin;
    final dest = alert.effectiveDest;
    final typeLabel = alert.isInternal
        ? (AppLocalizations.of(context)!.internalTrips)
        : (AppLocalizations.of(context)!.externalTrips);
    final dateStr = DateFormat.yMMMd(locale).format(alert.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.notifications_active,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          '$origin → $dest',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              typeLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
          tooltip: AppLocalizations.of(context)!.delete,
        ),
      ),
    );
  }
}
