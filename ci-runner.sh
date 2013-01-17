#!/bin/bash

set -e

BUILDDIR="$BASE_DIR/build"

LOGFILE="$BASE_DIR/build.log"
LOGFILE_HTML="$BASE_DIR/build.html"
VERDICTFILE="$BASE_DIR/build.verdict"

REPO_URL="git@github.com:$REPO.git"

if [ "$#" -lt 2 ]; then
	echo "USAGE: $0 remote commit [merge-into]"
	exit 1
fi

REMOTE="$1"
COMMIT="$2"
MERGE_INTO="$3"

if [ ! -d "$BUILDDIR" ]; then
	echo "**** cloning repository for the first time"
	git clone "$REPO_URL" "$BUILDDIR"
fi

GIT="git --git-dir $BUILDDIR/.git --work-tree $BUILDDIR"

echo "**** building in $BUILDDIR"

rm -f "$VERDICTFILE"

set +e
$GIT remote rm src
set -e

$GIT remote add src "$REMOTE"
$GIT fetch src
$GIT fetch origin

if [ "$MERGE_INTO" ]; then
	$GIT checkout "$MERGE_INTO"

	set +e
	$GIT branch -D ci
	set -e

	$GIT checkout -b ci "$MERGE_INTO"
	$GIT merge --no-edit "$COMMIT"
else
	$GIT checkout "$COMMIT"
fi

$GIT clean -xdf

NETWORKCONF_PATH="$BUILDDIR/Applications/Logatec/Clusters/local_usart_networkconf.h"
if [ -e "$NETWORKCONF_PATH" ]; then
	cp "$NETWORKCONF_PATH" $BUILDDIR/Applications/Logatec/networkconf.h
fi

set +e
#echo test > "$LOGFILE"
(cd $BUILDDIR && make) > "$LOGFILE" 2>&1
RESULT="$?"
set -e

if [ "$RESULT" -eq 0 ]; then
	if egrep -f "$BASE_DIR/fail_patterns" "$LOGFILE" > /dev/null; then
		VERDICT="failed-compile"
	else
		VERDICT="ok"
	fi
else
	VERDICT="failed-make"
fi

CGCC_FORCE_COLOR=1 colorgcc "$LOGFILE" | aha > "$LOGFILE_HTML"

echo "$VERDICT" > "$VERDICTFILE"
