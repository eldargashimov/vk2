#!/bin/bash

###################
### МОДУЛЬ ЗРДН ###
###################

# Функция для записи строки со штампом времени в лог-файл
function logline()
{
	if [ "$#" -eq "1" ]
	then
		echo -e "[`date +"%x %X"`] $1" >> $log_file
	fi
}

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

clear

station_id=`basename "$0" | sed "s/\.sh//g" | sed "s/\.\///g"`

trap "echo; echo 'Конец работы'; logline 'Конец работы'; sendmsg 'kp' 'Конец работы'; exit" SIGINT

station_details=`cat ${station_id}_details.txt`

echo "Добро пожаловать в $station_details"; echo

# ТТХ ЗРДН согласно заданию:
station_params=`cat "${station_id}_params.txt"`
station_x=`echo $station_params | cut -d ' ' -f 1`
station_y=`echo $station_params | cut -d ' ' -f 2`
station_r=`echo $station_params | cut -d ' ' -f 3`
station_crds="$station_x $station_y"
echo "Параметры станции: x = $station_x; y = $station_y; r = $station_r"

# Модуль математики:
maths="../../lib/maths"
# Для вхождения в окружность (для ЗРДН и СПРО)
maths_flag_circle="-c"
# Для вхождения в сектор (для РЛС)
#maths_flag_sector="-s"
# Для вхождения прогнозируемой траектории в ЗО СПРО
#maths_flag_predict="-p"

# Файл с ID обнаруженных (за всё время работы) целей
detected_tgts_ids_file="var/${station_id}_detected_tgts_ids.txt"
# Директория с целями, по которым совершён выстрел
shoot_attempts_dir="var/shoot_attempts"
# Интервал между выстрелом и проверкой его успешности
shoot_dtime_delay=3
# Статусный файл
status_file="${station_id}_status"

# Директория с целями
targets_dir="/tmp/GenTargets/Targets"
# Директория для поражения
destroy_dir="/tmp/GenTargets/Destroy"

# Директория сообщений КП
msg_dir_kp="../kp_vko/messages"
# Директория сообщений СПРО
msg_dir_spro="../spro/messages"

## 	Скрипты:
get_tgt_crds_by_id="../../lib/get_tgt_crds_by_id.sh"
get_tgt_vxvy_by_id="../../lib/get_tgt_vxvy_by_id.sh"
get_tgt_v_by_vxvy="../../lib/get_tgt_v_by_vxvy.sh"
get_tgt_type_by_v="../../lib/get_tgt_type_by_v.sh"
get_tgt_type_rus="../../lib/get_tgt_type_rus.sh"

# Лог-файл
log_file="var/$station_id.log"

# Инициализируем файлы
/dev/null > $detected_tgts_ids_file 2>/dev/null
/dev/null > $log_file 2>/dev/null

if [ ! -e "$targets_dir" ]
then
	echo -e "\n\e[1;31mДиректории $targets_dir не существует\e[0m"
	sleep 2
	exit
fi

# Создаём каталог выстрелов
mkdir -p $shoot_attempts_dir
# Очищаем следы предыдущего запуска
rm -f $shoot_attempts_dir/*

sleep 4

msg="Начало работы"
logline "$msg"
sendmsg "kp" "$msg"

shoot_attempts_cnt=0
missed_shoots_cnt=0

while true
do

	clear
	
	tgts_in_range_cnt=0
	
	let "destroyed_tgts_cnt=shoot_attempts_cnt-missed_shoots_cnt"
	
	echo -ne "$station_details\n`date +"%x %X.%N %:z"`\t"
	echo -ne "Выстрелов: $shoot_attempts_cnt\tУничтожено: $destroyed_tgts_cnt\tПромахов: $missed_shoots_cnt\t\n\n"
	echo 0 > $status_file

#############################################
### Цикл перебора всех существующих целей ###
###			 и их обработки               ###
#############################################

	for tgt_id in `ls $targets_dir 2>/dev/null | cut -d '.' -f 3 | sort -u`
	do
		# Пробуем получить координаты цели
		tgt_crds=`$get_tgt_crds_by_id $tgt_id`

		if [[ $tgt_crds == *"not found"* ]]
		then
			# За время между получением строки $tgt_id и получением координат
			# цель может умереть, и get_tgt_crds_by_id.sh выдаст
			# "Error: <цель> not found". В таком случае эту цель
			# не проверяем на вхождение в диапазон
			:
#			echo -en "tgt accidentally died\n"
		else
			# Если цель не исчезла, обрабатываем её
			
			# Вызов модуля математики для проверки вхождения в диапазон обнаружения
			$maths $maths_flag_circle $tgt_crds $station_crds $station_r
			# Результат - через код возврата
			tgt_in_range=$?
			
			if [ "$tgt_in_range" -eq "0" ]
			then
				# Цель физически не входит в зону ответственности позиции
				:
			elif [ "$tgt_in_range" -eq "1" ]
			then
				# Цель физически в диапазоне позиции,
				# однако зрдн видит не все типы целей

				# Пробуем определить тип цели
				tgt_vxvy=`$get_tgt_vxvy_by_id $tgt_id`
				tgt_v=`$get_tgt_v_by_vxvy $tgt_vxvy`
				tgt_type=`$get_tgt_type_by_v $tgt_v`
				# ЗРДН видит только самолёты и КР
				if [ "$tgt_type" = "airplane" -o "$tgt_type" = "missile" ]
				then
					# Цель входит в зону ответственности позиции,
					# т.е. на данном этапе зрдн видит цель
					let 'tgts_in_range_cnt++'
					# Русское название цели
					tgt_type_rus=`$get_tgt_type_rus $tgt_type`
					# Вывод информации в терминал
					echo -en "\t$tgt_id:\t$tgt_crds\t"
					# Однако с первого обнаружения позиция всё равно как бы
					# не может определить тип цели. Поэтому смотрим,
					# не была ли цель обнаружена раньше
					tgt_match=`grep -c "$tgt_id" "$detected_tgts_ids_file"`
					if [ "$tgt_match" -eq "0" ]
					then
						echo -en "\t*\n"
						# Новая цель, добавляем в список
						echo $tgt_id >> $detected_tgts_ids_file
						# Делаем запись в лог и отправляем сообщение на КП:
						msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)' 'Обнаружена цель' $tgt_id $tgt_crds`"
						logline "$msg"
						sendmsg "kp" "$msg"
						# Поскольку цель мы только обнаружили,
						# определить её тип пока как бы невозможно
					else
						# Цель уже отслеживалась
						echo -en "\t"
						# Тогда можем показывать скорость и тип
						printf "vx,vy: $tgt_vxvy\tv: $tgt_v\t%-16s" "$tgt_type_rus"
						# На данном этапе по цели можно сделать выстрел.
						# Проверяем, не был ли он уже сделан
						tgt_shoot_attempt=`ls $shoot_attempts_dir | grep -c $tgt_id`
						current_time_ticks=`date +%s`
						if [ "$tgt_shoot_attempt" -eq "0" ]
						then
							# Выстрелов не производили, тогда производим
							let "shoot_attempts_cnt++"
							echo -en "\tОбстрел"
							echo "" > "$destroy_dir/$tgt_id"
							# Добавляем запись в директорию выстрелов
							echo "$tgt_crds:$tgt_type" > "$shoot_attempts_dir/$tgt_id"
							# Заносим запись в журнал и сообщаем на КП
							msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)\tТип: %s' 'Тип цели определён. Обстрел' $tgt_id $tgt_crds "$tgt_type_rus"`"
							logline "$msg"
							sendmsg "kp" "$msg"
						else
							# Выстрел был произведён, однако цель ещё есть.
							# Предположим, что мгновенно цель не уничтожается,
							# поэтому сразу выводов о промахе делать не будем,
							# а проверим, насколько давно сделали выстрел
							shoot_time_ticks=`stat -c "%Y" "$shoot_attempts_dir/$tgt_id"`
							let "shoot_dtime=current_time_ticks-shoot_time_ticks"
							if [ "$shoot_dtime" -gt "$shoot_dtime_delay" ]
							then
								# В таком случае считаем, что совершён промах.
								let "missed_shoots_cnt++"
								# Повторный выстрел
								let "shoot_attempts_cnt++"
								echo -en "\tПромах. Обстрел"
								echo "" > "$destroy_dir/$tgt_id"
								# Обновляем запись о выстреле
								touch "$shoot_attempts_dir/$tgt_id"
								# Заносим запись в журнал и сообщаем КП
								msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)\tТип: %s' 'Промах. Повтор обстрела цели' $tgt_id $tgt_crds "$tgt_type_rus"`"
								logline "$msg"
								sendmsg "kp" "$msg"
							else
								# Время ещё не прошло, ждём результата
								echo -en "\t..."
							fi
						fi
						echo -en "\n"
					fi
				fi
			elif [ "$tgt_in_range" -eq "2" ]
			then
				# Ошибка модуля математики
				echo -en "Ошибка модуля математики\n"
				msg="Ошибка модуля математики"
				logline "$msg"
				sendmsg "kp" "$msg"
			fi
		fi
	done
	
	if [ "$tgts_in_range_cnt" -eq "0" ]
	then
		# Не видим ни одной цели
		echo -e "(нет видимых целей)"
	fi

	##########################################################
	### Цикл перебора целей, по которым произведён выстрел ###
	### 		и вывод сводки информации по ним           ###
	##########################################################

	echo
	shoots_cnt=0
	for tgt_id in `ls $shoot_attempts_dir`
	do
		let "shoots_cnt++"
		# Пробуем получить координаты цели
		tgt_crds=`$get_tgt_crds_by_id $tgt_id`

		if [[ $tgt_crds == *"not found"* ]]
		then
			# Цель уничтожена
			# Возьмём последнюю известную информацию об уничтоженной цели
			destroyed_tgt_crds=`cut -d ':' -f1 "$shoot_attempts_dir/$tgt_id"`
			destroyed_tgt_type=`cut -d ':' -f2 "$shoot_attempts_dir/$tgt_id"`
			destroyed_tgt_type_rus=`$get_tgt_type_rus $destroyed_tgt_type`
			printf "\t\e[3m$tgt_id:\t$destroyed_tgt_crds\t%20s - уничтожена\n" "$destroyed_tgt_type_rus"
			# Заносим запись в журнал и сообщаем КП
			msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)\tТип: %s' 'Цель уничтожена' $tgt_id $destroyed_tgt_crds "$destroyed_tgt_type_rus"`"
			logline "$msg"
			sendmsg "kp" "$msg"
			# Удаляем файл попытки выстрела, чтобы не информировать повторно
			rm -f "$shoot_attempts_dir/$tgt_id"
		else
			# Цель ещё существует. Через некоторое время
			# либо она исчезнет, либо будет сделан вывод
			# о промахе и совершён повторный выстрел
			# (всё это в цикле выше)
			:
		fi
	done
	
	if [ "$shoots_cnt" -eq "0" ]
	then
		# Выстрелов не было
		echo -e "\n(не было выстрелов за последний такт)"
	fi
	
	sleep 0.5	

done
