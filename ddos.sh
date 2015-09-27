#!/bin/bash
#
# base by db, tweaked by loeken
#
# dependencies
# apt-get install sharutils tcpdump sendmail-bin bwm-ng
#
#

interface=eth0
dumpdir=/tmp/
email=loeken@internetz.me
subject="ddos detected on `hostname`"
sender="`hostname`"
pkg_treshhold=100000

while /bin/true; do
	 pkt_old=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
	 sleep 1
	 pkt_new=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
	 pkt=$(( $pkt_new-$pkt_old ))
	 echo -ne "\r$pkt packets/s\033[0K"
	 if [ $pkt -gt $pkg_treshhold ]; then
		echo "more than $pkg_treshhold pks / s"
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
		filename1="/tmp/ip_data"
		filename2="/tmp/bwm_data"
                filename3="/tmp/bwm_data_filtered1"
		rm -rf $filename1 $filename2 $filename3
		sort -nu /tmp/src_ips_them > /tmp/src_ips_them_sorted
		count=`wc -l /tmp/src_ips_them_sorted | awk '{print $1}'`
		echo $count ips used in attack: >> $filename1
		cat /tmp/src_ips_them_sorted >> $filename1
		sort -nu /tmp/src_ports_us > /tmp/src_ports_us_sorted
		count2=`wc -l /tmp/src_ports_us_sorted | awk '{print $1}'`
		echo $count2 ports attacked  >> $filename1
		cat /tmp/src_ports_us_sorted >> $filename1
		bwm-ng -o csv -c 1 -T rate --unit byte >> $filename2
                cat $filename2 | cut -d ";" -f 2,3,4 >> $filename3
sendmail -F $sender -it <<END_MESSAGE
To: $email
Subject: $subject
MIME-Version: 1.0
Content-Type: text/html; charset="us-ascii"
Content-Disposition: inline
<div style="background-color:darkgrey">
<h1 style="background-color:green">More then $pkg_treshhold packets were received per second</h1>

<h2 style="background-color:orange">Listing IPs used in this attack</h2>
<pre style="background-color:darkgrey">`cat $filename1`</pre>

<h2 style="background-color:orange">Showing network load</h2>
Interface - Network OUT - Network INT bytes/s<br>Unit: Bytes/s
<pre style="background-color:darkgrey">`cat $filename3`</pre></span>
<h2 style="background-color:orange">Showing raw TCPDUMP</h2>
<pre style="background-color:darkgrey">`cat $filename`</pre></div>
END_MESSAGE
echo "sendmail complete"
		sleep 300
	fi
done
