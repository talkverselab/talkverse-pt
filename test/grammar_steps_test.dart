import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/screens/grammar_lesson_screen.dart';

/// 문법 스텝(지금 15) — 틀(스텝 목록)은 데이터, 서버 판이 있으면 그것, 없으면 앱 안 것, 빈 스텝은 숨김(2026-11-23).
void main() {
  String bundled(String rel) => File('assets/data/$rel').readAsStringSync();

  test('앱 안 묶음: 스텝 15칸 중 내용 있는 것만 보인다', () async {
    final idx = json.decode(bundled('grammar/lessons.json')) as Map<String, dynamic>;
    expect((idx['steps'] as List).length, 15);
    final ls = await GrammarLesson.loadAll(load: (rel) async => bundled(rel));
    expect(ls.map((l) => l.number), [1]);
    expect(ls.first.patterns, isNotEmpty);
  });

  test('서버 판이 있으면 그것 — 빈 스텝에 내용이 오면 나타나고, 제목·순서도 서버 목록대로', () async {
    final server = {
      'grammar/lessons.json': json.encode({
        'steps': [
          {'step': 3, 'file': 'grammar/lesson3.json', 'title': '서버 제목 3'},
          {'step': 1, 'file': 'grammar/lesson1.json'},
          {'step': 2, 'file': 'grammar/lesson2.json'},
        ]
      }),
      'grammar/lesson3.json': json.encode({
        'lesson': 3,
        'title': '',
        'patterns': [
          {'id': 'p1', 'label': 'x', 'examples': [{'tl': 'Olá', 'rd': '올라', 'ko': '안녕'}]}
        ]
      }),
    };
    final ls = await GrammarLesson.loadAll(load: (rel) async => server[rel] ?? bundled(rel));
    expect(ls.map((l) => l.number), [3, 1]); // 2 는 비어 숨김
    expect(ls.first.title, '서버 제목 3');
  });

  test('스텝 목록을 못 읽어도 1~15 기본 틀로', () async {
    final ls = await GrammarLesson.loadAll(load: (rel) async => rel == 'grammar/lessons.json' ? throw Exception('없음') : bundled(rel));
    expect(ls.map((l) => l.number), [1]);
  });

  test('서버 목록에서 스텝이 빠지면 안 보이고, 더해지면 보인다', () async {
    // 빠짐: 서버 목록에 1 이 없으면 묶음에 내용이 있어도 안 보임
    final gone = await GrammarLesson.loadAll(
        load: (rel) async => rel == 'grammar/lessons.json' ? json.encode({'steps': [{'step': 2, 'file': 'grammar/lesson2.json'}]}) : bundled(rel));
    expect(gone, isEmpty);
    // 더해짐: 묶음에 없는 스텝 16 이 서버에 생기면 보임
    final p16 = json.encode({'lesson': 16, 'title': '새 스텝', 'patterns': [{'id': 'a', 'examples': []}]});
    final added = await GrammarLesson.loadAll(load: (rel) async {
      if (rel == 'grammar/lessons.json') {
        return json.encode({'steps': [{'step': 1, 'file': 'grammar/lesson1.json'}, {'step': 16, 'file': 'grammar/lesson16.json'}]});
      }
      if (rel == 'grammar/lesson16.json') return p16;
      return bundled(rel);
    });
    expect(added.map((l) => l.number), [1, 16]);
  });
}
