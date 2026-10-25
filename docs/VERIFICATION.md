# Verification — 17 September 2026

- Godot 4.7.2 release web export completed with matching single-thread web templates. Godot splash remains disabled.
- 12 Python service tests passed, including selected-category validation and a mocked research/composition/review sequence with canonical per-mix caching.
- Godot checks passed all 255 nonempty category combinations: exactly 15 unique questions, only selected themes, every selected theme represented, balanced counts, and increasing difficulty tiers. The practice bank has 120 questions.
- Gameplay checks passed the full 15-question win, both safety nets, failure payout, cash-out confirmation and cancellation, character replacement, and replay with the same themes and reset lifelines.
- Timed mode pauses under lifeline dialogs and pays the guarantee on expiry. Audience votes total 100 and exclude 50:50-eliminated answers.
- In-app browser review at 1280 × 720 verified empty and multiple category selection, visible character changes, question layout, keyboard answer lock, answer reveal, audience bars, and results. Console had no errors or warnings.
- The native viewport is 1600 × 900; the UI targets desktop landscape play. Original procedural characters retain inward-facing seats. Cameras and stage lighting respond to play state.

Not verified: live OpenAI requests or YouTube/X feeds (no credentials configured), production hosting, mobile/touch behavior, Safari, multiplayer, or sustained performance across devices. This remains an original procedural prototype rather than the Steam game's character assets.

## Studio and free weekly bank — 2026-10-25

- Project `/Users/jacobclark/Source/trivia`; initially clean `main` at `1fc6797`. Initial local work committed as `ecba64f`; subsequent expanded scope authorizes publication and free weekly updates.
- Active bank: 218 facts, including 216 evergreen (nine per theme/tier) and two real NASA headline questions. Ninety-six source-backed evergreen additions, with reviewed batches and source-audit records. Existing Stardew Valley, Fool’s Mate and Wi-Fi wording corrected without resetting stable identities.
- Python suite: 17 checks pass, including source/date/schema/dedup validation, review/import preservation, cache behavior, primary RSS/article headline agreement, source-request bounds, atomic failure retention and snapshot rollback.
- Verified Godot 4.7.2: all 255 theme mixes, actual-bank twelve-run rotation (180 unique facts / zero repeats), exhaustion, dedup, expiry, save/reload with legacy fields, reveal input lock, answer bounds, lights and original gameplay checks pass. Engine archive and executed binary were checked against official upstream provenance; see QUESTION_BANK.md.
- Earlier actual-browser checks passed at 1600×900/reduced motion and 1280×720/motion. Final source-backed edition is rebuilt for the same actual game; browser/live endpoint evidence is reported with publication. Screenshots remain under ignored `builds/qa/`.
- The source-only refresh was exercised against the real NASA RSS feed and articles: two valid current questions, no model calls. The Pages workflow now schedules weekly source refresh and restores durable public snapshots/catalog before update. It reuses existing token permissions and the public standard runner.
- Cloudflare personal-profile/account/inventory reads succeeded; subscription read returned 403. No account upgrade, new scope, credential, Worker, D1 or paid AI service was created. The existing public GitHub Pages/Actions path provides free hosting and persistence.
- Single-theme 12-run coverage remains a distinct 1,440-question target. Current-event questions are headline identification, and the automated source coverage is NASA-only. Source failures preserve the prior live bank.
