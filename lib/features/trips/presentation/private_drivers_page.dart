import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tripship/features/trips/data/available_drivers_provider.dart';
import 'package:tripship/features/trips/presentation/driver_card.dart';
import 'package:tripship/core/widgets/skeleton_loader.dart';
import 'package:tripship/core/widgets/empty_state_widget.dart';
import 'package:tripship/l10n/generated/app_localizations.dart';

class PrivateTravelersPage extends ConsumerWidget {
  const PrivateTravelersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final travelersAsync = ref.watch(availableTravelersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(availableTravelersProvider.future),
      child: travelersAsync.when(
        data: (travelers) {
          if (travelers.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyStateWidget(
                  title: localizations.noTravelersFound,
                  message: localizations.tryAgainLater,
                  icon: Icons.person_pin,
                  iconColor: Colors.blueGrey,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: travelers.length,
            itemBuilder: (context, index) {
              return TravelerCard(
                traveler: travelers[index],
                onTap: () {
                  // Handle traveler selection / booking
                },
              );
            },
          );
        },
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => const TripCardSkeleton(),
        ),
        error: (err, stack) => Center(
          child: Text(AppLocalizations.of(context)?.unexpectedError ?? 'Error'),
        ),
      ),
    );
  }
}
