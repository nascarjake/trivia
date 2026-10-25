# Millionaire · Trending Edition

A Godot 4.7.2 3D web prototype: seated host and contestant, circular blue/purple studio, 15-question prize ladder, final-answer reveal, safeguards, walk-away, 50:50, phone-a-friend and audience simulation. No Godot logo splash.

Play the published [GitHub Pages game](https://nascarjake.github.io/trivia/).

See [the research and fan-asset shortlist](docs/RESEARCH.md) and [the exact inspected fan-model inventory](docs/fan-model-inventory.json).

## Play locally

The built browser version is in `builds/web/` (ignored by Git).

```sh
python3 server/app.py
```

Open [the game](http://127.0.0.1:8765). It works from the cached curated bank without credentials. Reduced motion follows the browser preference and can also be toggled in game. Select A–D or click an answer, then press Enter or click Final answer. Enter advances after a correct reveal. Each lifeline can be used once per run.

Choose any combination of the eight themes, with Select all and Clear controls. Practice contains 120 questions: five per difficulty tier in each category. A run contains 15 unique questions drawn only from your selected themes, balanced across them, with difficulty increasing every five questions. Even one theme supports a complete run. Lifelines are local simulations. Two steady spotlights and a short final-answer hold provide stage atmosphere; reduced motion removes camera drift and shortens the hold. Reveal labels identify the correct and chosen answers without relying on color.

Choose Alex, Mina, or Jules for the seated contestant. Play classic untimed mode or enable a 30-second clock; lifeline and confirmation dialogs pause it. Keys 1–3 activate lifelines, A–D select an answer, and Enter locks or advances. Camera cycles through wide, contestant, and host views. Walk-away and leaving a run require an in-game confirmation. Results offer replay with the same themes or a return to setup. Theme, character, timer and sound preferences plus your best payout are saved locally in Godot’s user data (browser storage for web).

## Shared bank and weekly candidates

Gameplay makes **zero model calls**. The local server serves a durable reviewed JSON snapshot at `/api/bank`, with an ETag and five-minute HTTP cache. Godot caches it for the session; static Pages/offline play uses the bundled snapshot. Lifelines are local simulations. The earlier per-play AI endpoints now return 410, even if a provider key is present.

The 120 existing questions now have stable IDs and canonical fact keys. Selection favors unseen facts within balanced themes and increasing difficulty, then the least recently seen facts. A run with repeats shows an exhaustion notice. History records questions when displayed, survives preference reload, and retains up to 10,080 distinct facts. Existing best scores/preferences and unknown save fields are retained. Anonymous history belongs to this browser/device: clearing storage, private sessions, another origin/device, or storage failure can reset it. No account synchronization is claimed.

Twelve complete runs require at least **180 distinct facts** in the selected mix. Supporting twelve runs of **any single theme** requires 60 facts in each of its three tiers: **1,440 total across eight themes**. Twelve runs every day for a week requires **10,080** under that same single-theme requirement. The shipped bank is still 120 (five per theme/tier), so repeats remain unavoidable; single-theme play exhausts after one complete run. The 12-run test uses explicitly synthetic capacity fixtures, never fake shipped questions.

```sh
python3 tools/question_batch.py capacity
python3 tools/question_batch.py dry-run --output server/cache/example-candidate.json
```

The dry-run validates three original, internet-informed NASA candidates (two evergreen, one expiring current event), then stages a pending review file. It makes no paid calls and does not alter the active bank. See [batch review, bounds and external enablement](docs/QUESTION_BANK.md). No live freshness job, paid generation, Cloudflare account/database, credentials, or cron was enabled.

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

The Godot test checks all 255 category combinations, twelve-run rotation with sufficient capacity, exhaustion, canonical deduplication, expiry, save/reload, reveal locking, answer bounds, reduced motion and the existing full climb/lifelines/safeguards. The Python suite checks schema/date/source rejection, review binding, local import and D1-compatible SQL round trips, HTTP caching, and disabled paid routes. Gameplay tests skip the optional server probe.

## Scope

This is an original procedural studio/gameplay foundation, not the licensed Steam game's assets or final-quality characters. Fan assets were researched but not bundled. Sound effects are synthesized original tones. No trademark permission is claimed. [Godot's license](https://godotengine.org/license/) applies to its engine/runtime; retain the exported runtime's notices when distributing.

Current limitations: single-player and client-authoritative answers; landscape desktop layout; no host voice/lip-sync; finite practice pool (15 questions per theme); no online accounts/leaderboards; no enabled trend refresh scheduler; no hosted backend; insufficient bank for twelve repeat-free runs. The static practice game is published on GitHub Pages. The local server is not a public deployment service. The research document gives the next production steps.

## GitHub Pages publishing

The public repository is [nascarjake/trivia](https://github.com/nascarjake/trivia). Pushing to `main` runs `.github/workflows/pages.yml`: installs the pinned Godot release, runs the service and gameplay checks, exports the game, and deploys to Pages. Engine downloads are checksum-verified and official GitHub actions are pinned to commits. Only `builds/pages` is published; source and server files are not part of the Pages artifact.

To produce the identical static edition locally:

```sh
GODOT_BIN=godot sh tools/export_pages.sh
```

The `GitHub Pages` export preset adds the `github_pages` feature. This edition skips the localhost API probe and clearly labels itself as practice-only. The normal `Web` preset fetches the optional shared-bank snapshot from the local/server-backed API. GitHub Pages does not run the Python backend; no provider credentials belong in the exported game or repository. All web assets use relative paths so the game loads under `/trivia/`.
