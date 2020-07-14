#!/bin/bash

#usage: ./tagaws.sh image.jpg
#for scripting: find . -iname "*.jpg" -not -path "*/@eaDir/*" | parallel --timeout 60 -u -j 10 ~/tagaws.sh '{}'
#apt install imagemagick exiv2 jq 
#install and configure aws cli manually https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

prefix="aws"

oldtags=$(exiv2 -K Xmp.dc.subject -Pv "$1")

#test if already processed
if ( grep -q "$prefix" <<< "$oldtags")
then
	echo -e $1' Done already'
	exit 1
fi

if ( grep -q "Document" <<< "$oldtags")
then
        echo -e $1' tagged as document, skipping.'
        exit 1
fi

maxsize=5242880
filesize=$(stat --printf="%s" "$1")
if [ $maxsize -lt $filesize ]
then
	echo $1 will be resized...
	tempfile=$(mktemp)
	convert "$1" -define jpeg:extent=5242880b $tempfile
	echo $1' resized. Querying aws...'
	awstags=$(aws rekognition detect-labels --image-bytes fileb://"$tempfile" | jq -r '.Labels[].Name' | tr -d ' ')
	rm $tempfile
else
	echo $1' AWS query starting.'
	awstags=$(aws rekognition detect-labels --image-bytes fileb://"$1" | jq -r '.Labels[].Name' | tr -d ' ')
fi

tagcount=0
for tag in $awstags
do
	tag=${prefix}-${tag}
	mline+=(-M "set Xmp.dc.subject XmpBag '$tag'")
	mline+=(-M "add Iptc.Application2.Keywords String '$tag'")
	mline+=(-M "set Xmp.digiKam.TagsList XmpSeq '$tag'")
	mline+=(-M "set Xmp.MicrosoftPhoto.LastKeywordXMP XmpBag '$tag'")
	mline+=(-M "set Xmp.lr.hierarchicalSubject XmpBag '$tag'")
	mline+=(-M "set Xmp.mediapro.CatalogSets XmpBag '$tag'")
	((tagcount++))
done
exiv2 "${mline[@]}" "$1"
echo $1' tagged with '$tagcount' tags'
exit 0
