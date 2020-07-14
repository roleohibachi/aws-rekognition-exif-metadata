# aws-rekognition-exif-metadata
This is glue code to retrieve AWS Rekognition object tags, and write them to jpeg metadata (exif, iptc, xmp) as tags. This is cross-compatible and tested with Digikam and Synology Photo Station, but should be pretty much universal.

## prereqs
You'll need to install imagemagick (to convert large images down to smaller sizes for processing), exiv2 (for interacting with metadata), aws cli (for talking to aws), and (optional/recommended) GNU parallel. 

GNU parallel is a wonderful tool. Here's a citation for where it comes from:
  O. Tange (2011): GNU Parallel - The Command-Line Power Tool,
  ;login: The USENIX Magazine, February 2011:42-47.

You'll also need to configure AWS. This is done by creating an account on the website, adding the rekognition api to your stuff on that dashboard, and configuring a key to use for the command line client ('aws configure' to be prompted for it).

Images larger than 5MiB will be resized in /tmp before being uploaded, then deleted. If you're running this from a spinning-disk hard drive, it will serve you well to make sure /tmp is mounted as a tmpfs first; or otherwise trick mktemp into storing stuff in RAM.

## usage
Download the file, and `chmod +x tagaws.sh`.

You can run `./tagaws.sh PICT7943.JPG` to tag just one image.

You can tag a whole mess of images by running: `find /path/to/files -iname "*.jpg" -not -path "*/@eaDir/*" | parallel --timeout 60 -u -j 10 ~/tagaws.sh '{}'`

## output
each line of output contains the filename to which it applies. So don't be afraid to speed up GNU parallel by running with `-u`.

Images are modified inline; there is no backup of the originals. This tool does not have an undo button. If you need to un-tag images, open them with a digital asset manager like DigiKam and delete any tag starting with the prefix (`aws-` in the code as written, though you can change it easily)
