/// 단어 목록·퀴즈에서 빼는 비속어(앱 등급 12+, 출시 심사 점검 11-23).
/// 빈도표(자막 기반)에 높은 순위로 들어 있는 욕설·성적 낱말 — 회화 대사에는 쓰지 않는다.
/// 한국어 뜻에 「(비속어)」 표시가 붙은 낱말도 함께 뺀다.
const Set<String> kOffensiveWords = {
  'foda', 'foda-se', 'fodase', 'foder', 'fodido', 'fodida', 'fodidos', 'fodidas', 'fode', 'fodes',
  'caralho', 'caralhos', 'puta', 'putas', 'porra', 'merda', 'merdas', 'cabrão', 'cabrões',
  'cona', 'conas', 'piça', 'pila', 'cu', 'sacana', 'paneleiro', 'broche', 'punheta', 'filho-da-puta',
};

bool isOffensiveWord(String word, [String ko = '']) =>
    kOffensiveWords.contains(word.trim().toLowerCase()) || ko.contains('비속어');
