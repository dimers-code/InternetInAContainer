# All-in-one Internet-in-a-Container image: portal (nginx) + Kiwix + Kolibri.
# Build from the repo root:  docker build -f iiab/Dockerfile -t iiab .
FROM python:3.12-slim-bookworm

ARG TARGETPLATFORM
ARG KOLIBRI_VERSION=0.19.5
# Leave blank for the latest kiwix-tools release, or pin e.g. 3.8.1
ARG KIWIX_TOOLS_VERSION=

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx tini wget ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# Kiwix: official static binaries
RUN set -e; \
    case "${TARGETPLATFORM:-linux/amd64}" in \
      linux/amd64*)            arch=x86_64 ;; \
      linux/arm64*)            arch=aarch64 ;; \
      linux/arm/v7)            arch=armv8 ;; \
      linux/arm/v6)            arch=armv6 ;; \
      *) echo "Unsupported platform: $TARGETPLATFORM"; exit 1 ;; \
    esac; \
    file="kiwix-tools_linux-${arch}${KIWIX_TOOLS_VERSION:+-$KIWIX_TOOLS_VERSION}.tar.gz"; \
    wget -qO /tmp/kiwix.tgz "https://download.kiwix.org/release/kiwix-tools/$file"; \
    tar -xzf /tmp/kiwix.tgz -C /usr/local/bin --strip-components=1; \
    rm /tmp/kiwix.tgz; \
    kiwix-serve --version

# Kolibri
RUN pip install --no-cache-dir "kolibri==${KOLIBRI_VERSION}" \
 && useradd --create-home --uid 1000 kolibri

COPY iiab/nginx.conf          /etc/nginx/conf.d/iiab.conf
COPY portal/proxy.conf        /etc/nginx/snippets/proxy.conf
COPY portal/html/             /usr/share/nginx/html/
COPY kiwix/start.sh           /usr/local/bin/kiwix-start
COPY scripts/fetch.sh         /usr/local/bin/iiab-fetch
COPY iiab/entrypoint.sh       /usr/local/bin/iiab-entrypoint
RUN chmod +x /usr/local/bin/kiwix-start /usr/local/bin/iiab-fetch /usr/local/bin/iiab-entrypoint

ENV ENABLE_KOLIBRI=true \
    PYTHONUNBUFFERED=1

VOLUME ["/data"]
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/iiab-entrypoint"]
