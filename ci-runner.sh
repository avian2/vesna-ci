#!/bin/bash

set -e

BASEDIR=`dirname $0`

BUILDDIR="$BASEDIR/build"

LOGFILE="$BASEDIR/build.log"
LOGFILE_HTML="$BASEDIR/build.html"

REPO="git@github.com:sensorlab/vesna-drivers.git"

if [ "$#" -lt 2 ]; then
	echo "USAGE: $0 remote commit [merge-into]"
	exit 1
fi

REMOTE="$1"
COMMIT="$2"
MERGE_INTO="$3"

if [ ! -d "$BUILDDIR" ]; then
	echo "**** cloning repository for the first time"
	git clone "$REPO" "$BUILDDIR"
fi

GIT="git --git-dir $BUILDDIR/.git --work-tree $BUILDDIR"

echo "**** building in $BUILDDIR"

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
	$GIT merge "$COMMIT"
else
	$GIT checkout "$COMMIT"
fi

$GIT clean -xdf

cp $BUILDDIR/Applications/Logatec/Clusters/local_usart_networkconf.h $BUILDDIR/Applications/Logatec/networkconf.h
(cd $BUILDDIR && make) > "$LOGFILE" 2>&1

RESULT=$?

CGCC_FORCE_COLOR=1 colorgcc "$LOGFILE" | aha > "$LOGFILE_HTML"
