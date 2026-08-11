import 'package:flutter/material.dart';

import 'package:drivana/ui/components/components.dart';
import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/state.dart';

/// The "Drive Sounds" home (app_spec id "0006") — the Sounds tab.
///
/// Presents the three assignable cue slots (Departure, Arrival, Home), a GET PRO
/// badge in the nav bar, a "not activated yet" tip and a prominent Setup Guide
/// call-to-action, all above the main tab bar.
///
/// Composes ONLY the shared design-system components + tokens — no bespoke
/// colors, fonts or button/card styling here.
class Screen_0006 extends StatelessWidget {
  const Screen_0006({super.key});

  /// The three slots, in display order, paired with a distinct (token) tint and
  /// a rounded Material glyph that diverges from the source app's icon set.
  static const List<_SlotSpec> _slots = <_SlotSpec>[
    _SlotSpec(
      slot: SoundSlotType.connection,
      title: 'Departure cue',
      emptyLabel: 'Plays when you set off — tap to choose',
      pickerId: '0004',
      icon: Icons.play_circle_outline_rounded,
      glyph: AppColors.primary,
    ),
    _SlotSpec(
      slot: SoundSlotType.disconnection,
      title: 'Arrival cue',
      emptyLabel: 'Plays when you arrive — tap to choose',
      pickerId: '0005',
      icon: Icons.flag_circle_rounded,
      glyph: AppColors.ratingStar,
    ),
    _SlotSpec(
      slot: SoundSlotType.homeArrival,
      title: 'Home cue',
      emptyLabel: 'Plays when you pull in at home — tap to choose',
      pickerId: 'home_arrival_sound',
      icon: Icons.cottage_rounded,
      glyph: AppColors.proGradientEnd,
    ),
  ];

  void _openPaywall(BuildContext context) => AppRouter.go(context, '0002');

  void _openMenu(BuildContext context) => AppRouter.go(context, '0003');

  void _openGuide(BuildContext context) =>
      AppRouter.go(context, 'connection_guide');

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: AppTopBar(
        title: 'Drive Sounds',
        leading: IconButton(
          icon: const Icon(Icons.tune_rounded),
          color: AppColors.textPrimary,
          onPressed: () => _openMenu(context),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: AppState.isPro,
            builder: (context, isPro, _) {
              if (isPro) return const SizedBox.shrink();
              return AppProBadge(
                compact: true,
                onPressed: () => _openPaywall(context),
              );
            },
          ),
        ],
      ),
      bottomBar: const AppMainTabBar(current: AppMainTab.sounds),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          10,
          AppDimens.gutter,
          28,
        ),
        children: [
          Text(
            'Pick a sound for each moment of a drive — setting off, '
            'arriving, and pulling in at home.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppBanner(
            tone: AppBannerTone.warning,
            icon: Icons.bolt_rounded,
            title: 'Not switched on yet',
            message:
                'Cues play once you wire them into a Shortcuts automation. '
                'Tap for the quick walkthrough.',
            onTap: () => _openGuide(context),
          ),
          const SizedBox(height: 22),
          AppSectionHeader(
            title: 'Assign a cue',
            padding: const EdgeInsets.only(bottom: 10),
          ),
          ValueListenableBuilder<Map<SoundSlotType, String?>>(
            valueListenable: AppState.slotSelections,
            builder: (context, selections, _) {
              final List<Widget> cards = [];
              for (int i = 0; i < _slots.length; i++) {
                final _SlotSpec spec = _slots[i];
                final Sound? sound =
                    SoundCatalog.byId(selections[spec.slot]);
                if (i > 0) cards.add(const SizedBox(height: 12));
                cards.add(
                  AppSlotCard(
                    title: spec.title,
                    icon: spec.icon,
                    glyphColor: spec.glyph,
                    selectedSound: sound?.name,
                    emptyLabel: spec.emptyLabel,
                    onTap: () => AppRouter.go(context, spec.pickerId),
                  ),
                );
              }
              return Column(children: cards);
            },
          ),
          const SizedBox(height: 26),
          AppButton(
            label: 'Setup Guide',
            icon: Icons.play_lesson_rounded,
            onPressed: () => _openGuide(context),
          ),
        ],
      ),
    );
  }
}

/// Static description of one home-screen cue slot card.
class _SlotSpec {
  const _SlotSpec({
    required this.slot,
    required this.title,
    required this.emptyLabel,
    required this.pickerId,
    required this.icon,
    required this.glyph,
  });

  final SoundSlotType slot;
  final String title;

  /// Shown in place of the sound name while the slot is empty — it doubles as
  /// the explanation of when this cue fires.
  final String emptyLabel;
  final String pickerId;
  final IconData icon;
  final Color glyph;
}
