#!/usr/bin/env bash
# Copyright (C) 2016-2025 Intel Corporation
# Under the Apache License v2.0 with LLVM Exceptions. See LICENSE.TXT.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# check-headers.sh - check copyright and license in source files

SELF=$0

function usage() {
	echo "Usage: $SELF <source_root_path> <license_tag> [-h|-v|-a|-d]"
	echo "   -h, --help          this help message"
	echo "   -v, --verbose       verbose mode"
	echo "   -a, --all           check all files (only modified files are checked by default)"
	echo "   -d, --update_dates  change Copyright dates in all analyzed files (rather not use with -a)"
}

if [ "$#" -lt 2 ]; then
	usage >&2
	exit 2
fi

SOURCE_ROOT=$1
shift
LICENSE=$1
shift

PATTERN=`mktemp`
TMP=`mktemp`
TMP2=`mktemp`
TEMPFILE=`mktemp`
rm -f $PATTERN $TMP $TMP2

if [ "$1" == "-h" -o "$1" == "--help" ]; then
	usage
	exit 0
fi

export GIT="git -C ${SOURCE_ROOT}"
$GIT rev-parse || exit 1

if [ -f $SOURCE_ROOT/.git/shallow ]; then
	SHALLOW_CLONE=1
	echo
	echo "Warning: This is a shallow clone. Checking dates in copyright headers"
	echo "         will be skipped in case of files that have no history."
	echo
else
	SHALLOW_CLONE=0
fi

VERBOSE=0
CHECK_ALL=0
UPDATE_DATES=0
while [ "$1" != "" ]; do
	case $1 in
	-v|--verbose)
		VERBOSE=1
		;;
	-a|--all)
		CHECK_ALL=1
		;;
	-d|--update_dates)
		UPDATE_DATES=1
		;;
	esac
	shift
done

if [ $CHECK_ALL -eq 0 ]; then
	CURRENT_COMMIT=$($GIT --no-pager log --pretty=%H -1)
	MERGE_BASE=$($GIT merge-base HEAD origin/main 2>/dev/null)
	[ -z $MERGE_BASE ] && \
		MERGE_BASE=$($GIT --no-pager log --pretty="%cN:%H" | grep GitHub 2>/dev/null | head -n1 | cut -d: -f2)
	[ -z $MERGE_BASE -o "$CURRENT_COMMIT" = "$MERGE_BASE" ] && \
		CHECK_ALL=1
fi

if [ $CHECK_ALL -eq 1 ]; then
	echo "INFO: Checking copyright headers of all files..."
	GIT_COMMAND="ls-tree -r --name-only HEAD"
else
	echo "INFO: Checking copyright headers of modified files only..."
	GIT_COMMAND="diff --name-only $MERGE_BASE $CURRENT_COMMIT"
fi

FILES=$($GIT $GIT_COMMAND | ${SOURCE_ROOT}/scripts/check_license/file-exceptions.sh)

RV=0
for file in $FILES ; do
	if [ $VERBOSE -eq 1 ]; then
		echo "Checking file: $file"
	fi
	# The src_path is a path which should be used in every command except git.
	# git is called with -C flag so filepaths should be relative to SOURCE_ROOT
	src_path="${SOURCE_ROOT}/$file"
	[ ! -f $src_path ] && continue
	# ensure that file is UTF-8 encoded
	ENCODING=`file -b --mime-encoding $src_path`
	iconv -f $ENCODING -t "UTF-8" $src_path > $TEMPFILE

	if ! grep -q "SPDX-License-Identifier: $LICENSE" $src_path; then
		echo >&2 "error: no $LICENSE SPDX tag in file: $src_path"
		RV=1
	fi

	if [ $SHALLOW_CLONE -eq 0 ]; then
		$GIT log --no-merges --format="%ai %aE" -- $file | sort > $TMP
	else
		# mark the grafted commits (commits with no parents)
		$GIT log --no-merges --format="%ai %aE grafted-%p-commit" -- $file | sort > $TMP
	fi

	# skip checking dates for non-Intel commits
	[[ ! $(tail -n1 $TMP) =~ "@intel.com" ]] && continue

	# skip checking dates for new files
	[ $(cat $TMP | wc -l) -le 1 ] && continue

	# grep out the grafted commits (commits with no parents)
	# and skip checking dates for non-Intel commits
	grep -v -e "grafted--commit" $TMP | grep -e "@intel.com" > $TMP2

	[ $(cat $TMP2 | wc -l) -eq 0 ] && continue

	FIRST=`head -n1 $TMP2`
	LAST=` tail -n1 $TMP2`

	YEARS=$(sed '
/.*Copyright (C) [0-9-]\+ Intel Corporation/!d
s/.*Copyright (C) \([0-9]\+\)-\([0-9]\+\).*/\1-\2/
s/.*Copyright (C) \([0-9]\+\).*/\1/' "$src_path")
	if [ -z "$YEARS" ]; then
		echo >&2 "No copyright years in $src_path"
		RV=1
		continue
	fi

	HEADER_FIRST=`echo $YEARS | cut -d"-" -f1`
	HEADER_LAST=` echo $YEARS | cut -d"-" -f2`

	COMMIT_FIRST=`echo $FIRST | cut -d"-" -f1`
	COMMIT_LAST=` echo $LAST  | cut -d"-" -f1`

	if [ "$COMMIT_FIRST" != "" -a "$COMMIT_LAST" != "" ]; then
    	if [ "$COMMIT_FIRST" -lt "$HEADER_FIRST" ]; then
    	    RV=1
    	fi

    	if [[ -n "$COMMIT_FIRST" && -n "$COMMIT_LAST" ]]; then
    	    if [[ $HEADER_FIRST -le $COMMIT_FIRST ]]; then
    	        if [[ $HEADER_LAST -eq $COMMIT_LAST ]]; then
    	            continue
    	        else
    	            NEW="$HEADER_FIRST-$COMMIT_LAST"
    	            if [[ ${UPDATE_DATES} -eq 1 ]]; then
    	                echo "Updating copyright date in $src_path: $YEARS -> $NEW"
    	                sed -i "s/Copyright (C) ${YEARS}/Copyright (C) ${NEW}/g" "${src_path}"
    	            else
    	                echo "$file:1: error: wrong copyright date: (is: $YEARS, should be: $NEW)" >&2
    	                RV=1
    	            fi
    	        fi
    	    else
    	        if [[ $COMMIT_FIRST -eq $COMMIT_LAST ]]; then
    	            NEW=$COMMIT_LAST
    	        else
    	            NEW=$COMMIT_FIRST-$COMMIT_LAST
    	        fi

    	        if [[ "$YEARS" == "$NEW" ]]; then
    	            continue
    	        else
    	            if [[ ${UPDATE_DATES} -eq 1 ]]; then
    	                echo "Updating copyright date in $src_path: $YEARS -> $NEW"
    	                sed -i "s/Copyright (C) ${YEARS}/Copyright (C) ${NEW}/g" "${src_path}"
    	            else
    	                echo "$file:1: error: wrong copyright date: (is: $YEARS, should be: $NEW)" >&2
    	                RV=1
    	            fi
    	        fi
    	    fi
    	fi
	else
	    echo "error: unknown commit dates in file: $file" >&2
	    RV=1
	fi
done
rm -f $TMP $TMP2 $TEMPFILE

# check if error found
if [ $RV -eq 0 ]; then
	echo "Copyright headers are OK."
else
	echo "Error(s) in copyright headers found!" >&2
fi
exit $RV
