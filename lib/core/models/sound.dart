import 'package:flutter/material.dart';

/// The browsable sound categories shown as filter chips in the pickers.
///
/// `all` is a virtual bucket that matches every sound; the rest are concrete
/// tags a sound can belong to. Labels are paraphrased from the source app.
enum SoundCategory {
  all('all', 'All'),
  trends('trends', 'Trending'),
  gaming('gaming', 'Gaming'),
  cinematic('cinematic', 'Cinematic'),
  engine('engine', 'Engines'),
  memesFun('memes_fun', 'Fun & Memes');

  const SoundCategory(this.key, this.label);

  /// Stable key used for persistence / analytics.
  final String key;

  /// User-facing chip label (design system owns styling).
  final String label;

  /// A neutral icon for the chip, in a consistent Material style that differs
  /// from the source app's glyphs.
  IconData get icon {
    switch (this) {
      case SoundCategory.all:
        return Icons.grid_view_rounded;
      case SoundCategory.trends:
        return Icons.trending_up_rounded;
      case SoundCategory.gaming:
        return Icons.sports_esports_rounded;
      case SoundCategory.cinematic:
        return Icons.movie_creation_rounded;
      case SoundCategory.engine:
        return Icons.directions_car_filled_rounded;
      case SoundCategory.memesFun:
        return Icons.emoji_emotions_rounded;
    }
  }

  static SoundCategory fromKey(String? key) => SoundCategory.values.firstWhere(
        (c) => c.key == key,
        orElse: () => SoundCategory.all,
      );

  /// Categories shown as selectable chips, in display order.
  static List<SoundCategory> get chips => const [
        SoundCategory.all,
        SoundCategory.trends,
        SoundCategory.gaming,
        SoundCategory.cinematic,
        SoundCategory.engine,
        SoundCategory.memesFun,
      ];
}

/// The three drive moments a cue can be assigned to.
///
/// Exactly these three slots exist (business rule); each holds at most one
/// selected sound. The `key`s are the persistence keys and MUST NOT change —
/// only the user-facing [title]s were reframed as departure / arrival / home
/// cues.
enum SoundSlotType {
  connection('connection', 'Departure cue'),
  disconnection('disconnection', 'Arrival cue'),
  homeArrival('home_arrival', 'Home cue');

  const SoundSlotType(this.key, this.title);

  /// Stable key used for persistence.
  final String key;

  /// The picker/slot title (paraphrased functional label).
  final String title;

  static SoundSlotType fromKey(String? key) =>
      SoundSlotType.values.firstWhere(
        (s) => s.key == key,
        orElse: () => SoundSlotType.connection,
      );
}

/// A single bundled drive sound in the catalog.
///
/// Immutable value type. The audio bytes live under `assets/audio/` and are
/// referenced by [assetPath]; [mediaId]/[sourcePath] retain the archive origin
/// so a picker/audio task can locate or (re)copy the file if needed.
@immutable
class Sound {
  const Sound({
    required this.id,
    required this.name,
    required this.categories,
    required this.assetPath,
    required this.isPremium,
    this.brand,
    this.mediaId,
    this.sourcePath,
  });

  /// Stable catalog id (also the entitlement/selection key).
  final String id;

  /// Human-readable, user-facing name.
  final String name;

  /// One or more categories this sound is tagged with (never includes `all`).
  final Set<SoundCategory> categories;

  /// Bundled asset location, e.g. `assets/audio/<file>.mp3`.
  final String assetPath;

  /// Whether an active PRO entitlement is required to assign this sound.
  final bool isPremium;

  /// Optional vehicle brand for engine-startup sounds.
  final String? brand;

  /// Origin media id from `media.json` (for tooling/asset resolution).
  final String? mediaId;

  /// Origin path under `media/` (for tooling/asset resolution).
  final String? sourcePath;

  /// The `AssetSource` path used by `audioplayers` (drops the `assets/` prefix).
  String get audioPlayerPath =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

  bool inCategory(SoundCategory category) =>
      category == SoundCategory.all || categories.contains(category);

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        (brand?.toLowerCase().contains(q) ?? false);
  }
}
