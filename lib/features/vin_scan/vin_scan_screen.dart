import 'package:flutter/material.dart';

import 'package:drivana/ui/components/components.dart';

import 'vin_result_screen.dart';
import 'vin_service.dart';

/// The "My Car" tab (app_spec id "vin_scan", route kept for deep links).
///
/// The driver types their vehicle's 17-character VIN and taps Decode VIN. That
/// runs a REAL network request against the NHTSA vPIC service (see
/// CAPABILITIES.md) and, on success, pushes a separate results screen with the
/// decoded vehicle. There is no camera scanner — only a VIN text field + a
/// Decode VIN button (limitation documented in CAPABILITIES.md).
///
/// Composes ONLY the shared design-system components + tokens — no bespoke
/// colors, fonts or button/card styling.
class Screen_vin_scan extends StatefulWidget {
  const Screen_vin_scan({super.key});

  @override
  State<Screen_vin_scan> createState() => _ScreenVinScanState();
}

class _ScreenVinScanState extends State<Screen_vin_scan> {
  static const int _vinLength = 17;

  final TextEditingController _controller = TextEditingController();

  String? _validationError;
  String? _lookupError;
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _cleaned => _cleanVin(_controller.text);
  bool get _canSearch => _cleaned.length == _vinLength;

  /// Keep only valid VIN characters (A-Z, 0-9 minus I/O/Q), uppercased, max 17.
  static String _cleanVin(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int unit in input.toUpperCase().codeUnits) {
      final String c = String.fromCharCode(unit);
      final bool isDigit = unit >= 0x30 && unit <= 0x39;
      final bool isLetter = unit >= 0x41 && unit <= 0x5A;
      if ((isDigit || isLetter) && c != 'I' && c != 'O' && c != 'Q') {
        buffer.write(c);
        if (buffer.length == _vinLength) break;
      }
    }
    return buffer.toString();
  }

  void _onChanged(String raw) {
    final String cleaned = _cleanVin(raw);
    if (cleaned != raw) {
      _controller.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    setState(() {
      _validationError = null;
      _lookupError = null;
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _validationError = null;
      _lookupError = null;
    });
  }

  Future<void> _search() async {
    if (_searching) return;
    FocusScope.of(context).unfocus();

    final String vin = _cleaned;
    if (vin.isEmpty) {
      setState(() {
        _validationError = 'Enter a VIN to decode.';
        _lookupError = null;
      });
      return;
    }
    if (vin.length != _vinLength) {
      setState(() {
        _validationError =
            'A VIN is exactly $_vinLength characters (letters I, O and Q are '
            'never used). You have ${vin.length}.';
        _lookupError = null;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _lookupError = null;
      _searching = true;
    });

    try {
      final VinResult result = await VinService.decode(vin);
      if (!mounted) return;
      setState(() => _searching = false);
      // Separate results screen (NOT inline, NOT a dialog/overlay).
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VinResultScreen(result: result),
        ),
      );
    } on VinLookupException catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _lookupError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _lookupError = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppScaffold(
      topBar: const AppTopBar(title: 'My Car', centerTitle: false),
      bottomBar: const AppMainTabBar(current: AppMainTab.car),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          10,
          AppDimens.gutter,
          28,
        ),
        children: [
          Text(
            'Add your vehicle: enter its 17-character VIN to look up the make, '
            'model, year, trim, engine and body class.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            'Details come from the public NHTSA vPIC vehicle database — this '
            'screen never shows made-up specs.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Vehicle identification number',
            padding: const EdgeInsets.only(bottom: 10),
          ),
          AppTextField(
            controller: _controller,
            hintText: 'Enter the 17-character VIN',
            leadingIcon: Icons.tag_rounded,
            showClear: _cleaned.isNotEmpty,
            onClear: _clear,
            onChanged: _onChanged,
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${_cleaned.length}/$_vinLength characters',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: text.bodySmall
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const AppBanner(
            tone: AppBannerTone.info,
            icon: Icons.help_outline_rounded,
            title: 'Where do I find it?',
            message:
                'The VIN is a 17-character code stamped near the base of the '
                'windshield and on the driver-side door frame.',
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _searching ? 'Decoding…' : 'Decode VIN',
            icon: Icons.travel_explore_rounded,
            loading: _searching,
            onPressed: _canSearch && !_searching ? _search : null,
          ),
          if (_lookupError != null) ...[
            const SizedBox(height: 22),
            AppEmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'Couldn’t complete the lookup',
              message: _lookupError,
              actionLabel: 'Try again',
              onAction: _search,
            ),
          ],
        ],
      ),
    );
  }
}
