#!/bin/sh

tidy -f /dev/null -miq -asxml -utf8 "${1:?Please specify file to tidy.}"
