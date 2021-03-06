#!/bin/bash

# http://stackoverflow.com/questions/16840184/how-can-i-automatically-be-warned-if-a-specific-file-changes
# https://raw.githubusercontent.com/greg0ire/git_template/master/template/hooks/change_detector.sh

# @param hook_type       post-checkout|post-merge|post-commit|pre-commit
# @param monitored_paths the paths to check
has_changed()
{
	local hook_type=$1; shift
	local monitored_paths=("$@")
	local against
	local changed

	monitored_paths=( "${monitored_paths[@]/#/$GIT_DIR/../}" )

	case $hook_type in
		post-commit)
			if git rev-parse --verify HEAD^ >/dev/null 2>&1
			then
				against=HEAD^
			else
				# Initial commit: diff against an empty tree object
				against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
			fi
			changed="$(git diff-tree $against 'HEAD' \
				--stat \
				-- ${monitored_paths[*]}| wc -l)"
			;;
		post-checkout | post-merge )
			changed="$(git diff 'HEAD@{1}' \
				--stat \
				-- ${monitored_paths[*]}| wc -l)"
			;;
		pre-commit)
			if git rev-parse --verify HEAD >/dev/null 2>&1
			then
				against=HEAD
			else
				# Initial commit: diff against an empty tree object
				against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
			fi
			changed="$(git diff-index \
				--name-status $against \
				-- "${monitored_paths[*]}" | wc -l)"
			;;
	esac

	if [ "$changed" -gt 0 ]
	then
		return 0
	else
		return 1
	fi
}
