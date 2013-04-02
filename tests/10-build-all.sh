#!/bin/bash

# Possible error codes and their descriptions:
#
# -- 2: There were fatal compiler errors.
# -- patterns: Compiler emitted warnings or non-fatal errors.

NETWORKCONF_PATH="Applications/Logatec/Clusters/local_usart_networkconf.h"
if [ -e "$NETWORKCONF_PATH" ]; then
	cp "$NETWORKCONF_PATH" Applications/Logatec/networkconf.h
fi

make -j4
