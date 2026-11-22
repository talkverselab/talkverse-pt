#!/bin/zsh
# 새벽 음성(uk 3090 배정, 11-22): zsh tools/tts/night_pt.sh <날짜 DD> [시작 HHMM=0340]
#   그 날 시작 시각까지 기다림 → 3090 8GB 미만일 때 시작 → 06:30 PAUSE(새 묶음 금지) → 06:55 전에 비움. 이어받기는 done.txt.
D=$1; T=${2:-0340}; W=~/tts_work/pt; cd "$(dirname "$0")/../.."
until [[ $(date +%d) == $D && $(date +%H%M) -ge $T ]]; do sleep 30; done
while :; do
  (( $(date +%H%M) >= 0630 )) && { echo "$(date +%T) 06:30 까지 3090 안 비워짐 — 쉼"; exit 2; }
  mem=$(ssh pc 'nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits -i 0' | tr -d ' \r')
  [[ -n $mem ]] && (( mem < 8192 )) && break
  echo "$(date +%T) 3090 ${mem}MiB — 대기"; sleep 60
done
echo "$(date +%T) 3090 ${mem}MiB 시작"
rm -f $W/PAUSE
( until [[ $(date +%H%M) -ge 0630 ]]; do sleep 30; done; touch $W/PAUSE; echo "$(date +%T) PAUSE 06:30" >> $W/run.log ) &
pw=$!
~/.venvs/tts_zh/bin/python tools/tts/run_all.py $W 3 --refs --night >> $W/run.log 2>&1
rc=$?
kill $pw 2>/dev/null
echo "$(date +%T) run_all exit $rc"; tail -6 $W/run.log; echo "끝난 편: $(grep -c . $W/done.txt) / 65"
