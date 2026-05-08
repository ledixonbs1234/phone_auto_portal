import 'dart:convert';
import 'package:flutter/services.dart';

class AddressSuggestion {
  final String fullAddress;
  final String wardName;
  final String districtName;
  final String provinceName;

  AddressSuggestion({
    required this.fullAddress,
    required this.wardName,
    required this.districtName,
    required this.provinceName,
  });
}

class AddressSuggestionService {
  final List<_AddressEntry> _entries = [];
  final Map<String, List<String>> _abbDict = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final s = await rootBundle.loadString('assets/tree_data.json');
    final root = jsonDecode(s)['QuocGiaTree'] as Map<String, dynamic>;

    for (final ttpName in root.keys) {
      final ttp = root[ttpName] as Map<String, dynamic>;
      final ttpKD = _norm(ttp['KD'] as String? ?? '');
      final ttpInit = (ttp['Init'] as String? ?? '').toLowerCase();
      final dists = ttp['Districts'] as Map<String, dynamic>? ?? {};

      for (final qhName in dists.keys) {
        final qh = dists[qhName] as Map<String, dynamic>;
        final qhKD = _norm(qh['KD'] as String? ?? '');
        final qhInit = (qh['Init'] as String? ?? '').toLowerCase();
        final wards = qh['Wards'] as List<dynamic>? ?? [];

        for (final w in wards) {
          final wMap = w as Map<String, dynamic>;
          final wardName = wMap['Name'] as String? ?? '';
          final wardKD = _norm(wMap['KD'] as String? ?? '');
          final wardInit = (wMap['Init'] as String? ?? '').toLowerCase();

          final full = '$wardName, $qhName, $ttpName';
          _entries.add(_AddressEntry(
            fullAddress: full,
            fullAddressKD: _norm(full),
            wardKD: wardKD,
            districtKD: qhKD,
            provinceKD: ttpKD,
          ));

          final c2 = '$wardInit $ttpInit';
          final c3 = '$wardInit $qhInit $ttpInit';
          _abbDict.putIfAbsent(c2, () => []).add(full);

          if (!_abbDict.containsKey(c3)) {
            _abbDict[c3] = [];
          }
          if (!_abbDict[c3]!.contains(full)) {
            _abbDict[c3]!.add(full);
          }
        }
      }
    }
    _loaded = true;
  }

  List<AddressSuggestion> search(String query, {int maxResults = 8}) {
    if (query.trim().isEmpty) return [];
    final nq = _norm(query.trim().toLowerCase());

    List<AddressSuggestion>? _matchAbb(String abb, String? addrPrefix) {
      final list = _abbDict[abb];
      if (list == null) return null;
      return list.map((full) {
        final parts = full.split(', ');
        final addr = addrPrefix != null && addrPrefix.isNotEmpty
            ? '$addrPrefix, $full'
            : full;
        return AddressSuggestion(
          fullAddress: addr,
          wardName: parts.isNotEmpty ? parts[0] : '',
          districtName: parts.length > 1 ? parts[1] : '',
          provinceName: parts.length > 2 ? parts[2] : '',
        );
      }).take(maxResults).toList();
    }

    final qTokens = query.trim().split(' ');
    final qParts = query.trim().split(RegExp(r'\s{2,}'));

    if (qParts.length > 1) {
      final result = _matchAbb(
        _norm(qParts.last.trim().toLowerCase()),
        qParts.first.trim(),
      );
      if (result != null && result.isNotEmpty) return result;
    }

    if (_abbDict.containsKey(nq)) {
      return _abbDict[nq]!
          .map((a) => _toSuggestion(a))
          .take(maxResults)
          .toList();
    }

    final nqTokens = nq.split(' ');
    if (nqTokens.length >= 2) {
      for (final len in [2, 3]) {
        if (nqTokens.length >= len) {
          final abb = nqTokens.sublist(nqTokens.length - len).join(' ');
          if (_abbDict.containsKey(abb)) {
            final addrPrefix = qTokens.sublist(0, qTokens.length - len).join(' ');
            return _matchAbb(abb, addrPrefix)!;
          }
        }
      }
    }

    final scored = <_ScoredEntry>[];
    for (final e in _entries) {
      int s = 0;
      if (e.wardKD.contains(nq)) {
        s = 3;
      } else if (e.districtKD.contains(nq)) {
        s = 2;
      } else if (e.provinceKD.contains(nq)) {
        s = 1;
      } else if (e.fullAddressKD.contains(nq)) {
        s = 1;
      }
      if (s > 0) scored.add(_ScoredEntry(e, s));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(maxResults).map((s) {
      final parts = s.entry.fullAddress.split(', ');
      return AddressSuggestion(
        fullAddress: s.entry.fullAddress,
        wardName: parts.isNotEmpty ? parts[0] : '',
        districtName: parts.length > 1 ? parts[1] : '',
        provinceName: parts.length > 2 ? parts[2] : '',
      );
    }).toList();
  }

  AddressSuggestion _toSuggestion(String full) {
    final parts = full.split(', ');
    return AddressSuggestion(
      fullAddress: full,
      wardName: parts.isNotEmpty ? parts[0] : '',
      districtName: parts.length > 1 ? parts[1] : '',
      provinceName: parts.length > 2 ? parts[2] : '',
    );
  }

  static final _aRE = RegExp(r'[àáảãạâầấẩẫậăằắẳẵặ]');
  static final _eRE = RegExp(r'[èéẻẽẹêềếểễệ]');
  static final _iRE = RegExp(r'[ìíỉĩị]');
  static final _oRE = RegExp(r'[òóỏõọôồốổỗộơờớởỡợ]');
  static final _uRE = RegExp(r'[ùúủũụưừứửữự]');
  static final _yRE = RegExp(r'[ỳýỷỹỵ]');

  String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll(_aRE, 'a')
        .replaceAll(_eRE, 'e')
        .replaceAll(_iRE, 'i')
        .replaceAll(_oRE, 'o')
        .replaceAll(_uRE, 'u')
        .replaceAll(_yRE, 'y')
        .replaceAll('đ', 'd');
  }

  bool get isLoaded => _loaded;
}

class _AddressEntry {
  final String fullAddress;
  final String fullAddressKD;
  final String wardKD;
  final String districtKD;
  final String provinceKD;

  _AddressEntry({
    required this.fullAddress,
    required this.fullAddressKD,
    required this.wardKD,
    required this.districtKD,
    required this.provinceKD,
  });
}

class _ScoredEntry {
  final _AddressEntry entry;
  final int score;
  _ScoredEntry(this.entry, this.score);
}
