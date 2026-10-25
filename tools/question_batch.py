#!/usr/bin/env python3
"""Free offline curation/import tooling. Scheduled source refresh is in refresh_bank.py."""
import argparse
import datetime as dt
import json
import os
from pathlib import Path
import sys
import urllib.request
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server.bank import BANK_PATH, CATEGORIES, capacity, digest, public_question, today, validate_batch, validate_review


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')
    temporary.replace(path)


def review_template(batch):
    return {'batch_sha256': digest(batch), 'decisions': {q['id']: {
        'status': 'pending', 'correct': None, 'reviewer': '', 'reviewed_at': today().isoformat(),
        'source_checked': False, 'one_correct': False, 'distractors_checked': False,
        'canonical_fact_checked': False, 'original_wording': False} for q in batch['questions']}}


def stage_candidate(output, batch):
    path = Path(output)
    review_path = Path(str(output) + '.review.json')
    if path.exists() and json.loads(path.read_text()) != batch:
        raise ValueError('Candidate path already contains different work; choose a new output')
    write_json(path, batch)
    if not review_path.exists(): write_json(review_path, review_template(batch))


def generate_candidate(output):
    raise ValueError('Paid/model generation is disabled by the free-only requirement. Use tools/refresh_bank.py.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['dry-run', 'generate', 'publish', 'sql', 'capacity'])
    parser.add_argument('--input', default='batches/example-candidate.json')
    parser.add_argument('--output', default='server/cache/candidate.json')
    parser.add_argument('--review')
    args = parser.parse_args()
    existing = json.loads(BANK_PATH.read_text())
    if args.action == 'capacity':
        print(json.dumps(capacity(existing), indent=2)); return
    if args.action == 'generate':
        generate_candidate(args.output); print('Candidate only; human review required.'); return
    batch = json.loads(Path(args.input).read_text())
    validate_batch(batch, existing)
    if args.action == 'dry-run':
        stage_candidate(args.output, batch)
        print(f'VALID: {len(batch["questions"])} candidates; pending human review; 0 provider calls; bank unchanged.'); return
    if not args.review: raise ValueError('--review is required for publication or SQL export')
    validate_review(batch, json.loads(Path(args.review).read_text()))
    if args.action == 'publish':
        # Local reversible snapshot change; no network, main merge, or deployment.
        merged = existing + [public_question(q) for q in batch['questions']]
        write_json(BANK_PATH, merged)
        print(f'Local bank updated to {len(merged)} questions; redeploy remains separate.'); return
    def sql_string(value): return "'" + str(value).replace("'", "''") + "'"
    rows = ['-- Reviewed candidate SQL only. Apply to an approved D1 database separately.', 'BEGIN TRANSACTION;']
    for q in batch['questions']:
        values = [q['id'], q['fact_key'], q['category'], q['difficulty'], q.get('expires_at', ''), json.dumps(public_question(q), ensure_ascii=False)]
        rows.append('INSERT INTO questions(id,fact_key,category,difficulty,expires_at,payload) VALUES (' + ','.join(sql_string(x) for x in values) + ');')
    rows.append('COMMIT;')
    Path(args.output).write_text('\n'.join(rows) + '\n')
    print('SQL written; no database created or contacted.')

if __name__ == '__main__':
    try: main()
    except (ValueError, OSError, KeyError, TypeError) as error:
        print(f'REJECTED: {error}', file=sys.stderr); sys.exit(1)
