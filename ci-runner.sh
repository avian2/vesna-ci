#!/bin/bash

function get_description {
	TEST="$1"
	CODE="$2"

	sed -ne "/^# -- $CODE: /{s/^.*: //;p}" "$TEST"
}

set -e

if [ ! "$BASE_DIR" ]; then
	HERE=`dirname $0`
	if [ -d "$HERE/build" ]; then
		BASE_DIR="$HERE"
	else
		echo "Please define BASE_DIR environment" >&2
		exit 1
	fi
fi

export BASE_DIR

BUILDDIR="$BASE_DIR/build"
TESTDIR="$BASE_DIR/tests"

LOGFILE="$BASE_DIR/build.log"
LOGFILE_HTML="$BASE_DIR/build.html"
VERDICTFILE="$BASE_DIR/build.verdict"

if [ "$#" -lt 2 ]; then
	echo "USAGE: $0 head_repo head_commit [base_repo base_commit]" >&2
	exit 1
fi

HEAD_REPO="$1"
HEAD_COMMIT="$2"

BASE_REPO="$3"
BASE_COMMIT="$4"

if [ ! -d "$BUILDDIR" ]; then
	if [ ! "$BASE_REPO" ]; then
		echo "Please set base_repo to clone repository for the first time." >&2
		exit 1
	fi

	echo "**** cloning repository for the first time"
	git clone "$BASE_REPO" "$BUILDDIR"
fi

GIT="git --git-dir $BUILDDIR/.git --work-tree $BUILDDIR"

echo "**** building in $BUILDDIR"

rm -f "$VERDICTFILE"

set +e
$GIT remote rm headremote
$GIT remote rm baseremote
set -e

$GIT remote add headremote "$HEAD_REPO"
$GIT fetch headremote

$GIT clean -xdf

if [ "$BASE_COMMIT" ]; then
	$GIT remote add baseremote "$BASE_REPO"
	$GIT fetch baseremote

	$GIT checkout -f -B ci "$BASE_COMMIT"
	if ! $GIT merge --no-edit "$HEAD_COMMIT"; then
		touch "$LOGFILE"
		touch "$LOGFILE_HTML"
		echo "failure: Branch cannot be automatically merged." > "$VERDICTFILE"
		exit 0
	fi
else
	$GIT checkout -f -B ci "$HEAD_COMMIT"
fi

rm -f "$LOGFILE"
VERDICT="success"
MESSAGE="Build successful"

for TEST in "$TESTDIR"/*.sh; do
	echo "Starting $TEST..." > "$LOGFILE.part"

	TEST=`realpath "$TEST"`

	set +e
	(cd "$BUILDDIR" && "$TEST") >> "$LOGFILE.part" 2>&1
	RESULT="$?"
	set -e

	if [ "$RESULT" -ne 0 ]; then
		VERDICT="failure"
		MESSAGE=`get_description "$TEST" "$RESULT"`
	fi

	PATTERNS=`dirname "$TEST"`/`basename "$TEST" .sh`.patterns

	if [ "$VERDICT" = "success" -a -e "$PATTERNS" ]; then
		if egrep -f "$PATTERNS" "$LOGFILE.part" > /dev/null; then
			VERDICT="failure"
			MESSAGE=`get_description "$TEST" patterns`
		fi
	fi

	cat "$LOGFILE.part" >> "$LOGFILE"
	rm "$LOGFILE.part"

	if [ "$VERDICT" != "success" ]; then
		break
	fi

done

CGCC_FORCE_COLOR=1 colorgcc "$LOGFILE" | aha > "$LOGFILE_HTML"

echo "$VERDICT: $MESSAGE" > "$VERDICTFILE"
