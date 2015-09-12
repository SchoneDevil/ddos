#!/bin/bash
#
# base by db, tweaked by loeken
#
# dependencies
# apt-get install sharutils tcpdump sendmail-bin
#
#

interface=eth0
dumpdir=/tmp/
email=your@email.com
subject="ddos detected on `hostname`"
sender="fsociety"

while /bin/true; do
	 pkt_old=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
	 sleep 1
	 pkt_new=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
	 pkt=$(( $pkt_new-$pkt_old ))
	 echo -ne "\r$pkt packets/s\033[0K"
	 if [ $pkt -gt 5000 ]; then
		echo "more then 5000 pks / s"
		filename=$dumpdir/dump.`date +"%Y%m%d-%H%M%S"`.cap
		netstat -ant | awk '{print $6}' | sort | uniq -c | sort -n > $filename
		sed -i 's/)//g' $filename
		echo "#################TCPDUMP##################"
		tcpdump -n -s0 -c 1000 >> $filename
		echo "`date` Packets dumped, sleeping now."
		sleep 1
		data=`cat $filename`
sendmail -F $sender -it <<END_MESSAGE
To: $email
Subject: $subject
Attack Detected
`cat $filename`
END_MESSAGE
echo "sendmail complete"
		sleep 300
	fi
done
