#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 1: Doxygen failed with a fatal error.
# -- patterns: Doxygen emitted warnings or non-fatal errors.

if [ -e "vesnalib-doxyfile.txt" ]; then
	ARGS="vesnalib-doxyfile.txt"
fi

doxygen $ARGS || exit 1
