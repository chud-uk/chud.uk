#!/bin/sh
set -e

INPUT="./src"
DIST="./dist"

rm -rf $DIST
mkdir -p $DIST

find $INPUT -name "*.md" -exec sh -c 'TEMP=`echo $1 | sed "s/.md$/.html/"`
pandoc -s --template ./html.template -o "$TEMP" $1
OUT=`echo $TEMP | sed "s+$2+$3+"`
mkdir -p `dirname $OUT`
mv $TEMP $OUT
' _ {} $INPUT $DIST \;

./rssg.sh dist/index.html > dist/rss.xml
