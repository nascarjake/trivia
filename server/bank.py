"""Shared, durable question snapshots and review-first batch validation. No paid calls."""
import collections
import datetime as dt
import hashlib
import json
from pathlib import Path
import re
import unicodedata
import urllib.parse

ROOT = Path(__file__).resolve().parents[1]
BANK_PATH = ROOT / 'game/data/questions.json'
CATEGORIES = ['Internet & creators', 'Gaming', 'Music', 'Film & TV', 'Science & space', 'Technology', 'Sports', 'Culture & food']
MAX_BATCH = 48

def today():
    return dt.datetime.now(dt.timezone.utc).date()

def normalized(text):
    return re.sub(r'[^\w]+', ' ', unicodedata.normalize('NFKC', text).casefold()).strip()

def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()

def date(value):
    if not isinstance(value, str): raise ValueError('Date must be ISO YYYY-MM-DD')
    parsed = dt.date.fromisoformat(value)
    if parsed.isoformat() != value: raise ValueError('Date must be ISO YYYY-MM-DD')
    return parsed

def validate_question(q, now=None, candidate=True):
    now = now or today()
    if not isinstance(q, dict): raise ValueError('Question must be an object')
    for field, maximum in [('id', 80), ('fact_key', 180), ('question', 180), ('explanation', 400), ('source', 500)]:
        if not isinstance(q.get(field), str) or not q[field].strip() or len(q[field]) > maximum:
            raise ValueError(f'Invalid {field}')
    if not re.fullmatch(r'[a-z0-9][a-z0-9:._-]*', q['fact_key']): raise ValueError('Canonical fact key required')
    if q.get('category') not in CATEGORIES or type(q.get('difficulty')) is not int or q['difficulty'] not in range(3):
        raise ValueError('Invalid category/difficulty')
    answers = q.get('answers')
    if not isinstance(answers, list) or len(answers) != 4 or any(not isinstance(a, str) or not a.strip() or len(a) > 48 for a in answers):
        raise ValueError('Four short choices required')
    if len({unicodedata.normalize('NFKC', a).strip().casefold() for a in answers}) != 4: raise ValueError('Duplicate choices')
    if type(q.get('correct')) is not int or q['correct'] not in range(4): raise ValueError('One correct index required')
    url = urllib.parse.urlsplit(q['source'])
    if url.scheme != 'https' or not url.hostname or url.username or url.password: raise ValueError('Public HTTPS source required')
    if q.get('kind') not in ['evergreen', 'current']: raise ValueError('Question kind required')
    expiry = q.get('expires_at', '')
    if expiry and date(expiry) <= now: raise ValueError('Expired question')
    if candidate:
        checked = date(q.get('verified_at'))
        published = date(q.get('source_date'))
        if published > checked or checked > now or (now - checked).days > 30: raise ValueError('Invalid/stale evidence dates')
        if q['kind'] == 'current':
            if not expiry or not checked < date(expiry) <= checked + dt.timedelta(days=14): raise ValueError('Current facts expire within 14 days')
            if (checked - published).days > 14: raise ValueError('Current topics need recent sources')
        if any(word in normalized(q['question']).split() for word in ['latest', 'currently', 'today', 'yesterday']):
            raise ValueError('Use explicit dates, not relative wording')
        if not isinstance(q.get('evidence'), str) or not 15 <= len(q['evidence']) <= 600: raise ValueError('Supporting claim required')
        notes = q.get('choice_notes')
        if not isinstance(notes, list) or len(notes) != 4 or any(not isinstance(n, str) or len(n) < 12 for n in notes):
            raise ValueError('Explain why each choice is correct or wrong')
    return q

def load_bank(path=BANK_PATH, now=None):
    now = now or today()
    questions = json.loads(Path(path).read_text())
    active = []
    for q in questions:
        # Published seeds predate evidence-date schema; keep their stable identity.
        if q.get('expires_at') and date(q['expires_at']) <= now: continue
        validate_question(q, now, candidate=False)
        active.append(q)
    return active

def validate_batch(batch, existing=(), now=None):
    now = now or today()
    if not isinstance(batch, dict) or batch.get('schema_version') != 1: raise ValueError('Batch schema_version 1 required')
    qs = batch.get('questions')
    if not isinstance(qs, list) or not 3 <= len(qs) <= MAX_BATCH: raise ValueError('Batch size must be 3–48')
    if date(batch.get('created_at')) > now: raise ValueError('Future batch date')
    scope = batch.get('categories')
    if not isinstance(scope, list) or not scope or len(scope) != len(set(scope)) or any(c not in CATEGORIES for c in scope): raise ValueError('Declare category scope')
    if len(qs) % (3 * len(scope)): raise ValueError('Balance each category and difficulty cell')
    expected = len(qs) // (3 * len(scope))
    counts = collections.Counter((q.get('category'), q.get('difficulty')) for q in qs if isinstance(q, dict))
    if counts != collections.Counter({(c, d): expected for c in scope for d in range(3)}): raise ValueError('Unbalanced category/difficulty cells')
    if sum(q.get('kind') == 'current' for q in qs) > len(qs) // 3: raise ValueError('At least two thirds evergreen')
    ids, facts, texts = set(), set(), set()
    # Include expired/retired entries in this input: rewording old facts is not freshness.
    for q in [*existing, *qs]:
        if q in qs: validate_question(q, now)
        keys = (q['id'], q['fact_key'], normalized(q['question']))
        if keys[0] in ids or keys[1] in facts or keys[2] in texts: raise ValueError('Duplicate ID, canonical fact, or wording')
        ids.add(keys[0]); facts.add(keys[1]); texts.add(keys[2])
    return batch

def validate_review(batch, review):
    if review.get('batch_sha256') != digest(batch): raise ValueError('Review does not match exact batch bytes/content')
    approvals = review.get('decisions', {})
    for q in batch['questions']:
        decision = approvals.get(q['id'], {})
        if decision.get('status') != 'approved' or decision.get('correct') != q['correct']:
            raise ValueError('Every question requires a recorded answer-key review')
        if not all(decision.get(k) is True for k in ['source_checked', 'one_correct', 'distractors_checked', 'canonical_fact_checked', 'original_wording']):
            raise ValueError('Incomplete factual/dedup review')
        if not isinstance(decision.get('reviewer'), str) or not decision['reviewer'].strip(): raise ValueError('Reviewer required')
        if date(decision.get('reviewed_at')) > today(): raise ValueError('Future review')
    return True

def public_question(q):
    return {k: v for k, v in q.items() if k not in ['evidence', 'choice_notes']}

def capacity(questions):
    cells = collections.Counter((q['category'], q['difficulty']) for q in questions)
    return {'questions': len(questions), 'run_length': 15, 'twelve_runs': 180,
            'single_theme_target': 1440, 'twelve_daily_for_week_target': 10080,
            'cells': {c: [cells[c, d] for d in range(3)] for c in CATEGORIES}}
