#!/bin/bash

# Получить пару координат цели по её ID

targets_dir="/tmp/GenTargets/Targets"

if [ ! -z "$1" ]
then
#	echo "Searching by ID: $1"
	# Выбираем один наиболее новый файл
	tgt_file=`ls $targets_dir -t 2>/dev/null | egrep "^Target.id.$1\." | head -n 1`
	if [ ! -z "$tgt_file" ]
	then
	
		# TODO: Что быстрее - awk или cut?
		
#		x=`cat "$targets_dir/$tgt_file" | awk '{print $1}'`
#		y=`cat "$targets_dir/$tgt_file" | awk '{print $2}'`
		
#		x=`cat "$targets_dir/$tgt_file" | cut -d ' ' -f 1`
#		y=`cat "$targets_dir/$tgt_file" | cut -d ' ' -f 2`
#		
#		printf "%8d %8d" $x $y

		printf "%8d %8d" `cat "$targets_dir/$tgt_file"`
		
	else
		echo "Error: $1 not found"
	fi
else
#	echo "Error: empty ID"
	:
fi
