#!/bin/bash
#
# https://www.romanzolotarev.com/bin/rssg
# Copyright 2018 Roman Zolotarev <hi@romanzolotarev.com>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

# It is a modified version of the script tailored specifically for my blog.

set -e

main () {
	test -n "$1" || usage
	test -f "$1" || no_file "$1"

	index_file=$(readlink -f "$1")
	test -z "${index_file##*html}" && html=$(cat "$index_file")
	test -n "$html" || usage

	base="${index_file%/*}"

	title="Chud.uk"
	description="Someone's blog"
	base_url="https://chud.uk"
	rss_url="https://chud.uk/rss.xml"

	items=$(	echo "$html" | get_items)

	rss=$(		echo "$items" |
			render_items "$base" "$base_url" |
			render_feed "$rss_url" "$title" "$description")

	>&2 echo "[rssg] ${index_file##$(pwd)/} $(echo "$rss" | grep -c '<item>') items"
	echo "$rss"
}

usage() {
	echo "usage: ${0##*/} index.{html,md} title > rss.xml" >&2
	exit 1
}

no_file() {
	echo "${0##*/}: $1: No such file" >&2
	exit 2
}

get_title() {
	awk 'tolower($0)~/^<h1/{gsub(/<[^>]*>/,"",$0);print;exit}'
}

get_url() {
	grep -i '<a .*rss.xml"' | head -1 |
	sed 's#.*href="\(.*\)".*#\1#'
}

get_items() {
	grep -i '<li>.*href=".*"' |
	sed 's#<li>\(.*\) <a href="\(.*\)">\(.*\)</a>.*#\2 \1 \3#'
}

remove_tags() {
	sed 's#<[^>]*>##g;s#</[^>]*>##g'
}

remove_nbsp() {
	sed 's#\&nbsp;# #g'
}

rel_to_abs_urls() {
	site_url="$1"
	base_url="$2"

	abs='s#(src|href)="/([^"]*)"#\1="'"$site_url"/'\2"#g'
	rel='s#(src|href)="([^:/"]*)"#\1="'"$base_url"/'\2"#g'
	sed -E "$abs;$rel"
}

date_rfc_822() {
	if [ $(uname -s) == "Linux" ]; then
		if [ $1 ]; then
			date -u '+%a, %d %b %Y 00:00:00 %z' --date=$1
		else
			date -u '+%a, %d %b %Y 00:00:00 %z'
		fi
	else
		if [ $1 ]; then
			date -juf '%Y-%m-%d' $1 '+%a, %d %b %Y 00:00:00 %z'
		else
			date -ju '+%a, %d %b %Y 00:00:00 %z'
		fi
	fi
}

render_items() {
	while read -r i
	do render_item "$1" "$2" "$i"
	done
}

render_item() {
	base="$1"
	base_url="$2"
	item="$3"

	site_url="$(echo "$base_url"| sed 's#\(.*//.*\)/.*#\1#')"

	date=$(echo "$item"|awk '{print$2}')
	url=$(echo "$item"|awk '{print$1}')

	f="$base/$url"

	test -f "$f" && html=$(cat "$f")

	description=$(
		echo "$html" | 
		sed -n "/<article>/,/<\/article>/p" | sed '1d;$d' |
		rel_to_abs_urls "$site_url" "$base_url" |
		remove_nbsp
	)
	title=$(echo "$description" | get_title)
	guid="$base_url/$(echo "$url" | sed 's#^/##')"

	echo '
<item>
<guid>'"$guid"'</guid>
<link>'"$guid"'</link>
<pubDate>'"$(date_rfc_822 "$date")"'</pubDate>
<title>'"$title"'</title>
<description><![CDATA[

'"$description"'

]]></description>
</item>'
}

render_feed() {
	url="$1"
	title=$(echo "$2" | remove_nbsp)
	description="$3"

	base_url="$(echo "$url" | cut -d '/' -f1-3)"

	echo '<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
<atom:link href="'"$url"'" rel="self" type="application/rss+xml" />
<title>'"$title"'</title>
<description>'"$description"'</description>
<link>'"$base_url"'/</link>
<lastBuildDate>'"$(date_rfc_822)"'</lastBuildDate>
'"$(cat)"'
</channel>
</rss>'
}

main "$@"
