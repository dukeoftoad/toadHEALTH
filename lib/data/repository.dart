import 'dart:convert';

import 'models.dart';
import 'vault_service.dart';

/// The on-device health database, persisted as an AES-256-GCM sealed JSON
/// document through [VaultService]. All numbers here are REAL user data -
/// nothing is simulated at runtime (the optional demo pond is a clearly
class HealthRepository {
  HealthRepository(this._vault);

  final VaultService _vault;
  Map<String, dynamic> _doc = _freshDoc();
  bool _loaded = false;

  static Map<String, dynamic> _freshDoc() => {
        'schema': 1,
        'days': <String, dynamic>{},
        'samples': <dynamic>[],
        'entries': <dynamic>[],
        'settings': VaultSettings().toMap(),
      };

  Future<void> load() async {
    final sealed = await _vault.readData();
    if (sealed == null) {
      _doc = _freshDoc();
    } else {
      try {
        final doc = jsonDecode(sealed) as Map<String, dynamic>;
        if ((doc['schema'] as num? ?? 0) == 1) {
          _doc = doc;
        } else {
          _doc = _freshDoc();
        }
      } catch (_) {
        _doc = _freshDoc();
      }
    }
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  VaultSettings get settings =>
      VaultSettings.fromMap((_doc['settings'] as Map).cast<String, dynamic>());

  set settings(VaultSettings s) => _doc['settings'] = s.toMap();

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _day(String key, {bool create = false}) {
    final days = (_doc['days'] as Map).cast<String, dynamic>();
    final existing = days[key];
    if (existing != null) {
      return (existing as Map).cast<String, dynamic>();
    }
    if (!create) return const <String, dynamic>{};
    final fresh = <String, dynamic>{
      'steps': 0,
      'water': 0,
      'sleepMin': 0,
      'updatedAt': 0,
    };
    days[key] = fresh;
    return fresh;
  }

  Map<String, dynamic> today({bool create = true}) =>
      _day(dayKey(DateTime.now()), create: create);

  int daySteps(String key) => (_day(key)['steps'] as num?)?.toInt() ?? 0;

  int dayWater(String key) => (_day(key)['water'] as num?)?.toInt() ?? 0;

  int daySleep(String key) => (_day(key)['sleepMin'] as num?)?.toInt() ?? 0;

  void addSteps(int delta) {
    final d = today();
    d['steps'] = ((d['steps'] as num?)?.toInt() ?? 0) + delta;
    d['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
  }

  void setWater(int value) {
    final d = today();
    d['water'] = value < 0 ? 0 : (value > 24 ? 24 : value);
    d['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
  }

  void logSleep(int minutes) {
    final d = today();
    d['sleepMin'] = minutes < 0 ? 0 : minutes;
    d['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
  }

  void upsertDay(
    String key, {
    int steps = 0,
    int water = 0,
    int sleepMin = 0,
  }) {
    final d = _day(key, create: true);
    d['steps'] = steps;
    d['water'] = water;
    d['sleepMin'] = sleepMin;
    d['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
  }

  /// Per-event step deltas (sensor or manual) - the source of the hourly
  /// rhythm chart. Capped so the vault stays small even after months.
  void addSample(int tsMs, int delta) {
    final samples = (_doc['samples'] as List);
    samples.add({'ts': tsMs, 'delta': delta});
    if (samples.length > 2000) {
      _doc['samples'] = samples.sublist(samples.length - 2000).toList();
    }
  }

  List<Map<String, dynamic>> samplesForDay(String key) {
    final out = <Map<String, dynamic>>[];
    for (final s in (_doc['samples'] as List)) {
      final m = (s as Map).cast<String, dynamic>();
      final ts = DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt());
      if (dayKey(ts) == key) {
        out.add(m);
      }
    }
    return out;
  }

  void addEntry(String type, String detail) {
    final entries = (_doc['entries'] as List);
    entries.add({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'type': type,
      'detail': detail,
    });
    if (entries.length > 100) {
      _doc['entries'] = entries.sublist(entries.length - 100).toList();
    }
  }

  List<HopEntry> recentEntries(int n) {
    final entries = (_doc['entries'] as List);
    final out = <HopEntry>[];
    for (var i = entries.length - 1; i >= 0 && out.length < n; i--) {
      final m = (entries[i] as Map).cast<String, dynamic>();
      out.add(HopEntry(
        DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
        m['type'] as String? ?? 'steps',
        m['detail'] as String? ?? '',
      ));
    }
    return out;
  }

  List<DayStat> lastDays(int n) {
    final now = DateTime.now();
    final out = <DayStat>[];
    for (var i = n - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final key = dayKey(d);
      out.add(DayStat(key, daySteps(key), dayWater(key), daySleep(key)));
    }
    return out;
  }

  String exportJson() => jsonEncode(_doc);

  void importJson(String json) {
    final doc = jsonDecode(json) as Map<String, dynamic>;
    if ((doc['schema'] as num? ?? 0) != 1) {
      throw const FormatException('unsupported backup schema');
    }
    _doc = doc;
  }

  void reset() {
    _doc = _freshDoc();
    _loaded = true;
  }

  Future<void> save() => _vault.writeData(jsonEncode(_doc));
}
