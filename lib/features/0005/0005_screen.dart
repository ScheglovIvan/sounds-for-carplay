import 'package:flutter/material.dart';

import 'package:drivana/core/models/sound.dart';
import 'package:drivana/features/sound_picker/sound_picker_page.dart';

/// "Arrival cue" picker (app_spec id "0005").
///
/// Thin wrapper that binds the shared [SoundPickerPage] to the arrival slot.
class Screen_0005 extends StatelessWidget {
  const Screen_0005({super.key});

  @override
  Widget build(BuildContext context) {
    return const SoundPickerPage(slot: SoundSlotType.disconnection);
  }
}
