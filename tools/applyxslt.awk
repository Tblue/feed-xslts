#!/bin/awk -f
# See the file COPYING in this distribution
# for details on the license of this file.

function reset_vars() {
    in_comment = 0
    in_meta    = 0

    source_url = ""
}


BEGIN {
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
        # XXX: Process XSLT here...

        # Ready for the next stylesheet.
        reset_vars()
    }
}
