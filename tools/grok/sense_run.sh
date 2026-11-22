#!/bin/zsh
# 언어감각 10급 Grok 회차(11-22) — 뼈대 data/review/grok/sense/<L>.txt(규칙이 뼈대 끝에 있음) → data/review/grok/out/sense_<L>.md. 한 방에 10급.
#   zsh tools/grok/sense_run.sh [L1 ...]   뒤: python3 tools/grok/sense_specs_1122.py apply
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9260
first=/private/tmp/claude-501/grok_pt_sense_first.txt
ids=(${@:-L1 L2 L3 L4 L5 L6 L7 L8 L9 L10}); chat=""
for id in $ids; do
  out=data/review/grok/out/sense_$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 뼈대 끝의 규칙이 이 방의 규칙이다. 빈칸을 채워 같은 형식으로만 답한다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > $first
    r=$(python3 tools/grok/grok_text.py $first $out data/review/grok/sense/$id.txt 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$id.txt" $out data/review/grok/sense/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|TIMEOUT|Error|오류" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
