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
		tcpdump -nn -s0 -c 1000 >> $filename
		echo "`date` Packets dumped, sleeping now."
		sleep 1
		data=`cat $filename`
		rm -rf /tmp/src_*
		while read p; do
		  ip_src=`echo $p | cut -d " " -f 3 | cut -d "." -f 1,2,3,4`
		  port_src=`echo $p | cut -d " " -f 3 | cut -d "." -f 5`
		  ip_dst=`echo $p | cut -d " " -f 5 | cut -d "." -f 1,2,3,4`
		  port_dst=`echo $p | cut -d " " -f 5 | cut -d "." -f 5 | sed 's/\://g'`
		  if [ "$ip_src" == "$2" ];
		  then
		    echo $ip_src >> /tmp/src_ips_us
		    echo $port_src >> /tmp/src_ports_us
		  else
		    echo $ip_src >> /tmp/src_ips_them
		    echo $port_src >> /tmp/src_ports_them
		  fi
		done <$filename
		filename1="/tmp/temp_data"
		rm -rf $filename1
		sort -nu /tmp/src_ips_them > /tmp/src_ips_them_sorted
		count=`wc -l /tmp/src_ips_them_sorted | awk '{print $1}'`
		echo $count ips used in attack: >> $filename1
		cat /tmp/src_ips_them_sorted >> $filename1
		sort -nu /tmp/src_ports_us > /tmp/src_ports_us_sorted
		count2=`wc -l /tmp/src_ports_us_sorted | awk '{print $1}'`
		echo $count2 ports attacked  >> $filename1
		cat /tmp/src_ports_us_sorted >> $filename1

sendmail -F $sender -it <<END_MESSAGE
To: $email
Subject: $subject
Attack Detected
`cat $filename1`
`cat $filename`
END_MESSAGE
echo "sendmail complete"
		sleep 300
	fi
done
