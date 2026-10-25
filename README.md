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

Choose any combination of the eight themes, with Select all and Clear controls. The bundled bank contains 216 evergreen facts: nine per difficulty tier in each category, plus dated NASA questions when available. A run contains 15 unique questions drawn only from your selected themes, balanced across them, with difficulty increasing every five questions. Even one theme supports a complete run. Lifelines are local simulations. Two steady spotlights and a short final-answer hold provide stage atmosphere; reduced motion removes camera drift and shortens the hold. Reveal labels identify the correct and chosen answers without relying on color.

Choose Alex, Mina, or Jules for the seated contestant. Play classic untimed mode or enable a 30-second clock; lifeline and confirmation dialogs pause it. Keys 1–3 activate lifelines, A–D select an answer, and Enter locks or advances. Camera cycles through wide, contestant, and host views. Walk-away and leaving a run require an in-game confirmation. Results offer replay with the same themes or a return to setup. Theme, character, timer and sound preferences plus your best payout are saved locally in Godot’s user data (browser storage for web).

## Shared bank and free weekly updates

The current bank has **218 questions**: 216 evergreen facts balanced across eight themes and three tiers, plus two dated NASA headlines checked on 2026-10-25. Ninety-six original source-backed questions were added; imprecise Stardew Valley, Fool’s Mate and Wi-Fi wording was corrected while preserving their existing question/fact identities.

Gameplay makes **zero model calls**. The published game fetches a small bank manifest and its immutable JSON version once per session, with the bundled bank as fallback. Local hosting also retains `/api/bank` with HTTP caching. Lifelines are local simulations; retired per-play AI endpoints return 410.

Selection favors unseen canonical facts within balanced themes and increasing difficulty, then the least recently seen facts. History is saved when displayed, retains up to 10,080 distinct facts and survives bank versions. Existing best scores/preferences and unknown save fields are retained. Anonymous history is browser/device/origin-local; clearing storage, private sessions or storage failure can reset it. No account synchronization is claimed.

The actual 218-question bank passes **twelve full-mix runs with 180 unique facts and zero repeats**. This does not extend to arbitrary narrow theme choices: twelve complete runs of any single theme need 60 facts per tier in all eight themes (**1,440 total**). Twelve daily runs for a week under that single-theme requirement would need **10,080**. The game explicitly reports pool exhaustion.

The existing Pages workflow now includes a **weekly Monday 08:17 UTC** source refresh. It fetches NASA’s public feed plus at most three articles and makes original, dated mission-name headline questions. It adds at most one current question per tier, replaces the previous current set only after validating the complete bank, and retains the 216 evergreen core. It is a bounded source-backed curation pipeline, with no AI, keys or paid service. It does not claim broad trend discovery or that static rotation creates new questions.

```sh
python3 tools/refresh_bank.py dry-run
python3 tools/refresh_bank.py refresh
python3 tools/refresh_bank.py rollback --version <retained-version>
```

Immutable snapshots, an active/previous manifest and a durable fact catalog are published with each atomic Pages artifact. Source failure leaves the prior deployment live; no new eligible source leaves the bank unchanged. Scheduled runners restore prior published state first, so neither history keys nor prior versions depend on the Mac staying awake. See [source checks, deployment, rollback and free-tier findings](docs/QUESTION_BANK.md).

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

Current limitations: single-player and client-authoritative answers; landscape desktop layout; no host voice/lip-sync; finite practice pool (27 evergreen questions per theme); no online accounts/leaderboards; NASA-only current-question refresh; no accounts or model backend; insufficient bank for twelve repeat-free single-theme runs. The static practice game is published on GitHub Pages. The local server is not a public deployment service. The research document gives the next production steps.

## GitHub Pages publishing

The public repository is [nascarjake/trivia](https://github.com/nascarjake/trivia). Pushing to `main` runs `.github/workflows/pages.yml`: installs the pinned Godot release, runs the service and gameplay checks, exports the game, and deploys to Pages. Engine downloads are checksum-verified and official GitHub actions are pinned to commits. Only `builds/pages` is published; source and server files are not part of the Pages artifact.

To produce the identical static edition locally:

```sh
GODOT_BIN=godot sh tools/export_pages.sh
```

The `GitHub Pages` export preset adds the `github_pages` feature. Both editions fetch relative versioned bank snapshots; the local server additionally provides its compatibility API. GitHub Pages does not run the Python backend; no provider credentials belong in the exported game or repository. All web assets use relative paths so the game loads under `/trivia/`.
