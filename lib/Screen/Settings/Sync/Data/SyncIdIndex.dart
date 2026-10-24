import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../../Core/NetworkManager/NetworkManager.dart';
import '../../../../Core/Preferences/StorageManager.dart';
import '../../../../Core/State/State.dart';
import 'SyncModels.dart';
import '../../../../Logger.dart';

const _animeSource =
    'https://raw.githubusercontent.com/Fribb/anime-lists/master/anime-list-mini.json';
const _mangaSource =
    'https://raw.githubusercontent.com/itsmechinmoy/dartotsu_manga_mapper/main/manga-list-mini.json';

const _animeColumns = [
  SyncKey.anilist,
  SyncKey.mal,
  SyncKey.kitsu,
  SyncKey.simkl,
];

const _mangaColumns = [
  SyncKey.mangabaka,
  SyncKey.anilist,
  SyncKey.mal,
  SyncKey.mangaupdates,
  SyncKey.kitsu,
];

const _maxAge = Duration(days: 7);

List<int> _compactAnime(String raw) {
  final rows = jsonDecode(raw) as List;
  final out = <int>[];
  for (final r in rows) {
    if (r is! Map) continue;
    final row = [
      for (final c in const ['anilist_id', 'mal_id', 'kitsu_id', 'simkl_id'])
        r[c] is int ? r[c] as int : 0,
    ];
    if (row.where((v) => v > 0).length < 2) continue;
    out.addAll(row);
  }
  return out;
}

List<int> _compactManga(String raw) {
  final rows = jsonDecode(raw) as List;
  final out = <int>[];
  for (final r in rows) {
    if (r is! Map) continue;
    final row = [
      for (final c in const [
        'mangabaka_id',
        'anilist_id',
        'mal_id',
        'mangaupdates_id',
        'kitsu_id',
      ])
        r[c] is int ? r[c] as int : 0,
    ];
    if (row.where((v) => v > 0).length < 2) continue;
    out.addAll(row);
  }
  return out;
}

List<int> _decodeFlat(String raw) => (jsonDecode(raw) as List).cast<int>();

class SyncIdIndex {
  final List<int> _flat;
  final List<String> _columns;
  late final Map<String, Map<int, int>> _by = _build();

  SyncIdIndex(this._flat, {List<String>? columns, bool anime = true})
      : _columns = columns ?? (anime ? _animeColumns : _mangaColumns);

  List<int> get flat => _flat;
  List<String> get columns => _columns;

  int get rows => _flat.length ~/ _columns.length;

  Map<String, Map<int, int>> _build() {
    final by = {for (final c in _columns) c: <int, int>{}};
    for (var row = 0; row < rows; row++) {
      for (var c = 0; c < _columns.length; c++) {
        final v = _flat[row * _columns.length + c];
        if (v > 0) by[_columns[c]]!.putIfAbsent(v, () => row);
      }
    }
    return by;
  }

  Map<String, int> expand(Map<String, int> ids, {String? prefer}) {
    final order = [
      ?prefer,
      for (final c in _columns)
        if (c != prefer) c,
    ];
    for (final c in order) {
      final id = ids[c];
      final row = id == null ? null : _by[c]?[id];
      if (row == null) continue;
      final out = {...ids};
      for (var i = 0; i < _columns.length; i++) {
        final v = _flat[row * _columns.length + i];
        if (v > 0) out.putIfAbsent(_columns[i], () => v);
      }
      return out;
    }
    return ids;
  }

  static SyncIdIndex? _cachedAnime;
  static SyncIdIndex? _cachedManga;

  static Future<File> _file({required bool anime}) async {
    final dir = await StorageManager.getDirectory(subPath: 'sync');
    final name = anime ? 'anime-ids.json' : 'manga-ids.json';
    return File(p.join(dir!.path, name));
  }

  static Future<SyncIdIndex> load({
    bool anime = true,
    bool force = false,
  }) async {
    if (anime && _cachedAnime != null && !force) return _cachedAnime!;
    if (!anime && _cachedManga != null && !force) return _cachedManga!;
    final file = await _file(anime: anime);
    final stale =
        !await file.exists() ||
        DateTime.now().difference(await file.lastModified()) > _maxAge;
    if (stale || force) {
      try {
        final res = await find<NetworkManager>().get(
          anime ? _animeSource : _mangaSource,
          decodeJson: false,
        );
        if (res.statusCode == 200 && res.data is String) {
          final flat = await compute(
            anime ? _compactAnime : _compactManga,
            res.data as String,
          );
          if (flat.isNotEmpty) {
            await file.writeAsString(jsonEncode(flat));
            final index = SyncIdIndex(flat, anime: anime);
            if (anime) {
              _cachedAnime = index;
            } else {
              _cachedManga = index;
            }
            return index;
          }
        }
      } catch (e) {
        logger(
          'SyncIdIndex (${anime ? 'anime' : 'manga'}) download failed: $e',
          logLevel: LogLevel.error,
        );
      }
    }
    if (await file.exists()) {
      final flat = await compute(_decodeFlat, await file.readAsString());
      final index = SyncIdIndex(flat, anime: anime);
      if (anime) {
        _cachedAnime = index;
      } else {
        _cachedManga = index;
      }
      return index;
    }
    throw SyncFatal(
      'Could not download the ${anime ? 'anime' : 'manga'} ID mapping',
    );
  }
}
