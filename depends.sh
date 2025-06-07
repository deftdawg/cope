#!/usr/bin/env bash

missing=0
for i in $(cat dependencies);do
    j=$(dpkg-query -l $i 2>/dev/null| grep "^.i" | wc -l)
    if [ "$j" -eq "0" ]; then 
	echo $i
	missing=$(($missing+1))
    fi
done
exit $missing
