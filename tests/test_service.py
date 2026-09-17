import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from server import app

class QuestionValidationTests(unittest.TestCase):
    def setUp(self):
        self.questions = json.loads((Path(__file__).resolve().parents[1] / 'game/data/questions.json').read_text())
        self.pack = {'questions': [copy.deepcopy(q) for d in range(3) for q in [x for x in self.questions if x['difficulty'] == d][:5]]}
        self.urls = {q['source'] for q in self.questions}

    def test_curated_bank_has_valid_unique_choices_and_tiers(self):
        self.assertEqual(120, len(self.questions))
        for category in app.CATEGORIES:
            for difficulty in range(3):
                self.assertEqual(5, sum(q['category'] == category and q['difficulty'] == difficulty for q in self.questions))
        self.assertEqual(120, len({q['question'] for q in self.questions}))
        for d in range(3): self.assertGreaterEqual(sum(q['difficulty'] == d for q in self.questions), 5)
        app.validate_pack(self.pack, self.urls)

    def test_category_selection_is_canonical(self):
        self.assertEqual(app.normalize_categories(['Music', 'Gaming', 'Music']), ('Gaming', 'Music'))
        for value in [[], 'Gaming', ['Unknown'], [None]]:
            with self.assertRaises(ValueError): app.normalize_categories(value)

    def test_single_category_pack(self):
        pack = {'questions': [copy.deepcopy(q) for q in self.questions if q['category'] == 'Gaming']}
        pack['questions'].sort(key=lambda q: q['difficulty'])
        app.validate_pack(pack, self.urls, ['Gaming'])
        with self.assertRaises(ValueError): app.validate_pack(pack, self.urls, ['Music'])
        with self.assertRaises(ValueError): app.validate_pack(pack, self.urls, ['Gaming', 'Music'])

    @patch.object(app, 'trend_signals', return_value=([], []))
    @patch.object(app, 'model_response')
    def test_selected_categories_reach_model_and_share_cache(self, model, trends):
        cats = ['Gaming', 'Music']
        questions = []
        for i in range(15):
            options = [q for q in self.questions if q['category'] == cats[i % 2] and q['difficulty'] == i // 5 and q not in questions]
            questions.append(copy.deepcopy(options[0]))
        model.side_effect = [('evidence', self.urls), (json.dumps({'questions': questions}), set()), (json.dumps({'accepted': True}), set())]
        app.cache.clear()
        result = app.create_pack(cats)
        self.assertEqual(set(cats), {q['category'] for q in result['questions']})
        self.assertEqual(cats, json.loads(model.call_args_list[1].args[1])['categories'])
        self.assertEqual(result, app.create_pack(list(reversed(cats))))
        self.assertEqual(3, model.call_count)
        app.cache.clear()

    def test_rejects_fabricated_source(self):
        self.pack['questions'][0]['source'] = 'https://invented.example/fact'
        with self.assertRaises(ValueError): app.validate_pack(self.pack, self.urls)

    def test_rejects_ambiguous_duplicate_answers(self):
        self.pack['questions'][0]['answers'][1] = self.pack['questions'][0]['answers'][0].upper()
        with self.assertRaises(ValueError): app.validate_pack(self.pack, self.urls)

    def test_rejects_invalid_correct_index(self):
        self.pack['questions'][0]['correct'] = -1
        with self.assertRaises(ValueError): app.validate_pack(self.pack, self.urls)

    def test_rejects_duplicate_question(self):
        self.pack['questions'][1] = copy.deepcopy(self.pack['questions'][0])
        with self.assertRaises(ValueError): app.validate_pack(self.pack, self.urls)

    def test_rejects_wrong_difficulty_order(self):
        self.pack['questions'][0]['difficulty'] = 2
        with self.assertRaises(ValueError): app.validate_pack(self.pack, self.urls)

    @patch.object(app, 'model_response')
    def test_lifeline_does_not_receive_answer_key(self, model):
        model.return_value = (json.dumps({'suggestion': 1, 'reasoning': 'I think B.', 'votes': [0, 60, 0, 40]}), set())
        body = {'kind': 'audience', 'question': 'A test?', 'answers': ['A', 'B', 'C', 'D'], 'eliminated': [0, 2], 'correct': 3}
        result = app.create_lifeline(body)
        self.assertTrue(result['simulation'])
        self.assertNotIn('correct', json.loads(model.call_args.args[1]))

    @patch.object(app, 'model_response')
    def test_lifeline_rejects_eliminated_suggestion(self, model):
        model.return_value = (json.dumps({'suggestion': 0, 'reasoning': 'A', 'votes': [0, 60, 0, 40]}), set())
        with self.assertRaises(ValueError): app.create_lifeline({'kind': 'friend', 'question': 'A test?', 'answers': ['A', 'B', 'C', 'D'], 'eliminated': [0, 2]})

    @patch.object(app, 'model_response')
    def test_lifeline_rejects_invalid_percentages(self, model):
        model.return_value = (json.dumps({'suggestion': 1, 'reasoning': 'B', 'votes': [0, 60, 0, 50]}), set())
        with self.assertRaises(ValueError): app.create_lifeline({'kind': 'audience', 'question': 'A test?', 'answers': ['A', 'B', 'C', 'D']})

if __name__ == '__main__': unittest.main()
