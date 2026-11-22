#!/bin/zsh
# 새벽 음성(uk 3090 배정, 11-22): zsh tools/tts/night_pt.sh <날짜 DD> [시작 HHMM=0340] [--refs-only]
#   --refs-only = 참고 음성(VoxCPM, 2060)만 — 3090 을 기다리지 않는다.
#   그 날 시작 시각까지 기다림 → 3090 8GB 미만일 때 시작 → 06:30 PAUSE(새 묶음 금지) → 06:55 전에 비움. 이어받기는 done.txt.
D=$1; T=${2:-0340}; RO=$3; W=~/tts_work/pt; cd "$(dirname "$0")/../.."
until [[ $(date +%d) == $D && $(date +%H%M) -ge $T ]]; do sleep 30; done
if [[ $RO == --refs-only ]]; then ~/.venvs/tts_zh/bin/python tools/tts/run_all.py $W 3 --refs --refs-only --night >> $W/run.log 2>&1; echo "$(date +%T) 참고 음성 끝 rc=$?"; tail -3 $W/run.log; exit; fi
ok=0
while :; do
  (( $(date +%H%M) >= 0630 )) && { echo "$(date +%T) 06:30 까지 3090 안 비워짐 — 쉼"; exit 2; }
  mem=$(ssh pc 'nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits -i 0' | tr -d ' \r')
  if [[ -n $mem ]] && (( mem < 8192 )); then ok=$((ok + 1)); else ok=0; fi
  (( ok >= 5 )) && break   # 5분 연속 비어야 시작 — 앞 언어(인도네시아어) 묶음 사이 틈에 끼어들지 않게(uk 11-22)
  echo "$(date +%T) 3090 ${mem}MiB — 대기($ok/5)"; sleep 60
done
echo "$(date +%T) 3090 ${mem}MiB 시작"
rm -f $W/PAUSE
( until [[ $(date +%H%M) -ge 0630 ]]; do sleep 30; done; touch $W/PAUSE; echo "$(date +%T) PAUSE 06:30" >> $W/run.log ) &
pw=$!
~/.venvs/tts_zh/bin/python tools/tts/run_all.py $W 3 --refs --night >> $W/run.log 2>&1
rc=$?
kill $pw 2>/dev/null
echo "$(date +%T) run_all exit $rc"; tail -6 $W/run.log; echo "끝난 편: $(grep -c . $W/done.txt) / 65"
