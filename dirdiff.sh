#!/bin/bash
# vim plugin for directory diffs.
# from: https://github.com/ZSaberLv0/ZFVimDirDiff

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
PATH_A=$(pwd)/$1
PATH_B=$(pwd)/$2
if test "0" = "1" \
    || test "x-$PATH_A" = "x-" \
    || test "x-$PATH_B" = "x-" \
    ; then
    echo "usage:"
    echo "  sh ZFDirDiff.sh PATH_A PATH_B"
    exit 1
fi

if test "x-$ZFDIRDIFF_VIM" = "x-"; then
    ZFDIRDIFF_VIM=vim
fi

"$ZFDIRDIFF_VIM" -c "call ZFDirDiff(\"$PATH_A\", \"$PATH_B\")"
