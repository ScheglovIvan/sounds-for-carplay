import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single labelled field decoded from a VIN (e.g. "Make" → "HONDA").
class VinField {
  const VinField(this.label, this.value);

  final String label;
  final String value;
}

/// The decoded result for one VIN: a human headline plus the non-empty fields
/// returned by the vehicle database. Only fields with a real value are kept.
class VinResult {
  const VinResult({
    required this.vin,
    required this.title,
    required this.fields,
  });

  final String vin;

  /// e.g. "2003 HONDA Accord" — built from the real Year/Make/Model, or null
  /// when none of those came back.
  final String? title;

  final List<VinField> fields;
}

/// Raised for any failure the UI should show as a friendly, retryable message
/// instead of crashing.
class VinLookupException implements Exception {
  const VinLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Real VIN decode against the public NHTSA vPIC service.
///
/// NOTE (see CAPABILITIES.md): the original app's exact VIN backend was never
/// observed (the VIN screen wasn't crawled and no VIN network traffic was
/// captured), so exact replication is impossible. This uses the closest real,
/// working, key-less HTTPS service — NHTSA vPIC `DecodeVinValues` — and shows
/// only the genuine fields it returns.
class VinService {
  const VinService._();

  static const String _base =
      'https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues';

  static const Duration _timeout = Duration(seconds: 15);

  /// The `(label, vPIC key, [fallback key])` fields we surface, in display
  /// order. Any field whose value comes back empty / "Not Applicable" is
  /// dropped by [_isRealValue].
  static const List<List<String>> _fieldSpec = [
    ['Make', 'Make'],
    ['Model', 'Model'],
    ['Model year', 'ModelYear'],
    ['Manufacturer', 'Manufacturer', 'ManufacturerName'],
    ['Trim', 'Trim'],
    ['Body class', 'BodyClass'],
    ['Vehicle type', 'VehicleType'],
    ['Series', 'Series'],
    ['Doors', 'Doors'],
    ['Engine cylinders', 'EngineCylinders'],
    ['Displacement (L)', 'DisplacementL'],
    ['Engine model', 'EngineModel'],
    ['Fuel type', 'FuelTypePrimary'],
    ['Transmission', 'TransmissionStyle'],
    ['Drive type', 'DriveType'],
    ['Plant country', 'PlantCountry'],
    ['Plant company', 'PlantCompanyName'],
  ];

  /// Performs the real network request and returns the decoded [VinResult].
  ///
  /// Throws [VinLookupException] with a user-friendly message on any offline /
  /// timeout / bad-status / unparseable / not-found condition — never lets a
  /// raw exception escape to the UI.
  static Future<VinResult> decode(String vin) async {
    final Uri uri = Uri.parse('$_base/$vin?format=json');

    final http.Response response;
    try {
      response = await http.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const VinLookupException(
        'The lookup took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const VinLookupException(
        "We couldn't reach the vehicle database. Check your connection and "
        'try again.',
      );
    } catch (e) {
      // `SocketException` (no internet) lives in `dart:io`, which the web
      // preview build cannot import — match it by type name so this file stays
      // web-safe while still giving a clear offline message on device.
      if (e.runtimeType.toString() == 'SocketException') {
        throw const VinLookupException(
          'You appear to be offline. Check your internet connection and try '
          'again.',
        );
      }
      throw const VinLookupException(
        'Something went wrong reaching the vehicle database. Please try again.',
      );
    }

    if (response.statusCode != 200) {
      throw VinLookupException(
        'The vehicle database is unavailable right now '
        '(error ${response.statusCode}). Please try again in a moment.',
      );
    }

    final Map<String, dynamic> row;
    try {
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> results =
          (decoded as Map<String, dynamic>)['Results'] as List<dynamic>;
      if (results.isEmpty) {
        throw const VinLookupException('empty');
      }
      row = results.first as Map<String, dynamic>;
    } on VinLookupException {
      throw const VinLookupException(
        "We couldn't find any details for that VIN. "
        'Double-check the number and try again.',
      );
    } catch (_) {
      throw const VinLookupException(
        "We couldn't read the response for that VIN. Please try again.",
      );
    }

    // vPIC signals a clean decode with ErrorCode "0". A non-zero primary code
    // means the VIN couldn't be decoded (bad check digit, not in database…).
    final String errorCode = (row['ErrorCode'] ?? '').toString();
    final String primaryCode = errorCode.split(',').first.trim();
    if (primaryCode.isNotEmpty && primaryCode != '0') {
      final String detail = (row['ErrorText'] ?? '').toString().trim();
      throw VinLookupException(
        detail.isNotEmpty && detail.toLowerCase() != 'null'
            ? "We couldn't decode that VIN. $detail"
            : "We couldn't decode that VIN. "
                'Double-check the number and try again.',
      );
    }

    final List<VinField> fields = <VinField>[];
    for (final List<String> spec in _fieldSpec) {
      final String label = spec[0];
      String? value = _stringOrNull(row[spec[1]]);
      if (value == null && spec.length > 2) {
        value = _stringOrNull(row[spec[2]]);
      }
      if (value != null) fields.add(VinField(label, value));
    }

    if (fields.isEmpty) {
      throw const VinLookupException(
        "We couldn't find any details for that VIN. "
        'Double-check the number and try again.',
      );
    }

    return VinResult(vin: vin, title: _title(row), fields: fields);
  }

  /// Builds "Year Make Model" from the real values, skipping any that are
  /// missing. Returns null when none are present.
  static String? _title(Map<String, dynamic> row) {
    final List<String> parts = <String?>[
      _stringOrNull(row['ModelYear']),
      _stringOrNull(row['Make']),
      _stringOrNull(row['Model']),
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Returns the trimmed value only when it is a real, meaningful value;
  /// null for empty strings, "Not Applicable" and similar vPIC placeholders.
  static String? _stringOrNull(dynamic raw) {
    if (raw == null) return null;
    final String value = raw.toString().trim();
    if (!_isRealValue(value)) return null;
    return value;
  }

  static bool _isRealValue(String value) {
    if (value.isEmpty) return false;
    final String lower = value.toLowerCase();
    return lower != 'not applicable' &&
        lower != 'not available' &&
        lower != 'null';
  }
}
