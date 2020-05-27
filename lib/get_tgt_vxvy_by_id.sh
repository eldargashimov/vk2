#!/bin/bash

# Получить компоненты скорости цели по её ID

targets_dir="/tmp/GenTargets/Targets"

declare -a tgt_x 
declare -a tgt_y

if [ ! -z "$1" ]
then
	# Выбираем два наиболее новых файла
	tgt_files=`ls $targets_dir -t 2>/dev/null | egrep "^Target.id.$1\." | head -n 2`
	if [ ! -z "$tgt_files" ]
	then
		i=2
		for tgt_file in $tgt_files
		do
			let 'i--'
			tgt_crds=`cat "$targets_dir/$tgt_file"`
			tgt_x[$i]=`echo "$tgt_crds" | cut -d ' ' -f 1`
			tgt_y[$i]=`echo "$tgt_crds" | cut -d ' ' -f 2`
		done
		
		if [ "$i" -eq "0" ]
		then
			# Если нашлось два файла
			let 'vx=tgt_x[1]-tgt_x[0]'
			let 'vy=tgt_y[1]-tgt_y[0]'
		else
			# Если нашёлся только один файл
			let 'vx=0'
			let 'vy=0'
		fi
		
		printf "%5d %5d" $vx $vy
	else
		echo "Error: $1 not found"
	fi
else
#	echo "Error: empty ID"
	:
fi

