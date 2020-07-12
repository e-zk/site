#!/bin/sh

# website url
WWW="${WWW:-https://zakaria.org}"
# httpd root
ROOT=${WEBROOT:-/www/htdocs}
# posts directory
POSTSDIR=${ROOT}/posts

# template paths
POSTM4=m4/post.m4
INDEXM4=m4/posts.m4


# help function
usage() {
	cat <<EOF
usage:  blog.sh [a|add] FILE
        blog.sh [i|index] [h|help]

        a|add   render a new post from FILE, create necessary dirs,
                copy plaintext to site root, then regenerate the index
        i|index regenerate index
	h|help  show this help message
EOF
}

# get file basename
# https://github.com/dylanaraps/pure-sh-bible#get-the-base-name-of-a-file-path
bname() {
        dir=${1%${1##*[!/]}}
        dir=${dir##*/}
        dir=${dir%"$2"}
        printf '%s\n' "${dir:-/}"
}

# date to seconds
#dts() {
#	# requires BSD `date`
#	date -j -f "%F %H:%M:%S" "${1} 00:00:00" +"%s"
#	# for gnu/busybox `date` uncomment:
#	#date -d "$1" +"%s"
#}

# get first h1 title from markdown file
get_md_title() {
	mdfile="$1"
	head -n 1 "$mdfile" | sed -e 's/^# //g'
}

# get post date from markdown filename
get_md_date() {
	filename="$1"
	#echo "$filename" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)\.md$/\1-\2-\3/'
	echo "$filename" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)$/\1-\2-\3/'
}

update_index() {
	
	echo "++ updating post index ..."

	# get list of posts
	posts=''
	for f in ${POSTSDIR}/*; do
		case "$f" in
			${POSTSDIR}/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*)
				posts="${posts}\n${f}" ;;
			*) ;;
		esac
	done
	
	# this is where we start generating the html
	html_table="<table class=\"poststable\">"

	# for each post dir in the sorted post dirs...
	for post in $(echo "$posts" | sort -r); do
		post_bname=$(bname $post)
		post_date=$(get_md_date "$post_bname")
		post_title=$(get_md_title "${POSTSDIR}/${post_bname}/${post_bname}.md")

		[ -z "$post_title" ] && post_title="untitled"

		echo "+ adding ${post_bname} ..."

		# add a table row to the html
		html="
	<tr>
		<td>${post_date}</td>
		<td><a href=\"${WWW}/posts/${post_bname}/\">${post_title}</a></td>
	</tr>"

		html_table="${html_table}${html}"
		
	done

	# close html table tag
	html_table="${html_table}\n</table>"
	
	# add indentation
	html_table=$(echo "${html_table}" | sed -e 's/^/		/g')

	echo "+ running m4 ..."
	m4 -DTABLE="$html_table" "$INDEXM4" > "${POSTSDIR}/index.html"
	
}

# make post
make_post() {
	mdfile="$1"
	post_title=$(get_md_title "$mdfile")
	post_date=$(get_md_date "$mdfile")
	filename=$(bname "$mdfile")
	post_dir="${POSTSDIR}/${filename%%.*}"

	echo "++ populating ${post_dir}/ ..."
	mkdir -p "${post_dir}"

	echo "+ compiling html w/ lowdown + m4 ..."
	m4 -DTITLE="$post_title" -DCREATED="$post_date" -DMDFILE="$mdfile" "$POSTM4" > "${post_dir}/post.html"

	echo "+ copying plaintext to ${post_dir}/${filename} ..."
	cp -v "$mdfile" "${post_dir}/${filename}"
}

# check argument length
if [ $# -lt 1 ]; then 
	usage
	exit 1
fi

# 
case "$1" in
	h|help|-h)
		usage
		exit 0
		;;
	a|add)
		# check if the file exists
		if [ ! -f "$2" ]; then
			echo "input file does not exist"
			exit 1
		fi

		# check if the file extension is .md
		if [ "${2##*.}" != "md" ]; then
			echo "input file does not have markdown extension"
			exit 1
		fi

		# compile post
		make_post "$2"

		# update index
		update_index
		;;
	i|index)
		# update index
		update_index
		;;
	*)
		echo "unknown command"
		usage
		exit 1
		;;
esac

