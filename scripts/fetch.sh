#!/bin/sh
# Content downloader. Runs inside a throwaway alpine container:
#
#   docker compose run --rm fetch kiwix <name-or-url>
#       name: a Kiwix ZIM name without the date, e.g.
#             wikipedia_en_100_mini   wikipedia_en_all_nopic
#             gutenberg_en_all        wiktionary_en_all_nopic
#             (browse https://download.kiwix.org/zim/ for more)
#       url:  a full https://...zim link
#
#   docker compose run --rm fetch maps <url-to-.mbtiles>
#   docker compose run --rm fetch files <url>
#
# Downloads resume if interrupted, and land as *.part until complete
# so Kiwix never loads a half-written file.
set -eu

usage() { sed -n '2,16p' "$0"; exit 1; }
[ $# -ge 2 ] || usage

kind="$1"; what="$2"
case "$kind" in
  kiwix) dest=/data/kiwix ;;
  maps)  dest=/data/maps ;;
  files) dest=/data/files ;;
  *) usage ;;
esac
mkdir -p "$dest"

case "$what" in
  http://*|https://*) url="$what" ;;
  *)
    [ "$kind" = kiwix ] || { echo "For $kind, give a full URL."; exit 1; }
    category="${what%%_*}"
    index="https://download.kiwix.org/zim/$category/"
    echo "Looking up latest '$what' in $index"
    file=$(wget -qO- "$index" | grep -o "${what}_[0-9][0-9-]*\.zim" | sort -u | tail -n 1 || true)
    [ -n "$file" ] || { echo "Not found. Check the name at $index"; exit 1; }
    url="$index$file"
    ;;
esac

name=$(basename "$url")
if [ -f "$dest/$name" ]; then echo "Already have $name"; exit 0; fi

echo "Downloading $url"
wget -c -O "$dest/$name.part" "$url"
mv "$dest/$name.part" "$dest/$name"
echo "Done: $dest/$name"
