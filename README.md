# scroll-film-website — a Claude skill

Build an Apple-style **scroll-driven video website**: the visitor's scroll position scrubs through one continuous AI-generated film (`journey.mp4`), assembled from keyframe-chained AI video clips (the ending frame of each clip is the exact beginning frame of the next).

## Install

**Option A — packaged:** download [`scroll-film-website.skill`](./scroll-film-website.skill) and install it in Claude Code / Claude.

**Option B — from source:** copy the `scroll-film-website/` folder into your skills directory (e.g. `~/.claude/skills/`).

**Option C — Claude Code plugin marketplace:**
```
/plugin marketplace add YOUR_USERNAME/scroll-film-website
/plugin install scroll-film-website@YOUR_USERNAME
```

## What it does

A five-phase pipeline with hard gates:

1. **Context discovery** — mines your repo (existing site, README, brand files) before asking anything; "you decide" green-flags autonomous design.
2. **Story design** — picks the number of clips (default 4–6), designs N+1 keyframe-chained boundary frames, drafts copy/palette, collects required reference photos & logos up front, and gets your approval.
3. **Asset generation** — via an AI image/video MCP if you have one (plan + cost shown before spending), or via a generated `PROMPT_KIT.html` with editable copy-button prompts for any external tool.
4. **Assembly** — `make_journey.sh` normalizes, concatenates, and scrub-encodes clips into `journey.mp4` (dense keyframes, automatic size step-down to stay web- and GitHub-safe).
5. **Website build** — fills the bundled working template: blob-loaded film, scroll-scrubbed playhead, duration-weighted beat text, contact card, mobile/reduced-motion fallback.

The defining acceptance test: **the video is frozen whenever you aren't scrolling.** Scroll down = frames advance; scroll up = rewind; page bottom = final frame.

## Layout

```
scroll-film-website/
├── SKILL.md                      # the pipeline
├── references/
│   ├── website-spec.md           # site mechanics, size budget, acceptance criteria
│   └── prompt-guide.md           # frame/clip prompt rules, chaining, naming
├── assets/
│   ├── site-template.html        # complete working scrub site (fill CONFIG)
│   └── prompt-kit-template.html  # two-page prompt kit for no-MCP users
└── scripts/
    └── make_journey.sh           # normalize + concat + scrub-encode
```

Requires `ffmpeg` for assembly.

## License

MIT — use it, fork it, build school websites with it.
