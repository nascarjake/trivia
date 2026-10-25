import copy
import datetime as dt
import json
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET
from tools import refresh_bank as refresh

NOW=dt.date(2026,10,25)
class RefreshTests(unittest.TestCase):
    def test_source_headline_exactness_dates_and_dedup_key(self):
        item=ET.fromstring('<item><title>NASA’s Swift Mission Ends</title><link>https://science.nasa.gov/missions/swift/test/?tracking=one</link><pubDate>Fri, 23 Oct 2026 21:51:19 +0000</pubDate></item>')
        article='<h1>NASA’s Swift Mission Ends</h1>'
        q=refresh.candidate_from_item(item,article,NOW)
        self.assertEqual(q['answers'][q['correct']],'Swift')
        item.find('link').text='https://science.nasa.gov/missions/swift/test/?tracking=two'
        self.assertEqual(refresh.candidate_from_item(item,article,NOW)['fact_key'],q['fact_key'])
        with self.assertRaises(ValueError):refresh.candidate_from_item(item,'<h1>Another mission</h1>',NOW)
        with self.assertRaises(ValueError):refresh.candidate_from_item(item,article,NOW+dt.timedelta(days=15))
        item.find('title').text='Hubble and Swift Work Together'
        with self.assertRaises(ValueError):refresh.candidate_from_item(item,'<h1>Hubble and Swift Work Together</h1>',NOW)

    def test_atomic_validation_and_retained_version_rollback(self):
        questions=json.loads(refresh.BANK_PATH.read_text())
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);state=root/'bank';bank=root/'questions.json'
            first=refresh.activate(questions,state,bank,now=NOW)
            before=(state/'manifest.json').read_bytes()
            bad=copy.deepcopy(questions);bad[1]['fact_key']=bad[0]['fact_key']
            with self.assertRaises(ValueError):refresh.activate(bad,state,bank,now=NOW)
            self.assertEqual((state/'manifest.json').read_bytes(),before)
            changed=copy.deepcopy(questions);changed[0]['explanation']+=' Reviewed.'
            second=refresh.activate(changed,state,bank,now=NOW)
            manifest=json.loads((state/'manifest.json').read_text())
            self.assertEqual(manifest['previous'],first['version'])
            self.assertTrue((state/'versions'/(first['version']+'.json')).exists())
            restored=refresh.activate(first['questions'],state,bank,'rollback',NOW)
            self.assertEqual(restored['version'],first['version'])
            self.assertNotEqual(first['version'],second['version'])
            self.assertEqual([q['id'] for q in restored['questions']],[q['id'] for q in questions])

    def test_feed_failure_preserves_bank_and_source_requests_are_bounded(self):
        questions=json.loads(refresh.BANK_PATH.read_text())
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);state=root/'bank';bank=root/'questions.json'
            refresh.activate(questions,state,bank,now=NOW)
            before=bank.read_bytes()
            def failed(url):raise OSError('Unavailable publisher')
            with self.assertRaises(OSError):refresh.refresh(state=state,bank_path=bank,now=NOW,fetch=failed)
            self.assertEqual(bank.read_bytes(),before)
            calls=[]
            def empty(url):calls.append(url);return b'<rss><channel/></rss>'
            result=refresh.refresh(state=state,bank_path=bank,now=NOW,fetch=empty)
            self.assertTrue(result['no_change']);self.assertEqual(len(calls),1)
            self.assertEqual(bank.read_bytes(),before)
if __name__=='__main__':unittest.main()
