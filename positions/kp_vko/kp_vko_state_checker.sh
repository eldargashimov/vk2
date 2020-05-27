#!/bin/bash

# КП ВКО:
# Модуль монитора состояния систем ВКО

# Функция отправки сообщений
# sndmsg ИмяСтанции Сообщение
# ИмяСтанции = kp
function sendmsg()
{
	# Принимаем только 2 аргумента - адресата и содержание сообщения
	if [ "$#" -eq "2" ]
	then
		msg_fname="mesg.${station_id^^}.`date +'%s.%N'`"
		msg_contents=$2
		case $1 in
			kp)
				# Отправка сообщения на КП
				destination=$msg_dir_kp
				;;
		esac
		# Шлём только если есть куда (иначе bash может выдавать ошибку)
		if [ -e $destination ]
		then
			echo "$msg_contents" > "$destination/$msg_fname"
		fi
	fi
}

station_id="kp_vko_state_checker"

trap "sendmsg 'kp' 'Модуль контроля СВКО прервал работу'; exit" SIGINT

# Директория сообщений КП
msg_dir_kp="messages"

dtime_tolerance=5

rls_list="1 2 3"
zrdn_list="1 2 3"

period=5

sendmsg "kp" "Модуль контроля СВКО начал работу"

while true
do
	clear
	
	echo -e "Состояние СВКО \e[1m`date +"%x\e[0m в \e[1m%X %:z"`\e[0m\n"
	
	current_time=`date +%s`

## Проверка РЛС
	
	for i in $rls_list
	do
		echo -e "\e[36;1mРЛС$i:\e[0m"
		status_file="../rls${i}/rls${i}_status"
		if [ -f $status_file ]
		then
			# Если статусный файл существует, т.е. станция была запущена
			rls_uptime=`stat ../rls${i}/rls${i}_status -c %Y`
			rls_status=`cat ../rls${i}/rls${i}_status`
			dtime=$dtime_tolerance
			let "dtime=current_time-rls_uptime"
			if [ "$dtime" -lt "$dtime_tolerance" ]
			then
				echo -e -n "\tРежим:\t\e[42mработает\e[0m\t"
				if [ "$rls_status" = "0" ]
				then
					echo -e "\tСтатус:\t\e[42mбез замечаний\e[0m"
					# Сообщаем главному модулю КП о нормальной работе (UPD: не нужно)
#					sendmsg "kp" "РЛС$i работает нормально"
				elif [ -z "$rls_status" ]
				then
					# Может произойти так, что cat не
					# сможет прочитать файл, т.к. он
					# занят РЛС.
					echo -e "\tСтатус:\t\e[43mнеизвестен\e[0m"
				else
					echo -e "\tСтатус:\t\e[43mимеются проблемы\e[0m"
					# Сообщаем главному модулю КП о проблеме
					sendmsg "kp" "Внимание: проблема на РЛС$i"
				fi
			else
				echo -e "\tРежим:\t\e[41;1mне работает\e[0m \e[2m$dtime секунд\e[0m"
				# Сообщаем главному модулю КП
				sendmsg "kp" "Внимание: РЛС$i не работает"
			fi
		else
			# Если нет статусного файла
			echo -e "\t\e[41;1mОшибка\e[0m:\tнет связи"
			# Сообщаем главному модулю КП
			sendmsg "kp" "Внимание: нет связи с РЛС$i"
		fi
		echo
	done
###############

## Проверка ЗРДН
	for i in $zrdn_list
	do
		echo -e "\e[36;1mЗРДН$i:\e[0m"
		status_file="../zrdn${i}/zrdn${i}_status"
		if [ -f $status_file ]
		then
			# Если статусный файл существует, т.е. станция была запущена
			zrdn_uptime=`stat ../zrdn${i}/zrdn${i}_status -c %Y`
			zrdn_status=`cat ../zrdn${i}/zrdn${i}_status`
			dtime=$dtime_tolerance
			let "dtime=current_time-zrdn_uptime"
			if [ "$dtime" -lt "$dtime_tolerance" ]
			then
				echo -e -n "\tРежим:\t\e[42mработает\e[0m\t"
				if [ "$zrdn_status" = "0" ]
				then
					echo -e "\tСтатус:\t\e[42mбез замечаний\e[0m"
					# Сообщаем главному модулю КП о нормальной работе (UPD: не нужно)
#					sendmsg "kp" "ЗРДН$i работает нормально"
				elif [ -z "$zrdn_status" ]
				then
					# Может произойти так, что cat не
					# сможет прочитать файл, т.к. он
					# занят ЗРДН.
					echo -e "\tСтатус:\t\e[43mнеизвестен\e[0m [status file busy]"
				else
					echo -e "\tСтатус:\t\e[43mимеются проблемы\e[0m"
					# Сообщаем главному модулю КП о проблеме
					sendmsg "kp" "Внимание: проблема на ЗРДН$i"
				fi
			else
				echo -e "\tРежим:\t\e[41;1mне работает\e[0m \e[2m$dtime секунд\e[0m"
				# Сообщаем главному модулю КП
				sendmsg "kp" "Внимание: ЗРДН$i не работает"
			fi
		else
			# Если нет статусного файла
			echo -e "\t\e[41;1mОшибка\e[0m:\tнет связи"
			# Сообщаем главному модулю КП
			sendmsg "kp" "Внимание: нет связи с ЗРДН$i"
		fi
		echo
	done
###############

## Проверка СПРО
	echo -e "\e[36;1mСПРО:\e[0m"
	status_file="../spro/spro_status"
	if [ -f $status_file ]
	then
		# Если статусный файл существует, т.е. станция была запущена
		spro_uptime=`stat ../spro/spro_status -c %Y`
		spro_status=`cat ../spro/spro_status`
		dtime=$dtime_tolerance
		let "dtime=current_time-spro_uptime"
		if [ "$dtime" -lt "$dtime_tolerance" ]
		then
			echo -e -n "\tРежим:\t\e[42mработает\e[0m\t"
			if [ "$spro_status" = "0" ]
			then
				echo -e "\tСтатус:\t\e[42mбез замечаний\e[0m"
				# Сообщаем главному модулю КП о нормальной работе (UPD: не нужно)
#				sendmsg "kp" "СПРО работает нормально"
			elif [ -z "$spro_status" ]
			then
				# Может произойти так, что cat не
				# сможет прочитать файл, т.к. он
				# занят СПРО.
				echo -e "\tСтатус:\t\e[43mнеизвестен\e[0m [status file busy]"
			else
				echo -e echo -e "\tСтатус:\t\e[43mимеются проблемы\e[0m"
				# Сообщаем главному модулю КП о проблеме
				sendmsg "kp" "Внимание: проблема на СПРО"
			fi
		else
			echo -e "\tРежим:\t\e[41;1mне работает\e[0m \e[2m$dtime секунд\e[0m"
			# Сообщаем главному модулю КП
			sendmsg "kp" "Внимание: СПРО не работает"
		fi
	else
		# Если нет статусного файла
		echo -e "\t\e[41;1mОшибка\e[0m:\tнет связи"
		# Сообщаем главному модулю КП
		sendmsg "kp" "Внимание: нет связи с СПРО"
	fi
	echo
###############
	
	sleep $period

done
