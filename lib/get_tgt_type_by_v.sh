#!/bin/bash

#############
### START ###
#############

if [ "$#" -eq "1" ]
then
	v=$1
	if [ "$v" -ge "50" -a "$v" -le "250" ]
	then
		echo "airplane"
	elif [ "$v" -gt "250" -a "$v" -le "1000" ]
	then
		echo "missile"
	elif [ "$v" -ge "8000" -a "$v" -le "10000" ]
	then
		echo "icbm"
	else
		echo "unknown"
	fi
fi
