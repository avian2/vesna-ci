#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 2: Code did not pass unit tests.

[ -e "test/Makefile" ] || exit 0

make -C "test" test
