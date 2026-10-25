#!/usr/bin/env python3
"""Free, source-backed weekly bank refresh. No AI, keys, databases or paid APIs."""
import argparse
import datetime as dt
from email.utils import parsedate_to_datetime
import hashlib
import html
import json
from pathlib import Path
import re
import ssl
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server.bank import BANK_PATH, CATEGORIES, digest, normalized, today, validate_question
from tools.question_batch import write_json

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / 'bank'
FEED = 'https://www.nasa.gov/feed/'
# Fixed, distinct mission names, grouped by approximate familiarity. No model inference.
MISSIONS = {0: ['Artemis', 'Hubble', 'Webb'], 1: ['Roman', 'Europa Clipper', 'Psyche'],
            2: ['Swift', 'Dragonfly', 'SPHEREx', 'PUNCH', 'Lucy']}
MAX_BYTES = 1_000_000

def read_public(url):
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != 'https' or parsed.hostname not in {'www.nasa.gov', 'science.nasa.gov'} or parsed.username:
        raise ValueError('Unapproved primary-source URL')
    context = ssl.create_default_context(cafile='/etc/ssl/cert.pem') if Path('/etc/ssl/cert.pem').exists() else ssl.create_default_context()
    with urllib.request.urlopen(url, timeout=15, context=context) as response:
        final = urllib.parse.urlsplit(response.url)
        if final.hostname not in {'www.nasa.gov', 'science.nasa.gov'}: raise ValueError('Source redirected outside NASA')
        value = response.read(MAX_BYTES + 1)
    if len(value) > MAX_BYTES: raise ValueError('Source exceeded byte limit')
    return value

def headline(value):
    return re.sub(r'\s+', ' ', html.unescape(re.sub('<[^>]*>', '', value or ''))).strip()

def candidate_from_item(item, article, now):
    title = headline(item.findtext('title'))
    source = item.findtext('link') or ''
    parsed = urllib.parse.urlsplit(source)
    if parsed.scheme != 'https' or parsed.hostname not in {'www.nasa.gov', 'science.nasa.gov'}: raise ValueError('Non-NASA item')
    source = urllib.parse.urlunsplit((parsed.scheme, parsed.netloc, parsed.path, '', ''))
    published = parsedate_to_datetime(item.findtext('pubDate')).astimezone(dt.timezone.utc).date()
    if not now - dt.timedelta(days=14) <= published <= now: raise ValueError('Stale/future source')
    matches = [(d, name) for d, names in MISSIONS.items() for name in names if re.search(r'\b' + re.escape(name) + r'\b', title, re.I)]
    if len(matches) != 1: raise ValueError('Ambiguous or unsupported mission headline')
    difficulty, mission = matches[0]
    slug=mission.casefold().replace(' ', '-')
    if not re.search(r'/(?:missions?|blogs)/'+re.escape(slug)+r'(?:[-/])', parsed.path.casefold()):
        raise ValueError('Article is not in the recognized mission’s publisher topic')
    h1s = re.findall(r'<h1\b[^>]*>(.*?)</h1>', article, re.I | re.S)
    if normalized(title) not in [normalized(headline(h)) for h in h1s]: raise ValueError('Feed/article headline mismatch')
    redacted = re.sub(r'\b' + re.escape(mission) + r'\b', '____', title, flags=re.I)
    question = f'Which mission fills the blank in NASA’s {published.isoformat()} headline: “{redacted}”?' 
    if len(question) > 180: raise ValueError('Headline too long for readable question')
    # Each option is another distinct mission, never an alias or overlapping name.
    alternatives = [name for names in MISSIONS.values() for name in names if name != mission]
    answers = [mission, *alternatives[:3]]
    key = 'nasa-report:' + hashlib.sha256(source.encode()).hexdigest()[:24]
    q = dict(id=key, fact_key=key, question=question, answers=answers, correct=0, category='Science & space',
             difficulty=difficulty, explanation=f'NASA’s dated report names {mission}. This is a headline-identification question.',
             source=source, source_date=published.isoformat(), source_date_kind='publisher-rss-publication-date',
             verified_at=now.isoformat(), kind='current', expires_at=(now + dt.timedelta(days=14)).isoformat(),
             evidence=title, choice_notes=[f'The verified publisher headline names {mission}.'] +
             [f'{name} is a different mission and is not named in this headline.' for name in answers[1:]])
    validate_question(q, now)
    q['source_sha256'] = hashlib.sha256(article.encode()).hexdigest()
    return q

def validate_snapshot(questions, now=None):
    now = now or today()
    if not isinstance(questions, list) or not 201 <= len(questions) <= 1000: raise ValueError('Bank must contain 201–1000 facts')
    ids, facts, texts = set(), set(), set()
    cells = {(c, d): 0 for c in CATEGORIES for d in range(3)}
    for q in questions:
        validate_question(q, now, candidate=False)
        if q['id'] in ids or q['fact_key'] in facts or normalized(q['question']) in texts: raise ValueError('Bank has duplicate facts/IDs/wording')
        ids.add(q['id']); facts.add(q['fact_key']); texts.add(normalized(q['question']))
        cells[q['category'], q['difficulty']] += 1
    if min(cells.values()) < 8: raise ValueError('Insufficient category/difficulty coverage')
    if sum(q['kind'] == 'current' for q in questions) > len(questions) // 3: raise ValueError('Evergreen/current balance failed')
    return questions

def activate(questions, state=STATE, bank_path=BANK_PATH, reason='curated-bootstrap', now=None):
    """Complete immutable snapshot first, then atomic pointer/source replacement.

    Hosted publication uses one GitHub Pages artifact; readers never see half a deploy.
    Prior versions and question identities remain available for rollback/history.
    """
    now = now or today()
    validate_snapshot(questions, now)
    state = Path(state)
    version = digest(questions)[:20]
    snapshot = {'version': version, 'updated_at': now.isoformat(), 'questions': questions,
                'refresh': {'cadence': 'weekly', 'method': 'NASA publisher-headline identification', 'reason': reason,
                            'generation_calls': 0, 'source_requests_max': 4}}
    destination = state / 'versions' / (version + '.json')
    if destination.exists():
        saved=json.loads(destination.read_text())
        if saved['questions'] != questions: raise ValueError('Immutable version collision')
        snapshot=saved
    else: write_json(destination, snapshot)
    old = json.loads((state / 'manifest.json').read_text()) if (state / 'manifest.json').exists() else {}
    catalog = json.loads((state / 'fact-catalog.json').read_text()) if (state / 'fact-catalog.json').exists() else {}
    for q in questions: catalog[q['fact_key']] = q['id']
    write_json(state / 'fact-catalog.json', catalog)
    write_json(bank_path, questions)
    write_json(state / 'current.json', snapshot)
    history = list(dict.fromkeys([version] + old.get('history', []) + ([old['active']] if old.get('active') else [])))[:8]
    write_json(state / 'manifest.json', {'active': version, 'previous': old.get('previous') if old.get('active') == version else old.get('active'), 'history': history, 'updated_at': snapshot['updated_at'],
                                       'count': len(questions), 'path': 'versions/' + version + '.json'})
    return snapshot

def refresh(dry_run=False, state=STATE, bank_path=BANK_PATH, now=None, fetch=read_public):
    now = now or today()
    existing = json.loads(Path(bank_path).read_text())
    evergreen = [q for q in existing if q['kind'] == 'evergreen']
    validate_snapshot(evergreen, now) # Current-event expiry can never shrink the core below 201.
    catalog = json.loads((Path(state) / 'fact-catalog.json').read_text()) if (Path(state) / 'fact-catalog.json').exists() else {}
    feed = ET.fromstring(fetch(FEED))
    chosen = {}
    attempts = 0
    for item in feed.findall('./channel/item')[:60]:
        title = headline(item.findtext('title'))
        matches = [(d, name) for d, names in MISSIONS.items() for name in names if re.search(r'\b'+re.escape(name)+r'\b',title,re.I)]
        if len(matches) != 1 or matches[0][0] in chosen: continue
        source = item.findtext('link') or ''
        canonical = urllib.parse.urlsplit(source)
        source = urllib.parse.urlunsplit((canonical.scheme, canonical.netloc, canonical.path, '', ''))
        key = 'nasa-report:' + hashlib.sha256(source.encode()).hexdigest()[:24]
        if key in catalog: continue # Same report/rewording never becomes a fresh fact.
        if attempts >= 3: break
        attempts += 1
        try: q = candidate_from_item(item, fetch(source).decode('utf8'), now)
        except (ValueError, TypeError, UnicodeError, OSError): continue
        chosen[q['difficulty']] = q
        if len(chosen) == 3: break
    if not chosen:
        return {'questions': existing, 'version': digest(existing)[:20], 'no_change': True, 'dry_run': dry_run}
    questions = evergreen + [chosen[d] for d in sorted(chosen)]
    validate_snapshot(questions, now)
    if not dry_run: return activate(questions, state, bank_path, 'weekly-source-refresh', now)
    return {'questions': questions, 'version': digest(questions)[:20], 'dry_run': True}

def hydrate_published(base_url):
    """Restore prior published state for a stateless free runner; no write credentials.

    Only validated SHA-bound snapshots become local state. Missing first deployment
    uses the committed bootstrap. Other failures stop publication and retain live data.
    """
    import urllib.error
    parsed = urllib.parse.urlsplit(base_url)
    if parsed.scheme != 'https' or parsed.hostname != 'nascarjake.github.io' or parsed.path.rstrip('/') != '/trivia':
        raise ValueError('Unexpected published-bank origin')
    def public_json(path):
        context=ssl.create_default_context(cafile='/etc/ssl/cert.pem') if Path('/etc/ssl/cert.pem').exists() else ssl.create_default_context()
        with urllib.request.urlopen(base_url.rstrip('/') + '/bank/' + path, timeout=15, context=context) as response:
            raw=response.read(MAX_BYTES+1)
        if len(raw)>MAX_BYTES: raise ValueError('Published state too large')
        return json.loads(raw)
    try: manifest=public_json('manifest.json')
    except urllib.error.HTTPError as error:
        if error.code == 404: return False
        raise
    active=manifest.get('active','')
    if not re.fullmatch('[a-f0-9]{20}',active): raise ValueError('Invalid published version')
    snapshot=public_json('versions/'+active+'.json')
    if digest(snapshot['questions'])[:20] != active: raise ValueError('Published snapshot hash mismatch')
    validate_snapshot([q for q in snapshot['questions'] if q['kind']=='evergreen'])
    catalog=public_json('fact-catalog.json')
    if not isinstance(catalog,dict) or len(catalog)>20000: raise ValueError('Invalid fact catalog')
    versions={active:snapshot}
    for version in manifest.get('history',[])[:8]:
        if not re.fullmatch('[a-f0-9]{20}',version): raise ValueError('Invalid retained version')
        if version not in versions:
            saved=public_json('versions/'+version+'.json')
            if digest(saved['questions'])[:20]!=version: raise ValueError('Retained snapshot hash mismatch')
            versions[version]=saved
    for version,saved in versions.items():write_json(STATE/'versions'/(version+'.json'),saved)
    # Carry the repo's reviewed core and the live current questions/catalog forward.
    committed=json.loads(BANK_PATH.read_text())
    core=[q for q in committed if q['kind']=='evergreen']
    current=[q for q in snapshot['questions'] if q['kind']=='current' and q['expires_at']>today().isoformat()]
    combined=core+current
    validate_snapshot(combined)
    write_json(STATE/'manifest.json',manifest)
    write_json(STATE/'fact-catalog.json',catalog)
    write_json(BANK_PATH,combined)
    return True


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['bootstrap','dry-run','refresh','rollback','hydrate'])
    parser.add_argument('--version')
    parser.add_argument('--published-url',default='https://nascarjake.github.io/trivia/')
    args=parser.parse_args()
    if args.action == 'hydrate':
        print(json.dumps({'restored':hydrate_published(args.published_url)}));return
    if args.action == 'bootstrap': value=activate(json.loads(BANK_PATH.read_text()))
    elif args.action == 'rollback':
        if not args.version or not re.fullmatch('[a-f0-9]{20}',args.version): raise ValueError('A saved version is required')
        value=activate(json.loads((STATE/'versions'/(args.version+'.json')).read_text())['questions'],reason='explicit-rollback')
    else: value=refresh(args.action=='dry-run')
    print(json.dumps({'version':value['version'],'questions':len(value['questions']),'dry_run':value.get('dry_run',False),'generation_calls':0,'no_change':value.get('no_change',False)}))

if __name__=='__main__':
    try:main()
    except (ValueError,OSError,ET.ParseError) as error:
        print('REFRESH REJECTED; previous published bank retained: '+str(error),file=sys.stderr);sys.exit(1)
