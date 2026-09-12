# pomostats.app

The landing page for **PomoStats** — App Store Connect stats on Android.

**[Get it on Google Play](https://play.google.com/store/apps/details?id=com.prof18.pomostats)**

A static page — `index.html` plus three files in `assets/`. No build step, no dependencies.

```bash
python3 -m http.server 8000
```

## Deploying

GitHub Pages serves `main` at <https://pomostats.app>. Pushing publishes; there is no CI.

Two files are load-bearing and should not be deleted:

- **`CNAME`** — the custom domain. Without it the site reverts to `prof18.github.io/pomostats-site`.
- **`.nojekyll`** — without it GitHub runs the tree through Jekyll, which silently ignores
  any path starting with an underscore.

DNS is in Cloudflare but **DNS-only, never proxied** — proxying blocks GitHub from validating
the domain, so its certificate never issues.

## Screenshots

Every screenshot is a real capture of the app in demo mode, never a mockup. They come from the
Maestro flow in the app repo; `build-screenshots.sh` converts raw captures into the WebP set,
and `releases-recapture.yaml` re-shoots the one screen that flow frames badly.

```bash
./build-screenshots.sh <raw-takeScreenshot-dir> [...]
```
