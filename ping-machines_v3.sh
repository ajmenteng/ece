#!/bin/sh
# Script Name 	= ping-machines_v3.sh
# Author		= John W Chandra
# Desc			= This script is used to check any inactive workstation in the computer lab. 
#				  It will create and send an email that will automatically create a problem ticket
# 3/18/2014

# The function to PING
function ping_it() {
	   #naming adjustment with 2 digits ID for pho115 & pho117
	   if [[ $1 == "pho115" || $1 == "pho117" ]]; then
		if [ $2 -lt 10 ]; then host="ece-$1-0$2.$DOMAIN"
		else host="ece-$1-$2.$DOMAIN"
		fi
	   #naming adjustment for hpcl which is using dash character
	   elif [[ $1 == "hpcl" ]]; then host="$1-$2"
	   else host="$1$2"
	   fi
	   
       PING_CHECK=`ping -c 1 $host | grep ttl | wc -l`
       if [ $PING_CHECK == 0 ]; then
		# check if the host is already reported before
		# 0 = no | 1 = yes
		reported=0
		for prevhost in `cat $HISTORY`
		do
       		if [ $host == $prevhost ]; then	reported=1;	fi
		done
		if [ $reported -eq 0 ];	then
			echo "$host" >>$MESSAGE_TMP
			
			#sanitize the hostname
			name=`echo $host | sed -e 's/ece-//g' -e 's/.ad.bu.edu//g'`
			
			#create a variable from a passed string. It will be combined for the subject of the email
			if [[ ${!1} == "" ]] ; then	printf -v $1 "$name"
			else printf -v $1 "${!1}/$2"
			fi			
		fi
		echo "$host" >>$HISTORY_TMP
       fi
}

DOMAIN="ad.bu.edu"

# Email
SUBJECT="Failed to PING "
EMAIL="[email address]" #change this field with the appropriate email
MESSAGE=/tmp/message.txt
MESSAGE_TMP=/tmp/message_tmp.txt

# create new files for messages
>$MESSAGE
>$MESSAGE_TMP

# History
HISTORY=/tmp/ping-machines_history.txt

# check history file
if [[ ! -f $HISTORY ]]; then >$HISTORY ; fi

# create temporary history file
HISTORY_TMP=/tmp/ping-machines_history-tmp.txt
>$HISTORY_TMP

for ((i=1; i<54; i++))
do
	if [[ $i -gt 9 && $i -lt 26 ]];	then ping_it "hpcl" $i; fi
	if [[ $i -lt 11 ]];	then ping_it "imsip" $i; fi
	if [[ $i -lt 22 ]];	then ping_it "pho115" $i; fi
	if [[ $i -lt 45 ]];	then ping_it "pho117" $i; fi
	if [[ $i -gt 7 ]]; then ping_it "signals" $i; fi
	if [[ $i -gt 10 && $i -lt 41 ]]; then ping_it "vlsi" $i; fi	
done

# if the $MESSAGE_TMP has something in it, send an email
if [[ -s $MESSAGE_TMP ]]
then
	#combine the variables and sanitize the string
	LISTDOWN=`echo "$hpcl;$imsip;$pho115;$pho117;$signals;$vlsi" | sed -e 's/;\{2,\}/;/g' -e 's/^;\|;$//g'`
	
	#prepare the message in the email
	echo "New list of machine(s) that cannot be pinged :" > $MESSAGE
	sort $MESSAGE_TMP >> $MESSAGE
	echo "" >> $MESSAGE
	echo "Summary of machine(s) that cannot be pinged :" >> $MESSAGE
	cat "$HISTORY_TMP" >> $MESSAGE
	
	#run the mail function
	/bin/mail -s "$SUBJECT $LISTDOWN" -r $FROM "$EMAIL" < $MESSAGE
fi

#replace the history file with the latest one
mv "$HISTORY_TMP" "$HISTORY"

#remove the unused files
rm "$MESSAGE"
rm "$MESSAGE_TMP"