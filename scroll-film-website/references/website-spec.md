# Website Spec — Scroll-Scrubbed Film Site

The deliverable: a single-page site where scroll position drives the playhead of `assets/journey.mp4`. Vanilla HTML/CSS/JS in one `index.html`. No framework, no build step, no JS dependencies (Google Fonts allowed). Deploys to any static host unchanged.

## Delivery & size budget (read before encoding)

Dense keyframes inflate file size hard. Budget: **journey.mp4 ≤ 60MB** (hard ceiling 95MB — GitHub rejects files over 100MB, and GitHub Pages/slow networks suffer long before that). `make_journey.sh` enforces this with an automatic step-down ladder (1080p keyint=2 → 1080p keyint=3 CRF 22 → 810p keyint=4 CRF 23); a keyframe every 3–4 frames is still imperceptibly smooth to scrub. If even the last rung exceeds the ceiling, shorten or drop clips — do not ship an oversized file. If the user must keep a big file in a Git repo, mention Git LFS, but smaller is the real fix.

## Loading: fetch-as-blob (mandatory in scrub mode)

Do NOT rely on `canplaythrough` + progressive streaming — a fast scroller will hit unbuffered regions and the playhead will stall mid-journey. Instead, download the whole film up front and make every frame seekable:

```js
async function loadFilm(url, onProgress){
  const res = await fetch(url);
  const total = +res.headers.get('Content-Length') || 0;
  const reader = res.body.getReader(); const chunks = []; let got = 0;
  for(;;){ const {done, value} = await reader.read(); if(done) break;
    chunks.push(value); got += value.length; if(total) onProgress(got/total); }
  film.src = URL.createObjectURL(new Blob(chunks, {type:'video/mp4'}));
  await new Promise(r => film.addEventListener('loadedmetadata', r, {once:true}));
}
```

Drive the loader's progress bar from `onProgress`. Release the page (fade loader, enable scrubbing) only after `loadedmetadata` on the blob URL. This is why the size budget above is non-negotiable. In fallback mode (autoplay-loop), plain progressive `src` is fine — skip the blob fetch there.

## Core mechanic (the part builds get wrong)

The video NEVER plays in scrub mode. Scroll = playhead.

```
<main class="spacer">            <!-- height: SCROLL_LEN, e.g. 700vh -->
  <section class="stage">        <!-- position: sticky; top: 0; height: 100vh -->
    <video id="film" src="assets/journey.mp4" muted playsinline preload="auto"></video>
    <!-- text layers, scrim, contact card overlay here -->
  </section>
</main>
```

- `#film`: full viewport, `object-fit: cover`. No `controls`, no `autoplay`, no `loop` (in scrub mode).
- `SCROLL_LEN` is a tunable constant, default `700vh`. Bigger = slower, more deliberate scrub.
- The rAF loop:

```js
const EASE = 0.12;                 // lerp factor, tunable
let target = 0;
function onScroll() {
  const max = spacer.offsetHeight - innerHeight;
  const p = Math.min(Math.max(scrollY / max, 0), 1);
  target = p * film.duration;
}
function tick() {
  if (film.readyState >= 2 && Number.isFinite(film.duration)) {
    const delta = target - film.currentTime;
    if (Math.abs(delta) > 1/60) film.currentTime += delta * EASE;
  }
  requestAnimationFrame(tick);
}
addEventListener('scroll', onScroll, { passive: true });
requestAnimationFrame(tick);
```

- Never call `film.play()` in scrub mode. If the video moves while the user isn't scrolling (beyond the easing settling), the build is wrong.
- `journey.mp4` must be the dense-keyframe encode from `make_journey.sh`; a normal encode will stutter on seek.

## Beat text overlays

The film is N concatenated clips. Each clip gets one absolutely-positioned text layer over the stage.

- Compute each clip's time window from the recorded per-clip durations (cumulative sums ÷ total). Near-equal clips → equal Nths of progress is acceptable.
- Visibility from playhead time: fade in over the first ~20% of the window, hold, fade out over the last ~15%. Drive opacity/transform from the same rAF loop (translateY 16px → 0 on entry, ~700ms feel).
- Layer order per beat: big display line (serif), then supporting line (sans). Keep copy exactly as approved — no paraphrasing.
- Beat 1 also shows a small "scroll" cue (label + down chevron, gentle pulse) that fades permanently once the user scrolls.
- A soft base-color-to-transparent gradient scrim sits behind text zones so copy stays legible over any frame. Tint the scrim with the palette base — never gray/black unless the palette is dark.

## Loader

Centered minimal loader on the palette base color with a thin accent **progress bar driven by the blob download** (see Loading section). Hold until the blob's `loadedmetadata`, then fade out ~400ms. Page must not scrub before the film is fully fetched.

## End card (contact / CTA)

Overlay on the final beat, appearing when that beat's local progress > ~0.6:
- Heading (e.g., "Let's talk." / "Visit us." — from approved copy)
- The confirmed contact rows only (email `mailto:`, links in new tab with `rel="noopener"`, file downloads via `<a download>`)
- Small footer line (name/org + location)

## Fallback mode (mandatory)

Activate when ANY of: viewport width < 900px, `matchMedia('(prefers-reduced-motion: reduce)')` matches, or primary input is coarse/touch.

- `#film` switches to `autoplay muted loop playsinline` and simply plays.
- Text layers fade by **scroll position** over the pinned stage (no `currentTime` writes at all).
- Everything else (loader, scrim, end card) unchanged.

## Visual system

CSS custom properties from the approved palette, e.g.:

```css
:root{
  --base: …;     /* page/scrim base */
  --base-2: …;   /* panel tint */
  --ink: …;      /* text */
  --accent: …;   /* sparing: scroll cue, links, climax accent, loader bar */
  --accent-dp: …;/* hover */
  --muted: …;    /* secondary text */
}
```

- Display serif for big lines (Fraunces or Playfair Display; weight 500–600), clean sans for supporting text/UI (Inter 400/500/600). System fallbacks.
- Big lines: large, tight tracking. Supporting lines: ~18–22px, +0.04em tracking, max-width ~36ch.
- Motion is unhurried and filmic; nothing bounces. Respect reduced-motion everywhere.

## Acceptance criteria (test all)

1. **Frozen test:** stop scrolling mid-page → the frame holds still (after easing settles). Scrolling down advances the film; up rewinds; page bottom = last frame.
2. Scrubbing is smooth at normal scroll speeds — no stutter, no flash.
3. Each beat's text appears and clears within its window; final beat shows the end card.
4. Contact rows work (mailto opens, links new-tab, downloads download).
5. Loader shows until seekable; no layout shift; zero console errors.
6. Fallback verified: narrow window or reduced-motion → video plays/loops, text fades on scroll, no jank.
7. `journey.mp4` ≤ 60MB (never > 95MB); film is blob-loaded in scrub mode, so scrubbing to any point never stalls — even immediately after the loader clears.
8. Site runs from `python3 -m http.server` and consists of `index.html` + `assets/` only.

## Test note

Range-seeking over `file://` is unreliable in most browsers. Always test through a local server:

```bash
python3 -m http.server 8000   # then open http://localhost:8000
```

Report tuned constants when done: `SCROLL_LEN`, `EASE`, beat windows, journey.mp4 size/duration.
