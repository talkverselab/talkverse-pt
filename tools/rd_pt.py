#!/usr/bin/env python3
"""유럽 포르투갈어(pt-PT) 문장 → 한글 독음. CLAUDE.md §10 독음 표기표를 그대로 규칙으로 옮긴 것(2026-11-07).
규칙으로 안 되는 낱말은 EXC 에 넣는다. 사용: from rd_pt import rd; 시험: python3 tools/rd_pt.py "Olá! Estás bem?" """
import re
import sys
import unicodedata

EXC = {
    'o': '우', 'os': '우쉬', 'a': '아', 'as': '아쉬', 'à': '아', 'às': '아쉬', 'e': '이', 'de': '드', 'que': '끄', 'te': '뜨', 'me': '므', 'se': '쓰',
    'lhe': '리', 'lhes': '리쉬', 'nos': '누쉬', 'vos': '부쉬', 'do': '두', 'dos': '두쉬', 'da': '다', 'das': '다쉬', 'no': '누', 'na': '나', 'nas': '나쉬',
    'ao': '아우', 'aos': '아우쉬', 'em': '앵', 'um': '웅', 'uns': '웅쉬', 'uma': '우마', 'umas': '우마쉬', 'com': '꽁', 'por': '뽀르', 'para': '빠라', 'pra': '프라',
    'tu': '뚜', 'eu': '에우', 'ele': '엘르', 'ela': '엘라', 'eles': '엘르쉬', 'não': '나웅', 'sim': '씽', 'bem': '벵', 'também': '땀벵', 'muito': '무이뚜', 'muita': '무이따',
    'muitos': '무이뚜쉬', 'muitas': '무이따쉬', 'sou': '쏘우', 'é': '에', 'és': '에쉬', 'ou': '오우', 'mas': '마쉬', 'mais': '마이쉬', 'pois': '뽀이쉬', 'já': '자',
    'ok': '오께이', 'trouxe': '트로쓰', 'trouxeste': '트로쎄쉬뜨', 'tiago': '띠아구', 'fixe': '피쉬', 'bué': '부에', 'tás': '따쉬', 'tá': '따', 'nada': '나다', 'porquê': '뽀르께', 'porque': '뽀르끄', 'aliás': '알리아쉬', 'sexta': '쌔이쉬따', 'mesmo': '메쥬무', 'mesma': '메쥬마', 'só': '쏘', 'sozinho': '쏘지뉴', 'sozinha': '쏘지냐', 'gelo': '젤루', 'rua': '후아', 'cão': '까웅', 'nisto': '니쉬뚜', 'isto': '이쉬뚜', 'isso': '이쑤', 'esse': '에쓰', 'essa': '에싸', 'este': '에쉬뜨', 'esta': '에쉬따', 'está': '이쉬따', 'estou': '이쉬또우', 'estás': '이쉬따쉬', 'estar': '이쉬따르', 'meia': '메이아', 'hora': '오라', 'horas': '오라쉬', 'ya': '야', 'pá': '빠', 'epá': '에빠', 'ó': '오', 'wi-fi': '와이파이', 'wifi': '와이파이', 'táxi': '딱씨', 'próximo': '쁘로씨무', 'próxima': '쁘로씨마',
    'exemplo': '이젬쁠루', 'exame': '이자므', 'exato': '이자뚜', 'exatamente': '이자따멘뜨', 'hoje': '오즈', 'boa': '보아', 'bom': '봉', 'bons': '봉쉬', 'boas': '보아쉬',
    'quê': '께', 'qual': '꽐', 'quando': '꽌두', 'quanto': '꽌뚜', 'quanta': '꽌따', 'quantos': '꽌뚜쉬', 'quantas': '꽌따쉬', 'quatro': '꽈트루',
    'se': '쓰', 'sem': '쎙', 'tem': '땡', 'têm': '땡잉', 'vem': '벵', 'vêm': '벵잉', 'nem': '넹', 'quem': '껭', 'cem': '쎙', 'dez': '데쉬', 'seis': '쎄이쉬', 'três': '트레쉬', 'mês': '메쉬', 'vez': '베쉬', 'luz': '루쉬', 'fiz': '피쉬', 'diz': '디쉬', 'faz': '파쉬', 'paz': '빠쉬', 'traz': '트라쉬',
    'ontem': '온뗑', 'homem': '오멩', 'mulher': '물례르', 'lisboa': '리쉬보아', 'porto': '뽀르뚜', 'inês': '이네쉬', 'tiago': '띠아구', 'duarte': '두아르뜨', 'beatriz': '베아트리쉬',
}
TENSE = {'p': 'ㅃ', 't': 'ㄸ', 'k': 'ㄲ', 's': 'ㅆ', 'b': 'ㅂ', 'd': 'ㄷ', 'g': 'ㄱ', 'z': 'ㅈ', 'f': 'ㅍ', 'v': 'ㅂ', 'm': 'ㅁ', 'n': 'ㄴ', 'l': 'ㄹ', 'r': 'ㄹ', 'R': 'ㅎ', '': 'ㅇ'}
BARE = {'p': '프', 't': '트', 'k': '크', 'b': '브', 'd': '드', 'g': '그', 'f': '프', 'v': '브', 's': '쓰', 'z': '즈', 'm': '므', 'n': '느', 'l': '르', 'r': '르', 'R': '흐'}
CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JUNG = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
JONG = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ'
V = 'aeiouáàâãéêíóôõúü'


def syl(c, v, j=' '):
    return chr(0xAC00 + CHO.index(c) * 588 + JUNG.index(v) * 28 + JONG.index(j))


def tokens(w):
    """글자 → (종류, 값) 차례. 종류: C 자음 · Y 샤 계열 · J 즈 계열 · NH · LH · V 모음 · CODA."""
    out, i, n = [], 0, len(w)
    nxt = lambda k: w[k] if k < n else ''
    while i < n:
        c = w[i]
        d = nxt(i + 1)
        if c in V:
            if w[i:i + 2] == 'ão':
                out += [('V', 'ㅏ'), ('V', 'ㅜ', 'ㅇ')]; i += 2; continue
            if w[i:i + 2] == 'ãe':
                out += [('V', 'ㅏ'), ('V', 'ㅣ', 'ㅇ')]; i += 2; continue
            if w[i:i + 2] == 'õe':
                out += [('V', 'ㅗ'), ('V', 'ㅣ', 'ㅇ')]; i += 2; continue
            base = unicodedata.normalize('NFD', c)[0]
            v = {'a': 'ㅏ', 'e': 'ㅔ', 'i': 'ㅣ', 'o': 'ㅗ', 'u': 'ㅜ'}[base]
            out.append(('V', v, 'ㅇ') if c == 'ã' else ('V', v)); i += 1; continue
        if c == 'h':
            i += 1; continue
        if w[i:i + 2] == 'ch':
            out.append(('Y', 'ㅅ')); i += 2; continue
        if w[i:i + 2] == 'nh':
            out.append(('NH',)); i += 2; continue
        if w[i:i + 2] == 'lh':
            out.append(('LH',)); i += 2; continue
        if w[i:i + 2] == 'rr':
            out.append(('C', 'R')); i += 2; continue
        if w[i:i + 2] == 'ss':
            out.append(('C', 's')); i += 2; continue
        if w[i:i + 3] in ('que', 'qui', 'qué', 'quê', 'quí'):
            out.append(('C', 'k')); i += 2; continue
        if w[i:i + 2] == 'qu':
            out.append(('W', 'ㄲ')); i += 2; continue
        if w[i:i + 3] in ('gue', 'gui', 'gué', 'guê', 'guí'):
            out.append(('C', 'g')); i += 2; continue
        if w[i:i + 3] in ('gua', 'guá'):
            out.append(('W', 'ㄱ')); i += 2; continue
        if c == 'c':
            out.append(('C', 's' if d in ('e', 'i', 'é', 'ê', 'í') else 'k')); i += 1; continue
        if c == 'ç':
            out.append(('C', 's')); i += 1; continue
        if c == 'g':
            out.append(('J', 'ㅈ') if d in ('e', 'i', 'é', 'ê', 'í') else ('C', 'g')); i += 1; continue
        if c == 'j':
            out.append(('J', 'ㅈ')); i += 1; continue
        if c == 'x':
            out.append(('Y', 'ㅅ')); i += 1; continue
        if c == 's':
            prev = w[i - 1] if i else ''
            if prev and prev in V and d and d in V:
                out.append(('C', 'z'))
            elif d == '' or d not in V:
                out.append(('S',) if prev else ('C', 's'))
            else:
                out.append(('C', 's'))
            i += 1; continue
        if c == 'z':
            out.append(('S',) if (d == '' or d not in V) else ('C', 'z')); i += 1; continue
        if c == 'r':
            out.append(('C', 'R' if i == 0 or w[i - 1] in 'nls' else 'r')); i += 1; continue  # 첫 r·n/l/s 뒤 r = ㅎ (honra, Israel)
        if c in 'mn' and (d == '' or d not in V):
            out.append(('N', c, d)); i += 1; continue
        if c == 'l' and (d == '' or d not in V):
            out.append(('L',)); i += 1; continue
        if c in 'ptbdfvmnlk':
            out.append(('C', c)); i += 1; continue
        i += 1
    return out


Y = {'ㅏ': 'ㅑ', 'ㅔ': 'ㅖ', 'ㅗ': 'ㅛ', 'ㅜ': 'ㅠ', 'ㅣ': 'ㅣ', 'ㅡ': 'ㅠ'}
WV = {'ㅏ': 'ㅘ', 'ㅔ': 'ㅞ', 'ㅣ': 'ㅟ', 'ㅗ': 'ㅗ'}


def word(w, nxt=''):
    key = w.lower()
    if key in EXC:
        r = EXC[key]
        return r[:-1] + '즈' if r.endswith('쉬') and nxt[:1] in V and nxt else r
    w = key
    t = tokens(w)
    # 어말 비강세 o/e(·os/es) 약화 — 악센트 없는 낱말만
    vs = [i for i, x in enumerate(t) if x[0] == 'V']
    if len(vs) > 1 and not w.endswith('z') and not re.search('[áàâéêíóôú][^aeiou]*$', w):
        last = vs[-1]
        tail = t[last + 1:]
        if not tail or tail == [('S',)]:
            if t[last][1] == 'ㅗ':
                t[last] = ('V', 'ㅜ')
            elif t[last][1] == 'ㅔ':
                t[last] = ('V', 'ㅡ')
    if w.startswith('es') and len(vs) > 1 and t and t[0][1:] == ('ㅔ',):
        t[0] = ('V', 'ㅣ')
    res = []  # 음절 조각: [초, 중, 종]

    def coda(j):
        if res and isinstance(res[-1], list) and res[-1][2] == ' ':
            res[-1][2] = j
            return True
        return False

    i, n = 0, len(t)
    while i < n:
        k = t[i]
        nx = t[i + 1] if i + 1 < n else None
        kind = k[0]
        if kind == 'V':
            res.append(['ㅇ', k[1], k[2] if len(k) > 2 else ' ']); i += 1; continue
        if kind in ('C', 'Y', 'J', 'W', 'NH', 'LH') and nx and nx[0] == 'V':
            v = nx[1]; j = nx[2] if len(nx) > 2 else ' '
            if kind == 'C':
                c = TENSE[k[1]]
                if k[1] == 'l' and i and t[i - 1][0] == 'V':
                    coda('ㄹ')  # 모음 사이 l = ㄹㄹ (Olá 올라)
                res.append([c, v, j])
            elif kind == 'Y':
                res.append('쉬' if v == 'ㅡ' else ['ㅅ', Y.get(v, v), j])
            elif kind == 'J':
                res.append(['ㅈ', 'ㅡ' if v == 'ㅡ' else v, j])
            elif kind == 'W':
                res.append([k[1], WV.get(v, v), j])
            elif kind == 'NH':
                coda('ㅇ'); res.append('느' if v == 'ㅡ' else ['ㅇ', Y.get(v, v), j])
            else:
                coda('ㄹ'); res.append('르' if v == 'ㅡ' else ['ㄹ', Y.get(v, v), j])  # 약화 e 앞 lh = ㄹ르 (escolhe 이쉬꼴르)
            i += 2; continue
        if kind == 'S':
            voiced = (nx and nx[0] == 'C' and nx[1] in 'bdgvmnlrR') or (nx and nx[0] == 'J')
            if i == n - 1:
                res.append('즈' if nxt[:1] in V and nxt else '쉬')
            else:
                res.append('쥬' if voiced else '쉬')
            i += 1; continue
        if kind == 'N':
            last = i == n - 1 or (t[i + 1] == ('S',) and i + 2 == n)
            c, d = k[1], k[2]
            if last:
                if res and isinstance(res[-1], list) and res[-1][1] == 'ㅏ' and c == 'm':
                    res.append(['ㅇ', 'ㅜ', 'ㅇ'])
                else:
                    coda('ㅇ')
            elif d in ('g', 'c', 'q', 'k') or (d in ('d', 'b', 'p') and res and isinstance(res[-1], list) and res[-1][1] == 'ㅗ'):
                coda('ㅇ')
            else:
                coda('ㅁ' if c == 'm' else 'ㄴ')
            i += 1; continue
        if kind == 'L':
            if not coda('ㄹ'):
                res.append('르')
            i += 1; continue
        if kind == 'C':
            if k[1] in 'pkfbg' and nx and nx[:2] == ('C', 'l') and i + 2 < n and t[i + 2][0] == 'V':
                res.append({'p': '쁠', 'k': '끌', 'f': '플', 'b': '블', 'g': '글'}[k[1]])  # 뒤의 ㄹ 음절과 이어서 cl → 끌라
                res.append(['ㄹ', t[i + 2][1], t[i + 2][2] if len(t[i + 2]) > 2 else ' '])
                i += 3; continue
            res.append(BARE[k[1]]); i += 1; continue
        if kind in ('Y', 'J'):
            res.append('쉬' if kind == 'Y' else '즈'); i += 1; continue
        i += 1
    return ''.join(x if isinstance(x, str) else syl(*x) for x in res)


TOK = re.compile(r"\{[a-z_]+\}|[0-9]+|[^\W\d_]+", re.U)


def rd(text):
    """문장 → 독음. 문장부호·{변수}·숫자는 그대로, 붙임표(접어)는 띄어 쓴다."""
    text = text.replace('-', ' ')
    ms = list(TOK.finditer(text))
    out, pos = [], 0
    for i, m in enumerate(ms):
        out.append(text[pos:m.start()])
        s = m.group(0)
        if s.startswith('{') or s.isdigit():
            out.append(s)
        else:
            gap = text[m.end():ms[i + 1].start()] if i + 1 < len(ms) else '.'
            nw = ms[i + 1].group(0).lower().lstrip('h') if i + 1 < len(ms) and gap.strip() == '' else ''  # há·hoje 는 모음으로 시작
            out.append(word(s, nw))
        pos = m.end()
    out.append(text[pos:])
    return ''.join(out)


if __name__ == '__main__':
    print(rd(' '.join(sys.argv[1:])))
