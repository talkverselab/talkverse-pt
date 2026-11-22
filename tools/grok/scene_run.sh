#!/bin/zsh
# 장면 컷 회차(11-22): 요청문 data/review/scene/<편>[_f]_prompt.md → 그림 data/review/scene/<편>[_f]/img1~4.jpg. 방 하나에 이어서, 첫 요청만 시트 첨부.
#   zsh tools/grok/scene_run.sh [편...]   (없으면 요청문 전부) — 크롬 규칙: 끝나면 9260 크롬을 끈다(chrome-usage-rule)
cd "$(dirname "$0")/../.."
ids=(${@:-$(ls data/review/scene/*_prompt.md | xargs -n1 basename | sed 's/_prompt.md$//')}); chat=""
for id in $ids; do
  d=data/review/scene/$id; [[ -f $d/img4.jpg ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then r=$(python3 tools/grok/grok_img.py data/review/scene/${id}_prompt.md $d.md --img $d --attach data/review/art/chars_pt_v1.jpg --maxwait 300 2>&1)
  else r=$(python3 tools/grok/grok_img.py data/review/scene/${id}_prompt.md $d.md --img $d --chat "$chat" --maxwait 300 2>&1); fi
  rc=$?; echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E 'IMGS|LIMIT|TIMEOUT|NOTFAST' | tr '\n' ' ') 장수 $(ls $d 2>/dev/null | wc -l)"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c && $c == *"/c/"* ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
