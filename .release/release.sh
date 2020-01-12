#! /usr/bin/env bash

while getopts ":c" opt; do
	case $opt in
	c)
		classic="true";;
	esac
done

if [ -d ".git" ]; then
	topdir="."
else
	topdir=".."
	while [ ! -d "$topdir/.git" ]; do
		topdir="$topdir/.."
	done
fi

releasedir="$topdir/.release"

if [ ! -d "$releasedir" ]; then
	mkdir "$releasedir"
fi

topdir=$( cd "$topdir" && pwd )
releasedir=$( cd "$releasedir" && pwd )


# GIT
si_repo_dir="$1"
si_repo_url=$( git -C "$si_repo_dir" remote get-url origin 2>/dev/null | sed -e 's/^git@\(.*\):/https:\/\/\1\//' )
if [ -z "$si_repo_url" ]; then # no origin so grab the first fetch url
	si_repo_url=$( git -C "$si_repo_dir" remote -v | awk '/(fetch)/ { print $2; exit }' | sed -e 's/^git@\(.*\):/https:\/\/\1\//' )
fi

# Populate filter vars.
si_project_hash=$( git -C "$si_repo_dir" show --no-patch --format="%H" 2>/dev/null )
si_project_abbreviated_hash=$( git -C "$si_repo_dir" show --no-patch --format="%h" 2>/dev/null )
si_project_author=$( git -C "$si_repo_dir" show --no-patch --format="%an" 2>/dev/null )
si_project_timestamp=$( git -C "$si_repo_dir" show --no-patch --format="%at" 2>/dev/null )
si_project_date_iso=$( TZ= printf "%(%Y-%m-%dT%H:%M:%SZ)T" "$si_project_timestamp" )
si_project_date_integer=$( TZ= printf "%(%Y%m%d%H%M%S)T" "$si_project_timestamp" )
# XXX --depth limits rev-list :\ [ ! -s "$(git rev-parse --git-dir)/shallow" ] || git fetch --unshallow --no-tags
si_project_revision=$( git -C "$si_repo_dir" rev-list --count "$si_project_hash" 2>/dev/null )

# Get the tag for the HEAD.
si_previous_tag=
si_previous_revision=
_si_tag=$( git -C "$si_repo_dir" describe --tags --always 2>/dev/null )
si_tag=$( git -C "$si_repo_dir" describe --tags --always --abbrev=0 2>/dev/null )
# si_tag="1.3.4-alpha1"
# _si_tag="1.3.4-alpha1"
# Set $si_project_version to the version number of HEAD. May be empty if there are no commits.
si_project_version=$si_tag
# The HEAD is not tagged if the HEAD is several commits past the most recent tag.
if [ "$si_tag" = "$si_project_hash" ]; then
	# --abbrev=0 expands out the full sha if there was no previous tag
	si_project_version=$_si_tag
	si_previous_tag=
	si_tag=
elif [ "$_si_tag" != "$si_tag" ]; then
	si_project_version=$_si_tag
	si_previous_tag=$si_tag
	si_tag=
else # we're on a tag, just jump back one commit
	si_previous_tag=$( git -C "$si_repo_dir" describe --tags --abbrev=0 HEAD~ 2>/dev/null )
fi

tag=$si_tag
project_version=$si_project_version
previous_version=$si_previous_tag
project_hash=$si_project_hash
project_revision=$si_project_revision
previous_revision=$si_previous_revision
project_timestamp=$si_project_timestamp
if [[ "$si_repo_url" == "https://github.com"* ]]; then
	project_github_url=${si_repo_url%.git}
	project_github_slug=${project_github_url#https://github.com/}
fi

if [ -z "$tag" ]; then
	echo "No tag" >&2
	exit 1
fi

# Simple .pkgmeta YAML processor.
yaml_keyvalue() {
	yaml_key=${1%%:*}
	yaml_value=${1#$yaml_key:}
	yaml_value=${yaml_value#"${yaml_value%%[! ]*}"} # trim leading whitespace
	yaml_value=${yaml_value#[\'\"]} # trim leading quotes
	yaml_value=${yaml_value%[\'\"]} # trim trailing quotes
}

yaml_listitem() {
	yaml_item=${1#*-}
	yaml_item=${yaml_item#"${yaml_item%%[! ]*}"} # trim leading whitespace
}


# PKGMETA
pkgmeta_file="$topdir/.pkgmeta"
awk '{ sub("\r$", ""); print }' "$pkgmeta_file" > "${pkgmeta_file}2"
mv "${pkgmeta_file}2" "$pkgmeta_file"

if [ -f "$pkgmeta_file" ]; then
	yaml_eof=
	while [ -z "$yaml_eof" ]; do
		IFS='' read -r yaml_line || yaml_eof="true"
		# Strip any trailing CR character.
		yaml_line=${yaml_line%$carriage_return}
		case $yaml_line in
		[!\ ]*:*)
			# Split $yaml_line into a $yaml_key, $yaml_value pair.
			yaml_keyvalue "$yaml_line"
			# Set the $pkgmeta_phase for stateful processing.
			pkgmeta_phase=$yaml_key

			case $yaml_key in
			enable-nolib-creation)
				if [ "$yaml_value" = "yes" ]; then
					enable_nolib_creation="true"
				fi
				;;
			manual-changelog)
				changelog=$yaml_value
				manual_changelog="true"
				;;
			package-as)
				package=$yaml_value
				;;
			wowi-create-changelog)
				if [ "$yaml_value" = "no" ]; then
					wowi_gen_changelog=
				fi
				;;
			wowi-archive-previous)
				if [ "$yaml_value" = "no" ]; then
					wowi_archive=
				fi
				;;
			*)
				# Split $yaml_line into a $yaml_key, $yaml_value pair.
				case $yaml_key in
				*"filename")
					changelog=$yaml_value
					manual_changelog="true"
					;;
				*"markup-type")
					if [ "$yaml_value" = "markdown" ] || [ "$yaml_value" = "html" ]; then
						changelog_markup=$yaml_value
					else
						changelog_markup="text"
					fi
					;;
				esac
				;;
			esac
			;;
		*)
			yaml_line=${yaml_line#"${yaml_line%%[! ]*}"} # trim leading whitespace
			case $yaml_line in
			*"- "*)
				yaml_listitem "$yaml_line"
				# Get the YAML list item.
				case $pkgmeta_phase in
				ignore)
					pattern=$yaml_item
					if [ -d "$topdir/$pattern" ]; then
						pattern="$pattern/*"
					elif [ ! -f "$topdir/$pattern" ]; then
						# doesn't exist so match both a file and a path
						pattern="$pattern:$pattern/*"
					fi
					if [ -z "$ignore" ]; then
						ignore="$pattern"
					else
						ignore="$ignore:$pattern"
					fi
					;;
				tools-used)
					relations["$yaml_item"]="tool"
					;;
				required-dependencies)
					relations["$yaml_item"]="requiredDependency"
					;;
				optional-dependencies)
					relations["$yaml_item"]="optionalDependency"
					;;
				embedded-libraries)
					relations["$yaml_item"]="embeddedLibrary"
					;;
				esac
				;;
			esac
			;;
		esac
	done < "$pkgmeta_file"
fi

# Add untracked/ignored files to the ignore list
OLDIFS=$IFS
IFS=$'\n'
for _vcs_ignore in $(git -C "$topdir" ls-files --others --directory); do
	if [ -d "$topdir/$_vcs_ignore" ]; then
		_vcs_ignore="$_vcs_ignore*"
	fi
	if [ -z "$ignore" ]; then
		ignore="$_vcs_ignore"
	else
		ignore="$ignore:$_vcs_ignore"
	fi
done
IFS=$OLDIFS

# TOC file processing.
tocfile=$(
	cd "$topdir" || exit
	filename=$( ls *.toc -1 2>/dev/null | head -n1 )
	if [[ -z "$filename" && -n "$package" ]]; then
		# Handle having the core addon in a sub dir, which people have starting doing
		# for some reason. Tons of caveats, just make the base dir your base addon people!
		filename=$( ls "$package"/*.toc -1 2>/dev/null | head -n1 )
	fi
	echo "$filename"
)
if [[ -z "$tocfile" || ! -f "$topdir/$tocfile" ]]; then
	echo "Could not find an addon TOC file. In another directory? Make sure it matches the 'package-as' in .pkgmeta" >&2
	exit 1
fi

# Get the interface version for setting upload version.
toc_file=$( sed -e '1s/^\xEF\xBB\xBF//' -e $'s/\r//g' "$topdir/$tocfile" ) # go away bom, crlf
if [ -z "$toc_version" ]; then
	toc_version=$( echo "$toc_file" | awk '/^## Interface:/ { print $NF }' )
fi

# Get the title of the project for using in the changelog.
project=$( echo "$toc_file" | awk '/^## Title:/' | sed -e 's/## Title\s*:\s*\(.*\)\s*/\1/' -e 's/|c[0-9A-Fa-f]\{8\}//g' -e 's/|r//g' )
unset toc_file

echo
echo "Packaging $package"
if [ -n "$project_version" ]; then
	echo "Current version: $project_version"
fi
if [ -n "$previous_version" ]; then
	echo "Previous version: $previous_version"
fi
(
	if [[ "$tag" =~ "alpha" ]]; then
		build_type="alpha"
	fi
	if [[ "$tag" == *beta* ]]; then
		build_type="beta"
	fi
	if [ -z "$build_type" ]; then
		build_type="retail"
	fi
	echo "Build type: $build_type"
	echo
)
if [ -n "$project_github_slug" ]; then
	echo "GitHub: $project_github_slug${github_token:+ [token set]}"
fi
echo "Checkout directory: $topdir"
echo "Release directory: $releasedir"
echo

# Set $pkgdir to the path of the package directory inside $releasedir.
pkgdir="$releasedir/$package"
if [ -d "$pkgdir" ] && [ -z "$overwrite" ]; then
	#echo "Removing previous package directory: $pkgdir"
	rm -fr "$pkgdir"
fi
if [ ! -d "$pkgdir" ]; then
	mkdir -p "$pkgdir"
fi

# Set the contents of the addon zipfile.
contents="$package"

match_pattern() {
	_mp_file=$1
	_mp_list="$2:"
	while [ -n "$_mp_list" ]; do
		_mp_pattern=${_mp_list%%:*}
		_mp_list=${_mp_list#*:}
		case $_mp_file in
		$_mp_pattern)
			return 0
			;;
		esac
	done
	return 1
}

set_info_file() {
	if [ "$si_repo_type" = "git" ]; then
		_si_file=${1#si_repo_dir} # need the path relative to the checkout
		# Populate filter vars from the last commit the file was included in.
		si_file_hash=$( git -C "$si_repo_dir" log --max-count=1 --format="%H" "$_si_file" 2>/dev/null )
		si_file_abbreviated_hash=$( git -C "$si_repo_dir" log --max-count=1  --format="%h"  "$_si_file" 2>/dev/null )
		si_file_author=$( git -C "$si_repo_dir" log --max-count=1 --format="%an" "$_si_file" 2>/dev/null )
		si_file_timestamp=$( git -C "$si_repo_dir" log --max-count=1 --format="%at" "$_si_file" 2>/dev/null )
		si_file_date_iso=$( TZ= printf "%(%Y-%m-%dT%H:%M:%SZ)T" "$si_file_timestamp" )
		si_file_date_integer=$( TZ= printf "%(%Y%m%d%H%M%S)T" "$si_file_timestamp" )
		si_file_revision=$( git -C "$si_repo_dir" rev-list --count "$si_file_hash" 2>/dev/null ) # XXX checkout depth affects rev-list, see set_info_git
	elif [ "$si_repo_type" = "svn" ]; then
		_si_file="$1"
		# Temporary file to hold results of "svn info".
		_sif_svninfo="${si_repo_dir}/.svn/release_sh_svnfinfo"
		svn info "$_si_file" 2>/dev/null > "$_sif_svninfo"
		if [ -s "$_sif_svninfo" ]; then
			# Populate filter vars.
			si_file_revision=$( awk '/^Last Changed Rev:/ { print $NF; exit }' < "$_sif_svninfo" )
			si_file_author=$( awk '/^Last Changed Author:/ { print $0; exit }' < "$_sif_svninfo" | cut -d" " -f4- )
			_si_timestamp=$( awk '/^Last Changed Date:/ { print $4,$5,$6; exit }' < "$_sif_svninfo" )
			si_file_timestamp=$( strtotime "$_si_timestamp" "%F %T %z" )
			si_file_date_iso=$( TZ= printf "%(%Y-%m-%dT%H:%M:%SZ)T" "$si_file_timestamp" )
			si_file_date_integer=$( TZ= printf "%(%Y%m%d%H%M%S)T" "$si_file_timestamp" )
			# SVN repositories have no project hash.
			si_file_hash=
			si_file_abbreviated_hash=

			rm -f "$_sif_svninfo" 2>/dev/null
		fi
	elif [ "$si_repo_type" = "hg" ]; then
		_si_file=${1#si_repo_dir} # need the path relative to the checkout
		# Populate filter vars.
		si_file_hash=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{node}' "$_si_file" 2>/dev/null )
		si_file_abbreviated_hash=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{node|short}' "$_si_file" 2>/dev/null )
		si_file_author=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{author}' "$_si_file" 2>/dev/null )
		si_file_timestamp=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{date}' "$_si_file" 2>/dev/null | cut -d. -f1 )
		si_file_date_iso=$( TZ= printf "%(%Y-%m-%dT%H:%M:%SZ)T" "$si_file_timestamp" )
		si_file_date_integer=$( TZ= printf "%(%Y%m%d%H%M%S)T" "$si_file_timestamp" )
		si_file_revision=$( hg --cwd "$si_repo_dir" log --limit 1 --template '{rev}' "$_si_file" 2>/dev/null )
	fi
}

# FILTERS
# Filter for simple repository keyword replacement.
simple_filter() {
	sed \
		-e "s/@project-revision@/$si_project_revision/g" \
		-e "s/@project-hash@/$si_project_hash/g" \
		-e "s/@project-abbreviated-hash@/$si_project_abbreviated_hash/g" \
		-e "s/@project-author@/$si_project_author/g" \
		-e "s/@project-date-iso@/$si_project_date_iso/g" \
		-e "s/@project-date-integer@/$si_project_date_integer/g" \
		-e "s/@project-timestamp@/$si_project_timestamp/g" \
		-e "s/@project-version@/$si_project_version/g" \
		-e "s/@file-revision@/$si_file_revision/g" \
		-e "s/@file-hash@/$si_file_hash/g" \
		-e "s/@file-abbreviated-hash@/$si_file_abbreviated_hash/g" \
		-e "s/@file-author@/$si_file_author/g" \
		-e "s/@file-date-iso@/$si_file_date_iso/g" \
		-e "s/@file-date-integer@/$si_file_date_integer/g" \
		-e "s/@file-timestamp@/$si_file_timestamp/g"
}

lua_filter() {
	sed \
		-e "s/--@$1@/--[===[@$1@/g" \
		-e "s/--@end-$1@/--@end-$1@]===]/g" \
		-e "s/--\[===\[@non-$1@/--@non-$1@/g" \
		-e "s/--@end-non-$1@\]===\]/--@end-non-$1@/g"
}

toc_filter() {
	_trf_token=$1; shift
	_trf_comment=
	_trf_eof=
	while [ -z "$_trf_eof" ]; do
		IFS='' read -r _trf_line || _trf_eof="true"
		# Strip any trailing CR character.
		_trf_line=${_trf_line%$carriage_return}
		_trf_passthrough=
		case $_trf_line in
		"#@${_trf_token}@"*)
			_trf_comment="# "
			_trf_passthrough="true"
			;;
		"#@end-${_trf_token}@"*)
			_trf_comment=
			_trf_passthrough="true"
			;;
		esac
		if [ -z "$_trf_passthrough" ]; then
			_trf_line="$_trf_comment$_trf_line"
		fi
		if [ -n "$_trf_eof" ]; then
			echo -n "$_trf_line"
		else
			echo "$_trf_line"
		fi
	done
}

toc_filter2() {
	_trf_token=$1
	_trf_action=1
	if [ "$2" = "true" ]; then
		_trf_action=0
	fi
	shift 2
	_trf_keep=1
	_trf_uncomment=
	_trf_eof=
	while [ -z "$_trf_eof" ]; do
		IFS='' read -r _trf_line || _trf_eof="true"
		# Strip any trailing CR character.
		_trf_line=${_trf_line%$carriage_return}
		case $_trf_line in
		*"#@$_trf_token@"*)
			# remove the tokens, keep the content
			_trf_keep=$_trf_action
			;;
		*"#@non-$_trf_token@"*)
			# remove the tokens, remove the content
			_trf_keep=$(( 1-_trf_action ))
			_trf_uncomment="true"
			;;
		*"#@end-$_trf_token@"*|*"#@end-non-$_trf_token@"*)
			# remove the tokens
			_trf_keep=1
			_trf_uncomment=
			;;
		*)
			if (( _trf_keep )); then
				if [ -n "$_trf_uncomment" ]; then
					_trf_line="${_trf_line#\# }"
				fi
				if [ -n "$_trf_eof" ]; then
					echo -n "$_trf_line"
				else
					echo "$_trf_line"
				fi
			fi
			;;
		esac
	done
}

xml_filter() {
	sed \
		-e "s/<!--@$1@-->/<!--@$1/g" \
		-e "s/<!--@end-$1@-->/@end-$1@-->/g" \
		-e "s/<!--@non-$1@/<!--@non-$1@-->/g" \
		-e "s/@end-non-$1@-->/<!--@end-non-$1@-->/g"
}

do_not_package_filter() {
	_dnpf_token=$1; shift
	_dnpf_string="do-not-package"
	_dnpf_start_token=
	_dnpf_end_token=
	case $_dnpf_token in
	lua)
		_dnpf_start_token="--@$_dnpf_string@"
		_dnpf_end_token="--@end-$_dnpf_string@"
		;;
	toc)
		_dnpf_start_token="#@$_dnpf_string@"
		_dnpf_end_token="#@end-$_dnpf_string@"
		;;
	xml)
		_dnpf_start_token="<!--@$_dnpf_string@-->"
		_dnpf_end_token="<!--@end-$_dnpf_string@-->"
		;;
	esac
	if [ -z "$_dnpf_start_token" ] || [ -z "$_dnpf_end_token" ]; then
		cat
	else
		# Replace all content between the start and end tokens, inclusive, with a newline to match CF packager.
		_dnpf_eof=
		_dnpf_skip=
		while [ -z "$_dnpf_eof" ]; do
			IFS='' read -r _dnpf_line || _dnpf_eof="true"
			# Strip any trailing CR character.
			_dnpf_line=${_dnpf_line%$carriage_return}
			case $_dnpf_line in
			*$_dnpf_start_token*)
				_dnpf_skip="true"
				echo -n "${_dnpf_line%%${_dnpf_start_token}*}"
				;;
			*$_dnpf_end_token*)
				_dnpf_skip=
				if [ -z "$_dnpf_eof" ]; then
					echo ""
				fi
				;;
			*)
				if [ -z "$_dnpf_skip" ]; then
					if [ -n "$_dnpf_eof" ]; then
						echo -n "$_dnpf_line"
					else
						echo "$_dnpf_line"
					fi
				fi
				;;
			esac
		done
	fi
}

line_ending_filter() {
	_lef_eof=
	while [ -z "$_lef_eof" ]; do
		IFS='' read -r _lef_line || _lef_eof="true"
		# Strip any trailing CR character.
		_lef_line=${_lef_line%$carriage_return}
		if [ -n "$_lef_eof" ]; then
			# Preserve EOF not preceded by newlines.
			echo -n "$_lef_line"
		else
			case $line_ending in
			dos)
				# Terminate lines with CR LF.
				printf "%s\r\n" "$_lef_line"
				;;
			unix)
				# Terminate lines with LF.
				printf "%s\n" "$_lef_line"
				;;
			esac
		fi
	done
}

copy_directory_tree() {
	_cdt_alpha=
	_cdt_debug=
	_cdt_ignored_patterns=
	_cdt_nolib=
	_cdt_do_not_package=
	_cdt_unchanged_patterns=
	_cdt_classic=
	OPTIND=1
	while getopts :adi:lnpu:c _cdt_opt "$@"; do
		case $_cdt_opt in
		a)	_cdt_alpha="true" ;;
		d)	_cdt_debug="true" ;;
		i)	_cdt_ignored_patterns=$OPTARG ;;
		n)	_cdt_nolib="true" ;;
		p)	_cdt_do_not_package="true" ;;
		u)	_cdt_unchanged_patterns=$OPTARG ;;
		c)	_cdt_classic="true"
		esac
	done
	shift $((OPTIND - 1))
	_cdt_srcdir=$1
	_cdt_destdir=$2

	echo "Copying files into ${_cdt_destdir#$topdir/}:"
	if [ ! -d "$_cdt_destdir" ]; then
		mkdir -p "$_cdt_destdir"
	fi
	# Create a "find" command to list all of the files in the current directory, minus any ones we need to prune.
	_cdt_find_cmd="find ."
	# Prune everything that begins with a dot except for the current directory ".".
	_cdt_find_cmd="$_cdt_find_cmd \( -name \".*\" -a \! -name \".\" \) -prune"
	# Prune the destination directory if it is a subdirectory of the source directory.
	_cdt_dest_subdir=${_cdt_destdir#${_cdt_srcdir}/}
	case $_cdt_dest_subdir in
	/*)	;;
	*)	_cdt_find_cmd="$_cdt_find_cmd -o -path \"./$_cdt_dest_subdir\" -prune" ;;
	esac
	# Print the filename, but suppress the current directory ".".
	_cdt_find_cmd="$_cdt_find_cmd -o \! -name \".\" -print"
	( cd "$_cdt_srcdir" && eval "$_cdt_find_cmd" ) | while read -r file; do
		file=${file#./}
		if [ -f "$_cdt_srcdir/$file" ]; then
			# Check if the file should be ignored.
			skip_copy=
			# Prefix external files with the relative pkgdir path
			_cdt_check_file=$file
			if [ -n "${_cdt_destdir#$pkgdir}" ]; then
				_cdt_check_file="${_cdt_destdir#$pkgdir/}/$file"
			fi
			# Skip files matching the colon-separated "ignored" shell wildcard patterns.
			if [ -z "$skip_copy" ] && match_pattern "$_cdt_check_file" "$_cdt_ignored_patterns"; then
				skip_copy="true"
			fi
			# Never skip files that match the colon-separated "unchanged" shell wildcard patterns.
			unchanged=
			if [ -n "$skip_copy" ] && match_pattern "$file" "$_cdt_unchanged_patterns"; then
				skip_copy=
				unchanged="true"
			fi
			# Copy unskipped files into $_cdt_destdir.
			if [ -n "$skip_copy" ]; then
				echo "  Ignoring: $file"
			else
				dir=${file%/*}
				if [ "$dir" != "$file" ]; then
					mkdir -p "$_cdt_destdir/$dir"
				fi
				# Check if the file matches a pattern for keyword replacement.
				skip_filter="true"
				if match_pattern "$file" "*.lua:*.md:*.toc:*.txt:*.xml"; then
					skip_filter=
				fi
				if [ -n "$skip_filter" ] || [ -n "$unchanged" ]; then
					echo "  Copying: $file (unchanged)"
					cp "$_cdt_srcdir/$file" "$_cdt_destdir/$dir"
				else
					# Set the filters for replacement based on file extension.
					_cdt_alpha_filter=cat
					_cdt_debug_filter=cat
					_cdt_nolib_filter=cat
					_cdt_do_not_package_filter=cat
					_cdt_classic_filter=cat
					case $file in
					*.lua)
						[ -n "$_cdt_alpha" ] && _cdt_alpha_filter="lua_filter alpha"
						[ -n "$_cdt_debug" ] && _cdt_debug_filter="lua_filter debug"
						[ -n "$_cdt_do_not_package" ] && _cdt_do_not_package_filter="do_not_package_filter lua"
						[ -n "$_cdt_classic" ] && _cdt_classic_filter="lua_filter retail"
						;;
					*.xml)
						[ -n "$_cdt_alpha" ] && _cdt_alpha_filter="xml_filter alpha"
						[ -n "$_cdt_debug" ] && _cdt_debug_filter="xml_filter debug"
						[ -n "$_cdt_nolib" ] && _cdt_nolib_filter="xml_filter no-lib-strip"
						[ -n "$_cdt_do_not_package" ] && _cdt_do_not_package_filter="do_not_package_filter xml"
						[ -n "$_cdt_classic" ] && _cdt_classic_filter="xml_filter retail"
						;;
					*.toc)
						_cdt_alpha_filter="toc_filter2 alpha ${_cdt_alpha:-0}"
						_cdt_debug_filter="toc_filter2 debug ${_cdt_debug:-0}"
						_cdt_nolib_filter="toc_filter2 no-lib-strip ${_cdt_nolib:-0}"
						_cdt_do_not_package_filter="toc_filter2 do-not-package ${_cdt_do_not_package:-0}"
						_cdt_classic_filter="toc_filter2 retail ${_cdt_classic:-0}"
						;;
					esac
					# As a side-effect, files that don't end in a newline silently have one added.
					# POSIX does imply that text files must end in a newline.
					set_info_file "$_cdt_srcdir/$file"
					echo "  Copying: $file"
					simple_filter < "$_cdt_srcdir/$file" \
						| $_cdt_alpha_filter \
						| $_cdt_debug_filter \
						| $_cdt_nolib_filter \
						| $_cdt_do_not_package_filter \
						| $_cdt_classic_filter \
						> "$_cdt_destdir/$file"

					# simple_filter < "$_cdt_srcdir/$file" \
					# 	| $_cdt_alpha_filter \
					# 	| $_cdt_debug_filter \
					# 	| $_cdt_nolib_filter \
					# 	| $_cdt_do_not_package_filter \
					# 	| $_cdt_classic_filter \
					# 	| line_ending_filter \
					# 	> "$_cdt_destdir/$file"
				fi
			fi
		fi
	done
}

if [ -z "$skip_copying" ]; then
	cdt_args="-dp"
	if [ -n "$tag" ]; then
		cdt_args="${cdt_args}a"
	fi
	if [ -n "$nolib" ]; then
		cdt_args="${cdt_args}n"
	fi
	if [ -n "$classic" ]; then
		cdt_args="${cdt_args}c"
	fi
	if [ -n "$ignore" ]; then
		cdt_args="$cdt_args -i \"$ignore\""
	fi
	# if [ -n "$changelog" ]; then
	# 	cdt_args="$cdt_args -u \"$changelog\""
	# fi
	eval copy_directory_tree "$cdt_args" "\"$topdir\"" "\"$pkgdir\""
	echo
fi

# Create a changelog in the package directory if the source directory does
# not contain a manual changelog.
if [ -n "$manual_changelog" ] && [ -f "$topdir/$changelog" ]; then
	echo "Using manual changelog at $changelog"
	echo
	head -n7 "$topdir/$changelog"
	[ "$( wc -l < "$topdir/$changelog" )" -gt 7 ] && echo "..."
	echo

	if [ "$changelog_markup" = "markdown" ]; then
		# Convert Markdown to BBCode (with HTML as an intermediary) for sending to WoWInterface
		# Requires pandoc (http://pandoc.org/)
		_html_changelog=
		if pandoc --version &>/dev/null; then
			_html_changelog=$( pandoc -t html "$topdir/$changelog" )
		fi
		if [ -n "$_html_changelog" ]; then
			wowi_changelog="$releasedir/WOWI-$project_version-CHANGELOG.txt"
			echo "$_html_changelog" | sed \
				-e 's/<\(\/\)\?\(b\|i\|u\)>/[\1\2]/g' \
				-e 's/<\(\/\)\?em>/[\1i]/g' \
				-e 's/<\(\/\)\?strong>/[\1b]/g' \
				-e 's/<ul[^>]*>/[list]/g' -e 's/<ol[^>]*>/[list="1"]/g' \
				-e 's/<\/[ou]l>/[\/list]\n/g' \
				-e 's/<li>/[*]/g' -e 's/<\/li>//g' -e '/^\s*$/d' \
				-e 's/<h1[^>]*>/[size="6"]/g' -e 's/<h2[^>]*>/[size="5"]/g' -e 's/<h3[^>]*>/[size="4"]/g' \
				-e 's/<h4[^>]*>/[size="3"]/g' -e 's/<h5[^>]*>/[size="3"]/g' -e 's/<h6[^>]*>/[size="3"]/g' \
				-e 's/<\/h[1-6]>/[\/size]\n/g' \
				-e 's/<a href=\"\([^"]\+\)\"[^>]*>/[url="\1"]/g' -e 's/<\/a>/\[\/url]/g' \
				-e 's/<img src=\"\([^"]\+\)\"[^>]*>/[img]\1[\/img]/g' \
				-e 's/<\(\/\)\?blockquote>/[\1quote]\n/g' \
				-e 's/<pre><code>/[code]\n/g' -e 's/<\/code><\/pre>/[\/code]\n/g' \
				-e 's/<code>/[font="monospace"]/g' -e 's/<\/code>/[\/font]/g' \
				-e 's/<\/p>/\n/g' \
				-e 's/<[^>]\+>//g' \
				-e 's/&quot;/"/g' \
				-e 's/&amp;/&/g' \
				-e 's/&lt;/</g' \
				-e 's/&gt;/>/g' \
				-e "s/&#39;/'/g" \
				| line_ending_filter > "$wowi_changelog"

				# extra conversion for discount markdown
				# -e 's/&\(ld\|rd\)quo;/"/g' \
				# -e "s/&\(ls\|rs\)quo;/'/g" \
				# -e 's/&ndash;/--/g' \
				# -e 's/&hellip;/.../g' \
				# -e 's/^[ \t]*//g' \
		fi
	fi
else
	if [ -n "$manual_changelog" ]; then
		echo "Warning! Could not find a manual changelog at $topdir/$changelog"
		manual_changelog=
	fi
	changelog="CHANGELOG.md"
	changelog_markup="markdown"

	echo "Generating changelog of commits into $changelog"

	if [ "$repository_type" = "git" ]; then
		changelog_url=
		changelog_version=
		changelog_url_wowi=
		changelog_version_wowi=
		_changelog_range=
		if [ -z "$previous_version" ] && [ -z "$tag" ]; then
			# no range, show all commits up to ours
			changelog_url="[Full Changelog](${project_github_url}/commits/${project_hash})"
			changelog_version="[${project_version}](${project_github_url}/tree/${project_hash})"
			changelog_url_wowi="[url=${project_github_url}/commits/${project_hash}]Full Changelog[/url]"
			changelog_version_wowi="[url=${project_github_url}/tree/${project_hash}]${project_version}[/url]"
			_changelog_range="$project_hash"
		elif [ -z "$previous_version" ] && [ -n "$tag" ]; then
			# first tag, show all commits upto it
			changelog_url="[Full Changelog](${project_github_url}/commits/${tag})"
			changelog_version="[${project_version}](${project_github_url}/tree/${tag})"
			changelog_url_wowi="[url=${project_github_url}/commits/${tag}]Full Changelog[/url]"
			changelog_version_wowi="[url=${project_github_url}/tree/${tag}]${project_version}[/url]"
			_changelog_range="$tag"
		elif [ -n "$previous_version" ] && [ -z "$tag" ]; then
			# compare between last tag and our commit
			changelog_url="[Full Changelog](${project_github_url}/compare/${previous_version}...${project_hash})"
			changelog_version="[$project_version](${project_github_url}/tree/${project_hash})"
			changelog_url_wowi="[url=${project_github_url}/compare/${previous_version}...${project_hash}]Full Changelog[/url]"
			changelog_version_wowi="[url=${project_github_url}/tree/${project_hash}]${project_version}[/url]"
			_changelog_range="$previous_version..$project_hash"
		elif [ -n "$previous_version" ] && [ -n "$tag" ]; then
			# compare between last tag and our tag
			changelog_url="[Full Changelog](${project_github_url}/compare/${previous_version}...${tag})"
			changelog_version="[$project_version](${project_github_url}/tree/${tag})"
			changelog_url_wowi="[url=${project_github_url}/compare/${previous_version}...${tag}]Full Changelog[/url]"
			changelog_version_wowi="[url=${project_github_url}/tree/${tag}]${project_version}[/url]"
			_changelog_range="$previous_version..$tag"
		fi
		# lazy way out
		if [ -z "$project_github_url" ]; then
			changelog_url=
			changelog_version=$project_version
			changelog_url_wowi=
			changelog_version_wowi="[color=orange]${project_version}[/color]"
		fi
		changelog_date=$( TZ= printf "%(%Y-%m-%d)T" "$project_timestamp" )

		cat <<- EOF | line_ending_filter > "$pkgdir/$changelog"
		# $project

		## $changelog_version ($changelog_date)
		$changelog_url

		EOF
		git -C "$topdir" log "$_changelog_range" --pretty=format:"###%B" \
			| sed -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/- /g' -e 's/$/  /' \
			      -e 's/\([a-zA-Z0-9]\)_\([a-zA-Z0-9]\)/\1\\_\2/g' \
			      -e 's/\[ci skip\]//g' -e 's/\[skip ci\]//g' \
			      -e '/git-svn-id:/d' -e '/^\s*This reverts commit [0-9a-f]\{40\}\.\s*$/d' \
			      -e '/^\s*$/d' \
			| line_ending_filter >> "$pkgdir/$changelog"

		# WoWI uses BBCode, generate something usable to post to the site
		# the file is deleted on successful upload
		if [ -n "$addonid" ] && [ -n "$tag" ] && [ -n "$wowi_gen_changelog" ]; then
			changelog_previous_wowi=
			if [ -n "$project_github_url" ] && [ -n "$github_token" ]; then
				changelog_previous_wowi="[url=${project_github_url}/releases]Previous releases[/url]"
			fi
			wowi_changelog="$releasedir/WOWI-$project_version-CHANGELOG.txt"
			cat <<- EOF | line_ending_filter > "$wowi_changelog"
			[size=5]${project}[/size]
			[size=4]${changelog_version_wowi} (${changelog_date})[/size]
			${changelog_url_wowi} ${changelog_previous_wowi}
			[list]
			EOF
			git -C "$topdir" log "$_changelog_range" --pretty=format:"###%B" \
				| sed -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/[*]/g' \
				      -e 's/\[ci skip\]//g' -e 's/\[skip ci\]//g' \
				      -e '/git-svn-id:/d' -e '/^\s*This reverts commit [0-9a-f]\{40\}\.\s*$/d' \
				      -e '/^\s*$/d' \
				| line_ending_filter >> "$wowi_changelog"
			echo "[/list]" | line_ending_filter >> "$wowi_changelog"
		fi

	elif [ "$repository_type" = "svn" ]; then
		_changelog_range=
		if [ -n "$previous_version" ]; then
			_changelog_range="-r$project_revision:$previous_revision"
		fi
		changelog_date=$( TZ= printf "%(%Y-%m-%d)T" "$project_timestamp" )

		cat <<- EOF | line_ending_filter > "$pkgdir/$changelog"
		# $project

		## $project_version ($changelog_date)

		EOF
		svn log "$topdir" "$_changelog_range" --xml \
			| awk '/<msg>/,/<\/msg>/' \
			| sed -e 's/<msg>/###/g' -e 's/<\/msg>//g' \
			      -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/- /g' -e 's/$/  /' \
			      -e 's/\([a-zA-Z0-9]\)_\([a-zA-Z0-9]\)/\1\\_\2/g' \
			      -e 's/\[ci skip\]//g' -e 's/\[skip ci\]//g' \
			      -e '/^\s*$/d' \
			| line_ending_filter >> "$pkgdir/$changelog"

		# WoWI uses BBCode, generate something usable to post to the site
		# the file is deleted on successful upload
		if [ -n "$addonid" ] && [ -n "$tag" ] && [ -n "$wowi_gen_changelog" ]; then
			wowi_changelog="$releasedir/WOWI-$project_version-CHANGELOG.txt"
			cat <<- EOF | line_ending_filter > "$wowi_changelog"
			[size=5]${project}[/size]
			[size=4][color=orange]${project_version}[/color] (${changelog_date})[/size]

			[list]
			EOF
			svn log "$topdir" "$_changelog_range" --xml \
				| awk '/<msg>/,/<\/msg>/' \
				| sed -e 's/<msg>/###/g' -e 's/<\/msg>//g' \
				      -e 's/^/    /g' -e 's/^ *$//g' -e 's/^    ###/[*]/g' \
				      -e 's/\[ci skip\]//g' -e 's/\[skip ci\]//g' \
				      -e '/^\s*$/d' \
				| line_ending_filter >> "$wowi_changelog"
			echo "[/list]" | line_ending_filter >> "$wowi_changelog"
		fi

	elif [ "$repository_type" = "hg" ]; then
		_changelog_range=.
		if [ -n "$previous_revision" ]; then
			_changelog_range="::$project_revision - ::$previous_revision - filelog(.hgtags)"
		fi
		changelog_date=$( TZ= printf "%(%Y-%m-%d)T" "$project_timestamp" )

		cat <<- EOF | line_ending_filter > "$pkgdir/$changelog"
		# $project

		## $project_version ($changelog_date)

		EOF
		hg --cwd "$topdir" log -r "$_changelog_range" --template '- {fill(desc|strip, 76, "", "  ")}\n' | line_ending_filter >> "$pkgdir/$changelog"

		# WoWI uses BBCode, generate something usable to post to the site
		# the file is deleted on successful upload
		if [ -n "$addonid" ] && [ -n "$tag" ] && [ -n "$wowi_gen_changelog" ]; then
			wowi_changelog="$releasedir/WOWI-$project_version-CHANGELOG.txt"
			cat <<- EOF | line_ending_filter > "$wowi_changelog"
			[size=5]${project}[/size]
			[size=4][color=orange]${project_version}[/color] (${changelog_date})[/size]

			[list]
			EOF
			hg --cwd "$topdir" log "$_changelog_range" --template '[*]{desc|strip|escape}\n' | line_ending_filter >> "$wowi_changelog"
			echo "[/list]" | line_ending_filter >> "$wowi_changelog"
		fi
	fi

	echo
	echo "$(<"$pkgdir/$changelog")"
	echo
fi

###
### Process .pkgmeta to perform move-folders actions.
###

if [ -f "$pkgmeta_file" ]; then
	yaml_eof=
	while [ -z "$yaml_eof" ]; do
		IFS='' read -r yaml_line || yaml_eof="true"
		# Strip any trailing CR character.
		yaml_line=${yaml_line%$carriage_return}
		case $yaml_line in
		[!\ ]*:*)
			# Split $yaml_line into a $yaml_key, $yaml_value pair.
			yaml_keyvalue "$yaml_line"
			# Set the $pkgmeta_phase for stateful processing.
			pkgmeta_phase=$yaml_key
			;;
		" "*)
			yaml_line=${yaml_line#"${yaml_line%%[! ]*}"} # trim leading whitespace
			case $yaml_line in
			"- "*)
				;;
			*:*)
				# Split $yaml_line into a $yaml_key, $yaml_value pair.
				yaml_keyvalue "$yaml_line"
				case $pkgmeta_phase in
				move-folders)
					srcdir="$releasedir/$yaml_key"
					destdir="$releasedir/$yaml_value"
					if [[ -d "$destdir" && -z "$overwrite" && "$srcdir" != "$destdir/"* ]]; then
						rm -fr "$destdir"
					fi
					if [ -d "$srcdir" ]; then
						if [ ! -d "$destdir" ]; then
							mkdir -p "$destdir"
						fi
						echo "Moving $yaml_key to $yaml_value"
						mv -f "$srcdir"/* "$destdir" && rm -fr "$srcdir"
						contents="$contents $yaml_value"
						# Check to see if the base source directory is empty
						_mf_basedir=${srcdir%$(basename "$yaml_key")}
						if [ ! "$( ls -A "$_mf_basedir" )" ]; then
							echo "Removing empty directory ${_mf_basedir#$releasedir/}"
							rm -fr "$_mf_basedir"
						fi
					fi
					# update external dir
					nolib_exclude=${nolib_exclude//$srcdir/$destdir}
					;;
				esac
				;;
			esac
			;;
		esac
	done < "$pkgmeta_file"
	if [ -n "$srcdir" ]; then
		echo
	fi
fi

###
### Create the final zipfile for the addon.
###

if [ -z "$skip_zipfile" ]; then
	archive_package_name="${package//[^A-Za-z0-9._-]/_}"

	classic_tag=
	if [[ -n "$classic" && "${project_version,,}" != *"classic"* ]]; then
		# if it's a classic build, and classic isn't in the name, append it for clarity
		classic_tag="-classic"
	fi

	archive_version="$project_version"
	archive_name="$archive_package_name-$project_version$classic_tag.zip"
	archive="$releasedir/$archive_name"

	nolib_archive_version="$project_version-nolib"
	nolib_archive_name="$archive_package_name-$nolib_archive_version$classic_tag.zip"
	nolib_archive="$releasedir/$nolib_archive_name"

	if [ -n "$nolib" ]; then
		archive_version="$nolib_archive_version"
		archive_name="$nolib_archive_name"
		archive="$nolib_archive"
		nolib_archive=
	fi

	echo
	echo "Creating archive: $archive_name"

	if [ -f "$archive" ]; then
		rm -f "$archive"
	fi
	( cd "$releasedir" && zip -X -r "$archive" $contents )

	if [ ! -f "$archive" ]; then
		exit 1
	fi
	echo

	# Create nolib version of the zipfile
	if [ -n "$enable_nolib_creation" ] && [ -z "$nolib" ] && [ -n "$nolib_exclude" ]; then
		echo "Creating no-lib archive: $nolib_archive_name"

		# run the nolib_filter
		find "$pkgdir" -type f \( -name "*.xml" -o -name "*.toc" \) -print | while read -r file; do
			case $file in
			*.toc)	_filter="toc_filter2 no-lib-strip" ;;
			*.xml)	_filter="xml_filter no-lib-strip" ;;
			esac
			$_filter < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
		done

		# make the exclude paths relative to the release directory
		nolib_exclude=${nolib_exclude//$releasedir\//}

		if [ -f "$nolib_archive" ]; then
			rm -f "$nolib_archive"
		fi
		# set noglob so each nolib_exclude path gets quoted instead of expanded
		( set -f; cd "$releasedir" && zip -X -r -q "$nolib_archive" $contents -x $nolib_exclude )

		if [ ! -f "$nolib_archive" ]; then
			exit_code=1
		fi
		echo
	fi

	###
	### Deploy the zipfile.
	###

	github_token=$GITHUB_OAUTH

	upload_github=$( [[ -z "$skip_upload" && -n "$tag" && -n "$project_github_slug" && -n "$github_token" ]] && echo true )

	if [[ -n "$upload_github" ]] && ! jq --version &>/dev/null; then
		echo "Skipping upload because \"jq\" was not found."
		echo
		upload_github=
		exit_code=1
	fi

	# Create a GitHub Release for tags and upload the zipfile as an asset.
	if [ -n "$upload_github" ]; then
		upload_github_asset() {
			_ghf_release_id=$1
			_ghf_file_name=$2
			_ghf_file_path=$3
			_ghf_resultfile="$releasedir/gh_asset_result.json"

			# check if an asset exists and delete it (editing a release)
			asset_id=$( curl -sS -H "Authorization: token $github_token" "https://api.github.com/repos/$project_github_slug/releases/$_ghf_release_id/assets" | jq '.[] | select(.name? == "'"$_ghf_file_name"'") | .id' )
			if [ -n "$asset_id" ]; then
				curl -s -H "Authorization: token $github_token" -X DELETE "https://api.github.com/repos/$project_github_slug/releases/assets/$asset_id" &>/dev/null
			fi

			echo -n "Uploading $_ghf_file_name... "
			result=$( curl -sS --retry 3 --retry-delay 10 \
					-w "%{http_code}" -o "$_ghf_resultfile" \
					-H "Authorization: token $github_token" \
					-H "Content-Type: application/zip" \
					--data-binary "@$_ghf_file_path" \
					"https://uploads.github.com/repos/$project_github_slug/releases/$_ghf_release_id/assets?name=$_ghf_file_name" ) &&
			{
				if [ "$result" = "201" ]; then
					echo "Success!"
				else
					echo "Error ($result)"
					if [ -s "$_ghf_resultfile" ]; then
						echo "$(<"$_ghf_resultfile")"
					fi
					exit_code=1
				fi
			} || {
				exit_code=1
			}

			rm -f "$_ghf_resultfile" 2>/dev/null
			return 0
		}

		_gh_payload=$( cat <<-EOF
		{
		  "tag_name": "$tag",
		  "name": "$tag",
		  "body": $( jq --slurp --raw-input '.' < "$topdir/$changelog" ),
		  "draft": false,
		  "prerelease": $( [[ "${tag,,}" == *"beta"* || "${tag,,}" == *"alpha"* ]] && echo true || echo false )
		}
		EOF
		)
		resultfile="$releasedir/gh_result.json"

		release_id=$( curl -sS -H "Authorization: token $github_token" "https://api.github.com/repos/$project_github_slug/releases/tags/$tag" | jq '.id // empty' )
		if [ -n "$release_id" ]; then
			echo "Updating GitHub release: https://github.com/$project_github_slug/releases/tag/$tag"
			_gh_release_url="-X PATCH https://api.github.com/repos/$project_github_slug/releases/$release_id"
		else
			echo "Creating GitHub release: https://github.com/$project_github_slug/releases/tag/$tag"
			_gh_release_url="https://api.github.com/repos/$project_github_slug/releases"
		fi
		result=$( echo "$_gh_payload" | curl -sS --retry 3 --retry-delay 10 \
				-w "%{http_code}" -o "$resultfile" \
				-H "Authorization: token $github_token" \
				-d @- \
				$_gh_release_url ) &&
		{
			if [ "$result" = "200" ] || [ "$result" = "201" ]; then # edited || created
				if [ -z "$release_id" ]; then
					release_id=$( jq '.id' < "$resultfile" )
				fi
				upload_github_asset "$release_id" "$archive_name" "$archive"
				if [ -f "$nolib_archive" ]; then
					upload_github_asset "$release_id" "$nolib_archive_name" "$nolib_archive"
				fi
			else
				echo "Error! ($result)"
				if [ -s "$resultfile" ]; then
					echo "$(<"$resultfile")"
				fi
				exit_code=1
			fi
		} || {
			exit_code=1
		}

		rm -f "$resultfile" 2>/dev/null
		echo
	fi
fi