---
name: scroll-film-website
description: Build an Apple-style scroll-driven video website where scrolling scrubs through one continuous AI-generated film (journey.mp4), built from keyframe-chained AI video clips. Use this skill whenever the user wants a scroll-driven video website, a cinematic scrolling site, an "Apple-style" website, a scroll-scrubbed video experience, a website where video plays as you scroll, or a visual storytelling site for a portfolio, school, brand, product, or organization. Also trigger when the user mentions scroll-controlled video, video scrubbing websites, continuous AI video journeys, or turning AI videos into a website. Trigger even if they only describe the effect ("video moves when I scroll") without naming it.
---

# Scroll-Film Website

Build a website where the visitor's scroll position drives the playhead of one continuous cinematic film. The film is assembled from AI-generated clips that are **keyframe-chained**: the ending frame of clip N is the exact beginning frame of clip N+1, so the clips concatenate into one seamless `journey.mp4`.

**The single most important concept — repeat it to yourself and the user:** this is NOT videos playing one after another. The video never autoplays. Scroll position = playhead position. Scrolling down advances frames; scrolling up rewinds; the bottom of the page is the last frame. If the final site plays video while the user isn't scrolling, the build is wrong.

## Pipeline overview

```
Phase 0  Context discovery   → find or ask for project context
Phase 1  Story design        → N beats, N+1 boundary frames, copy, palette (user approves)
Phase 2  Asset generation    → MCP path (generate directly) or Prompt-Kit path (user generates externally)
Phase 3  Assembly            → validate clips, concat into journey.mp4 (scripts/make_journey.sh)
Phase 4  Website build       → scroll-scrub site per references/website-spec.md
```

Do the phases in order. Each phase has a gate: do not proceed until its gate passes.

---

## Phase 0 — Context discovery (always do this FIRST, before any video work)

Search the working directory/repository for context **before asking the user anything**:

1. Look for context files: `README*`, `CONTEXT*`, `ABOUT*`, `BRIEF*`, `*.md` describing the org/person, an existing website (`index.html`, a deployed-site folder), brand documents, logos, color tokens in CSS, and any photos/images.
2. If an existing website is present, read it: extract the organization's name, mission, tone, colors, key facts, and contact details. This becomes the default context.
3. Summarize what you found to the user in a few sentences and ask them to confirm or correct it.

**If no context is found**, ask the user for it. Tell them exactly what to provide (see "Guiding the user" below). If the user says some variation of "you decide" / "let the AI decide" — that is a **green flag**: invent a tasteful, coherent concept yourself from whatever is available, state your choices plainly, and proceed. Do not stall asking more questions after a green flag.

**Gate:** you have confirmed context (subject, audience, tone, palette, key facts, contact info) — either user-provided, discovered, or AI-invented after a green flag.

## Phase 1 — Story design

Decide the spine of the film:

1. **Number of clips (beats).** Default **4–6**. Fewer than 4 feels thin; more than 8 inflates generation cost and scroll length. Each beat = one ~5s clip = one message/section of the site. Choose the count from the story, not arbitrarily, and tell the user why.
2. **Boundary frames.** N clips need **N+1 frames** (A, B, C, …). Clip k is a start-frame → end-frame morph from frame k to frame k+1. Because adjacent clips share the exact frame where they meet, the chain is seamless. Frames must be **clean single scenes** — never prompt a "blend" image; the video model does the morphing between clean waypoints.
3. **Narrative arc.** Typical shapes: origin → growth → present → future (schools, orgs); place → place → purpose (personal journeys); problem → product → impact (brands). Bookending with a person/identity shot works well for portfolios.
4. **On-screen copy.** One short line (or fact) per beat, plus an opening title and a closing call-to-action/contact card. Facts must come from the context — never invent claims about a real person or organization.
5. **Palette & type.** Two-color system (base + accent) derived from the context/brand. Defaults if none: warm cream `#F4ECE0` base, accent from the subject's branding.

6. **Reference assets (people & logos) — collect BEFORE any image is created.** Scan the planned frames: does any frame depict a real person (portrait bookends, a school's head) or an organization's logo/mascot/building? If yes, these MUST be generated from a reference image, never from a text description. Check whether a usable photo/logo already exists in the project (Phase 0 findings); if not, **ask the user to provide it now** — one clear, well-lit photo per person; a high-resolution logo file (PNG/SVG) — and wait. Do not start generating frames while a needed reference is missing. If the user can't provide one, redesign those beats to not depict that person/logo (silhouettes, environments, abstract identity) rather than inventing a likeness.

Write the full plan (beats table: frame A…N+1 descriptions, clip morph descriptions, copy per beat, palette, and a **reference-asset list: which file feeds which frames**) and **show it to the user for approval**. This is the cheap moment to change things; generation is the expensive one.

**Gate:** user approved the plan (or green-flagged you to proceed) AND every needed reference image is in hand.

## Phase 2 — Asset generation (two paths)

First, **check for AI image/video generation MCP tools** (e.g., Higgsfield "higg", or any tool whose description covers image/video generation). Search available tools before deciding.

### Path A — MCP available

1. Upload the collected reference images (person photos, logos) to the generation service first; map each to the frames that use it.
2. Create the generation plan: for each boundary frame, a detailed image prompt **plus which reference image it uses (if any)**; for each clip, the pair (start frame file → end frame file) plus a motion prompt. Follow `references/prompt-guide.md` for prompt construction.
3. Show the plan and the **estimated cost/credits** to the user. Get explicit approval before generating anything — generation spends the user's money.
4. Generate all N+1 frames first. Show them to the user; regenerate any they reject. **Do not start clips until frames are approved** — clips inherit frame flaws.
5. Generate the N clips with a start+end-frame capable model (e.g., Kling, Seedance). Use the **same model and the same grade line for all clips**.
6. Download/collect outputs into `assets/` using the canonical names from the plan: `frame_<Letter>_<slug>.png` and `clip_<NN>_<startslug>-to-<endslug>.mp4` (naming convention defined in `references/prompt-guide.md`).

### Path B — no MCP (Prompt-Kit)

Build a local, self-contained HTML file the user opens in a browser to run generation themselves in whatever tool they have (Higgsfield web, Runway, Kling, etc.):

1. Copy `assets/prompt-kit-template.html` to the project as `PROMPT_KIT.html`.
2. Inject the project's actual prompts into the `PROMPTS` JSON object at the top of the file's script (the template renders everything else). For any frame that uses a person photo or logo, set that frame's `reference` field to the exact filename (e.g., `"reference":"photo_principal.jpg"`) — the kit then shows a prominent "attach this reference image FIRST" step on that frame's card. It has two pages:
   - **Page 1 — Frames:** each boundary frame with its full image prompt in an **editable** textarea and a copy button, the exact filename to save as, and — where applicable — the reference image to attach before generating.
   - **Page 2 — Clips:** each clip as `frame_X.png → frame_Y.png` with its motion prompt (editable + copy button), the model requirement ("must accept a start frame AND an end frame"), and the exact filename to save as.
3. **Tell the user explicitly, in chat, before they start:** for every frame card that lists a reference image, they must upload/attach that photo or logo as the *reference image* in their generation tool **before** running the prompt — text alone will not reproduce a real face or logo. Then: generate frames first, approve them yourself, then make the clips; save everything into `assets/` with the listed filenames; come back when done.

**Prompt quality bar (both paths):** prompts must be as detailed as possible and website-suitable — 16:9 landscape, no text/watermarks/logos baked into imagery, safe margins (subject not at extreme edges), one slow continuous camera move per clip, no internal cuts, and one identical color-grade sentence appended to every prompt so all assets read as one film. Full rules and templates: read `references/prompt-guide.md` before writing prompts.

**Gate:** all N clips (correct count, correct order, 16:9) exist in `assets/`.

## Phase 3 — Assembly into journey.mp4

**Intake check first.** List `assets/` and reconcile against the plan. Users often save files with their tool's default names (`kling_export_183722.mp4`) or their own words (`istanbul video.mp4`). Be tolerant: match files to beats using every available signal — slug words in the filename, file order/timestamps, duration, and (if needed) a frame sample. When a mapping is confident, **rename the file yourself** to its canonical `clip_<NN>_<startslug>-to-<endslug>.mp4` name and tell the user what you renamed. Ask only about genuinely ambiguous files. Verify the final count equals N before assembling — a missing or doubled clip silently corrupts the whole film's beat timing.

Run `scripts/make_journey.sh` from the project root (requires ffmpeg; if missing, tell the user to install it — `brew install ffmpeg` / `sudo apt install ffmpeg` / `winget install ffmpeg`):

```bash
bash scripts/make_journey.sh assets/clip_*.mp4
```

The script normalizes every clip to identical specs (1920×1080, 30fps, yuv420p, silent), concatenates them in argument order, and re-encodes with a **keyframe on nearly every frame** (`keyint=2`) plus `+faststart`. Dense keyframes are what make `currentTime` seeking land instantly — without this the scrub stutters. It prints per-clip durations and the total; **record these numbers**, the website's text-timing windows are computed from them.

Sanity-check `assets/journey.mp4`: play it once; verify the boundaries are seamless and the duration ≈ sum of clips.

**Gate:** `journey.mp4` exists, plays seamlessly, durations recorded.

## Phase 4 — Build the website

**Start from the bundled template — do not reimplement the scrub mechanic from scratch.** Copy `assets/site-template.html` to the project as `index.html`, then:

1. Fill the `CONFIG` object at the top of its script: `beats` (one entry per clip, in order, with the **normalized durations printed by make_journey.sh** and the approved copy), `endCard` rows (confirmed contact details only), `scrollLenVh` (default 700).
2. Replace `<!--SITE_TITLE-->` and `<!--LOADER_MARK-->`, and restyle the `:root` CSS tokens + fonts to the approved palette/typography.
3. Read `references/website-spec.md` to understand what the template implements and the acceptance criteria; extend the template only if the plan requires something it lacks.

The template already implements: blob-loading with a progress bar (so scrubbing never stalls mid-journey), the rAF scrub loop with easing, duration-weighted beat text windows, the scroll cue, the end card, and the mobile/reduced-motion/touch fallback (autoplay-loop + scroll-driven text).

Test via a local server (`python3 -m http.server`) — seeking is unreliable over `file://`. Verify against the spec's acceptance criteria, the first of which is: **video is frozen whenever the user is not scrolling.**

**Gate:** all acceptance criteria in `references/website-spec.md` pass.

---

## Guiding the user (what to ask for, and when)

At Phase 0, if context is missing, ask for — in one compact message, not an interrogation:

1. **Who/what is this site for?** (school, person, company — name + one paragraph or a link/file)
2. **Audience?** (parents, recruiters, customers…)
3. **3–6 key facts or messages** the site must land (or "you pick from the context")
4. **Brand colors / an existing site or logo** (or "you choose")
5. **Contact details** for the end card (email, phone, address, socials — only what they want public)
6. **Any photos or logos** that must appear (e.g., a real person for bookend shots — one clear, well-lit photo is enough; logos as high-res PNG/SVG). Make clear these are needed **up front**, before image generation begins.

Remind the user explicitly that "you decide" is allowed for any item — and if they say it for everything, that is the green flag to design autonomously. The one exception: a real person's face or a real logo can never be "you decide" — either the user supplies the reference image or those elements stay out of the frames.

At Phase 2 Path B, set expectations: which external tool features they need (start+end frame video generation), that **reference images (person photos, logos) must be attached in their tool before running those frames' prompts**, that frames come before clips, and exact save-as filenames.

At Phase 3, run the intake check: reconcile whatever filenames arrive against the plan, rename confident matches yourself, and ask only about ambiguous files.

## Hard rules

- Never let the final site autoplay the film as a sequence — scroll must drive the playhead. This is the failure mode; check for it explicitly.
- Never invent factual claims (achievements, statistics, history) about a real subject; use only confirmed context.
- Never depict a real person or real logo without a user-supplied reference image — ask for it before any image generation begins; if unavailable, redesign those beats instead.
- Never generate assets that spend user credits without showing the plan + cost and getting a yes.
- All assets 16:9. All prompts carry the same grade line. Boundary frames are clean scenes, never blends.
- Keep the site self-contained: `index.html` + `assets/journey.mp4` + whatever it links (resume, etc.). No JS dependencies beyond fonts.

## Bundled resources

- `references/website-spec.md` — the complete website implementation spec (mechanics, size budget, blob loading, fallback, acceptance criteria). Read in Phase 4.
- `references/prompt-guide.md` — how to write frame and clip prompts (structure, grade line, chaining rules, naming convention). Read in Phase 2 before writing any prompt.
- `assets/site-template.html` — a complete working scrub site; Phase 4 copies it and fills its `CONFIG`.
- `assets/prompt-kit-template.html` — the two-page copy-button HTML for Path B. Inject prompts into its `PROMPTS` object.
- `scripts/make_journey.sh` — normalize + concat + dense-keyframe encode with an automatic size step-down ladder (≤60MB budget; hard-fails over 95MB because GitHub rejects >100MB files). Run in Phase 3.
