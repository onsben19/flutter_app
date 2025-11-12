import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

// Provide the key at runtime:
// flutter run --dart-define=OPENWEATHER_API_KEY=your_key
const String kOpenWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

class WeatherInfo {
  final String main; // Clear, Clouds, Rain, etc.
  final String icon; // e.g. 10d
  final double temp; // average temp of the day
  final double pop; // max probability of precipitation [0..1]
  final bool isRainy;

  const WeatherInfo({
    required this.main,
    required this.icon,
    required this.temp,
    required this.pop,
    required this.isRainy,
  });
}

class WeatherService {
  Future<WeatherInfo?> fetchDayForecast({
    required double lat,
    required double lon,
    required DateTime date,
  }) async {
    final apiKey = await _WeatherKey.resolve();
    if (apiKey == null || apiKey.isEmpty) return null;
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=fr');

    final res = await http.get(url);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['list'] as List<dynamic>?) ?? const [];
    if (list.isEmpty) return null;

    String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final targetKey = key(DateTime(date.year, date.month, date.day));

    final entries = <Map<String, dynamic>>[];
    for (final e in list) {
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000, isUtc: true).toLocal();
      if (key(dt) == targetKey) {
        entries.add(e as Map<String, dynamic>);
      }
    }
    if (entries.isEmpty) return null;

    // Aggregate
    final counts = <String, int>{};
    final iconsFor = <String, String>{};
    double tempSum = 0;
    int tempCount = 0;
    double maxPop = 0;
    for (final e in entries) {
      final weather = (e['weather'] as List).first as Map<String, dynamic>;
      final main = (weather['main'] as String?) ?? 'Clear';
      final icon = (weather['icon'] as String?) ?? '01d';
      counts.update(main, (v) => v + 1, ifAbsent: () => 1);
      iconsFor[main] = icon;
      final mainTemp = (e['main'] as Map<String, dynamic>);
      final t = (mainTemp['temp'] as num?)?.toDouble();
      if (t != null) {
        tempSum += t;
        tempCount += 1;
      }
      final pop = (e['pop'] as num?)?.toDouble() ?? 0.0;
      if (pop > maxPop) maxPop = pop;
    }
    String dominant = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final icon = iconsFor[dominant] ?? '01d';
    final temp = tempCount > 0 ? tempSum / tempCount : 0.0;
    final rainyTypes = {'Rain', 'Drizzle', 'Thunderstorm'};
    final isRainy = rainyTypes.contains(dominant) || maxPop >= 0.4;

    return WeatherInfo(main: dominant, icon: icon, temp: temp, pop: maxPop, isRainy: isRainy);
  }
}

class _WeatherKey {
  static String? _cached;

  static Future<String?> resolve() async {
    if (_cached != null) return _cached;
    // 1) dart-define at build/run time
    if (kOpenWeatherApiKey.isNotEmpty) return _cached = kOpenWeatherApiKey;

    // 2) Environment variable
    try {
      final env = Platform.environment['OPENWEATHER_API_KEY'];
      if (env != null && env.trim().isNotEmpty) return _cached = env.trim();
    } catch (_) {}

    // 3) Asset file
    try {
      final content = await rootBundle.loadString('assets/config/weather.json');
      final data = jsonDecode(content) as Map<String, dynamic>;
      final fromAsset = (data['OPENWEATHER_API_KEY'] as String?)?.trim();
      if (fromAsset != null && fromAsset.isNotEmpty) return _cached = fromAsset;
    } catch (_) {}

    // 4) Hardcoded fallback (user-provided)
    const hardcoded = '51f84a1a688305c28b258b774eca4b8a';
    if (hardcoded.isNotEmpty) return _cached = hardcoded;

    return null;
  }
}
