#!/usr/bin/python
from github import Github
import subprocess
import os

BASE_URL = "http://log-a-tec.eu/vesna-ci/logs"

def main():
	token = open("ci-runner.token").read().strip()
	gh = Github(token)

	repo = gh.get_repo("sensorlab/vesna-drivers")

	for pull in repo.get_pulls('open'):
		#print pull.base.repo.git_url, pull.base.ref
		print pull.head.repo.git_url, pull.head.ref

		remote = pull.head.repo.clone_url
		remote = remote.replace("https://github.com/", "git@github.com:")

		sha = pull.head.sha

		commit = pull.head.repo.get_commit(sha)

		ref = "src/" + pull.head.ref

		#print remote
		#print ref

		already_done = any(status.state != 'error' for status in commit.get_statuses())
		if already_done:
			print "Already done"
			continue
			#break
			#pass

		retcode = subprocess.call(["/bin/bash", "ci-runner.sh", remote, ref])
		if retcode == 0:
			status = open("build.verdict").read().strip()
		else:
			status = "failed-ci"

		for e in ["log", "html", "verdict"]:
			os.rename("build.%s" % (e,), "logs/build.%s.%s" % (sha, e))

		if status == 'ok':
			state = 'success'
			description = 'Build successful'
		elif status == 'failed-ci':
			state = 'error'
			description = 'CI system failed'
		else:
			state = 'failure'
			description = 'Build failed: %s' % status

		target_url = "%s/build.%s.html" % (BASE_URL, sha)

		commit.create_status(state, target_url, description)

main()
