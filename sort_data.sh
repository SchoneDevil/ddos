#!/bin/bash
rm $1_ips.txt $1_ips_unique.txt
cat $1.txt | cut -d \  -f 3 | cut -d "." -f 1,2,3,4 > $1_ips.txt
sort -nu $1_ips.txt > $1_ips_unique.txt
