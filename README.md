# Internet-in-a-Container

A Docker Compose version of [Internet-in-a-Box](https://internet-in-a-box.org) (IIAB):
an offline library of Wikipedia, courses, books and maps behind one home page.
It runs anywhere Docker runs (Linux, Windows, macOS, Raspberry Pi 4/5).

## Why not just put the IIAB installer in a container?

IIAB installs with Ansible, which configures systemd, networking, the Wi-Fi hotspot
and ~40 apps directly on the host OS, and the IIAB team
[advises against Docker](https://iiab.live/info/Technical-Contributors-Guide.html).
So this project rebuilds IIAB's core apps from their official images and puts
them behind an nginx portal with the same `http://box/<app>` layout.

| Path        | App                     | Profile   | Image |
|-------------|-------------------------|-----------|-------|
| `/`         | Home page               | always on | `nginx:1.27-alpine` |
| `/kiwix/`   | Kiwix (ZIM library)     | always on | `ghcr.io/kiwix/kiwix-tools` |
| `/kolibri/` | Kolibri LMS             | `kolibri` | `ghcr.io/duimstpj/iiab-kolibri` |
| `/books/`   | Calibre-Web             | `books`   | `lscr.io/linuxserver/calibre-web` |
| `/maps/`    | TileServer GL (OSM)     | `maps`    | `maptiler/tileserver-gl` |
| `/files/`   | File share (read-only)  | `files`   | `nginx:1.27-alpine` |

## Quick start

```bash
cp .env.example .env              # choose apps, port, data location
docker compose up -d
docker compose run --rm fetch kiwix wikipedia_en_100_mini   # ~5 MB test ZIM
```

Open http://localhost (or `http://localhost:<HTTP_PORT>`). Kiwix picks up the new
ZIM file within about a minute.

## Adding content

All content lives under `DATA_DIR` (default `./data`):

```
data/
  kiwix/        *.zim files            -> /kiwix/
  kolibri/      Kolibri home (DB + channels)
  books/        a Calibre library (metadata.db + folders)
  calibre-web/  Calibre-Web settings
  maps/         *.mbtiles files        -> /maps/
  files/        anything               -> /files/
```

**Kiwix:** download by name (the latest dated build is chosen for you) or by URL.
You can also copy `.zim` files straight into `data/kiwix`.
```bash
docker compose run --rm fetch kiwix wikipedia_en_all_nopic       # ~50 GB
docker compose run --rm fetch kiwix gutenberg_en_all
docker compose run --rm fetch kiwix https://download.kiwix.org/zim/....zim
```
Browse the catalog at https://download.kiwix.org/zim/. After you **remove** a ZIM,
run `docker compose restart kiwix`.

**Kolibri:** open `/kolibri/`, finish the setup wizard, then import channels from
*Device → Channels* (from Kolibri Studio when online, or from a USB drive/peer).

**Books:** put an existing Calibre library (a folder with `metadata.db`) in
`data/books`, then open `/books/` and log in as `admin` / `admin123`.
**Change that password right away.** Set the library location to `/books`.
To upload or convert books from the web UI, set
`CALIBRE_MODS=linuxserver/mods:universal-calibre` in `.env` (x86-64 only).

**Maps:** drop one or more OpenStreetMap vector `.mbtiles` files into `data/maps`
(for example from MapTiler or OpenMapTiles), enable the `maps` profile, then
run `docker compose up -d`.

## All-in-one image + Cloudflare Tunnel (Portainer)

`ghcr.io/duimstpj/iiab` bundles the portal, Kiwix and Kolibri into one image
(built by `.github/workflows/iiab-image.yml` from `iiab/Dockerfile`).
`portainer-stack.yml` runs it next to `cloudflared`, with nothing to clone.

1. In Cloudflare Zero Trust, go to **Networks → Tunnels → Create a tunnel** (Cloudflared)
   and copy the token. Add a **Public Hostname** whose service is `http://iiab:80`.
2. In Portainer, go to **Stacks → Add stack → Web editor**, paste `portainer-stack.yml`,
   and set `CLOUDFLARE_TUNNEL_TOKEN` (plus `IIAB_DATA=/srv/iiab` if you want
   content in a host folder). Deploy.
3. Add content from Portainer's container console, or from the host:
   ```bash
   docker exec iiab iiab-fetch kiwix wikipedia_en_100_mini
   ```

Calibre-Web and maps aren't in the all-in-one image; use the full Compose stack for those.

## Everyday commands

```bash
docker compose ps                       # what's running
docker compose logs -f kiwix            # watch an app
docker compose pull && docker compose up -d   # update
docker compose down                     # stop (content stays in data/)
```

## Deploying somewhere else / offline

Content is just files in `DATA_DIR`, and the images can be moved without internet:

```bash
# on a connected machine
docker compose pull
docker save $(docker compose config --images) -o iiab-images.tar
# copy iiab-images.tar + this folder + data/ to the target, then:
docker load -i iiab-images.tar
docker compose up -d
```

## Kolibri image

Kolibri has no maintained official image, so this repo builds one from PyPI
([kolibri/Dockerfile](kolibri/Dockerfile)) and publishes it to GitHub Container
Registry for amd64 and arm64 via [a GitHub Actions workflow](.github/workflows/kolibri-image.yml).
It rebuilds when `kolibri/` changes on `main`. To publish another Kolibri version,
run the workflow from the Actions tab with that version, then set
`KOLIBRI_VERSION` in `.env`.

If the image can't be pulled, `docker compose up` builds it locally instead.
To always build it yourself, run `docker compose build kolibri`.

## Notes and limits

- **Wi-Fi hotspot / `box.lan`:** not included. Containers can't easily run a Wi-Fi
  access point. Run the host as a hotspot, or point your router's DNS at it,
  and devices nearby can reach the portal.
- **Windows/macOS performance:** Docker Desktop reads bind-mounted Windows/macOS
  folders slowly. For large ZIM libraries, set `DATA_DIR` to a path inside WSL2
  (for example `/home/you/iiab-data`) or a Linux disk.
- **Port 80 taken?** Set `HTTP_PORT=8080` in `.env`.
- **Line endings:** `.gitattributes` keeps `*.sh` files as LF. If you edit them
  on Windows, make sure your editor keeps LF line endings.

## License

The files in this repository are released into the public domain under
[The Unlicense](LICENSE). The apps this stack runs (Kiwix, Kolibri, Calibre-Web,
TileServer GL, nginx) keep their own licenses. Several are GPL, so if you
redistribute the container images themselves (e.g. a `docker save` tarball),
follow those projects' terms.
