import 'package:flutter/material.dart';

import 'package:drivana/core/models/sound.dart';
import 'package:drivana/features/sound_picker/sound_picker_page.dart';

/// "Home cue" picker (app_spec id "home_arrival_sound").
///
/// Thin wrapper that binds the shared [SoundPickerPage] to the home slot.
class Screen_home_arrival_sound extends StatelessWidget {
  const Screen_home_arrival_sound({super.key});

  @override
  Widget build(BuildContext context) {
    return const SoundPickerPage(slot: SoundSlotType.homeArrival);
  }
}
