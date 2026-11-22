#!/usr/bin/env python3
"""전편 회화 음성 생성 진행기(M6 에서 길게 돈다). 묶음마다: 작업 파일 → PC 생성 → 받아 오기 → 받아쓰기 검사·재생성(두 번까지) → mp4·R2·D1.
  <venv>/bin/python tools/tts/run_all.py <작업폴더> [묶음 크기=6] [--night] [--refs]   --refs = PC 에 없는 참고 음성만 먼저 만들고(VoxCPM, 기존 base 유지) §5 잡음 검사·재생성.   끝난 편은 <작업폴더>/done.txt 에 적히고 다시 돌리면 건너뛴다.
PC 쪽은 작업 스케줄러 'TTS job 2060'(run_job.sh)이 돈다 — 참고 음성 2060, 문장 3090. 중간에 멈춰도 있는 파일은 건너뛰고 이어서 한다."""
import glob, json, os, subprocess, sys, time
import ttslib as L
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
_a = [x for x in sys.argv[1:] if x not in ('--night', '--refs', '--refs-only')]; work = _a[0]; N = int(_a[1]) if len(_a) > 1 else 6
os.makedirs(f'{work}/job', exist_ok=True); os.makedirs(f'{work}/wav', exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    # PC PowerShell 오류문은 한국어 코드페이지(cp949)라 utf-8 로 못 읽으면 실행이 죽었다(11-23 새벽) — 못 읽는 글자는 바꿔 넣는다
    return subprocess.run(a, check=check, capture_output=True, text=True, encoding='utf-8', errors='replace', **k)


def pc_run(kind='moss'):
    """작업 스케줄러를 돌리고 JOB_END 까지 기다린다."""
    while 'Ready' not in sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout:
        time.sleep(30)                     # 앞선 작업(참고 음성 등)이 끝날 때까지
    other = 'vox' if kind == 'moss' else 'moss'
    J = 'D:\\tts_test\\job\\'
    # 작업 파일 이름은 여러 앱 공용(uk 11-22) — 다른 앱이 미리 올려 둔 파일이면 지우지 않고 잠시 옮겼다가 끝나면 되돌린다
    held = False
    o = sh('ssh', PC, f"if (Test-Path {J}{other}_jobs.json) {{ if (Select-String -Path {J}{other}_jobs.json -Pattern 'ref_pt/' -SimpleMatch -Quiet) {{ 'MINE' }} else {{ 'OTHER' }} }} else {{ 'NONE' }}", check=False).stdout
    if 'OTHER' in o:
        sh('ssh', PC, f"Move-Item -Force {J}{other}_jobs.json {J}{other}_jobs.json.held_by_pt"); held = True
        log('다른 앱의', f'{other}_jobs.json', '잠시 옮김')
    elif 'MINE' in o:
        sh('ssh', PC, f"Remove-Item {J}{other}_jobs.json -ErrorAction SilentlyContinue")
    sh('scp', '-q', f'{work}/job/{kind}_jobs.json', f'{PC}:D:/tts_test/job/')
    sh('ssh', PC, "Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    try:
        while True:
            r = sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout
            if 'Ready' in r:
                break
            time.sleep(30)
    finally:
        sh('ssh', PC, f"Remove-Item {J}{kind}_jobs.json -ErrorAction SilentlyContinue", check=False)   # 끝난 pt 작업 파일은 남기지 않는다
        if held:
            sh('ssh', PC, f"Move-Item -Force {J}{other}_jobs.json.held_by_pt {J}{other}_jobs.json", check=False); log('되돌림', f'{other}_jobs.json')


def fetch(path):
    os.makedirs(os.path.dirname(f'{work}/wav/{path}'), exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/pt/{path}', os.path.dirname(f'{work}/wav/{path}') + '/', check=False)



def refs():
    """PC 에 없는 참고 음성만 만들기 → 받아 오기 → 잡음 검사(§5, check_refs.py) → 미달분 seed 바꿔 두 번까지(태국어앱 refs() 이식, 11-22)."""
    os.makedirs(f'{work}/ref_pt', exist_ok=True)
    sh(sys.executable, f'{HERE}/make_jobs.py', f'{work}/job', '--refs')
    have = set(sh('ssh', PC, 'cmd /c dir /b D:\\tts_test\\job\\out\\ref_pt', check=False).stdout.split())
    jobs = [j for j in json.load(open(f'{work}/job/vox_jobs.json')) if os.path.basename(j['out']) not in have]
    log('참고 음성 새로', len(jobs))
    if not jobs:
        return
    json.dump(jobs, open(f'{work}/job/vox_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); pc_run('vox')
    for rnd in range(3):
        sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/ref_pt/*', f'{work}/ref_pt/', check=False)
        r = sh(sys.executable, f'{HERE}/check_refs.py', f'{work}/ref_pt', '--jobs', f'{work}/job/vox_jobs.json', check=False)
        log(r.stdout.strip().splitlines()[-2] if r.stdout.strip().count('\n') else (r.stdout or r.stderr)[-200:])
        jobs = json.load(open(f'{work}/job/vox_jobs.json')) if os.path.exists(f'{work}/job/vox_jobs.json') else []
        if not jobs or rnd == 2:
            break
        t = time.localtime()
        if '--refs-only' in sys.argv and (t.tm_hour, t.tm_min) >= (2, 20):   # 11-23 은 02:30 태국어 차례 — 02:25 전에 비운다(uk)
            log('02:20 지나 참고 음성 재생성 멈춤 — 남은', len(jobs)); break
        for j in jobs:
            j['seed'] = 7 + 31 * (rnd + 1)
        json.dump(jobs, open(f'{work}/job/vox_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0); pc_run('vox')


done = set(open(f'{work}/done.txt').read().split()) if os.path.exists(f'{work}/done.txt') else set()
ids = [e for e in L.planned() if e not in done]
log('남은 편', len(ids))
if '--refs' in sys.argv:
    refs()
if '--refs-only' in sys.argv:
    log('참고 음성만 — 끝'); sys.exit(0)
for i in range(0, len(ids), N):
    if os.path.exists(f'{work}/PAUSE'):      # uk 끼어들기: 묶음 경계에서 멈춤(파일을 지우고 다시 실행하면 이어간다) — 태국어앱과 같게
        log('PAUSE 로 멈춤 — 남은 편', len(ids) - i); sys.exit(0)
    t = time.localtime()
    if '--night' in sys.argv and not (1 <= t.tm_hour < 6 or (t.tm_hour == 6 and t.tm_min < 30)):   # 새벽만, 06:30 이후 새 묶음 금지(uk 3090 배정 11-22)
        log('06:30 지나 멈춤 — 남은 편', len(ids) - i); sys.exit(0)
    eps = ids[i:i + N]
    sh(sys.executable, f'{HERE}/make_jobs.py', f'{work}/job', *eps); pc_run()
    for ep in eps:
        fetch(ep)
    for rnd in range(3):
        # whisper 가 한 파일에서 멈추는 일이 있어(일본어 7시간) 편별 하위 프로세스 + 600초 제한. 넘기면 그 편 재생성본은 버리고 넘어간다.
        tot = 0
        for ep in eps:
            try:
                r = subprocess.run([sys.executable, f'{HERE}/qa.py', f'{work}/wav', ep, '--jobs', f'{work}/job/qa_{ep}.json'], capture_output=True, text=True, timeout=600)
                log(r.stdout.strip() or r.stderr.strip()[-200:])
            except subprocess.TimeoutExpired:
                log('TIMEOUT', ep)
                for f in glob.glob(f'{work}/wav/retake/{ep}/*.wav'):
                    os.remove(f)
        jobs = []
        for ep in eps:
            p = f'{work}/job/qa_{ep}.json'
            if os.path.exists(p):
                jobs += json.load(open(p)); os.remove(p)
        tot = len(jobs)
        if tot == 0:
            break
        json.dump(jobs, open(f'{work}/job/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        pc_run()
        for ep in eps:
            fetch(f'retake/{ep}')
    for ep in eps:
        r = sh(sys.executable, f'{HERE}/pack.py', f'{work}/wav', ep, '--upload', check=False)
        if r.returncode:
            log('실패', ep, (r.stderr or r.stdout)[-300:]); continue
        log(r.stdout.strip()); open(f'{work}/done.txt', 'a').write(ep + '\n')
log('끝')
