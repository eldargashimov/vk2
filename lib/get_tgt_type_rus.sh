#!/bin/bash

# Получить русское наименование станции по кодовому

# Только один аргумент

if [ "$#" -eq "1" -a ! -z "$1" ]
then
	case "$1" in
		airplane)
			tgt_type_rus="Самолёт"
			;;
		missile)
			tgt_type_rus="Крылатая ракета"
			;;
		icbm)
			tgt_type_rus="ББ БР"
			;;
		unknown)
			tgt_type_rus="Неизвестно"
			;;
		*)
			tgt_type_rus="$1"
			;;
	esac
	echo -n "$tgt_type_rus"
fi
