#!/usr/bin/python
import datetime
from github import Github
import logging
import subprocess
from settings import *
import os
from optparse import OptionParser

options = None

def url_to_repo(url):
	return url.replace("https://github.com/", "git@github.com:")

def already_done(commitobj, base_sha):
	
	def is_current(status):
		their_base_sha = status.target_url.split('.')[-2]
		return status.state != 'error' and their_base_sha == base_sha

	return any(is_current(status) for status in commitobj.get_statuses())

def setup():
	log_path = os.path.join(BASE_DIR, "logs/ci-runner.log")
	logging.basicConfig(filename=log_path, level=logging.INFO)

	parser = OptionParser(usage="%prog [options]")

	parser.add_option("-f", "--force", dest="force", action="store_true",
			help="Force test, even if commit status already up-to-date")
	parser.add_option("-n", "--dry-run", dest="dryrun", action="store_true",
			help="Don't push anything to GitHub")

	global options
	(options, args) = parser.parse_args()

def run_pullreq(pulln, head_repo, head_commit, head_sha, base_repo, base_commit, base_sha):
	env = dict(os.environ)
	env['BASE_DIR'] = BASE_DIR

	p = subprocess.Popen(["/bin/bash", os.path.join(BASE_DIR, "ci-runner.sh"), 
			head_repo, head_commit, base_repo, base_commit],
			stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
	pout, perr = p.communicate()

	for line in pout.split("\n"):
		logging.info("%d: ci-runner.sh 1: %s" % (pulln, line))
	for line in perr.split("\n"):
		logging.info("%d: ci-runner.sh 2: %s" % (pulln, line))

	if p.returncode == 0:
		verdict = open(os.path.join(BASE_DIR, "build.verdict")).read().strip()
	else:
		logging.warning("%d: ci-runner.sh exited with %d" % (pulln, p.returncode))
		verdict = "error: CI system failed"

	for e in ["log", "html", "verdict"]:
		os.rename(os.path.join(BASE_DIR, "build.%s" % (e,)),
				os.path.join(BASE_DIR, "logs/build.%s.%s.%s" % (head_sha, base_sha, e)))

	state, description = verdict.split(": ")
	return state, description

def run():
	token_path = os.path.join(BASE_DIR, "ci-runner.token")
	token = open(token_path).read().strip()
	gh = Github(token)

	repo = gh.get_repo(REPO)

	for pulln, pull in enumerate(repo.get_pulls('open')):
		logging.info("%d: inspecting pull request %s: %s" % (
			pulln, pull.head.repo.git_url, pull.head.ref))

		head_repo = url_to_repo(pull.head.repo.clone_url)
		head_sha = pull.head.sha
		head_commit = "headremote/" + pull.head.ref

		base_repo = url_to_repo(pull.base.repo.clone_url)
		base_sha = pull.base.repo.get_branch(pull.base.ref).commit.sha
		base_commitobj = pull.base.repo.get_commit(head_sha)
		base_commit = "baseremote/" + pull.base.ref

		logging.debug("%d: head is %s, base is %s" % (pulln, head_sha, base_sha))

		if already_done(base_commitobj, base_sha):
			if options.force:
				logging.info("%d: already annotated, but forcing re-test" % (pulln,))
			else:
				logging.info("%d: already annotated, skipping" % (pulln,))
				continue
		else:
			logging.info("%d: needs test" % (pulln,))

		state, description = run_pullreq(pulln, 
				head_repo, head_commit, head_sha, 
				base_repo, base_commit, base_sha)

		target_url = "%s/logs/build.%s.%s.html" % (BASE_URL, head_sha, base_sha)

		logging.info("%d: final verdict: %s" % (pulln, state))
		logging.info("%d: description  : %s" % (pulln, description))
		logging.info("%d: target url   : %s" % (pulln, target_url))

		if not options.dryrun:
			base_commitobj.create_status(state, target_url, description)

def main():
	setup()

	logging.info("Starting run at %s" % (datetime.datetime.now(),))
	logging.info("BASE_DIR = %s" % (BASE_DIR,))

	lock_path = os.path.join(BASE_DIR, "ci-runner.lock")
	try:
		os.mkdir(lock_path)
	except OSError:
		logging.info("Lock present. Exiting.")
	else:
		try:
			run()
		except:
			logging.exception("unhandled exception during run")

		os.rmdir(lock_path)

	logging.info("Ending run at %s" % (datetime.datetime.now(),))

main()
