#!/usr/bin/env bash
# Turn raw Maestro demo-mode captures into the WebP set the landing page ships.
#
# The captures come from .maestro/raw-screenshots.yaml run against a device in
# gesture-nav + SysUI demo mode (clean 9:41 status bar, no three-button bar) —
# see README.md § Screenshots for the exact recipe.
#
# Usage:  ./build-screenshots.sh <raw-dir> [<raw-dir> ...]
# Later directories win, so you can layer a re-capture over an earlier run.

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <raw-takeScreenshot-dir> [...]" >&2
  exit 64
fi

# Resolve the argument directories against the caller's cwd BEFORE moving to
# the script's own directory, so relative paths work from anywhere.
ABS=()
for d in "$@"; do
  [ -d "$d" ] || { echo "not a directory: $d" >&2; exit 66; }
  ABS+=("$(cd "$d" && pwd)")
done

cd "$(dirname "$0")"
OUT="assets/screenshots"
mkdir -p "$OUT"

# published name → raw capture basename
names=(home       analytics        reviews          proceeds                 countries              releases              demo)
srcs=(03-home-portfolio 05-app-detail-dau 19-reviews-inbox 10-app-detail-sales-history 09-app-detail-countries 08-app-detail-releases 02-onboarding-demo-entry)

# The hero is rendered at 348 CSS px, the rest at 300. 1080 / 900 keeps both at 3x.
widths=(1080 900 900 900 900 900 900)

DIRS=("${ABS[@]}")

# Last directory containing the capture wins, so a re-capture layers over an
# earlier run without having to delete anything.
find_src() {
  local base="$1" dir hit=""
  for dir in "${DIRS[@]}"; do
    [ -f "$dir/$base.png" ] && hit="$dir/$base.png"
  done
  printf '%s' "$hit"
}

missing=0
for i in "${!names[@]}"; do
  name="${names[$i]}"
  src="$(find_src "${srcs[$i]}")"
  w="${widths[$i]}"

  if [ -z "$src" ]; then
    echo "MISSING  $name  (no ${srcs[$i]}.png in any given directory)" >&2
    missing=$((missing + 1))
    continue
  fi

  tmp="$(mktemp -t pomoshot).png"
  cp "$src" "$tmp"
  sips --resampleWidth "$w" "$tmp" --out "$tmp" >/dev/null
  cwebp -quiet -q 82 -m 6 -sharp_yuv "$tmp" -o "$OUT/$name.webp"
  rm -f "$tmp"

  printf '%-10s %-30s %s\n' "$name" "$(basename "$src")" "$(du -h "$OUT/$name.webp" | cut -f1)"
done

echo
echo "written to $OUT"
[ "$missing" -eq 0 ] || { echo "$missing missing — rerun the Maestro flow for those screens." >&2; exit 1; }
