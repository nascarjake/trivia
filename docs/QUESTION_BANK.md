# Bank, weekly refresh and free operation

Current bank: **218 active questions**, including **216 evergreen facts** (nine per theme/tier cell) and two dated NASA headline questions. Four reviewed source batches add 96 original evergreen facts. `batches/source-audit-2026-10-25.json` records source support: 79 direct bounded fetch/term checks, with the remaining 17 checked against the official publisher pages or indexed excerpts and reviewed for factual/distractor correctness. Wordings were checked against the existing bank; canonical keys identify facts, not paraphrases. Ordinary source-backed facts can be reviewed by the agent; no per-question human approval is required.

Existing-bank review corrected the solo-developer attribution for Stardew Valley 1.0, the meaning of a numbered move in Fool’s Mate, and the attribution of the Wi-Fi naming claim. Their stable IDs/keys were retained. The new facts use primary publishers including Nintendo, FIDE, Yamaha, Pixar, NASA, W3C/IETF, Google documentation, UNESCO, Kew and source research indexed by FAO. No proprietary question bank, broadcast logo, or music was copied.

## Rotation and capacity

The actual bank supports twelve full-mix runs: 180 displayed facts with zero repeat slots in the gameplay check. Narrow pools still exhaust: any-single-theme coverage for twelve runs needs **1,440 total** (60 per tier/theme), and twelve daily runs for seven days needs **10,080** (420/cell). These are separate targets. Client history retains 10,080 distinct IDs/facts, is saved when displayed and survives bank publication. It is local to the browser/device/origin; clearing storage or changing origin loses it. No in-progress run save or account history is claimed.

## Live weekly mechanism

The existing `.github/workflows/pages.yml` has a Monday `08:17 UTC` cron plus an optional manual refresh input. The standard Ubuntu runner in the existing **public** repository runs `tools/refresh_bank.py` and the existing game build/deploy. No local computer, Dot task, new secret, provider account or enlarged workflow-token permission is required.

The job restores the previous published manifest, immutable snapshot, fact catalog and up to eight retained versions. It fetches `https://www.nasa.gov/feed/` and at most three NASA-hosted article bodies (15-second timeout, 1 MB limit each). Only items from the past 14 days are considered. Exactly one recognized mission must occur in the publisher headline; the article H1 must match the feed headline. URLs are canonicalized and hashed for stable keys. Rewording or tracking parameters cannot make an old report fresh.

The free question template asks which mission fills the blank in a dated NASA headline. Distractors are distinct mission names. These are **headline-identification questions**, not a claim of deep factual synthesis or broad trend research. Up to one question per tier is selected, with at most three per week. The evergreen core remains 216; current questions expire after 14 days. In the initial real dry-run, two eligible headlines were found: Artemis and Swift. No model call or provider key was used.

`validate_snapshot` checks the entire replacement: >200 questions, ID/fact/text uniqueness, four distinct choices, valid answer index, source URL, expiry and minimum theme/tier coverage. It stages an immutable version before atomically replacing the active pointer. GitHub Pages publishes the whole artifact atomically, so live readers see a complete old or new bank. Source failure fails the build and leaves the prior live deployment; no eligible new report preserves the bank. Failed/expired current content never removes the >200-question evergreen core.

The game reads `bank/manifest.json`, then the SHA-bound `bank/versions/<version>.json`. IDs/fact keys remain stable across versions. Rollback is `python3 tools/refresh_bank.py rollback --version <retained-version>`, followed by the existing Pages publication; the previous application deployment and Git history remain available too. No wipe-first operation exists.

## Free-tier decision and cost

The chosen path is the existing **public GitHub repository + GitHub Pages + standard GitHub-hosted Ubuntu Actions**, documented as free for public repositories/Pages. It introduces no model calls, billable API or database. Refresh uses at most four publisher requests plus bounded reads of the existing published state. Pages artifact retention is one day; no new cache/artifact service is added. [GitHub billing documentation](https://docs.github.com/en/billing/concepts/product-billing/github-actions).

The existing personal Cloudflare profile was read successfully. No trivia D1 database or Worker existed. Account settings returned `default_usage_model: standard`; the subscription-list read returned **403 Forbidden** with the current credential. Therefore the account’s free-plan billing stop could not be verified. No new OAuth scope, credential, plan or Cloudflare resource was created. Existing unrelated resources were not modified.

Official Cloudflare docs checked 2026-10-25: Workers Free includes 100,000 requests/day and 10 ms CPU/invocation; five Cron triggers/account. D1 Free includes 5 million rows read/day, 100,000 written/day and 5 GB total storage, and stops queries at the free limits. Workers AI includes 10,000 neurons/day; **paid accounts can incur overage**. These published free allowances do not prove this existing account is on a free plan. [Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/) · [limits](https://developers.cloudflare.com/workers/platform/limits/) · [D1](https://developers.cloudflare.com/d1/platform/pricing/) · [AI](https://developers.cloudflare.com/workers-ai/platform/pricing/).

D1 remains an optional future adapter: `server/migrations/001_questions.sql` and reviewed SQL export exist, but the current durable bank is published versioned JSON. Verifying the Cloudflare subscription requires a separate billing-read permission action; it is unnecessary for this working free path.

The earlier weekly 24-question/$6 proposal was an **unmeasured conservative estimate**, not an observed bill or a free-tier claim: five attempts × (three full 400k input contexts at $0.75/M + 20k capped output tokens at $4.50/M + two $0.01 searches) = $5.05 before tax. It was superseded by the free-only instruction. Paid-generation code is now disabled; current measured provider-call count is **zero**. A 24-question AI batch is not claimed by the free NASA curation job.

## Engine provenance

Before further tests, the existing Godot 4.7.2 macOS archive matched a freshly fetched **official** SHA512-SUMS file: `38aa16e5bba2083941fc5b3e54be0089bd4cc35e32415f5b9fd9a8a6a7b9818255d44532ea8ef94b5aef56c4b407c2d634fa4f657e4ebe681ebbf59b7bac69ca`. The executed binary exactly matched the binary inside that archive (SHA256 `c7cccbf8fb143e34e02fd6521e09be2c2b974f0d5db080b19071c9c570718ccf`). The workflow’s Linux SHA256 was also checked against the official release asset digest: `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4`. [Official release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
