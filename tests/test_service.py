import copy
import datetime as dt
import http.client
import http.server
import io
import json
from pathlib import Path
import sqlite3
import tempfile
import threading
import unittest
from unittest.mock import patch
from server import app, bank
from tools import question_batch

NOW = dt.date(2026, 10, 25)

class BankTests(unittest.TestCase):
    def setUp(self):
        clock = patch.object(bank, 'today', return_value=NOW); clock.start(); self.addCleanup(clock.stop)
        batch_clock = patch.object(question_batch, 'today', return_value=NOW); batch_clock.start(); self.addCleanup(batch_clock.stop)
        self.batch = json.loads((bank.ROOT / 'batches/example-candidate.json').read_text())
        self.existing = json.loads(bank.BANK_PATH.read_text())
        for i, q in enumerate(self.batch['questions']):
            q['id'] = 'test-candidate-' + str(i)
            q['fact_key'] = 'test-candidate:' + str(i)
            q['question'] = 'Fixture: ' + q['question']

    def test_seed_capacity_and_schema(self):
        self.assertGreaterEqual(len(bank.load_bank()), 201)
        self.assertEqual(len({q['fact_key'] for q in self.existing}), len(self.existing))
        for q in self.existing: bank.validate_question(q, NOW, candidate=False)
        report = bank.capacity(self.existing)
        self.assertEqual(report['single_theme_target'], 1440)
        self.assertTrue(all(min(v) >= 9 for v in report['cells'].values()))

    def test_valid_balanced_candidate(self):
        self.assertEqual(bank.validate_batch(self.batch, self.existing, NOW), self.batch)

    def test_bad_answers_rejected(self):
        for mutation in [lambda q: q.update(correct=True), lambda q: q.update(correct=4),
                         lambda q: q['answers'].__setitem__(1, q['answers'][0].upper())]:
            batch = copy.deepcopy(self.batch); mutation(batch['questions'][0])
            with self.assertRaises(ValueError): bank.validate_batch(batch, self.existing, NOW)

    def test_paraphrase_key_and_text_dedup(self):
        for key in ['id', 'fact_key', 'question']:
            batch = copy.deepcopy(self.batch)
            batch['questions'][0][key] = self.existing[0][key]
            with self.assertRaises(ValueError): bank.validate_batch(batch, self.existing, NOW)

    def test_stale_invalid_source_and_relative_dates(self):
        for fields in [{'verified_at': '2026-01-01'}, {'source_date': '2026-11-01'},
                       {'source': 'http://example.com'}, {'expires_at': '2026-10-25'},
                       {'verified_at': 'not-a-date'}, {'question': 'Who is currently in charge?'}]:
            batch = copy.deepcopy(self.batch); batch['questions'][1].update(fields)
            with self.assertRaises(ValueError): bank.validate_batch(batch, self.existing, NOW)

    def test_missing_distractor_evidence_and_balance(self):
        for fields in [{'choice_notes': []}, {'evidence': ''}, {'difficulty': 0}]:
            batch = copy.deepcopy(self.batch); batch['questions'][1].update(fields)
            with self.assertRaises(ValueError): bank.validate_batch(batch, self.existing, NOW)

    def test_pending_review_and_edits_block_publication(self):
        review = question_batch.review_template(self.batch)
        with self.assertRaises(ValueError): bank.validate_review(self.batch, review)
        for q in self.batch['questions']:
            review['decisions'][q['id']].update(status='approved', correct=q['correct'], reviewer='Test fixture',
                source_checked=True, one_correct=True, distractors_checked=True, canonical_fact_checked=True, original_wording=True)
        bank.validate_review(self.batch, review)
        self.batch['questions'][0]['question'] += ' Edited'
        with self.assertRaises(ValueError): bank.validate_review(self.batch, review)

    def test_published_expired_entries_are_filtered(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'bank.json'
            questions = copy.deepcopy(self.existing)
            questions[0].update(kind='current', expires_at='2026-10-25')
            path.write_text(json.dumps(questions))
            self.assertEqual(len(bank.load_bank(path, NOW)), len(self.existing)-1)

    def test_staging_preserves_human_review(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'candidate.json'
            question_batch.stage_candidate(path, self.batch)
            review_path = Path(str(path) + '.review.json')
            review = json.loads(review_path.read_text()); review['decisions'][self.batch['questions'][0]['id']]['reviewer'] = 'Keep human note'
            review_path.write_text(json.dumps(review))
            question_batch.stage_candidate(path, self.batch)
            self.assertEqual(json.loads(review_path.read_text()), review)
            self.batch['questions'][0]['question'] += ' Changed'
            with self.assertRaises(ValueError): question_batch.stage_candidate(path, self.batch)

    def test_default_generation_gate_no_network(self):
        with patch.dict('os.environ', {}, clear=True), patch('urllib.request.urlopen') as network:
            with self.assertRaises(ValueError): question_batch.generate_candidate('/tmp/unused-candidate.json')
            network.assert_not_called()

    def test_local_import_and_sql_require_exact_review(self):
        review = question_batch.review_template(self.batch)
        for q in self.batch['questions']:
            review['decisions'][q['id']].update(status='approved', correct=q['correct'], reviewer='TEST FIXTURE ONLY',
                source_checked=True, one_correct=True, distractors_checked=True, canonical_fact_checked=True, original_wording=True)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); bank_file = root / 'bank.json'; input_file = root / 'candidate.json'
            review_file = root / 'review.json'; sql_file = root / 'batch.sql'
            bank_file.write_text(json.dumps(self.existing)); input_file.write_text(json.dumps(self.batch)); review_file.write_text(json.dumps(review))
            with patch.object(question_batch, 'BANK_PATH', bank_file), patch.object(bank, 'today', return_value=NOW):
                with patch('sys.argv', ['batch', 'sql', '--input', str(input_file), '--review', str(review_file), '--output', str(sql_file)]):
                    question_batch.main()
                connection = sqlite3.connect(':memory:')
                connection.executescript((bank.ROOT / 'server/migrations/001_questions.sql').read_text())
                connection.executescript(sql_file.read_text())
                self.assertEqual(connection.execute('SELECT COUNT(*) FROM questions').fetchone()[0], 3)
                connection.close()
                with patch('sys.argv', ['batch', 'publish', '--input', str(input_file), '--review', str(review_file)]):
                    question_batch.main()
                self.assertEqual(len(json.loads(bank_file.read_text())), len(self.existing)+3)
                with patch('sys.argv', ['batch', 'publish', '--input', str(input_file), '--review', str(review_file)]):
                    with self.assertRaises(ValueError): question_batch.main()

    def test_d1_schema_rejects_fact_duplicates(self):
        connection = sqlite3.connect(':memory:')
        connection.executescript((bank.ROOT / 'server/migrations/001_questions.sql').read_text())
        connection.execute("INSERT INTO questions VALUES ('a','same','Gaming',0,'','{}')")
        with self.assertRaises(sqlite3.IntegrityError):
            connection.execute("INSERT INTO questions VALUES ('b','same','Gaming',0,'','{}')")
        connection.close()

class HTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), app.Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True); cls.thread.start()
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown(); cls.server.server_close(); cls.thread.join()
    def request(self, method, path, headers=None):
        connection = http.client.HTTPConnection(*self.server.server_address)
        connection.request(method, path, headers=headers or {})
        response = connection.getresponse(); data = response.read()
        result = response.status, dict(response.getheaders()), data
        connection.close(); return result
    def test_shared_bank_etag_and_no_generation_routes(self):
        status, headers, data = self.request('GET', '/api/bank')
        self.assertEqual(status, 200); self.assertGreaterEqual(len(json.loads(data)['questions']), 201)
        self.assertEqual(headers['Cache-Control'], 'public, max-age=300')
        self.assertEqual(self.request('GET', '/api/bank', {'If-None-Match': headers['ETag']})[0], 304)
        for route in ['/api/pack', '/api/lifeline']:
            self.assertEqual(self.request('POST', route)[0], 410)
    def test_config_reports_free_weekly_method(self):
        config = json.loads(self.request('GET', '/api/config')[2])
        self.assertTrue(config['scheduled_refresh']); self.assertFalse(config['ai_available'])

if __name__ == '__main__': unittest.main()
