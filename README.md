# PomoStats — landing page

A single static page. No build step, no dependencies, no framework: `index.html` plus three
files in `assets/`. Open it in a browser and it works.

```
pomostats-site/
├── index.html              the page
├── assets/
│   ├── styles.css          design tokens + layout
│   ├── main.js             sticky-header hairline + scroll reveal (the only JS)
│   ├── favicon.svg         the launcher mark on a cream ground
│   ├── apple-touch-icon.png
│   ├── og-image.jpg        1200×630 social card
│   ├── og-image.src.html   the template it was rendered from (see below)
│   ├── logo/               1024x1024 logo, three grounds + their SVG sources
│   └── screenshots/*.webp  demo-mode captures, built by build-screenshots.sh
├── build-screenshots.sh    raw Maestro captures → the WebP set
├── releases-recapture.yaml Maestro flow for the one badly-framed capture
├── robots.txt
├── sitemap.xml
├── site.webmanifest
├── CNAME                   the custom domain, read by GitHub Pages
└── .nojekyll               serve the tree verbatim, no Jekyll processing
```

Preview it with any static server:

```bash
python3 -m http.server 8000
```

---

## The domain

**`https://pomostats.app`** — confirmed 12 September 2026. Every absolute URL already uses
it: the canonical link, `og:url`, `og:image`, `twitter:image`, the JSON-LD `@id`s and
`screenshot` array, `sitemap.xml` and `robots.txt`. Nothing needs swapping before deploying.

If it ever does change, one command covers all three files:

```bash
grep -rl 'pomostats\.app' . | xargs sed -i '' 's|pomostats\.app|NEW-DOMAIN|g'
grep -rn 'pomostats\.app' .   # confirm nothing was missed
```

Two things to keep right:

- **Trailing slash.** The homepage is `https://pomostats.app/` everywhere. If `canonical`
  and `og:url` disagree on it, they are two URLs as far as a crawler is concerned.
- **`.app` is an HSTS-preloaded TLD.** Google operates it and the whole TLD is on the
  preload list, so browsers refuse plain `http://` on this domain — HTTPS is not a choice
  you have to make, and any `http://` URL introduced here is simply broken. Cloudflare
  terminates TLS for you, so there is nothing to configure; just never write `http://`.

---

## Design

The page does not invent a visual language. It ports the app's own — direction **"1c
Harvest"** from
`docs/design/HANDOFF.md` in the app repo — so the site and the screenshots on
it read as one thing:

| | |
|---|---|
| Display | **Fraunces** 600, optical size tuned per level |
| Body | **Inter Tight** 400–700 |
| Labels | **IBM Plex Mono** 500, uppercase, letter-spaced |
| Field | `#EFEBDF` light · `#0F140F` dark |
| Paper (cards) | `#FBF9F2` · `#18211A` |
| Panel (the dark slab) | `#1C2620` · `#18211A` |
| Accent | `#D8483C` · `#E4544A` |
| Leaf / positive | `#35734A` · `#7CC98B` |

Every colour in `styles.css` comes from the `themes(dark)` object in
`docs/design/PomoStats.dc.html` in the app repo, with one deliberate
exception, noted in the file. The app's `sub` token does not clear WCAG AA for body-size
text on the field colour, so the site uses its own value at both ends:

| | app token | site token | contrast on the field |
|---|---|---|---|
| light `--ink-sub` | `#8a927f` (2.71:1) | `#616659` | **4.96:1** — and 4.57:1 on the deeper band |
| dark `--ink-sub` | `#7d887e` (5.05:1) | `#93a094` | **6.83:1** |

That token carries the mono eyebrows, the header nav, the fineprint and the footer, so it is
the one that had to move. Every other text pair in both themes clears AA unchanged — the
lowest is the panel's own sub at 5.80:1.

**The theme follows the device and nothing else.** There is no in-page switch: the dark
palette is defined in exactly one `@media (prefers-color-scheme: dark)` block and the page
has no `data-theme` attribute, no stored preference and no theme JavaScript. That is why
dark mode cannot flash or disagree with itself — CSS resolves it before the first paint and
nothing later overrides it.

If a toggle is ever wanted back, it needs three things in step: a `:root[data-theme="dark"]`
block duplicating the token values, the same override guarded onto the media query
(`:root:not([data-theme="light"])`) so an explicit light choice wins over a dark OS, and an
inline head script applying the stored value before paint. Re-adding only the button is what
produces a flash of the wrong theme.

The device frame is the app design's own phone frame — 9px bezel, 42px radius — drawn in
CSS rather than shipped as an image, so it stays crisp and costs nothing.

### The scroll reveal is progressive enhancement, on purpose

`main.js` fades sections in as they arrive. The hidden state that makes that possible is
scoped to a `.js` class which the inline head script adds to `<html>` — so
`.js .reveal { opacity: 0 }` only ever applies in a browser that is actually running the
script. Without JS, or if `main.js` fails to load, nothing is hidden and the page is simply
a static page. Don't un-scope that selector: an unscoped `opacity: 0` turns a JS failure
into a completely blank page.

`prefers-reduced-motion: reduce` skips the animation entirely and shows everything at once.

---

## Screenshots

Every screenshot on the page is a real capture of the app in **demo mode** on a Pixel 4 XL
(1440×3040) — nothing is a mockup or a retouched frame. They were produced by the repo's own
Maestro flow with the device put into a clean state first.

The recipe, in full:

```bash
# 1. gesture navigation, so there is no three-button bar in the frame
adb shell cmd overlay enable-exclusive com.android.internal.systemui.navbar.gestural

# 2. a clean status bar: 9:41, full battery, wifi only, no notification icons
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile hide
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false

# 3. capture
./gradlew -q --console=plain :androidApp:installDebug
maestro test --debug-output artifacts/shots .maestro/raw-screenshots.yaml

# 4. put the device back
adb shell am broadcast -a com.android.systemui.demo -e command exit
adb shell settings put global sysui_demo_allowed 0
adb shell cmd overlay enable-exclusive com.android.internal.systemui.navbar.threebutton
```

Then convert. `build-screenshots.sh` takes one or more raw `takeScreenshot` directories,
downscales each capture to 3× its rendered CSS width and encodes WebP at q82:

```bash
./build-screenshots.sh artifacts/shots/.maestro/tests/*/raw-screenshots/takeScreenshot
```

Pass several directories to layer a re-capture over an earlier run — the last directory
holding a given file wins.

Published name → source capture:

| Published | Capture | Used for |
|---|---|---|
| `home.webp` | `03-home-portfolio` | hero |
| `analytics.webp` | `05-app-detail-dau` | App analytics |
| `reviews.webp` | `19-reviews-inbox` | Reviews |
| `proceeds.webp` | `10-app-detail-sales-history` | Sales proceeds |
| `countries.webp` | `09-app-detail-countries` | Territories |
| `releases.webp` | `08-app-detail-releases` | Releases — **see the note below** |
| `demo.webp` | `02-onboarding-demo-entry` | Sample data |

If you change which capture backs a section, update the `alt` text in `index.html` to match.
The alt text describes the actual figures on screen, which is the point of it.

### The releases capture needs its own flow

`.maestro/raw-screenshots.yaml` uses `scrollUntilVisible` for `RELEASES`, which stops the
scroll the instant the header's first pixel appears — so `08-app-detail-releases` comes out
with the store-conversion card filling the frame and `RELEASES` clipped off the bottom edge.
The release and TestFlight rows, which are the whole point of that section, are not in shot.
`docs/release/play-store-listing.md` §5 records the same defect in Play slot 6.

`releases-recapture.yaml` fixes it: it centres `RELEASES` and then swipes once more
so the header leads the frame. Run it after the main flow, with the same device prep, and
pass its output directory **last** so it wins:

```bash
maestro test --debug-output artifacts/shots-releases path/to/pomostats-site/releases-recapture.yaml

./build-screenshots.sh \
  artifacts/shots/.maestro/tests/*/raw-screenshots/takeScreenshot \
  artifacts/shots-releases/.maestro/tests/*/releases2/takeScreenshot
```

If you re-run only the main flow and rebuild, this section silently regresses to the
clipped capture — so either run both, or leave `releases.webp` alone.

---

## SEO

What's in place:

- One `<h1>`, a single heading hierarchy, semantic sectioning
- `<title>` 46 chars, meta description 143 chars — both inside the truncation limits
- Canonical URL, `max-image-preview:large`
- Open Graph + Twitter card with a 1200×630 image and image alt
- JSON-LD `@graph`: `SoftwareApplication`, `WebSite`, `FAQPage` — the FAQ markup matches the
  visible FAQ text verbatim, which is what Google requires for it to count
- Descriptive `alt` on every screenshot
- `width`/`height` on every image so nothing shifts as it loads (CLS)
- Hero image preloaded with `fetchpriority="high"`; every other image `loading="lazy"`
- `robots.txt`, `sitemap.xml`, web app manifest
- Fonts preconnected and `display=swap`

### Two things deliberately left out

**No `offers` / price in the structured data, and no prices on the page.** The house rule
recorded in `dec-pomo-stats-store-copy-monetization-claims` is that PomoStats marketing copy
carries no price claim and nothing that needs upkeep. The page therefore says what Premium
unlocks (additional apps, additional connected accounts) without the €29.99/year and €59.99
lifetime figures. Adding them is a one-line change in the FAQ if you decide the website
should differ from the Play listing on this — it is a real choice, not an oversight.

**No `aggregateRating`.** Same rule: a ratings figure in markup is a number that silently
goes stale, and Google penalises rating markup that disagrees with the store.

### After deploying

1. Verify the property in Google Search Console and submit `sitemap.xml`
2. Run the page through the [Rich Results Test](https://search.google.com/test/rich-results)
   — it should report `SoftwareApplication` and `FAQPage`
3. Check the social card with a debugger for whichever network matters to you
4. Lighthouse on mobile; the page is static so anything below ~95 is worth a look

## The logo

`assets/logo/` holds a 1024x1024 mark in three grounds, each with the SVG it was rendered
from:

| File | Ground | Alpha | For |
|---|---|---|---|
| `logo-1024-white.png` | `#FFFFFF` | none (RGB) | store listings, anywhere an opaque square is required |
| `logo-1024-cream.png` | `#EFEBDF` | none (RGB) | on-brand contexts — slides, docs, the site |
| `logo-1024-transparent.png` | none | yes (RGBA) | compositing over your own background |

The white and cream files are deliberately **RGB with no alpha channel**, because the App
Store rejects icons that carry one. Only the transparent variant has alpha.

These are not a new drawing. They reproduce the shipped launcher icon's exact geometry: the
Android adaptive icon renders through the standard 72/108 viewport, which is a 1.5x crop of
the 108dp canvas, so the SVGs use `viewBox="18 18 72 72"` with the foreground layer's own
`translate(5.4 5.4) scale(0.9)` group. That puts the apple at 61% of the frame — measured
against `androidApp/src/main/ic_launcher-playstore.png`, which measures ~62%.

To re-render after a path change:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --force-device-scale-factor=1 \
  --default-background-color=00000000 --window-size=1024,1024 \
  --screenshot=logo-1024-white.png "file://$PWD/logo-1024-white.svg"
```

**The `0.9` inset is for launcher tiles only.** It is the adaptive-icon safe zone. The
in-page wordmark and `favicon.svg` deliberately do *not* use it — they crop to the glyph's
real bounds (`viewBox="28 27 52 55"`), because on the web that inset just shrinks the mark
to 45% of its box and makes it read as a small green dot.

### Regenerating the social card

`assets/og-image.jpg` was rendered from `assets/og-image.src.html` with headless Chrome, so
it uses the real fonts and the real home screenshot rather than being drawn by hand. Chrome
only writes PNG, so the second step re-encodes:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --virtual-time-budget=6000 --window-size=1200,630 \
  --screenshot=/tmp/og.png \
  "http://localhost:4321/assets/og-image.src.html"

sips -s format jpeg -s formatOptions 92 /tmp/og.png --out assets/og-image.jpg
```

Re-run it if the hero screenshot or the headline changes. Keep the output exactly 1200×630 —
that is what the `og:image:width` / `og:image:height` tags declare.

**It is JPEG, not WebP, on purpose.** Social scrapers are the one place WebP is still not
safe: several platforms will not render a WebP preview even though every browser handles it
fine. JPEG at q92 is visually identical here and a third of the PNG's size (112 KB vs
372 KB), which also keeps it under the size ceilings some scrapers impose.

---

## Deploying

The site is served by **GitHub Pages** from the `main` branch of this repository, at
<https://pomostats.app>. There is no build step and no CI: pushing to `main` publishes.

Two files make that work and should not be deleted:

- **`CNAME`** holds the custom domain. GitHub Pages reads it on every build; removing it
  reverts the site to `prof18.github.io/pomostats-site`.
- **`.nojekyll`** disables Jekyll. Without it GitHub runs the tree through Jekyll, which
  silently ignores any path beginning with an underscore.

DNS lives in Cloudflare (the zone was already there for the domain purchase) but is
**DNS-only, not proxied** — four `A` records and four `AAAA` records pointing at GitHub's
Pages servers. Proxying them through Cloudflare would block GitHub from validating the
domain and issuing its Let's Encrypt certificate.

### There are no custom headers, deliberately

GitHub Pages has no mechanism for setting HTTP headers, so the `_headers` file this site
used to carry was deleted rather than left in place to imply something that never happens.
What it contained, and whether it mattered:

| Header | Verdict |
|---|---|
| `Cache-Control: immutable` on `/assets/*` | Was a **bug**. Filenames are not content-hashed, so a long immutable cache pinned returning visitors to a stale stylesheet. Good riddance. |
| `Referrer-Policy` | Redundant — `strict-origin-when-cross-origin` is already the browser default. |
| `X-Frame-Options`, `X-Content-Type-Options`, `Permissions-Policy` | Hygiene with no concrete threat on a static page that has no auth, no forms and no actions. |

GitHub Pages serves its own short cache with revalidation, which for unhashed filenames is
the safer behaviour anyway. If headers ever genuinely matter, that is the moment to move to
a host that supports them — not before.

### After changing the screenshots or copy

```bash
git add -A && git commit -m "..." && git push
```

Pages redeploys within a minute or so. Check the Actions tab (or the repository's
Settings → Pages) if a deploy seems stuck.

## Fonts

Loaded from Google Fonts. That is one third-party request on an otherwise dependency-free
page; self-hosting the four WOFF2 files in `assets/fonts/` and swapping the `<link>` for a
local `@font-face` block would remove it and shave the round trip. Worth doing if the page
ever needs to be provably request-free, not worth doing before launch.
