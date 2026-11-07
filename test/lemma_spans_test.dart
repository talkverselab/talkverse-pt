import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/services/dialogue_service.dart';
import 'package:portuguese_universe/widgets/lemma_text.dart';

void main() {
  test('표면형을 글자 경계에서 차례로 찾는다', () {
    const text = 'Olá, chamo-me Inês. De onde és?';
    final r = lemmaSpans(text, const [Lemma('chamo', 'chamar', ''), Lemma('onde', 'onde', ''), Lemma('és', 'ser', '')]);
    expect(r.map((e) => text.substring(e.$1, e.$2)), ['chamo', 'onde', 'és']);
  });

  test('낱말 안쪽은 잡지 않고, 없는 표면형은 건너뛴다', () {
    const text = 'O serviço é bom.';
    final r = lemmaSpans(text, const [Lemma('é', 'ser', ''), Lemma('ser', 'ser', ''), Lemma('bom', 'bom', '')]);
    expect(r.map((e) => e.$3.surface), ['é', 'bom']);
  });
}
