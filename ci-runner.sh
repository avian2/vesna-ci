#!/bin/bash

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

BUILDDIR="$BASE_DIR/build"

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

if [ "$BASE_COMMIT" ]; then
	$GIT remote add baseremote "$BASE_REPO"
	$GIT fetch baseremote

	$GIT checkout -f -B ci "$BASE_COMMIT"
	if ! $GIT merge --no-edit "$HEAD_COMMIT"; then
		touch "$LOGFILE"
		touch "$LOGFILE_HTML"
		echo "failed-merge" > "$VERDICTFILE"
		exit 0
	fi
else
	$GIT checkout -f -B ci "$HEAD_COMMIT"
fi

$GIT clean -xdf

NETWORKCONF_PATH="$BUILDDIR/Applications/Logatec/Clusters/local_usart_networkconf.h"
if [ -e "$NETWORKCONF_PATH" ]; then
	cp "$NETWORKCONF_PATH" $BUILDDIR/Applications/Logatec/networkconf.h
fi

set +e
#echo test > "$LOGFILE"
make -C "$BUILDDIR" > "$LOGFILE" 2>&1
RESULT="$?"
set -e

if [ "$RESULT" -eq 0 ]; then
	if egrep -f "$BASE_DIR/fail_patterns" "$LOGFILE" > /dev/null; then
		VERDICT="failed-compile"
	else
		if [ -e "$BUILDDIR/test/Makefile" ]; then
			set +e
			make -C "$BUILDDIR/test" test >> "$LOGFILE" 2>&1
			RESULT="$?"
			set -e
			if [ "$RESULT" -eq 0 ]; then
				VERDICT="ok"
			else
				VERDICT="failed-tests"
			fi
		else
			VERDICT="ok"
		fi
	fi
else
	VERDICT="failed-make"
fi

CGCC_FORCE_COLOR=1 colorgcc "$LOGFILE" | aha > "$LOGFILE_HTML"

echo "$VERDICT" > "$VERDICTFILE"
