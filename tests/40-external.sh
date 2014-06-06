#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 1: Missing description for external code.

if [ -d "External" ]; then
	EC=0

	OIFS="$IFS"
	IFS=$'\n'

	for DIR in `find External -mindepth 1 -maxdepth 1 -type d`; do
		if [ ! -f "$DIR.txt" ]; then
			echo "$DIR.txt:0: error: Missing description for external code in $DIR"
			echo "$DIR.txt:0: please add a link to project website and copyright information."
			EC=1
		fi
	done

	IFS="$OIFS"

	exit $EC
fi
