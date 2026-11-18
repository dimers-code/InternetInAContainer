# Kolibri has no maintained official image, so we build a small one from PyPI.
FROM python:3.12-slim

ARG KOLIBRI_VERSION=0.19.5
RUN pip install --no-cache-dir "kolibri==${KOLIBRI_VERSION}" \
 && useradd --create-home --uid 1000 kolibri \
 && mkdir -p /kolibrihome && chown kolibri:kolibri /kolibrihome

ENV KOLIBRI_HOME=/kolibrihome \
    KOLIBRI_HTTP_PORT=8080 \
    KOLIBRI_URL_PATH_PREFIX=/kolibri/ \
    PYTHONUNBUFFERED=1

USER kolibri
VOLUME ["/kolibrihome"]
EXPOSE 8080
CMD ["kolibri", "start", "--foreground"]
