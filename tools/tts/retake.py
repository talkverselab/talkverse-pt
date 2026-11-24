#!/usr/bin/env python3
"""qa.json 에서 불합격(ok=false)인 조각만 새 seed 로 다시 만든다(run_all 은 끝난 편을 건너뛰고 세 번 다 쓴 조각은 다시 안 만든다).
  <venv>/bin/python tools/tts/retake.py <작업폴더> [--go] [--rounds 3]     --go 없으면 작업 목록만 <작업폴더>/job/retake_plan.json 에 쓰고 끝(3090 안 씀)
번호는 t4 부터(seed 42+97×번호) — t1~t3 은 이미 쓴 seed 라 같은 결과가 나온다. 옛 재생성본은 보지 않는다.
합격 = 받아쓰기 0.85 이상 + 말 뒤 잡소리 없음(tail()) + 묶은 뒤 받아쓰기 0.85 이상(packqa — 작게 나온 조각이 묶을 때 잘리는 것을 막음). 합격본만 본 파일로 바꾸고(원래 것은 <작업폴더>/retake_bak) 묶어 올리기는 따로 한다(바뀐 편 이름을 출력).
PAUSE 파일이 있으면 회차 경계에서 멈춘다."""
import json, os, shutil, subprocess, sys, time
import numpy as np
A = [a for a in sys.argv[1:] if not a.startswith('--')]; GO = '--go' in sys.argv
ROUNDS = int(A[1]) if len(A) > 1 else 3
sys.argv = [sys.argv[0], A[0]]
import run_all as RA, ttslib as L, qa, packqa   # noqa: E402
work = A[0]; wav = f'{work}/wav'; log = RA.log


def tail(f):
    """말 뒤 0.4초 넘는 쉼 다음에 0.35초 이하 소리(조각 최대 -15dB 안쪽)로 끝나면 True(11-24)."""
    x = np.frombuffer(subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-f', 'f32le', '-ac', '1', '-ar', '16000', '-'], capture_output=True).stdout, dtype=np.float32)
    m = len(x) // 160
    if m < 10:
        return False
    db = 20 * np.log10(np.maximum(np.abs(x[:m * 160]).reshape(m, 160).max(1), 1e-5)); mx = db.max(); segs = []
    for i in np.where(db > -45)[0]:
        if segs and i - segs[-1][1] < 10:
            segs[-1][1] = i + 1
        else:
            segs.append([i, i + 1])
    segs = [s for s in segs if db[s[0]:s[1]].max() > mx - 30]
    if len(segs) < 2:
        return False
    a, b = segs[-2], segs[-1]
    return (b[0] - a[1]) > 40 and (b[1] - b[0]) <= 35 and db[b[0]:b[1]].max() > mx - 15


def main():
    Q = json.load(open(f'{wav}/qa.json', encoding='utf-8')); done = open(f'{work}/done.txt').read().split()
    todo = {f'{ep}/{n}': (v, e, t) for ep in done for n, v, e, t in L.seg_files(ep) if not Q.get(f'{ep}/{n}', {}).get('ok')}
    job = lambda k, n: {'out': f'pt/retake/{k[:-4]}.t{n}.wav', 'text': todo[k][2], 'language': 'Portuguese', 'reference': f'out/ref_pt/{todo[k][0]}_{todo[k][1]}.wav', 'seed': 42 + 97 * n}
    log('다시 만들 조각', len(todo), '편', len({k.split('/')[0] for k in todo}))
    if not GO:
        json.dump([job(k, 4) for k in todo], open(f'{work}/job/retake_plan.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); return
    changed = set()
    for n in range(4, 4 + ROUNDS):
        left = [k for k in todo if not Q.get(k, {}).get('ok')]
        if not left or os.path.exists(f'{work}/PAUSE'):
            break
        json.dump([job(k, n) for k in left], open(f'{work}/job/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); RA.pc_run()
        for k in left:
            ep, name = k.split('/'); c = f'{wav}/retake/{k[:-4]}.t{n}.wav'
            os.makedirs(os.path.dirname(c), exist_ok=True)
            RA.sh('scp', '-q', f'{RA.PC}:D:/tts_test/job/out/pt/retake/{k[:-4]}.t{n}.wav', c, check=False)
            if not os.path.exists(c):
                log('없음', k, n); continue
            s, d = qa.score(c, todo[k][2]); bad = tail(c)
            g, p = packqa.packed_score(c, 'retake/' + k, todo[k][2]) if s >= 0.85 and not bad else ('', 0.0)   # 새 조각에는 조각별 예외(trim_rel)를 쓰지 않는다
            log(k, f't{n}', round(s, 2), '묶은 뒤', round(p, 2), repr(g), '잡소리' if bad else '')
            if s >= 0.85 and not bad and p >= 0.85:
                b = f'{work}/retake_bak/{k}'; os.makedirs(os.path.dirname(b), exist_ok=True)
                if not os.path.exists(b):
                    shutil.copy2(f'{wav}/{k}', b)
                shutil.copy(c, f'{wav}/{k}'); q = Q[k]; q.pop('manual', None); q.pop('sim_auto', None)
                q.update(sim=s, dur=d, ok=True, tries=n, mtime=int(os.path.getmtime(f'{wav}/{k}')), text=todo[k][2]); changed.add(ep)
        json.dump(Q, open(f'{wav}/qa.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    log('끝 — 아직 불합격', sum(not Q.get(k, {}).get('ok') for k in todo), '바뀐 편', ' '.join(sorted(changed)))


if __name__ == '__main__':
    main()
