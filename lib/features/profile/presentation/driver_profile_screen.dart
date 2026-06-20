import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tripsfactory/features/profile/data/profile_service.dart';
import 'package:tripsfactory/core/config/domain_config.dart';
import 'package:tripsfactory/core/utils/logger.dart';
import 'package:tripsfactory/l10n/generated/app_localizations.dart';
import 'package:tripsfactory/features/ratings/data/rating_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tripsfactory/core/widgets/trust_badge.dart';
import 'package:tripsfactory/core/widgets/tripsfactory_expandable_text.dart'
    as import_tripsfactory_expandable;

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String role; // 'driver' or 'client'

  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.role = 'driver',
  });

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _driverData;
  double _rating = 0.0;
  int _ratingCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  String get _normalizedRole => widget.role == 'client' ? 'client' : 'driver';

  bool get _isDriverRole => _normalizedRole == 'driver';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      debugPrint(
        'DriverProfileScreen _loadProfile for userId: ${widget.userId}, role: ${widget.role}, normalizedRole: $_normalizedRole, userName: ${widget.userName}',
      );

      // 1. Load Base Profile Data (Name, Avatar, Ratings, and Vehicles)
      final profileResponse = await ref
          .read(profileServiceProvider)
          .getPublicProfile(widget.userId);

      if (profileResponse == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 2. If Driver, use existing profile data (travelers table was merged into profiles)
      Map<String, dynamic>? driverInfo;
      if (_isDriverRole) {
        driverInfo = profileResponse;
      }

      // 3. Load Recent Reviews
      final reviews = await ref
          .read(ratingServiceProvider)
          .getReviews(widget.userId, _normalizedRole);

      if (mounted) {
        setState(() {
          _profileData = profileResponse;
          _driverData = driverInfo;
          _reviews = reviews;

          // Compute average from actual reviews (profile fields may be stale)
          if (reviews.isNotEmpty) {
            final sum = reviews.fold<double>(
              0.0,
              (acc, r) => acc + ((r['rating'] ?? 0) as num).toDouble(),
            );
            _rating = sum / reviews.length;
            _ratingCount = reviews.length;
          } else if (_isDriverRole) {
            _rating =
                ((profileResponse['traveler_rating_avg'] ??
                            profileResponse['driver_rating_avg'] ??
                            profileResponse['driver_rating']) ??
                        0.0)
                    .toDouble();
            _ratingCount =
                profileResponse['traveler_rating_count'] ??
                profileResponse['driver_rating_count'] ??
                0;
          } else {
            _rating = (profileResponse['client_rating'] ?? 0.0).toDouble();
            _ratingCount = profileResponse['client_rating_count'] ?? 0;
          }

          _isLoading = false;
        });
      }
    } catch (e, st) {
      StructuredLogger.error(
        'DriverProfileScreen',
        'Load profile failed',
        e,
        st,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLoadingProfile}: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDriver = _isDriverRole;

    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    localizations.unknownTraveler,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RepaintBoundary(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                (_profileData!['avatar_url'] != null &&
                                    _profileData!['avatar_url']
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                ? CachedNetworkImageProvider(
                                    _profileData!['avatar_url'],
                                  )
                                : null,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            child:
                                (_profileData!['avatar_url'] == null ||
                                    _profileData!['avatar_url']
                                        .toString()
                                        .trim()
                                        .isEmpty)
                                ? Text(
                                    widget.userName.isNotEmpty
                                        ? widget.userName
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.userName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Verification Badge (Only for Drivers or Verified Users)
                          if (isDriver && _driverData != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _driverData!['traveler_status'] ==
                                        DomainConfig.statusApproved
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _driverData!['traveler_status'] ==
                                          DomainConfig.statusApproved
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _driverData!['traveler_status'] ==
                                            DomainConfig.statusApproved
                                        ? Icons.verified
                                        : Icons.pending,
                                    size: 16,
                                    color:
                                        _driverData!['traveler_status'] ==
                                            DomainConfig.statusApproved
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _driverData!['traveler_status'] ==
                                            DomainConfig.statusApproved
                                        ? localizations.verifiedTraveler
                                        : localizations.pendingVerification,
                                    style: TextStyle(
                                      color:
                                          _driverData!['traveler_status'] ==
                                              DomainConfig.statusApproved
                                          ? Colors.green[800]
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isDriver)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _buildAccountTypeChip(localizations),
                            ),
                          Builder(
                            builder: (context) {
                              final badge = TrustBadge.fromProfileBadge(
                                trustBadge: _profileData!['trust_badge']
                                    as String?,
                                isTrusted:
                                    _profileData!['is_trusted'] == true,
                                isFeatured:
                                    _profileData!['is_featured'] == true,
                                showLabel: true,
                                iconSize: 14,
                              );
                              if (badge == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: badge,
                              );
                            },
                          ),

                          // Display User Description (Nabdha / Bio)
                          Builder(
                            builder: (context) {
                              final desc =
                                  _profileData!['nabdha'] ??
                                  _profileData!['bio'];
                              if (desc != null &&
                                  desc.toString().trim().isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child:
                                      import_tripsfactory_expandable.TripsFactoryExpandableText(
                                        text: desc.toString().trim(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey[800]),
                                        trimLines: 2,
                                      ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Rating Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).shadowColor.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 40),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_ratingCount ${localizations.reviews}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // View All Button
                          TextButton(
                            onPressed: () {
                              context.push(
                                '/ratings-detail',
                                extra: {
                                  'userId': widget.userId,
                                  'isClient': !isDriver,
                                },
                              );
                            },
                            child: Text(localizations.viewAll),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Vehicle Information (Drivers Only)
                    if (isDriver &&
                        _driverData != null &&
                        _driverData?['vehicles'] != null &&
                        (_driverData!['vehicles'] as List).isNotEmpty) ...[
                      Text(
                        localizations.vehicleInfo,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.local_shipping,
                                localizations.vehicleType,
                                _driverData!['vehicles'][0]['type'] ?? 'N/A',
                              ),
                              if (_driverData!['vehicles'][0]['plate_number'] !=
                                  null)
                                _buildInfoRow(
                                  Icons.confirmation_number,
                                  localizations.plateNumber,
                                  _driverData!['vehicles'][0]['plate_number'],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Recent Reviews
                    Text(
                      localizations.reviews,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_reviews.isEmpty)
                      Center(
                        child: Text(
                          localizations.noRatingsYet,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._reviews.map((review) => _buildReviewCard(review)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final raterName = review['rater']?['full_name'] ?? 'Unknown';
    final rating = (review['rating'] as num).toDouble();
    final comment = review['comment'] as String?;
    final date = DateTime.parse(review['created_at']); // Date formatting needed

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  raterName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment),
            ],
            const SizedBox(height: 4),
            Text(
              date.toString().split(' ')[0], // Simple date format
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeChip(AppLocalizations localizations) {
    final isDriver = _profileData?['is_driver'] == true;
    final color = isDriver ? Colors.blue : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDriver ? Icons.directions_car : Icons.person,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isDriver
                ? localizations.driverLabel
                : localizations.travelerAsPerson,
            style: TextStyle(
              color: isDriver ? Colors.blue[800] : Colors.teal[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
