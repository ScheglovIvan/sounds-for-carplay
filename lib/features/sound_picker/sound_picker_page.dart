import 'package:flutter/material.dart';

import 'package:drivana/core/router/app_router.dart';
import 'package:drivana/core/state.dart';
import 'package:drivana/ui/components/components.dart';

/// The shared sound picker used for all three cue slots (Departure / Arrival /
/// Home). A thin per-id wrapper binds it to a [slot].
///
/// Layout mirrors the source picker (search field, category chip row, scrolling
/// preview rows, pinned confirm button) but composes ONLY design-system
/// components + tokens and paraphrases every string.
///
/// AUDIO: this is where the app spec's `content.audio` triggers become real
/// sound. Each row's play/pause button previews its clip through the shared
/// [SoundPreviewPlayer] (preview is always free), and selecting a row both
/// assigns the sound to the slot AND plays it once — mirroring the clip firing
/// on its assigned drive moment. Premium clips are gated to the paywall when
/// the user has no PRO entitlement.
class SoundPickerPage extends StatefulWidget {
  const SoundPickerPage({super.key, required this.slot});

  final SoundSlotType slot;

  @override
  State<SoundPickerPage> createState() => _SoundPickerPageState();
}

class _SoundPickerPageState extends State<SoundPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  final SoundPreviewPlayer _player = SoundPreviewPlayer.instance;

  String _query = '';
  int _categoryIndex = 0;

  /// Divergent, paraphrased screen titles keyed by slot (kept out of the shared
  /// enum copy so the picker header reads differently from the source app).
  static const Map<SoundSlotType, String> _titles = <SoundSlotType, String>{
    SoundSlotType.connection: 'Departure cue',
    SoundSlotType.disconnection: 'Arrival cue',
    SoundSlotType.homeArrival: 'Home cue',
  };

  List<SoundCategory> get _categories => SoundCategory.chips;

  SoundCategory get _selectedCategory => _categories[_categoryIndex];

  @override
  void dispose() {
    // Silence any preview when the picker is dismissed.
    _player.stop();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) => setState(() => _query = value);

  void _clearQuery() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _onCategorySelected(int index) =>
      setState(() => _categoryIndex = index);

  /// Tapping a row: gate premium clips to the paywall, otherwise assign the
  /// sound to this slot and play it once as the "assigned event" cue.
  void _onSelect(Sound sound, {required bool locked}) {
    if (locked) {
      AppRouter.go(context, '0002'); // Standard paywall.
      return;
    }
    AppState.selectSound(widget.slot, sound.id);
    _player.playSound(sound);
  }

  void _confirm() {
    _player.stop();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: _titles[widget.slot] ?? 'Choose a Sound',
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              8,
              AppDimens.gutter,
              12,
            ),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Find a sound',
              onChanged: _onQueryChanged,
              showClear: _query.isNotEmpty,
              onClear: _clearQuery,
            ),
          ),
          AppChipBar(
            labels: [for (final c in _categories) c.label],
            selectedIndex: _categoryIndex,
            onSelected: _onCategorySelected,
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildList() {
    // Rebuild the list whenever the entitlement, the slot selection or the
    // currently-playing clip changes.
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.isPro,
      builder: (context, isPro, _) {
        return ValueListenableBuilder<Map<SoundSlotType, String?>>(
          valueListenable: AppState.slotSelections,
          builder: (context, selections, __) {
            return ValueListenableBuilder<String?>(
              valueListenable: _player.nowPlayingId,
              builder: (context, playingId, ___) {
                final List<Sound> results = SoundCatalog.filter(
                  category: _selectedCategory,
                  query: _query,
                );

                if (results.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.graphic_eq_rounded,
                    title: 'Nothing to hear here',
                    message: _query.isEmpty
                        ? 'No sounds in this category yet.'
                        : 'No sounds match your search. Try another '
                            'keyword or category.',
                    actionLabel: _query.isEmpty ? null : 'Clear search',
                    onAction: _query.isEmpty ? null : _clearQuery,
                  );
                }

                final String? selectedId = selections[widget.slot];

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    6,
                    AppDimens.gutter,
                    12,
                  ),
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final Sound sound = results[i];
                    final bool locked = sound.isPremium && !isPro;
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: AppSoundRow(
                        title: sound.name,
                        selected: sound.id == selectedId,
                        playing: sound.id == playingId,
                        premium: sound.isPremium,
                        locked: locked,
                        onPlayToggle: () => _player.toggle(sound),
                        onTap: () => _onSelect(sound, locked: locked),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          6,
          AppDimens.gutter,
          10,
        ),
        child: AppButton(
          label: 'Save Choice',
          icon: Icons.check_circle_outline_rounded,
          onPressed: _confirm,
        ),
      ),
    );
  }
}
