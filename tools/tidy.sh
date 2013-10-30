#!/bin/sh
# See the file COPYING in this distribution
# for details on the license of this file.

tidy -f /dev/null -minq -asxml -utf8 "${1:?Please specify file to tidy.}"
