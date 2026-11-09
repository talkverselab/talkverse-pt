import '../core/embed_env.dart';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import '../core/prefs.dart';

import 'learner_prefs.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 포르투갈어앱(2026-11-03): 인도네시아어앱 1차 복제판을 옮겨 이 앱의 데이터에 맞췄다.
/// 지금 데이터는 초안 `assets/data/dialogues/L1.json`(5편 × 8턴, 유럽 포르투갈어) 하나뿐이라 그것을 그대로 읽어 이 모양으로 바꾼다.
/// 회화 콘텐츠는 바꾸지 않는다(회화 작성 금지 기간) — 새 구조(R0~R4·주제별·성별판 파일)는 회화 작성이 풀리면.
/// 칸: tl = 포르투갈어(옛 템플릿 칸 이름 `es`), gloss = 없음, rd = 한글 독음, ko = 한국어, note = 핵심 표현(`x = 뜻`).
/// 문장 내용어 한 개: 표면형(문장 속 모양)·기본형(사전형)·읽기(한글 독음, 아직 비어 있음).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어(표면형·기본형·읽기) — 단어장 연결(2026-11-04)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: j['es'] as String? ?? j['tl'] as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 핵심 단어 후보: 핵심 표현 메모(`palavra = 뜻`)의 왼쪽 낱말들.
  List<String> get pictureWords {
    final left = note.split('=').first;
    return [for (final m in RegExp(r"[A-Za-zÀ-ÿ]+(?:-[A-Za-zÀ-ÿ]+)*").allMatches(left)) if (m.group(0)!.length > 1) m.group(0)!];
  }
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  final String kind; // short · long · chat · survival (옛 L1 은 short)
  final int twist; // 반전 턴 번호(0 = 없음)
  final String twistType;
  final String variant; // pt-PT · pt-BR
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
    this.kind = 'short',
    this.twist = 0,
    this.twistType = '',
    this.variant = 'pt-PT',
  });

  /// 새 회화 묶음(`tools/build_dialogues.py` → `assets/data/pt-PT/dialogues/<성별>.json`)의 편 하나.
  /// 목소리 성별은 cast(화자 → 목소리 이름)로 정한다.
  factory Dialogue.fromJson(Map<String, dynamic> j) {
    final speakers = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    final cast = ((j['cast'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? 'life',
      title: j['title'] as String? ?? j['id'] as String,
      emoji: j['emoji'] as String? ?? '💬',
      scene: j['scene'] as String? ?? '',
      speakers: speakers,
      genders: {for (final e in cast.entries) e.key: _maleVoices.contains(e.value) ? 'male' : 'female'},
      expressions: ((j['expressions'] as List?) ?? const []).map((e) => '$e').toList(),
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList(),
      kind: j['kind'] as String? ?? 'short',
      twist: j['twist'] as int? ?? 0,
      twistType: j['twist_type'] as String? ?? '',
      variant: j['variant'] as String? ?? 'pt-PT',
    );
  }

  static const _maleVoices = {'duarte', 'tiago'};

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 지금 회화는 화자 이름·성별이 정해진 이야기(A Minjun 남 · B Inês 여)라 데이터의 성별을 따른다.
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  /// 회화 레벨 = 문법 단계(docs/GRAMMAR_LEVELS_pt.md) — 단어 메뉴의 절벽 구간 R1~R5 와 번호가 다르다.
  static const levelKo = {
    'R0': '레벨 0 · 소리·짧은 회화',
    'R1': '레벨 1 · 활용 골격',
    'R2': '레벨 2 · 채팅 실전',
    'R3': '레벨 3 · 복수·존댓말',
    'R4': '레벨 4 · 어려운 문법',
    'R5': '레벨 5 · 어휘 완주',
    'L1': '이야기',
  };
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  Future<void>? _loading;
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 넓은 화면에서 여러 탭이 동시에 불러도 한 번만 읽는다(플래그 방식은 목록이 두 번 찬다).
  /// 학습자 성별이 바뀌면 그 성별판을 다시 읽는다(성별판 = 파일 분리, CLAUDE.md §10).
  Future<void> ensureLoaded() {
    if (_loadedGender != null && _loadedGender != LearnerPrefs.gender.value) _loading = null;
    return _loading ??= _load();
  }

  String? _loadedGender;

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    final g = _loadedGender = LearnerPrefs.gender.value;
    final all = <Dialogue>[];
    try {
      final list = json.decode(await rootBundle.loadString(assetPath('assets/data/pt-PT/dialogues/$g.json'))) as List;
      for (final e in list) {
        final d = Dialogue.fromJson(e as Map<String, dynamic>);
        if (d.turns.isNotEmpty) all.add(d);
      }
    } catch (_) {}
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/dialogues/L1.json'))) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        all.add(Dialogue(
          id: '${level}_${m['id']}',
          region: level,
          island: 'love', // 옛 L1 = 언어교환 앱에서 시작하는 설렘 이야기(원칙: 기존 연애 서사는 love 주제)
          title: m['title'] as String? ?? m['id'] as String,
          emoji: m['emoji'] as String? ?? '💬',
          scene: m['scenario'] as String? ?? '',
          speakers: names,
          genders: genders,
          expressions: const [],
          turns: turns,
        ));
      }
    } catch (_) {}
    _all
      ..clear()
      ..addAll(all);
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => _all.map((d) => d.region).toSet().toList();

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
