#!/usr/bin/env bash
# cryo background generator

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${SCRIPT_DIR}/background.png"

PALETTE_CANDIDATES=(
  "${CRYO_PALETTE:-}"
  "${SCRIPT_DIR}/../../../theme/.config/theme/colors.sh"
)
PALETTE=""
for cand in "${PALETTE_CANDIDATES[@]}"; do
  [ -n "$cand" ] && [ -r "$cand" ] && PALETTE="$cand" && break
done
if [ -n "$PALETTE" ]; then
  # shellcheck disable=SC1090
  source "$PALETTE"
else
  CRYO_BASE="#303446"
  CRYO_ACCENT_TEAL="#5eead4"
  CRYO_ACCENT_INDIGO="#818cf8"
fi

W=2560
H=1440

magick -size "${W}x${H}" \
  xc:"${CRYO_BASE}" \
  \( -size "${W}x${H}" radial-gradient:"${CRYO_ACCENT_TEAL}-none" \
  -gravity SouthWest -extent "${W}x${H}" \
  -evaluate multiply 0.18 \) -compose Screen -composite \
  \( -size "${W}x${H}" radial-gradient:"${CRYO_ACCENT_INDIGO}-none" \
  -gravity NorthEast -extent "${W}x${H}" \
  -evaluate multiply 0.10 \) -compose Screen -composite \
  \( -size "${W}x${H}" xc:gray50 +noise random -channel R -separate +channel \
  -evaluate multiply 0.04 \) -compose Screen -composite \
  "$OUT"

echo "Generated: $OUT"
