#!/bin/bash
#
# initial code from db modded by loeken
# dependencies
# apt-get install tcpdump sendmail-bin
#
# name ddos_wanring.sh
#
# description: counts packets every second, if more then 5000 packets received per second,
# it will  start a tcpdump and send you via email. Adjust hte config values with your information
#
# config section start
interface=eth0
dumpdir=/tmp/
email=your.em@il.org
subject="ddos detected on `hostname`"
sender="`hostname`"
# config section end

while /bin/true; do
         pkt_old=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
         sleep 1
         pkt_new=`grep $interface: /proc/net/dev | cut -d : -f2 | awk '{ print $2 }'`
         pkt=$(( $pkt_new-$pkt_old ))
         echo -ne "\r$pkt packets/s\033[0K"
         if [ $pkt -gt 5000 ]; then
                filename=$dumpdir/dump.`date +"%Y%m%d-%H%M%S"`.cap
                tcpdump -n -s0 -c 2000 > $filename
                echo "`date` Packets dumped, sleeping now."
                sleep 1
                data=`cat $filename`
sendmail -F $sender -it <<END_MESSAGE
To: $email
Subject: $subject
`cat $filename`
END_MESSAGE
echo "sendmail complete"
                sleep 300
        fi
done
