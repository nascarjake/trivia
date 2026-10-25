# Question bank / review path

Work is local on `enhance/studio-question-rotation`; nothing was pushed or deployed.

- Actual stack: Godot 4.7.2, Python standard library, GitHub Pages static export. No D1/Worker/cron configuration existed. Dependencies are unchanged.
- Current bank: 120 curated questions, 5 per theme/difficulty cell. It cannot meet twelve repeat-free runs. Minimum total is 180 for a fixed mix with appropriate tier coverage; any-single-theme coverage needs 1,440 (60/cell). Twelve daily runs for seven days needs 10,080 (420/cell). Full-mix balancing can require additional cell headroom.
- Canonical fact keys identify a fact, independent of wording/ID. Import rejects matching IDs, keys, or normalized wording against the whole snapshot, including retired facts. Semantic paraphrases with invented keys require the explicit human canonical-fact review; automatic semantic equivalence is not claimed. Seed keys remain stable. Never replace a key just to advertise freshness.
- Client history is anonymous/local, bounded to 10,080 distinct IDs/facts, saved when displayed. There was no prior question history or in-progress-run save to migrate; existing preferences/best scores survive. Clearing storage or changing origin/device loses history. Publication does not reset it.

## Free dry-run and review

```sh
python3 tools/question_batch.py dry-run --output server/cache/example-candidate.json
```

This validates the real `batches/example-candidate.json` against the active bank. The example is deliberately scoped to Science & space: one question per tier, two evergreen plus one current event. It is not a balanced eight-theme expansion and is not in gameplay. A production generated batch contains 24: one per each of eight themes × three tiers, at least 16 evergreen and at most 8 current. Manual batches may contain 3–48, evenly distributed across their declared theme/tier cells.

Candidates require an HTTPS source, source date, verification date, supporting claim, four distinct short answers, one correct index, and a reason each choice is correct/wrong. Current facts need sources within 14 days and expiry within 14 days of verification. Invalid/uncertain facts must be rejected, never filled in. The example expires naturally; re-research it rather than editing dates to pass validation. Its source dates are the pages' recorded update/publication dates, not invented research dates.

Sources inspected on 2026-10-25: [NASA Europa Clipper](https://science.nasa.gov/mission/europa-clipper/) and [NASA Dragonfly simulated flight, October 23](https://science.nasa.gov/blogs/dragonfly/2026/10/23/nasas-dragonfly-completes-first-simulated-flight/). Original questions use public facts, with no bank scraping or copied broadcast assets.

The adjacent `.review.json` starts **pending**. A human must open each source, independently solve the question, check all distractors and canonical keys, then fill reviewer/date, correct index, approved status and all five review checks. A SHA-256 digest binds decisions to the exact candidate content; editing questions invalidates review. Dry-runs preserve existing review decisions and refuse to overwrite different candidate work.

After that review, these commands change a local snapshot or emit SQL only:

```sh
python3 tools/question_batch.py publish --input server/cache/example-candidate.json --review server/cache/example-candidate.json.review.json
python3 tools/question_batch.py sql --input server/cache/example-candidate.json --review server/cache/example-candidate.json.review.json --output server/cache/reviewed.sql
```

`publish` atomically updates `game/data/questions.json`; no network action occurs. Static exports need rebuilding separately. `sql` targets `server/migrations/001_questions.sql`, a D1-compatible schema with a unique canonical fact key and selection index. Neither command provisions or contacts D1. Keep the source snapshot/review artifacts in version control when approving a production batch so retired fact keys stay available for deduplication.

## Scheduler-ready, disabled paid path

`python3 tools/question_batch.py generate --output server/cache/candidate-YYYY-MM-DD.json` is callable by a future persistent scheduler. It researches public sources with web search, composes JSON, validates locally and independently audits evidence in at most three provider requests. It produces candidates only, never auto-publishes. No retry loop; failed attempts consume the cadence allowance. Existing candidate/review paths are protected.

Recommended initial cadence: **weekly, 24 candidate questions**. Code permits one attempt per seven days and at most five in a rolling 31-day window, with a persistent atomic ledger and exclusive lock. Limits: research 6,000 output tokens, compose 12,000, audit 2,000; two web-tool calls maximum, input JSON at most 40,000 characters/request. The only allowed model is explicitly configured `gpt-5.4-mini`. All three stages and actual web-search integration remain untested with live credentials.

Cost proposal for approval: **at most $6 per 31 days**, zero spend now. At checked rates ($0.75/M input, $4.50/M output; web search $10/1,000 calls), even conservatively reserving the model's entire 400k input context for each of three calls gives $0.90 input + $0.09 output + $0.02 search = $1.01/attempt, or $5.05 for five attempts before tax. Actual ordinary batches should be much smaller. This estimate depends on unchanged model/pricing and includes search content within the conservative context allowance. Reconfirm availability/rates and an enforceable provider budget before enabling; the local cadence ledger is not an account-wide billing cap. [Model pricing/context](https://openai.com/index/introducing-gpt-5-4-mini-and-nano/) · [tool pricing](https://developers.openai.com/api/docs/pricing).

At 24 accepted questions/week, adding the 1,320 facts needed for the 1,440 target takes **55 weeks**; expiry/rejections can lengthen that. Weekly freshness does not replace a separately reviewed bootstrap expansion. Never claim a small refresh batch solves bank capacity.

Pending external enablement: approval for the cadence/model/$6 bound, server-only credentials, a chosen persistent scheduler host/ledger, and separately approved backend deployment. The explicit gate `TRIVIA_PAID_BATCH_APPROVAL=weekly-24-max3calls` remains unset. No cron or Dot automation was created. If D1 is chosen, approve the database/account and Worker hosting separately, apply the schema, connect the bank-serving adapter, and verify an actual scheduled run before claiming live freshness. Current Python hosting reads JSON; no live D1 adapter is claimed. [D1 usage pricing](https://developers.cloudflare.com/d1/platform/pricing/) and [Workers cron](https://developers.cloudflare.com/workers/configuration/cron-triggers/) were inspected; no service was provisioned.
