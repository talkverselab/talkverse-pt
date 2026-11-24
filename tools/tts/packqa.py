#!/usr/bin/env python3
"""묶은 뒤 다시 받아쓰는 검사(11-24): qa.py 는 묶기 전 조각만 봐서, 묶을 때(pack.py 자르기) 작은 목소리의 말이 잘린 것을 못 잡는다.
  <venv>/bin/python tools/tts/packqa.py <작업폴더> [--all]
1) 의심 고르기(받아쓰기 없음): 조각 최대 음량의 30dB 안쪽인 10ms 프레임 합 = 말 길이(잡음이 큰 조각은 길게 잡힌다), 묶기용으로 자른 길이가 그 85% 미만이면 의심.  --all = 의심만이 아니라 전부.
2) 의심 조각만 묶은 상태(자르기 + 음량 맞추기)로 받아써 0.85 미만을 출력. 결과 <작업폴더>/packqa.json. 부하 20 넘으면 멈춘다."""
import difflib, json, os, subprocess, sys, tempfile
import numpy as np
import ttslib as L, qa, pack


def pcm(f):
    return np.frombuffer(subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-f', 'f32le', '-ac', '1', '-ar', '16000', '-'], capture_output=True).stdout, dtype=np.float32)


def packed_score(src, key, text):
    """묶은 상태로 받아쓴 비슷함(받아쓴 글, 0~1). 네 글자까지도 그대로 견준다(길이만 보지 않음)."""
    with tempfile.TemporaryDirectory() as t:
        pack.clip(src, key, f'{t}/a.wav')
        pack.run('ffmpeg', '-y', '-i', f'{t}/a.wav', '-af', 'apad=pad_dur=0.12,loudnorm=I=-18:TP=-1.5:LRA=11', '-ar', '24000', '-ac', '1', f'{t}/b.wav')
        g = qa.mlx_whisper.transcribe(f'{t}/b.wav', path_or_hf_repo=qa.M, language='pt', condition_on_previous_text=False)['text'].strip()
    return g, difflib.SequenceMatcher(None, qa.norm(text), qa.norm(g)).ratio()


def lost(src, key):
    """자르기로 말 길이의 15% 넘게 잃으면 True."""
    with tempfile.TemporaryDirectory() as t:
        pack.clip(src, key, f'{t}/a.wav'); x = pcm(src); kept = len(pcm(f'{t}/a.wav')) / 16000
    m = len(x) // 160; db = 20 * np.log10(np.maximum(np.abs(x[:m * 160]).reshape(m, 160).max(1), 1e-5))
    return kept < 0.85 * float((db > db.max() - 30).sum() * .01)


def main():
    work = sys.argv[1]; wav = f'{work}/wav'; Q = json.load(open(f'{wav}/qa.json', encoding='utf-8')); out = []
    T = [(f'{ep}/{n}', t) for ep in open(f'{work}/done.txt').read().split() for n, _, _, t in L.seg_files(ep)]
    sus = T if '--all' in sys.argv else [(k, t) for k, t in T if lost(f'{wav}/{k}', k)]
    print('조각', len(T), '의심', len(sus), flush=True)
    for k, t in sus:
        if os.getloadavg()[0] > 20:
            print('부하 20 넘어 멈춤'); break
        g, s = packed_score(f'{wav}/{k}', k, t); out.append({'k': k, 'text': t, 'got': g, 'sim': round(s, 3), 'qa_ok': Q.get(k, {}).get('ok')})
        if s < 0.85:
            print(k, repr(t), round(s, 2), repr(g), 'qa 통과' if out[-1]['qa_ok'] else 'qa 불합격', flush=True)
    json.dump(out, open(f'{work}/packqa.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print('묶은 뒤 0.85 미만', sum(o['sim'] < .85 for o in out), '그중 qa 통과', sum(o['sim'] < .85 and bool(o['qa_ok']) for o in out))


if __name__ == '__main__':
    main()
