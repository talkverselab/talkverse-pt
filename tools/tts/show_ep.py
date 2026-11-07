#!/usr/bin/python3
"""편 내용을 짧게 보여 준다(감정 계획 작성용). python3 tools/tts/show_ep.py <편id>..."""
import json, sys
import ttslib as L
for ep in sys.argv[1:]:
    d = json.load(open(L.EP[ep], encoding='utf-8'))
    print(f"\n## {ep} | {d['title']} | {d['scene']} | {d['speakers']}")
    for t in d['turns']:
        print(t['num'], t['speaker'], t['tl'], '||', t['ko'])
