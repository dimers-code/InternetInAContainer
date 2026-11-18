#!/bin/sh
# Starts Kiwix and Kolibri in the background (restarting them if they crash),
# then runs nginx in the foreground as the container's main process.
set -eu

mkdir -p /data/kiwix /data/kolibri /data/files /data/maps

supervise() {
  name="$1"; shift
  (
    while true; do
      "$@" || true
      echo "[$name] exited; restarting in 5s"
      sleep 5
    done
  ) &
}

supervise kiwix env KIWIX_DATA=/data/kiwix KIWIX_PORT=8081 KIWIX_URL_ROOT=/kiwix \
  /usr/local/bin/kiwix-start

if [ "${ENABLE_KOLIBRI}" = "true" ]; then
  [ "$(stat -c %u /data/kolibri)" = "1000" ] || chown -R 1000:1000 /data/kolibri
  supervise kolibri setpriv --reuid=1000 --regid=1000 --init-groups \
    env HOME=/home/kolibri KOLIBRI_HOME=/data/kolibri KOLIBRI_HTTP_PORT=8082 \
        KOLIBRI_URL_PATH_PREFIX=/kolibri/ \
    sh -c 'rm -f /data/kolibri/server.pid; exec kolibri start --foreground'
else
  echo "[kolibri] disabled (ENABLE_KOLIBRI=$ENABLE_KOLIBRI)"
fi

echo "[portal] serving on port 80"
exec nginx -g 'daemon off;'
