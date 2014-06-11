#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 1: Do not put ':' after parameter name in Doxygen block.
# -- 2: Remove the @<tag> instead of writing "@<tag> None".

DIRS="Applications Examples VESNADriversDemo VESNALib"

if find $DIRS \( -name "*.c" -o -name "*.h" \) -print0 |\
		xargs -0 grep -Hn '@param\s\+\w\+\s*:'; then
	exit 1
fi

if find $DIRS \( -name "*.c" -o -name "*.h" \) -print0 |\
		xargs -0 grep -Hn '@\(retval\|return\|param\)\s\+None'; then
	exit 2
fi
