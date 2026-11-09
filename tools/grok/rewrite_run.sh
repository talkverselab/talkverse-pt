#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9260, 전문가 모드). 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄(사용자 지시 11-09 프롬프트 최소화).
#   zsh tools/grok/rewrite_run.sh <편id>...     결과 data/review/grok/out/<id>.md
# 전: python3 tools/grok/pt_dialogue_txt.py export / 후: python3 tools/grok/pt_dialogue_txt.py import → build_dialogues.py → make_plan.py
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9260
first=/private/tmp/claude-501/grok_pt_first.txt
mkdir -p data/review/grok/out
chat=""
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rewrite_grok_pt.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > $first
    r=$(python3 tools/grok/grok_text.py $first $out tools/grok/rewrite_grok_pt.md data/review/grok/src/$id.txt 2>&1)
  else
    r=$(python3 tools/grok/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|전문가|Error|오류' | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
