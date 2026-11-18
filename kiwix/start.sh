#!/bin/sh
# Builds a Kiwix library from every .zim in /data and serves it.
# New .zim files dropped into data/kiwix are picked up within a minute.
set -u

DATA="${KIWIX_DATA:-/data}"
LIB=/tmp/library.xml
ROOT="${KIWIX_URL_ROOT:-/kiwix}"

have_zims() { ls "$DATA"/*.zim >/dev/null 2>&1; }

add_new_zims() {
  for z in "$DATA"/*.zim; do
    [ -f "$z" ] || continue
    grep -qF "$(basename "$z")" "$LIB" 2>/dev/null && continue
    echo "[kiwix] adding $(basename "$z")"
    kiwix-manage "$LIB" add "$z" || echo "[kiwix] WARNING: could not add $z (corrupt or incomplete?)"
  done
}

until have_zims; do
  echo "[kiwix] no .zim files in data/kiwix yet; checking again in 30s"
  echo "[kiwix]   try: docker compose run --rm fetch kiwix wikipedia_en_100_mini"
  sleep 30
done

rm -f "$LIB"
add_new_zims

# Watch for new files; --monitorLibrary makes kiwix-serve reload the library.
( while sleep 60; do add_new_zims; done ) &

exec kiwix-serve --library --monitorLibrary \
  --urlRootLocation="$ROOT" --port="${KIWIX_PORT:-8080}" "$LIB"
