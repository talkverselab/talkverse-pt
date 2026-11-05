import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/data/db/app_database.dart';
import 'package:portuguese_universe/data/db/seed_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DB 업데이트 번호가 바뀌어 다시 채워도 학습 기록은 같은 턴에 남아야 한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('다시 채워도 학습 기록이 같은 턴에 남는다', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = SeedLoader(db);
    await seed.seedIfNeeded();

    final turns = await db.select(db.turns).get();
    expect(turns, isNotEmpty);
    final t = turns[3];
    final when = DateTime(2026, 11, 1);
    await db.into(db.userProgress).insert(UserProgressCompanion.insert(
          turnId: Value(t.id),
          learned: const Value(true),
          favorite: const Value(true),
          lastReviewed: Value(when),
          reviewCount: const Value(5),
        ));

    // 번호가 달라진 상황을 만든다
    (await SharedPreferences.getInstance()).setInt('db_version', -1);
    await seed.seedIfNeeded();

    final after = await db.select(db.turns).get();
    expect(after.length, turns.length);
    final same = after.singleWhere((r) => r.level == t.level && r.episodeId == t.episodeId && r.num == t.num);
    final p = await db.select(db.userProgress).get();
    expect(p.length, 1);
    expect(p.single.turnId, same.id);
    expect(p.single.learned, isTrue);
    expect(p.single.favorite, isTrue);
    expect(p.single.reviewCount, 5);
    expect(p.single.lastReviewed, when);
  });

  test('번호가 같으면 다시 채우지 않는다', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final seed = SeedLoader(db);
    await seed.seedIfNeeded();
    final first = (await db.select(db.turns).get()).first.id;
    await seed.seedIfNeeded();
    expect((await db.select(db.turns).get()).first.id, first);
  });
}
