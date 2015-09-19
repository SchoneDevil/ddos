#!/bin/bash
#
# usage ./sort_data.sh <dumpfile> <ip under attack>
#
rm -rf src_*
while read p; do
  ip_src=`echo $p | cut -d " " -f 3 | cut -d "." -f 1,2,3,4`
  port_src=`echo $p | cut -d " " -f 3 | cut -d "." -f 5`
  ip_dst=`echo $p | cut -d " " -f 5 | cut -d "." -f 1,2,3,4`
  port_dst=`echo $p | cut -d " " -f 5 | cut -d "." -f 5 | sed 's/\://g'`
  if [ "$ip_src" == "$2" ];
  then
    echo $ip_src >> src_ips_us
    echo $port_src >> src_ports_us
  else
    echo $ip_src >> src_ips_them
    echo $port_src >> src_ports_them
  fi
done <$1
sort -nu src_ips_them > src_ips_them_sorted
count=`wc -l src_ips_them_sorted | awk '{print $1}'`
echo $count ips used in attack:
cat src_ips_them_sorted
sort -nu src_ports_us > src_ports_us_sorted
count2=`wc -l src_ports_us_sorted | awk '{print $1}'`
echo $count2 ports attacked
cat src_ports_us_sorted
