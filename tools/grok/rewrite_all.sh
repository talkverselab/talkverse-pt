#!/bin/zsh
# 남은 편을 10편씩 방을 새로 열어 차례로(한도 문구가 나오면 멈춤).
cd "$(dirname "$0")/../.."
ids=($(ls data/review/grok/src | sed 's/.txt$//' | sort))
todo=(); for i in $ids; do [[ -s data/review/grok/out/$i.md ]] || todo+=$i; done
echo "남은 편 ${#todo}"
for ((k = 1; k <= ${#todo}; k += 10)); do
  zsh tools/grok/rewrite_run.sh ${todo[k,k+9]} || { echo "멈춤(한도 등)"; exit 3; }
done
echo "전부 끝"
