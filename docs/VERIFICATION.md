# Verification — 17 September 2026

- Godot 4.7.2 release web export completed with matching single-thread web templates. Godot splash remains disabled.
- 12 Python service tests passed, including selected-category validation and a mocked research/composition/review sequence with canonical per-mix caching.
- Godot checks passed all 255 nonempty category combinations: exactly 15 unique questions, only selected themes, every selected theme represented, balanced counts, and increasing difficulty tiers. The practice bank has 120 questions.
- Gameplay checks passed the full 15-question win, both safety nets, failure payout, cash-out confirmation and cancellation, character replacement, and replay with the same themes and reset lifelines.
- Timed mode pauses under lifeline dialogs and pays the guarantee on expiry. Audience votes total 100 and exclude 50:50-eliminated answers.
- In-app browser review at 1280 × 720 verified empty and multiple category selection, visible character changes, question layout, keyboard answer lock, answer reveal, audience bars, and results. Console had no errors or warnings.
- The native viewport is 1600 × 900; the UI targets desktop landscape play. Original procedural characters retain inward-facing seats. Cameras and stage lighting respond to play state.

Not verified: live OpenAI requests or YouTube/X feeds (no credentials configured), production hosting, mobile/touch behavior, Safari, multiplayer, or sustained performance across devices. This remains an original procedural prototype rather than the Steam game's character assets.

## Local studio/bank enhancement — 2026-10-25

- Project `/Users/jacobclark/Source/trivia`; initial `main` at `1fc6797`, clean. Work isolated on `enhance/studio-question-rotation`; no push/deploy/main merge. No project-specific AGENTS.md was present.
- Python: 15 tests pass, including shared-bank HTTP 200/304, retired POST routes, date/schema/dedup failures, human-review binding, review preservation, mocked provider call/token/cadence bounds and disposable SQLite/D1 SQL/import round trips. Production bank remains 120.
- Godot 4.7.2 headless: all 255 theme combinations, twelve sufficient-capacity runs without repeats, actual-bank twelve-run simulation, explicit exhaustion, canonical dedup, expiry, save/reload with legacy fields, reveal input lock, answer text/bounds, two stage lights and original safeguards/lifelines/timer/replay pass. Actual bank simulation: 120 unique facts and 60 repeat slots across 180 slots; this is not a claim of zero repeats.
- Free dry-run: three NASA candidates validate and remain pending human review. Default paid-generation invocation rejects before network activity. Live provider generation has not been tested.
- Both Web and GitHub Pages export successfully. Sandboxed macOS Godot emits certificate/editor-preferences diagnostics; exports exit 0 and actual browser play works. No foreground Mac windows were opened.
- Headless Chromium: actual exported game at 1600×900 with reduced motion and 1280×720 with motion; lobby, question, locked and reveal states inspected. Zero browser/page errors; only one GET `/api/bank` per session, no per-play POSTs. Late progress callback and missing reveal glyph were fixed during this check.
- Local offscreen evidence (ignored): `builds/qa/question-1600.png`, `reveal-1600.png`, `locked-1280.png`, `question-1280.png`. No screen recording.
- Remaining: bank bootstrap/review, bounded paid-job approval/credentials/persistent host and separate deployment. D1 migration/SQL are prepared but no D1 database or adapter is active; no live freshness is claimed. See `QUESTION_BANK.md` for exact capacity/cost/cadence proposal.
