"""Synthetic command/file checks only: no certificates, credentials or network."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = '''#!/usr/bin/env python3
import json,os,pathlib,sys
root=pathlib.Path(os.environ['TEST_ROOT'])
if pathlib.Path(sys.argv[0]).name=='certbot':
 (root/'arguments.json').write_text(json.dumps(sys.argv[1:]))
 sys.exit(int(os.environ.get('CERTBOT_EXIT','0')))
target=pathlib.Path(sys.argv[sys.argv.index('-O')+1])
target.write_text('partial download' if os.environ.get('WGET_FAIL') else
 '-----BEGIN DH PARAMETERS-----\\nsynthetic-parameters\\n-----END DH PARAMETERS-----\\n')
sys.exit(9 if os.environ.get('WGET_FAIL') else 0)
'''

class ScriptTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.certs = self.root / 'certs'
        self.certs.mkdir()
        for name in ['certbot', 'wget']:
            p = self.bin / name
            p.write_text(STUB)
            p.chmod(0o755)
        self.env = dict(os.environ, TEST_ROOT=str(self.root),
                        PATH=str(self.bin) + ':' + os.environ['PATH'],
                        CERTBOT_CERT_DIR=str(self.certs))

    def run_script(self, name, **env):
        return subprocess.run(['/bin/sh', str(ROOT / name)],
                              env=dict(self.env, **env), capture_output=True, text=True)

    def test_renew_quotes_arguments(self):
        result = self.run_script('renew-certs.sh', CERTBOT_WEBROOT_DIR='/tmp/web root',
                                 CERTBOT_DEPLOY_SCRIPT='/tmp/deploy hook', CERTBOT_DRY_RUN='true')
        self.assertEqual(result.returncode, 0)
        args = json.loads((self.root / 'arguments.json').read_text())
        self.assertEqual(args[args.index('--webroot-path') + 1], '/tmp/web root')
        self.assertEqual(args[args.index('--deploy-hook') + 1], '/tmp/deploy hook')
        self.assertIn('--dry-run', args)

    def test_renew_failure_propagates_without_success_message(self):
        result = self.run_script('renew-certs.sh', CERTBOT_EXIT='23')
        self.assertEqual(result.returncode, 23)
        self.assertNotIn('renew finished', result.stdout)

    def test_failed_parameter_refresh_preserves_existing_file_and_signals_renewal(self):
        params = self.certs / 'ssl-dhparams.pem'
        params.write_text('existing parameters')
        result = self.run_script('deploy/deploy-nginx.sh', WGET_FAIL='true')
        self.assertEqual(result.returncode, 0)
        self.assertEqual(params.read_text(), 'existing parameters')
        self.assertTrue((self.certs / '.renewal-history').exists())
        self.assertFalse(list(self.certs.glob('.dhparams.*')))

    def test_failed_first_parameter_download_does_not_signal_reload(self):
        result = self.run_script('deploy/deploy-nginx.sh', WGET_FAIL='true')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.certs / '.renewal-history').exists())
        self.assertFalse((self.certs / 'ssl-dhparams.pem').exists())
        self.assertFalse(list(self.certs.glob('.dhparams.*')))

    def test_successful_parameter_refresh_is_installed(self):
        self.assertEqual(self.run_script('deploy/deploy-nginx.sh').returncode, 0)
        self.assertIn('BEGIN DH PARAMETERS', (self.certs / 'ssl-dhparams.pem').read_text())
        self.assertTrue((self.certs / '.renewal-history').exists())

    def test_failed_creation_does_not_write_success_history(self):
        result = self.run_script('create-certs.sh', CERTBOT_EMAIL='synthetic@example.invalid',
                                 CERTBOT_DOMAINS='example.invalid', CERTBOT_EXIT='24')
        self.assertEqual(result.returncode, 24)
        self.assertFalse((self.certs / '.renewal-history').exists())

    def test_creation_quotes_file_settings(self):
        email = self.root / 'email'
        email.write_text('synthetic@example.invalid')
        result = self.run_script('create-certs.sh', CERTBOT_EMAIL_FILE=str(email),
                                 CERTBOT_DOMAINS='example.invalid,www.example.invalid', CERTBOT_STAGING='true')
        self.assertEqual(result.returncode, 0)
        args = json.loads((self.root / 'arguments.json').read_text())
        self.assertEqual(args[args.index('-m') + 1], 'synthetic@example.invalid')
        self.assertEqual(args[args.index('-d') + 1], 'example.invalid,www.example.invalid')
        self.assertIn('--test-cert', args)

    def test_conflicting_file_settings_are_rejected(self):
        result = self.run_script('create-certs.sh', CERTBOT_EMAIL='synthetic@example.invalid',
                                 CERTBOT_EMAIL_FILE='/not-read', CERTBOT_DOMAINS='example.invalid')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'arguments.json').exists())

if __name__ == '__main__':
    unittest.main()
