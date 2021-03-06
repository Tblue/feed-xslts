#!/usr/bin/awk -f
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
# FEED_NAME     Name of the feed file to generate in output_dir.
#
# The following optional keys are accepted:
#
# ENCODING      Encoding of the source file. Default is "utf8".
#
#
# This script accepts the following optional global variables
# (use awk's -v key=value option to specify them):
#
# output_dir    Where to put generated feeds. Default is ".".
# temp_dir      Directory to use for temporary downloaded source files.
#               Default is "/tmp".
# curl_bin      Path to curl binary. Default is "curl".
# tidy_bin      Path to HTML tidy binary. Default is "tidy".
# xsltproc_bin  Path to xsltproc binary. Default is "xsltproc".
# curl_opts     Additional options to pass to curl. Default is "".
# tidy_opts     Additional options to pass to HTML tidy. Default is "".
# xsltproc_opts Additional options to pass to xsltproc. Default is "".

# Resets various file-specific variables to their initial values.
function reset_vars() {
    last_file    = FILENAME
    # Set to 1 if there was a valid metadata section
    # in the last file processed.
    last_endmeta = 0

    in_comment = 0
    in_meta    = 0

    source_url  = ""
    feed_name   = ""
    encoding    = "utf8"
}

# Checks if the last processed file had an invalid
# metadata section and displays a warning if that is the case.
function check_warn_invalid_meta() {
    if(! last_endmeta && last_file != "") {
        printf("%s: No (or invalid) metadata section found! " \
               "File may not have been processed correctly.\n",
                    last_file) | "cat >&2"
    }
}

# Applies the current XSLT stylesheet to its source file.
function process() {
    # Where to put the downloaded source file?
    source_file = source_url
    # Trim trailing slashes
    sub("/+$", "", source_file)
    # Only leave the basename of the source URL
    sub("^.*/", "", source_file)
    source_file = temp_dir "/" source_file

    # Now, retrieve the source file.
    cmd = sprintf("'%s' -fgLsS -o '%s' %s '%s'",
        curl_bin, source_file, curl_opts, source_url)
    if(system(cmd) > 0) {
        printf("%s: Could not retrieve source file: Command `%s' failed!\n",
               FILENAME, cmd) | "cat >&2"
        return
    }

    # Then, run the source file through HTML tidy.
    cmd = sprintf("'%s' -mnq -asxml --char-encoding '%s' " \
                        "--show-warnings 0 %s '%s'",
                    tidy_bin, encoding, tidy_opts, source_file)
    if(system(cmd) >= 2) {
        # Exit status 2 means there were errors.
        # (Exit status 1 indicates that there were
        # warnings, but we allow that.)
        printf("%s: Could not tidy source file: Command `%s' failed!\n",
               FILENAME, cmd) | "cat >&2"
        return
    }

    # Where to put the generated feed?
    output_file = output_dir "/" feed_name

    # Finally, let xsltproc do its magic.
    cmd = sprintf("'%s' --encoding '%s' -o '%s' %s '%s' '%s'",
            xsltproc_bin, encoding, output_file, xsltproc_opts,
            FILENAME, source_file)
    if(system(cmd) > 0) {
        printf("%s: Could not transform source file: Command `%s' failed!\n",
               FILENAME, cmd) | "cat >&2"
        return
    }
}

BEGIN {
    if(output_dir == "") {
        output_dir = "."
    }
    if(temp_dir == "") {
        temp_dir = "/tmp"
    }

    if(curl_bin == "") {
        curl_bin = "curl"
    }
    if(tidy_bin == "") {
        tidy_bin = "tidy"
    }
    if(xsltproc_bin == "") {
        xsltproc_bin = "xsltproc"
    }
}

END {
    # Check/warn if last file had invalid meta section
    check_warn_invalid_meta()
}

FNR == 1 {
    # Check/warn if last file had invalid meta section
    check_warn_invalid_meta()

    # New file. Make sure to reset all the variables.
    reset_vars()
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

in_comment && ! in_meta && ($1 == "[META]" || $1 == "<!--" && $2 == "[META]") {
    if(last_endmeta) {
        printf("%s: Line %d: Multiple metadata sections are not supported. " \
                    "Only the first one will be parsed.\n",
                FILENAME, FNR) | "cat >&2"
        next
    }

    last_endmeta = 0
    in_meta      = 1

    next
}

$NF == "-->" {
    in_comment = 0
    # Closing comment also ends a metadata block.
    in_meta    = 0
}

in_meta && $1 == "[/META]" {
    # End of metadata block. We should have all the needed data now.
    last_endmeta = 1
    in_meta      = 0

    if(source_url == "") {
        printf("%s: No source URL specified. Not processing.\n",
               FILENAME) | "cat >&2"
    } else if(feed_name == "") {
        printf("%s: No feed name specified. Not processing.\n",
               FILENAME) | "cat >&2"
    } else {
        # Apply stylesheet to its source file.
        process()
    }
}

in_meta {
    if($1 == "SOURCE_URL") {
        source_url = $2
        next
    } else if($1 == "ENCODING") {
        encoding = $2
        next
    } else if($1 == "FEED_NAME") {
        feed_name = $2
        next
    }

    printf("%s: Invalid metadata key `%s' on line %d. Ignoring.\n",
           FILENAME, $1, FNR) | "cat >&2"
}
