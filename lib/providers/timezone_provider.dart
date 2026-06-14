import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import '../core/country_timezone_map.dart';

class TimezoneState {
  final String selectedCountry;
  final String countryCode;
  final String timezoneName;
  final String timezoneAbbreviation;
  final bool isAutoDetected;

  TimezoneState({
    required this.selectedCountry,
    required this.countryCode,
    required this.timezoneName,
    required this.timezoneAbbreviation,
    required this.isAutoDetected,
  });

  TimezoneState copyWith({
    String? selectedCountry,
    String? countryCode,
    String? timezoneName,
    String? timezoneAbbreviation,
    bool? isAutoDetected,
  }) {
    return TimezoneState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      countryCode: countryCode ?? this.countryCode,
      timezoneName: timezoneName ?? this.timezoneName,
      timezoneAbbreviation: timezoneAbbreviation ?? this.timezoneAbbreviation,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }
}

final timezoneProvider = StateNotifierProvider<TimezoneNotifier, TimezoneState>((ref) {
  return TimezoneNotifier();
});

class TimezoneNotifier extends StateNotifier<TimezoneState> {
  TimezoneNotifier()
      : super(TimezoneState(
          selectedCountry: 'United States',
          countryCode: 'us',
          timezoneName: 'America/New_York',
          timezoneAbbreviation: 'EDT',
          isAutoDetected: true,
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountry = prefs.getString('selected_country');
      final savedCode = prefs.getString('selected_country_code');
      final savedTimezone = prefs.getString('selected_timezone');
      final savedAuto = prefs.getBool('is_auto_detected') ?? true;

      if (savedCountry != null && savedTimezone != null && savedCode != null) {
        state = TimezoneState(
          selectedCountry: savedCountry,
          countryCode: savedCode,
          timezoneName: savedTimezone,
          timezoneAbbreviation: _getAbbreviation(savedTimezone),
          isAutoDetected: savedAuto,
        );
      } else {
        await detectDeviceTimezone();
      }
    } catch (_) {
      // SharedPreferences / Timezone init failure fallback
      state = TimezoneState(
        selectedCountry: 'United States',
        countryCode: 'us',
        timezoneName: 'America/New_York',
        timezoneAbbreviation: 'EDT',
        isAutoDetected: true,
      );
    }
  }

  String _getAbbreviation(String timezoneName) {
    try {
      final loc = tz.getLocation(timezoneName);
      final now = tz.TZDateTime.now(loc);
      return now.timeZone.abbreviation;
    } catch (_) {
      return 'UTC';
    }
  }

  tz.TZDateTime convertToLocal(DateTime utcTime) {
    try {
      final loc = tz.getLocation(state.timezoneName);
      final utcDateTime = utcTime.isUtc ? utcTime : utcTime.toUtc();
      return tz.TZDateTime.from(utcDateTime, loc);
    } catch (_) {
      return tz.TZDateTime.from(utcTime, tz.UTC);
    }
  }

  String formatMatchTime(DateTime utcTime, String pattern) {
    final local = convertToLocal(utcTime);
    final formatted = DateFormat(pattern).format(local);
    final abbr = local.timeZone.abbreviation;
    return '$formatted $abbr';
  }

  Future<void> selectCountry(CountryTimezone country, {bool isAuto = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_country', country.name);
      await prefs.setString('selected_country_code', country.code);
      await prefs.setString('selected_timezone', country.timezone);
      await prefs.setBool('is_auto_detected', isAuto);

      state = TimezoneState(
        selectedCountry: country.name,
        countryCode: country.code,
        timezoneName: country.timezone,
        timezoneAbbreviation: _getAbbreviation(country.timezone),
        isAutoDetected: isAuto,
      );
    } catch (_) {}
  }

  Future<void> detectDeviceTimezone() async {
    try {
      String? deviceTz;
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        deviceTz = tzInfo.identifier;
      } catch (_) {
        deviceTz = 'America/New_York';
      }

      // Find country matching the device's timezone
      CountryTimezone matchedCountry = const CountryTimezone(
        name: 'United States',
        code: 'us',
        timezone: 'America/New_York',
      );

      for (final country in countryTimezones) {
        if (country.timezone == deviceTz) {
          matchedCountry = country;
          break;
        }
      }

      await selectCountry(matchedCountry, isAuto: true);
    } catch (_) {
      // Fallback
      await selectCountry(
        const CountryTimezone(
          name: 'United States',
          code: 'us',
          timezone: 'America/New_York',
        ),
        isAuto: true,
      );
    }
  }
}
