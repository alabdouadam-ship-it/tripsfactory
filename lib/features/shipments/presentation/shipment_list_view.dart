import 'package:tripship/core/config/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:tripship/features/shipments/presentation/providers/shipment_list_provider.dart';
import 'package:tripship/features/home/presentation/providers/home_filter_provider.dart';
import 'package:tripship/features/shipments/presentation/shipment_card.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';
import 'package:tripship/core/utils/error_utils.dart';
import 'package:tripship/core/widgets/empty_state_widget.dart';
import 'package:tripship/core/widgets/skeleton_loader.dart';
import 'package:tripship/core/enums/app_enums.dart';

class ShipmentListView extends ConsumerStatefulWidget {
  final TransportType transportType;
  final bool excludeInteracted;
  final NotifierProvider<HomeFilterNotifier, HomeFilterState> filterProvider;

  const ShipmentListView({
    super.key,
    required this.transportType,
    required this.filterProvider,
    this.excludeInteracted = false,
  });

  @override
  ConsumerState<ShipmentListView> createState() => _ShipmentListViewState();
}

class _ShipmentListViewState extends ConsumerState<ShipmentListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filter = _getFilter();
      ref.read(shipmentListProvider(filter).notifier).loadMore();
    }
  }

  ShipmentListFilter _getFilter() {
    return ShipmentListFilter(
      transportType: widget.transportType,
      excludeInteracted: widget.excludeInteracted,
      filterState: ref.read(widget.filterProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final filterState = ref.watch(widget.filterProvider);
    final filter = ShipmentListFilter(
      transportType: widget.transportType,
      excludeInteracted: widget.excludeInteracted,
      filterState: filterState,
    );

    final shipmentState = ref.watch(shipmentListProvider(filter));

    return shipmentState.when(
      data: (state) {
        if (state.shipments.isEmpty) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(shipmentListProvider(filter).notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: EmptyStateWidget(
                  title: localizations.noShipmentsFound,
                  message: localizations.checkBackLater,
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.orangeAccent,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(shipmentListProvider(filter).notifier).refresh(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.showCachedBanner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.amber.shade100,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 20,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.showingCachedData,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          state.shipments.length + (state.hasMore ? 1 : 0),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemBuilder: (context, index) {
                        if (index == state.shipments.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return ShipmentCard(
                          shipment: state.shipments[index],
                          delay: (index * 50).ms, // Staggered delay
                          onTap: () {
                            final shipment = state.shipments[index];
                            context
                                .push(
                                  AppRoutes.shipmentDetails,
                                  extra: shipment,
                                )
                                .then((_) {
                                  ref
                                      .read(
                                        shipmentListProvider(filter).notifier,
                                      )
                                      .refreshInteractionForShipment(shipment);
                                });
                          },
                        );
                      },
                    ),
                    if (state.hasNewRealtimeUpdates)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child:
                              ElevatedButton.icon(
                                    onPressed: () {
                                      _scrollController.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                      ref
                                          .read(
                                            shipmentListProvider(
                                              filter,
                                            ).notifier,
                                          )
                                          .refresh();
                                    },
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: Text(
                                      isArabic
                                          ? 'شحنات جديدة متاحة'
                                          : 'New Shipments Available',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      foregroundColor:
                                          theme.colorScheme.onPrimaryContainer,
                                      elevation: 4,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideY(begin: -0.2, end: 0),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) => const ShipmentCardSkeleton(),
      ),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                "${localizations.error}: ${getUserFriendlyMessage(e, localizations.unexpectedError, context)}",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(shipmentListProvider(filter).notifier).refresh();
                },
                child: Text(localizations.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
