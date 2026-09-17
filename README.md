# Millionaire · Trending Edition

A Godot 4.7.2 3D web prototype: seated host and contestant, circular blue/purple studio, 15-question prize ladder, final-answer reveal, safeguards, walk-away, 50:50, phone-a-friend and audience simulation. No Godot logo splash.

Play the published [GitHub Pages game](https://nascarjake.github.io/trivia/).

See [the research and fan-asset shortlist](docs/RESEARCH.md) and [the exact inspected fan-model inventory](docs/fan-model-inventory.json).

## Play locally

The built browser version is in `builds/web/` (ignored by Git).

```sh
python3 server/app.py
```

Open [the game](http://127.0.0.1:8765). It works in curated practice without credentials. Select A–D or click an answer, then press Enter or click Final answer. Enter advances after a correct reveal. Each lifeline can be used once per run.

Choose any combination of the eight themes, with Select all and Clear controls. Practice contains 120 questions: five per difficulty tier in each category. A run contains 15 unique questions drawn only from your selected themes, balanced across them, with difficulty increasing every five questions. Even one theme supports a complete run. Practice lifelines are simulations.

Choose Alex, Mina, or Jules for the seated contestant. Play classic untimed mode or enable a 30-second clock; lifeline and confirmation dialogs pause it. Keys 1–3 activate lifelines, A–D select an answer, and Enter locks or advances. Camera cycles through wide, contestant, and host views. Walk-away and leaving a run require an in-game confirmation. Results offer replay with the same themes or a return to setup. Theme, character, timer and sound preferences plus your best payout are saved locally in Godot’s user data (browser storage for web).

## Enable AI

Set `OPENAI_API_KEY` in the server process environment and restart it. `OPENAI_MODEL` defaults to `gpt-5.4-mini` and can be changed to a Responses model supporting web search and structured outputs. Optional `YOUTUBE_API_KEY` and `X_BEARER_TOKEN` enable chart/trend input. Region defaults to US. See [environment variable names](server/.env.example); that file is a template, not automatically loaded.

The AI checkbox enables generated question packs and generated hints. Three model calls research, compose, and review a pack; packs are cached in memory for one hour per category combination. The server rejects questions outside the selected themes, missing themes, and unbalanced category counts. First generation can take time and consumes API usage. Failed validation produces a retry message rather than silently substituting practice questions. Feed failures allow web research to continue. API credentials stay on the server and are not exported in the game.

**Live AI and X/YouTube integration have not been tested with credentials in this workspace.** No credentials were configured during development. Local logic and mocked output-validation tests are separate from provider integration testing.

## Open and export in Godot

Open `game/project.godot` in Godot 4.7.2. Set a `GODOT_BIN` environment variable to your Godot executable, or use `godot` if it is on PATH.

```sh
python3 tools/fetch_web_template.py
GODOT_BIN=godot sh tools/export_web.sh
```

The downloader retrieves only the two web templates from the official pinned release, rather than the full 1.28 GB multi-platform archive. Matching templates are already present locally in `.tools/`. A custom shell provides a plain progress indicator while loading. The export uses Compatibility/WebGL 2 and a single thread.

## Verification

```sh
python3 -m unittest discover -s tests -v
godot --headless --path game --script tests.gd
```

The game test checks all 255 category combinations, character switching, the 15-question climb, both safeguards, failure payout, cash-out confirmation/cancellation, 50:50, audience votes after elimination, timer pause/expiry, and replay. The 12 service tests cover question/lifeline validation, selected-category enforcement, AI request plumbing and canonical cache keys with mocked model responses. The Godot test assumes the local server is running for the optional configuration probe.

## Scope

This is an original procedural studio/gameplay foundation, not the licensed Steam game's assets or final-quality characters. Fan assets were researched but not bundled. Sound effects are synthesized original tones. No trademark permission is claimed. [Godot's license](https://godotengine.org/license/) applies to its engine/runtime; retain the exported runtime's notices when distributing.

Current limitations: single-player and client-authoritative answers; landscape desktop layout; no host voice/lip-sync; finite practice pool (15 questions per theme); no online accounts/leaderboards; no automatic trend refresh scheduler; no production hosting. The local server is not a public deployment service. The research document gives the next production steps.

## GitHub Pages publishing

The public repository is [nascarjake/trivia](https://github.com/nascarjake/trivia). Pushing to `main` runs `.github/workflows/pages.yml`: installs the pinned Godot release, runs the service and gameplay checks, exports the game, and deploys to Pages. Engine downloads are checksum-verified and official GitHub actions are pinned to commits. Only `builds/pages` is published; source and server files are not part of the Pages artifact.

To produce the identical static edition locally:

```sh
GODOT_BIN=godot sh tools/export_pages.sh
```

The `GitHub Pages` export preset adds the `github_pages` feature. This edition skips the localhost API probe and clearly labels itself as practice-only. The normal `Web` preset retains the optional AI connection for local/server-backed use. GitHub Pages does not run the Python backend; no provider credentials belong in the exported game or repository. All web assets use relative paths so the game loads under `/trivia/`.
