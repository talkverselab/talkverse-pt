/// 유럽 포르투갈어 문자·발음 표 — 「문자와 발음」 메뉴(일본어앱 50음도와 발음 이식, 2026-11-08).
/// 칸: 글자(label) · 한글 독음(rd, 보조 표기) · IPA · 읽어 줄 말(speak) · 예시 낱말 · 소리 나는 곳 · 한국어와 비교.
class PtSound {
  final String label, rd, ipa, speak, example, exampleKo, place, korSim, korDiff;
  final bool consonant;
  const PtSound(this.label, this.rd, this.ipa, this.speak, this.example, this.exampleKo, this.place, this.korSim, this.korDiff, {this.consonant = true});
}

class PtSoundGroup {
  final String name, note;
  final List<PtSound> items;
  const PtSoundGroup(this.name, this.note, this.items);
}

const _v = false;

const List<PtSoundGroup> kPtSoundGroups = [
  PtSoundGroup('알파벳', '26글자. 이름이 아니라 실제 소리 중심으로 봅니다.', [
    PtSound('A a', '아', 'a / ɐ', 'casa', 'casa', '집', '입을 크게 벌린 「아」. 강세 없으면 입을 덜 벌린 「어」 쪽 [ɐ].', '아', '강세 없는 a 는 한국어 「어」와 「아」 사이로 약해집니다(casa 까자: 뒤 a 가 약함).', consonant: _v),
    PtSound('B b', 'ㅂ', 'b / β', 'bom', 'bom', '좋은', '두 입술. 모음 사이에서는 입술을 덜 닫아 [β].', 'ㅂ', '한국어 ㅂ보다 목청이 처음부터 울립니다(유성음).'),
    PtSound('C c', 'ㄲ / ㅆ', 'k / s', 'casa, cidade', 'casa · cidade', '집 · 도시', 'a·o·u 앞 혀뒤 [k], e·i 앞 혀끝 [s].', 'ㄲ · ㅆ', '숨을 거의 내지 않아 「까」에 가깝습니다. 「카」처럼 세게 내뿜지 않습니다.'),
    PtSound('D d', 'ㄷ', 'd / ð', 'dia', 'dia', '날', '혀끝을 윗니 뒤에. 모음 사이에서는 살짝 떼어 [ð].', 'ㄷ', '유럽판은 di 를 「지」로 바꾸지 않습니다(브라질판과 다름): dia 디아.'),
    PtSound('E e', '에 / 으', 'e / ɛ / ɨ', 'café', 'café · de', '커피 · ~의', 'é 는 열린 「애」 쪽, ê 는 닫힌 「에」, 강세 없으면 「으」로 약해지거나 사라집니다.', '에 · 애 · 으', '강세 없는 e 가 거의 안 들리는 것이 유럽판의 가장 큰 특징입니다(telefone 뜰르포느).', consonant: _v),
    PtSound('F f', 'ㅍ', 'f', 'falar', 'falar', '말하다', '윗니를 아랫입술에 대고 바람.', 'ㅍ', '한국어 ㅍ은 두 입술 — f 는 윗니와 아랫입술입니다.'),
    PtSound('G g', 'ㄱ / ㅈ', 'ɡ / ʒ', 'gato, gente', 'gato · gente', '고양이 · 사람들', 'a·o·u 앞 혀뒤 [ɡ], e·i 앞 「쥐」에 가까운 [ʒ].', 'ㄱ · ㅈ', 'ge·gi 의 [ʒ]는 입술을 내밀고 떨리게 내는 소리 — 한국어 ㅈ보다 부드럽습니다.'),
    PtSound('H h', '(소리 없음)', '—', 'hoje', 'hoje', '오늘', '단어 첫 h 는 읽지 않습니다. ch·lh·nh 에서만 쓰입니다.', '—', 'hoje 는 「오즈」.', consonant: _v),
    PtSound('I i', '이', 'i', 'aqui', 'aqui', '여기', '입을 옆으로 벌린 「이」.', '이', '거의 같습니다.', consonant: _v),
    PtSound('J j', 'ㅈ', 'ʒ', 'já', 'já', '이미', '입술을 내밀고 혀를 들어 떨리게 「쥐」.', 'ㅈ', '한국어 ㅈ은 막았다 터뜨리고, j 는 막지 않고 흘립니다.'),
    PtSound('K k', 'ㄲ', 'k', 'kiwi', 'kiwi', '키위', '외래어에만 씁니다.', 'ㄲ', '숨을 적게.'),
    PtSound('L l', 'ㄹ', 'l / ɫ', 'Lisboa', 'Lisboa · mal', '리스본 · 나쁘게', '혀끝을 윗잇몸에. 음절 끝에서는 혀뒤를 들어 어두운 [ɫ].', 'ㄹ', '모음 사이 l 은 「ㄹㄹ」(Olá 올라). 끝의 l 은 「우」에 가깝게 들리기도 합니다.'),
    PtSound('M m', 'ㅁ', 'm', 'mãe', 'mãe', '엄마', '두 입술을 닫고 콧소리.', 'ㅁ', '음절 끝 m 은 앞 모음을 콧소리로 만듭니다(sim 씽).'),
    PtSound('N n', 'ㄴ', 'n', 'não', 'não', '아니', '혀끝을 윗잇몸에, 콧소리.', 'ㄴ', '음절 끝 n 은 앞 모음을 콧소리로(então 엔따웅).'),
    PtSound('O o', '오 / 우', 'o / ɔ / u', 'avó, avô', 'avó · avô · obrigado', '할머니 · 할아버지 · 고마워', 'ó 는 열린 「오」, ô 는 닫힌 「오」, 강세 없으면 「우」.', '오 · 우', '어말 o 는 거의 「우」: obrigado 오브리가두.', consonant: _v),
    PtSound('P p', 'ㅃ', 'p', 'pai', 'pai', '아빠', '두 입술을 닫았다 터뜨림.', 'ㅃ', '숨을 거의 내지 않아 「빠」에 가깝습니다.'),
    PtSound('Q q', 'ㄲ', 'k', 'quero', 'quero · quatro', '원해 · 넷', 'qu+e/i 는 [k], qu+a 는 [kw].', 'ㄲ · 꽈', 'que 「끄」, quatro 「꽈트루」.'),
    PtSound('R r', 'ㄹ / ㅎ', 'ɾ / ʁ', 'caro, carro', 'caro · carro · Rio', '비싼 · 차 · 강', '모음 사이 r 은 혀끝 한 번 튕김 [ɾ], 단어 첫 r·rr 은 목 안쪽 [ʁ].', 'ㄹ · ㅎ', '단어 첫 r 은 가래 끓듯 목에서 — 한국어 「ㅎ」을 거칠게 낸 소리에 가깝습니다.'),
    PtSound('S s', 'ㅆ / ㅈ / 쉬', 's / z / ʃ', 'sim, casa, mais', 'sim · casa · mais', '응 · 집 · 더', '단어 첫 [s], 모음 사이 [z], 음절 끝 「쉬」[ʃ].', 'ㅆ · ㅈ · 쉬', '음절 끝 s 가 「쉬」가 되는 것이 유럽판 특징(Lisboa 리쉬보아).'),
    PtSound('T t', 'ㄸ', 't', 'tu', 'tu · noite', '너 · 밤', '혀끝을 윗니 뒤에, 숨 적게.', 'ㄸ', '유럽판은 ti 를 「치」로 바꾸지 않습니다: noite 노이뜨.'),
    PtSound('U u', '우', 'u', 'tu', 'tu', '너', '입술을 둥글게 내민 「우」.', '우', '거의 같습니다.', consonant: _v),
    PtSound('V v', 'ㅂ', 'v', 'vinho', 'vinho', '포도주', '윗니를 아랫입술에 대고 목청을 울림.', 'ㅂ', 'b 와 다릅니다 — 입술을 닫지 않습니다.'),
    PtSound('W w', '우', 'w', 'wi-fi', 'wi-fi', '와이파이', '외래어에만.', '우', '—'),
    PtSound('X x', '쉬 / ㅆ / ㅈ', 'ʃ / ks / z', 'xícara', 'peixe · táxi · exame', '물고기 · 택시 · 시험', '대개 「쉬」[ʃ], 낱말에 따라 [ks]·[z].', '쉬', '낱말마다 외웁니다.'),
    PtSound('Y y', '이', 'i', 'yoga', 'yoga', '요가', '외래어에만.', '이', '—', consonant: _v),
    PtSound('Z z', 'ㅈ / 쉬', 'z / ʃ', 'zero, feliz', 'zero · feliz', '영 · 행복한', '모음 앞 [z], 낱말 끝 「쉬」.', 'ㅈ · 쉬', 'feliz 「플리쉬」.'),
  ]),
  PtSoundGroup('모음·악센트', '부호는 강세 자리와 입을 여는 정도를 알려 줍니다.', [
    PtSound('á', '아(강세)', 'a', 'está', 'está', '있다', '강세 있는 열린 「아」.', '아', '부호가 있는 음절을 세게.', consonant: _v),
    PtSound('â', '어(강세)', 'ɐ', 'câmara', 'câmara', '카메라', '닫힌 「어」.', '어', '「아」보다 입을 덜 벌립니다.', consonant: _v),
    PtSound('é', '애', 'ɛ', 'é', 'é · café', '~이다 · 커피', '열린 「에」 — 입을 크게.', '애', '한국어 「애」에 가깝습니다.', consonant: _v),
    PtSound('ê', '에', 'e', 'você', 'você · mês', '당신 · 달', '닫힌 「에」.', '에', '「이」 쪽으로 입을 덜 벌립니다.', consonant: _v),
    PtSound('ó', '오(열린)', 'ɔ', 'avó', 'avó · só', '할머니 · 오직', '열린 「오」 — 「어」와 「오」 사이.', '오', '입을 크게 벌린 「오」.', consonant: _v),
    PtSound('ô', '오(닫힌)', 'o', 'avô', 'avô', '할아버지', '닫힌 「오」 — 입술을 둥글게.', '오', 'avó(할머니)와 avô(할아버지)는 이 차이뿐입니다.', consonant: _v),
    PtSound('í · ú', '이 · 우(강세)', 'i · u', 'aí', 'aí · baú', '거기 · 상자', '강세 자리 표시.', '이 · 우', '부호가 있는 음절을 세게.', consonant: _v),
    PtSound('à', '아', 'a', 'à', 'à · às', '~로(a + a)', '전치사 a 와 관사 a 가 합쳐진 꼴.', '아', '소리는 a 와 같습니다.', consonant: _v),
  ]),
  PtSoundGroup('비모음', '콧소리로 내는 모음 — 코로 숨이 함께 나갑니다.', [
    PtSound('ão', '아웅', 'ɐ̃w̃', 'não', 'não · pão · então', '아니 · 빵 · 그럼', '「어」를 코로 내다가 「우」로 닫음.', '아웅', '「아웅」을 한 음절로 짧게, 끝을 코로.', consonant: _v),
    PtSound('ãe', '아잉', 'ɐ̃j̃', 'mãe', 'mãe · cães', '엄마 · 개들', '「어」를 코로 내다가 「이」로.', '아잉', '「마잉」처럼 한 음절.', consonant: _v),
    PtSound('õe', '오잉', 'õj̃', 'põe', 'põe · lições', '놓다 · 수업들', '「오」를 코로 내다가 「이」로.', '오잉', '한 음절.', consonant: _v),
    PtSound('ã · am · an', '앙', 'ɐ̃', 'amanhã', 'amanhã · campo', '내일 · 들판', '「어」를 코로.', '앙', '받침 ㅇ 처럼 들리지만 혀를 닫지 않습니다.', consonant: _v),
    PtSound('em · en', '앵 / 엥', 'ẽ / ɐ̃j̃', 'bem', 'bem · sempre · em', '잘 · 항상 · ~에', '낱말 끝 em 은 「앵이」에 가깝게.', '앵 · 엥', 'em 「앵」, bem 「벵」.', consonant: _v),
    PtSound('im · in', '잉', 'ĩ', 'sim', 'sim · cinco', '응 · 다섯', '「이」를 코로.', '잉', '—', consonant: _v),
    PtSound('om · on', '옹', 'õ', 'bom', 'bom · onde', '좋은 · 어디', '「오」를 코로.', '옹', '—', consonant: _v),
    PtSound('um · un', '웅', 'ũ', 'um', 'um · mundo', '하나 · 세상', '「우」를 코로.', '웅', '—', consonant: _v),
  ]),
  PtSoundGroup('자음 조합', '두 글자가 한 소리 — 철자만 보고 읽을 수 있게.', [
    PtSound('ch', '쉬', 'ʃ', 'chá', 'chá · chamar', '차 · 부르다', '입술을 내밀고 「쉬」.', '쉬', '영어 sh 와 같습니다(「치」 아님).'),
    PtSound('lh', 'ㄹ리', 'ʎ', 'filho', 'filho · mulher', '아들 · 여자', '혀 가운데를 입천장에 붙인 ㄹ.', 'ㄹ리', 'filho 「필류」 — 「리」를 짧게 섞습니다.'),
    PtSound('nh', '니', 'ɲ', 'vinho', 'vinho · amanhã', '포도주 · 내일', '혀 가운데를 입천장에 붙인 ㄴ.', '냐·뇨', 'vinho 「빙유」 — 스페인어 ñ 와 같은 소리.'),
    PtSound('rr', 'ㅎ', 'ʁ', 'carro', 'carro · terra', '차 · 땅', '목 안쪽에서 거칠게.', 'ㅎ', 'caro(비싼)와 carro(차)를 구별하는 소리.'),
    PtSound('ss', 'ㅆ', 's', 'isso', 'isso · passar', '그것 · 지나가다', '모음 사이에서도 [s] 로 지키는 표기.', 'ㅆ', 'casa(ㅈ)와 cassa(ㅆ).'),
    PtSound('ç', 'ㅆ', 's', 'coração', 'coração · faço', '마음 · 하다', 'a·o·u 앞에서 [s] 를 내는 c.', 'ㅆ', '—'),
    PtSound('qu · gu', 'ㄲ · ㄱ', 'k · ɡ', 'quero', 'quero · guitarra', '원해 · 기타', 'e·i 앞 qu·gu 의 u 는 읽지 않습니다.', 'ㄲ · ㄱ', 'quero 「께루」, guitarra 「기따하」.'),
    PtSound('s 끝', '쉬', 'ʃ', 'mais', 'mais · dois · Lisboa', '더 · 둘 · 리스본', '음절 끝 s·z 는 「쉬」, 유성음 앞은 「쥬」.', '쉬 · 쥬', 'mesmo 「메쥬무」.'),
  ]),
  PtSoundGroup('모음 약화', '강세 없는 모음이 약해지거나 사라집니다 — 유럽판이 빠르게 들리는 이유.', [
    PtSound('e → 으', '으 / 탈락', 'ɨ', 'telefone', 'telefone · pequeno · de', '전화 · 작은 · ~의', '강세 없는 e 는 「으」로 약해지거나 거의 사라집니다.', '으', 'telefone 「뜰르포느」, pequeno 「쁘께누」.', consonant: _v),
    PtSound('o → 우', '우', 'u', 'obrigado', 'obrigado · porque · bonito', '고마워 · 왜냐하면 · 예쁜', '강세 없는 o 는 「우」.', '우', 'porque 「뿌르끄」, bonito 「부니뚜」.', consonant: _v),
    PtSound('a → 어', '어', 'ɐ', 'casa', 'casa · semana', '집 · 주', '강세 없는 a 는 입을 덜 벌린 「어」.', '어', 'casa 의 뒤 a.', consonant: _v),
    PtSound('강세 자리', '', '', 'português', 'português · cidade · falar', '포르투갈어 · 도시 · 말하다', '부호가 있으면 그 음절, a·e·o(s)·am·em 으로 끝나면 끝에서 둘째, 그 밖은 마지막 음절.', '—', '강세 음절만 또렷하고 나머지는 약해집니다.', consonant: _v),
  ]),
];
