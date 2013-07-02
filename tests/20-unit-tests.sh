#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 2: Code did not pass unit tests.

if [ -e "test/Makefile" ]; then
	make -C "test" test
elif [ -e "Tests/host" ]; then
	make -C "Tests/host" test
else
	exit 0
fi
