#!/bin/bash
# File Splitter Tool
# Makes large files easier to use with Parallel Scanner by cutting them down by line count (goal should be 500 or smaller since Parallel max allowed jobs is 500, smaller if you want to reserve CPU resources)...
#
# ./splitter.sh <file2split> <Split-Size> <Prefix>
# ./splitter.sh ../range_lists/AUSTRALIA_IP_ranges.lst 500 AU

if [ ! -r "$1" ]; then
	echo
	echo "Can't read provided file! Please check path and permissions and try again......"
	echo
	exit 1;
fi

split -d -l "$2" "$1" "`echo $3`-tmps_"
