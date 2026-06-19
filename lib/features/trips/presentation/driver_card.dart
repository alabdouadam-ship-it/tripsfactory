import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class TravelerCard extends StatelessWidget {
  final Map<String, dynamic> traveler;
  final VoidCallback? onTap;

  const TravelerCard({super.key, required this.traveler, this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fullName = traveler['full_name'] ?? 'Unknown Traveler';
    final avatarUrl = traveler['avatar_url'] as String?;

    // Handling vehicles
    final vehicles = traveler['vehicles'] as List?;
    final vehicle = (vehicles != null && vehicles.isNotEmpty)
        ? vehicles.first
        : null;
    final vehicleTypeRaw = vehicle != null
        ? vehicle['vehicle_type']
        : 'Private Transport';
    final vehicleType = _getVehicleLabel(loc, vehicleTypeRaw);
    final licensePlate = vehicle != null ? vehicle['license_plate'] : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Traveler Avatar / Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    image: avatarUrl != null && avatarUrl.trim().isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null || avatarUrl.trim().isEmpty
                      ? const Icon(
                          Icons.person_pin,
                          color: Colors.orangeAccent,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Traveler Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicleType,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (licensePlate.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          licensePlate,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Availability / Action Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.message_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  String _getVehicleLabel(AppLocalizations loc, String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return loc.car;
      case 'sedan':
        return loc.sedan;
      case 'van':
        return loc.van;
      case 'truck':
        return loc.truck;
      case 'bus':
        return loc.bus;
      case 'tractortrailer':
      case 'tractor_trailer':
        return loc.tractorTrailer;
      case 'largecar':
      case 'large_car':
        return loc.largeCar;
      case 'mediumcar':
      case 'medium_car':
        return loc.mediumCar;
      case 'smallcar':
      case 'small_car':
        return loc.smallCar;
      case 'refrigerated':
        return loc.refrigerated;
      default:
        return vehicleType;
    }
  }
}
