#!/bin/awk -f
# See the file COPYING in this distribution
# for details on the license of this file.
#
#
# Treats each input file as an XSLT stylesheet
# and parses it for metadata. Downloads and processes
# the source file for each stylesheet.
#
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
# The following optional keys are accepted:
#
# ENCODING      Encoding of the source file. Default is "utf8".
#
#
# This script accepts the following optional global variables
# (use awk's -v key=value option to specify them):
#
# temp_dir      Directory to use for temporary downloaded source files.
#               Default is "/tmp".
# curl_opts     Additional options to pass to curl. Default is "".
# tidy_opts     Additional options to pass to HTML tidy. Default is "".
# xsltproc_opts Additional options to pass to xsltproc. Default is "".

function reset_vars() {
    in_comment = 0
    in_meta    = 0

    source_url  = ""
    encoding    = "utf8"
}

function process() {
    # Where to put the downloaded source file?
    source_file = source_url
    # Trim trailing slashes
    sub("/+$", "", source_file)
    # Only leave the basename of the source URL
    sub(".*/", "", source_file)
    source_file = temp_dir "/" source_file

    # Now, retrieve the source file.
    cmd = sprintf("curl -fgLsS %s -o '%s' '%s'",
        curl_opts, source_file, source_url)
    if(system(cmd) > 0) {
        printf("%s: Could not retrieve source file: Command `%s' failed!",
               FILENAME, cmd)
        return
    }

    # Then, run the source file through HTML tidy.
    cmd = sprintf("tidy -mnq -asxml --char-encoding '%s' " \
                        "--show-warnings 0 %s '%s'",
                    encoding, tidy_opts, source_file)
    if(system(cmd) >= 2) {
        printf("%s: Could not tidy source file: Command `%s' failed!",
               FILENAME, cmd)
        return
    }

    # Where to put the generated feed?
    output_file = FILENAME
    # Strip file extension
    sub(/\.[^.]*/, "", output_file)
    output_file = output_file ".atom"

    # Finally, let xsltproc do its magic.
    cmd = sprintf("xsltproc --encoding '%s' -o '%s' %s '%s' '%s'",
            encoding, output_file, xsltproc_opts, FILENAME, source_file)
    if(system(cmd) > 0) {
        printf("%s: Could transform source file: Command `%s' failed!",
               FILENAME, cmd)
        return
    }
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
    } else if ($1 == "ENCODING") {
        encoding = $2
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
        process()
    }

    # Ready for the next stylesheet.
    reset_vars()
}
