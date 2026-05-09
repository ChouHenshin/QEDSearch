#!/usr/bin/env bash
set -euo pipefail

scrape_part() {
  local part="$1" prefix="$2" count="$3"
  local base="https://cribs-static.pages.dev/$part/tripos"
  for n in $(seq 1 "$count"); do
    mkdir -p "$part/${prefix}$n"
    for m in {1996..2025}; do
      out="$part/${prefix}${n}/QP_$m.pdf"
      [[ -s $out ]] && continue
      curl -fsSL -o "$out" "$base/${prefix}${n}/QP_$m.pdf" || rm -f "$out"
      echo "$base/${prefix}${n}/QP_$m.pdf"
    done
  done
}

scrape_part IA 1P 4
scrape_part IB 2P 8
