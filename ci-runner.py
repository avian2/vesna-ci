#!/usr/bin/python
import datetime
from github import Github
import logging
import subprocess
from settings import *
import os

def setup():
	log_path = os.path.join(BASE_DIR, "logs/ci-runner.log")
	logging.basicConfig(filename=log_path, level=logging.INFO)

def run_pullreq(pulln, remote, ref, sha):
	env = dict(os.environ)
	env['BASE_DIR'] = BASE_DIR
	env['REPO'] = REPO

	p = subprocess.Popen(["/bin/bash", os.path.join(BASE_DIR, "ci-runner.sh"), remote, ref],
			stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
	pout, perr = p.communicate()

	for line in pout.split("\n"):
		logging.info("%d: ci-runner.sh 1: %s" % (pulln, line))
	for line in perr.split("\n"):
		logging.info("%d: ci-runner.sh 2: %s" % (pulln, line))

	if p.returncode == 0:
		status = open(os.path.join(BASE_DIR, "build.verdict")).read().strip()
	else:
		logging.warning("%d: ci-runner.sh exited with %d" % (pulln, p.returncode))
		status = "failed-ci"

	for e in ["log", "html", "verdict"]:
		os.rename(os.path.join(BASE_DIR, "build.%s" % (e,)),
				os.path.join(BASE_DIR, "logs/build.%s.%s" % (sha, e)))

	if status == 'ok':
		state = 'success'
		description = 'Build successful'
	elif status == 'failed-ci':
		state = 'error'
		description = 'CI system failed'
	else:
		state = 'failure'
		description = 'Build failed: %s' % status

	return state, description

def run():
	logging.info("BASE_DIR = %s" % (BASE_DIR,))
	logging.info("Starting run at %s" % (datetime.datetime.now(),))

	token_path = os.path.join(BASE_DIR, "ci-runner.token")
	token = open(token_path).read().strip()
	gh = Github(token)

	repo = gh.get_repo(REPO)

	for pulln, pull in enumerate(repo.get_pulls('open')):
		logging.info("%d: inspecting pull request %s: %s" % (
			pulln, pull.head.repo.git_url, pull.head.ref))

		remote = pull.head.repo.clone_url
		remote = remote.replace("https://github.com/", "git@github.com:")

		sha = pull.head.sha

		commit = pull.head.repo.get_commit(sha)

		ref = "src/" + pull.head.ref

		already_done = any(status.state != 'error' for status in commit.get_statuses())
		if already_done:
			logging.info("%d: already annotated, skipping" % (pulln,))
			continue
		else:
			logging.info("%d: needs test" % (pulln,))

		state, description = run_pullreq(pulln, remote, ref, sha)

		logging.info("%d: final verdict: %s" % (pulln, state))

		target_url = "%s/logs/build.%s.html" % (BASE_URL, sha)

		commit.create_status(state, target_url, description)

	logging.info("Ending run at %s" % (datetime.datetime.now(),))

def main():
	setup()
	run()

main()
