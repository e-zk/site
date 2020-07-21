#!/bin/sh

# site info
DOMAIN=zakaria.org
WWW="https://${DOMAIN}"

# directory to put posts
POSTSDIR=posts

# path to post template
POSTM4=m4/post.m4

# path to index template
INDEXM4=m4/posts.m4


# help function
usage() {
	cat <<EOF
usage:  blog.sh [a|add] FILE
        blog.sh [i|index] [h|help]

        a|add   render a new post from FILE, create necessary dirs,
                copy plaintext to site root, then regenerate the index
        i|index regenerate index
	r|rss   regenerate rss
	h|help  show this help message
EOF
}

log() {
	message="$1"
	level="$2"

	if [ -z "$level" ]; then
		printf "[blog] %s\\n" "$message"
		return
	fi

	printf "[%s] %s\\n" "$level" "$message"
}

# get file basename
# https://github.com/dylanaraps/pure-sh-bible#get-the-base-name-of-a-file-path
bname() {
        dir=${1%${1##*[!/]}}
        dir=${dir##*/}
        dir=${dir%"$2"}
        printf '%s\n' "${dir:-/}"
}

# get list of posts
get_post_list() {
	posts=''
	for post in ${POSTSDIR}/*; do
	        #[ "$post" = "posts/index.html" ] && continue
		case "$post" in
			${POSTSDIR}/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.html)
		        	posts="${posts}\\n${post}" ;;
			*) ;;
		esac
	done

	# reverse post order
	posts_rev=''
	for post in $(echo "$posts" | sort -r); do
		posts_rev="${posts_rev}\\n${post}"
	done

	echo "$posts_rev"
}

# get first h1 title from markdown file
get_md_title() {
	md_file="$1"
	head -n 1 "$md_file" | sed -e 's/^#\ \(.*\)$/\1/g'
}

# get post date from markdown filename
get_md_date() {
	filename="$1"
	echo "$filename" | sed -E 's/^([0-9]{4})-([0-9]{2})-([0-9]{2})-(.*)$/\1-\2-\3/'
}

# update post index page
update_index() {
	log "updating post index"

	# get list of posts
	posts="$(get_post_list)"
	
	# this is where we start generating the html
	html_table="<table class=\"poststable\">"

	# for each post dir in the sorted post dirs...
	for post in $posts; do

		post_bname=$(bname "$post")
		post_date=$(get_md_date "${post_bname%%.*}.md")
		post_title=$(get_md_title "${POSTSDIR}/${post_bname%%.*}.md")

		[ -z "$post_title" ] && post_title="untitled"

		log "adding ${post_bname} \"${post_title}\"" "indexing"

		# add a table row to the html
		html="
	<tr>
		<td>${post_date}</td>
		<td><a href=\"${post_bname%%.*}\">${post_title}</a></td>
	</tr>"

		html_table="${html_table}${html}"
	
	done

	# close html table tag
	html_table="${html_table}\\n</table>"
	
	# add indentation
	html_table=$(echo "${html_table}" | sed -e 's/^/		/g')

	log "running m4" "indexing"
	m4 -DTITLE="blog" -DTABLE="$html_table" "$INDEXM4" > "${POSTSDIR}/index.html"
	
}

# generate an rss feed
generate_rss() {
	printf '<rss version="2.0" xml:base="%s">\n' "${WWW}/"
	printf '\t<channel>\n'
	printf '\t<title>zakaria</title>\n'
	printf '\t\t<description/>\n'
	printf '\t\t<link>%s</link>\n' "${WWW}/"

	# get list of posts
	posts="$(get_post_list)"

	for post in $posts; do
		post_base=$(bname "$post")
		md_file="${post_base%%.*}.md"
		md_title=$(get_md_title "$md_file")
		md_date=$(get_md_date "$md_file")

	        printf '\t\t<item>\n'
	        printf '\t\t\t<link>%s</link>\n'       "${WWW}/${post}"
	        printf '\t\t\t<title>%s</title>\n'     "$md_title"
	        printf '\t\t\t<pubDate>%s</pubDate>\n' "$md_date"
	        printf '\t\t</item>\n'

	done

	printf '\t</channel>\n'
	printf '</rss>\n'
}

# make post
make_post() {
	md_file="$1"
	post_title=$(get_md_title "$md_file")
	post_date=$(get_md_date "$md_file")
	filename=$(bname "$md_file")

	# from lowdown get article content
	article_html=$(lowdown -Thtml "${md_file}")

	log "compiling html"
	m4 -DATITLE="$post_title" -DCREATED="$post_date" -DMDFILE="$md_file" -DCONTENT="$article_html" "$POSTM4" > "${POSTSDIR}/${filename%%.*}.html"

	log "copying plaintext"
	cp "$md_file" "${POSTSDIR}/${filename}" || { echo "error"; exit 1; }
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

		# update rss
		log "generating rss feed" "rss"
		generate_rss > rss.xml
		;;
	i|index)
		# update index
		update_index
		;;
	r|rss)
		# update rss
		log "generating rss feed" "rss"
		generate_rss > rss.xml
		;;
	*)
		echo "unknown command"
		usage
		exit 1
		;;
esac

