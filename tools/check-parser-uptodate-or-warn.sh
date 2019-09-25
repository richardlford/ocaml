#!/bin/sh

#**************************************************************************
#*                                                                        *
#*                                 OCaml                                  *
#*                                                                        *
#*            Gabriel Scherer, projet Parsifal, INRIA Saclay              *
#*                                                                        *
#*   Copyright 2018 Institut National de Recherche en Informatique et     *
#*     en Automatique.                                                    *
#*                                                                        *
#*   All rights reserved.  This file is distributed under the terms of    *
#*   the GNU Lesser General Public License version 2.1, with the          *
#*   special exception on linking described in the file LICENSE.          *
#*                                                                        *
#**************************************************************************

# We try to warn if the user edits parsing/parser.mly but forgets to
# rebuild the generated parser. Our heuristic is to use the file
# modification timestamp, but just testing
#   (parsing/parser.mly -nt boot/menhir/parser.ml)
# is not robust to clone/checkout refreshing the files in an arbitrary
# order, so we check whether parser.mly was modified at least 10
# seconds after boot/menhir/parser.ml.

# mtime(): access a file's last modification time as a timestamp,
# using either
#  GNU coreutils' stat --format, or
#  busybox's stat -c, or
#  BSD/macos stat -f.
# Default to 0 if 'stat' is not available.

stat . 2>/dev/null 1>/dev/null
if test $? != 0
then MTIME=""
elif test -n "$(stat --version 2>/dev/null | grep coreutils)"
then MTIME="stat --format %Y"
elif test -n "$(stat 2>&1 | grep busybox)"
then MTIME="stat -c %Y"
else MTIME="stat -f %m" # BSD stat?
fi

mtime() {
  if test -z "$MTIME"
  then echo 0
  else $MTIME "$1"
  fi
}

# The check itself
SOURCE_MTIME=$(mtime parsing/parser.mly)
GENERATED_MTIME=$(mtime boot/menhir/parser.ml)
if test "$SOURCE_MTIME" -gt $(( GENERATED_MTIME + 10 ))
then
  echo
  tput setaf 3; tput bold; printf "Warning: "; tput sgr0
  echo "Your 'parser.mly' file is more recent than the parser in 'boot/'."
  echo "Its changes will be ignored unless you run:"
  echo "    make promote-menhir"
  echo
fi
