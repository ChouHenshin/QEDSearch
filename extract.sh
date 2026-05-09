#!/usr/bin/env bash
set -euo pipefail

srcs=("$@")
[[ ${#srcs[@]} -eq 0 ]] && srcs=(IA IB)

extract_pdf() {
  local pdf="$1" out_dir="$2"
  mkdir -p "$out_dir"
  [[ -n $(ls -A "$out_dir" 2>/dev/null) ]] && return

  local tmp
  tmp=$(mktemp --suffix=.pdf)

  # --skip-text: OCR scanned pages, leave pages that already have a text layer alone.
  # Fall back to the original if ocrmypdf fails for any reason.
  if ocrmypdf --skip-text --quiet "$pdf" "$tmp" 2>/dev/null; then
    local src="$tmp"
  else
    local src="$pdf"
  fi

  local pages
  pages=$(pdfinfo "$src" | awk '/^Pages:/ {print $2}')
  for p in $(seq 1 "$pages"); do
    pdftotext -layout -f "$p" -l "$p" "$src" "$out_dir/page-$(printf '%02d' "$p").txt"
  done

  rm -f "$tmp"
  echo "$pdf ($pages pages)"
}

for SRC in "${srcs[@]}"; do
  [[ -d "$SRC" ]] || continue
  DEST="extracted/$SRC"

  while IFS= read -r pdf; do
    rel="${pdf#$SRC/}"
    out_dir="$DEST/${rel%.pdf}"
    extract_pdf "$pdf" "$out_dir"
  done < <(find "$SRC" -name '*.pdf')
done
