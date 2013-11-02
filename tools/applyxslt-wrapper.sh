#!/bin/sh
# See the file COPYING in this distribution
# for details on the license of this file.
#
#
# Simple wrapper for applyxslt.awk. Allows for setting
# global options; invokes applyxslt.awk with all stylesheets
# found in XSLT_DIR.

MYDIR="$(dirname "$0")"
case "$MYDIR" in
    /*) ;;
    *)  MYDIR="${PWD}/${MYDIR}";;
esac

XSLT_DIR="${MYDIR}/.."
OUTPUT_DIR="${MYDIR}/../out"
TEMP_DIR=''

CURL_BIN=''
TIDY_BIN=''
XSLTPROC_BIN=''

FIND_OPTS='-maxdepth 1'
CURL_OPTS=''
TIDY_OPTS=''
XSLTPROC_OPTS="--novalid --path '${MYDIR}/../lib'"

find "$XSLT_DIR" $FIND_OPTS -iname '*.xsl' \
    -execdir "${MYDIR}/applyxslt.awk" -v output_dir="$OUTPUT_DIR" \
        -v temp_dir="$TEMP_DIR" -v curl_opts="$CURL_OPTS" \
        -v tidy_opts="$TIDY_OPTS" -v xsltproc_opts="$XSLTPROC_OPTS" \
        -v curl_bin="$CURL_BIN" -v tidy_bin="$TIDY_BIN" \
        -v xsltproc_bin="$XSLTPROC_BIN" \
        '{}' +
