# Prompt Guide — Frames & Clips for a Keyframe-Chained Film

How to write the image prompts (boundary frames) and video prompts (clips) so the result reads as one continuous, website-ready film. Read this before writing any prompt, in either MCP or Prompt-Kit mode.

## The chaining model

N clips require N+1 boundary frames: `A, B, C, …`. Clip k is generated as a **start-frame → end-frame** video from frame k to frame k+1. Adjacent clips share the literal frame where they meet, so concatenation is seamless.

Rules that make chaining work:

1. **Frames are clean single scenes.** Never prompt a half-blended image ("a face dissolving into a skyline"). Blends generate poorly and give the video model a muddy target. The MORPH lives in the clip prompt; the frames are crisp waypoints.
2. **One grade line, everywhere.** Write one color-grade sentence for the project and append it verbatim to every frame prompt and every clip prompt. This is the single highest-leverage trick for visual continuity. Template:
   > warm cinematic color grade, golden-hour {accent-color} light, {base-color} tones, soft film grain, shallow depth of field, anamorphic feel
   Adapt colors to the approved palette; then never vary the sentence.
3. **Same models throughout.** One image model for all frames; one start+end-frame-capable video model for all clips (Kling and Seedance class models support start+end frames). Mixing models mid-film shifts the look.
4. **People & logos = reference-driven, collected before generation.** A real face or a real logo can only come from a user-supplied reference image — confirm it's in hand *before* writing/running any frame prompt that needs it. For a person: generate ONE polished portrait still from their photo first, then reuse that same still as the reference for every frame containing them; keep their face in as few frames as possible (bookends are ideal) — likeness drift across many frames is the #1 quality risk. Append "photoreal, keep exact facial likeness" to those prompts. For a logo: prefer compositing the real file into the website's HTML over baking it into AI imagery; if it must appear in a frame (e.g., on a building), attach the logo file as a reference and instruct "reproduce the logo exactly as provided". In Prompt-Kit mode, every such frame card must name its reference file and the user must be told to attach it in their tool before running the prompt.

## Website-suitability requirements (every prompt)

- **16:9 landscape**, always — frames AND clips. The site is full-bleed 16:9.
- **No text, no watermarks, no logos, no UI** baked into the imagery. On-screen copy is HTML, not pixels.
- **Safe margins:** keep the subject in the center ~70%; edges get cropped by `object-fit: cover` on other aspect ratios.
- **Legibility headroom:** scenes should have at least one calmer region (sky, water, soft bokeh) where overlay text can sit.
- **Nothing strobing or rapid** — scrubbing magnifies flicker.

## Frame prompt structure

Be as detailed as possible. Build each frame prompt in this order:

```
[shot type + camera] [subject, specific] [setting, specific] [time of day / light]
[mood adjectives] [composition notes: where the calm region is] [GRADE LINE]
```

Example (Istanbul beat):
> Wide cinematic establishing shot, the Bosphorus at dawn, Istanbul skyline with silhouetted mosque minarets, ferries on misty water, upper third open sky for headroom, golden amber sunrise, serene and proud mood, warm cinematic color grade, golden-hour amber light, cream and sand tones, soft film grain, shallow depth of field, anamorphic feel

## Clip prompt structure

Each clip prompt describes the **journey from its start frame to its end frame** plus exactly ONE slow continuous camera move. No internal cuts, no speed ramps.

```
[one camera move: slow push-in / drift forward / slow pan] +
[what transforms into what, stated simply] + [pace words: slow, gradual, gentle] + [GRADE LINE]
```

Example (skyline → markets beat):
> Slow continuous push toward the city lights; the lights gradually blur and reform into glowing amber financial charts and flowing data lines, gentle and gradual transformation, warm cinematic color grade, golden-hour amber light, cream and sand tones, soft film grain, shallow depth of field, anamorphic feel

Morph difficulty ranking (plan regeneration budget accordingly): place→place is easy; abstract→abstract easy; face→place and place→face are the ambitious ones — if one fails, simplify the camera move and slow the transformation language, then regenerate just that clip.

## Per-beat copy pairing

Each beat carries one short on-screen line (HTML overlay, not in the prompt). When designing frames, note where the text will sit and prompt the calm region on that side. Facts in the copy must come from confirmed context only.

## Output naming (canonical)

Names must be **sortable AND semantic** — a number prefix preserves story order for tools and globs; a short slug tells humans and AI what the file is without opening it.

- Frames: `frame_A_<slug>.png`, `frame_B_<slug>.png`, … where `<slug>` is 1–3 lowercase hyphenated words naming the scene. E.g., `frame_A_portrait.png`, `frame_B_istanbul-dawn.png`, `frame_E_market-data.png`.
- Clips: `clip_01_<startslug>-to-<endslug>.mp4`, zero-padded, story order. E.g., `clip_01_portrait-to-istanbul.mp4`, `clip_02_istanbul-to-arrival.mp4`. The name self-documents the morph: which frame it starts on, which it ends on.
- Slugs: lowercase, hyphens only, no spaces/underscores/dates, keep them short. The letter/number prefixes are the contract; the slugs are the meaning.

Generate the exact filenames during Phase 1 planning (they fall out of the beats table) and use them everywhere: the plan shown to the user, the Prompt-Kit cards, MCP downloads, and the `make_journey.sh` invocation. `clip_*.mp4` still globs in correct order because the zero-padded number sorts first.
