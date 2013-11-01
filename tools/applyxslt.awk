#!/bin/awk -f
# See the file COPYING in this distribution
# for details on the license of this file.
#
# Treats each input file as an XSLT stylesheet
# and parses it for metadata. Downloads and processes
# the source file for each stylesheet.
#
# A metadata block is introduced by a line like
# <!-- [META]
# or by a line inside an XML comment containing only the
# word [META]. A line inside a comment containing
# [/META] as its first word ends the metadata section.
#
# Metadata lines inside a metadata section consist
# _only_ of two words separated by whitespace, the first
# being the key and the second the value (no quotes, spaces etc.
# allowed). The following keys are mandatory:
#
# SOURCE_URL    Remote location of the document to be transformed.
#
# This script accepts the following optional global variables
# (use awk's -v key=value option to specify them):
#
# temp_dir      Directory to use for temporary downloaded source files.
#               Default is "/tmp".
# xsltproc_opts Options to pass to xsltproc. Default is "".

function reset_vars() {
    in_comment = 0
    in_meta    = 0

    source_url  = ""
}


BEGIN {
    reset_vars()

    if(temp_dir == "") {
        temp_dir = "/tmp"
    }
}

NF == 0 {
    # Skip empty lines
    next
}

$1 == "<!--" {
    in_comment = 1

    # Do not skip to the next line here:
    # "<!-- [META]" is also allowed, so the next pattern
    # needs to be allowed to match as well.
}

$1 == "[META]" || $1 == "<!--" && $2 == "[META]" {
    in_meta = 1
    next
}

in_meta && $1 == "[/META]" {
    # End of metadata block.
    in_comment = 0
    in_meta    = 0
}

in_comment && in_meta {
    if($1 == "SOURCE_URL") {
        source_url = $2
        next
    }

    printf("Warning: %s: Invalid metadata key `%s' on line %d. Ignoring.\n",
           FILENAME, $1, FNR) | "cat >&2"
}

END {
    if(source_url == "") {
        printf("Warning: %s: No source URL specified. Not processing.\n",
               FILENAME) | "cat >&2"
    } else {
        # XXX: Download file here.

        # We got all the needed variables; invoke xsltproc now.
        command = sprintf("xsltproc %s -o '%s' %s %s",
                xsltproc_opts, output_file, FILENAME, html_file);

        # Ready for the next stylesheet.
        reset_vars()
    }
}
