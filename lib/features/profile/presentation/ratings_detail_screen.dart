import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/features/profile/data/profile_service.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/utils/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RatingsDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isClient; // true = client ratings, false = driver ratings

  const RatingsDetailScreen({
    super.key,
    required this.userId,
    required this.isClient,
  });

  @override
  ConsumerState<RatingsDetailScreen> createState() =>
      _RatingsDetailScreenState();
}

class _RatingsDetailScreenState extends ConsumerState<RatingsDetailScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final reviewType = widget.isClient ? 'client' : 'driver';
      final response = await ref
          .read(profileServiceProvider)
          .getRatings(widget.userId, reviewType);

      if (mounted) {
        final reviews = response;

        // Calculate average
        if (reviews.isNotEmpty) {
          final sum = reviews.fold<double>(
            0,
            (sum, r) => sum + (r['rating'] ?? 0),
          );
          _averageRating = sum / reviews.length;
        }

        setState(() {
          _reviews = reviews;
          _totalCount = reviews.length;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      StructuredLogger.error(
        'RatingsDetailScreen',
        'Error loading reviews',
        e,
        st,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              getUserFriendlyMessage(
                e,
                AppLocalizations.of(context)!.errorLoadingReviews,
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
    final title = widget.isClient
        ? localizations.clientRating
        : localizations.driverRating;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 40),
                          const SizedBox(width: 8),
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_totalCount ${localizations.reviews}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Reviews List
                Expanded(
                  child: _reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.noReviews,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reviews.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return _buildReviewCard(review, localizations);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildReviewCard(
    Map<String, dynamic> review,
    AppLocalizations localizations,
  ) {
    final raterName = review['rater']?['full_name'] ?? 'Unknown';
    final rating = review['rating'] ?? 0;
    final comment = review['comment'] ?? '';
    final reviewDate = review['created_at'] != null
        ? DateTime.parse(review['created_at'])
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      review['rater']?['avatar_url'] != null &&
                          review['rater']['avatar_url']
                              .toString()
                              .trim()
                              .isNotEmpty
                      ? CachedNetworkImageProvider(
                          review['rater']['avatar_url'],
                        )
                      : null,
                  child:
                      review['rater']?['avatar_url'] == null ||
                          review['rater']['avatar_url']
                              .toString()
                              .trim()
                              .isEmpty
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        raterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (reviewDate != null)
                        Text(
                          _formatDate(reviewDate, localizations),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Rating Stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations localizations) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return localizations.today;
    } else if (difference.inDays == 1) {
      return localizations.yesterday;
    } else if (difference.inDays < 7) {
      return localizations.daysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      return localizations.weeksAgo(difference.inDays ~/ 7);
    } else if (difference.inDays < 365) {
      return localizations.monthsAgo(difference.inDays ~/ 30);
    } else {
      return localizations.yearsAgo(difference.inDays ~/ 365);
    }
  }
}
