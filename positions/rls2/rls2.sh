#!/bin/bash

##################
### МОДУЛЬ РЛС ###
##################

# Функция для записи строки со штампом времени в лог-файл
function logline()
{
	# Принимаем только 1 аргумент - содержание сообщения
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

station_details=`cat ${station_id}_details.txt`

echo "Добро пожаловать в $station_details"; echo

# ТТХ РЛС согласно заданию:
station_params=`cat "${station_id}_params.txt"`
station_x=`echo $station_params | cut -d ' ' -f 1`
station_y=`echo $station_params | cut -d ' ' -f 2`
station_r=`echo $station_params | cut -d ' ' -f 3`
station_alpha=`echo $station_params | cut -d ' ' -f 4`
station_phi=`echo $station_params | cut -d ' ' -f 5`
station_crds="$station_x $station_y"
echo "Параметры станции: x = $station_x; y = $station_y; r = $station_r; alpha = $station_alpha; phi = $station_phi"

# ТТХ СПРО
spro_params=`cat "../spro/spro_params.txt"`
spro_x=`echo $spro_params | cut -d ' ' -f 1`
spro_y=`echo $spro_params | cut -d ' ' -f 2`
spro_r=`echo $spro_params | cut -d ' ' -f 3`
spro_crds="$spro_x $spro_y"
echo "Параметры защищаемой зоны (СПРО): x = $spro_x; y = $spro_y; r = $spro_r"

# Модуль математики:
maths="../../lib/maths"
# Для вхождения в окружность (для ЗРДН и СПРО)
#maths_flag="-c"
# Для вхождения в сектор (для РЛС)
maths_flag_sector="-s"
# Для вхождения прогнозируемой траектории в ЗО СПРО
maths_flag_predict="-p"

# Файл с ID обнаруженных (за всё время работы) целей
detected_tgts_ids_file="var/${station_id}_detected_tgts_ids.txt"
# Файл с ID обнаруженных (за всё время работы) опасных целей
# (движущихся в направлении СПРО)
detected_danger_tgts_ids_file="var/${station_id}_detected_danger_tgts_ids.txt"
# Статусный файл
status_file="${station_id}_status"

# Директория с деталями по целям, отслеживаемым станцией
tracked_tgts_detail_dir="var/tracked_tgts_detail"

# Директория с целями
targets_dir="/tmp/GenTargets/Targets"

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
/dev/null > $detected_danger_tgts_ids_file 2>/dev/null
/dev/null > $log_file 2>/dev/null

# Очищаем директорию отслеживаемых целей после предыдущего запуска
rm -rf $tracked_tgts_detail_dir/*
# Создаём директорию (если не была создана)
mkdir -p $tracked_tgts_detail_dir

if [ ! -e "$targets_dir" ]
then
	echo -e "\nДиректории $targets_dir не существует"
	sleep 2
	exit
fi

trap "echo; echo 'Конец работы'; logline 'Конец работы'; sendmsg 'kp' 'Конец работы'; exit" SIGINT

sleep 4

msg="Начало работы"
logline "$msg"
sendmsg "kp" "$msg"

while true
do

	clear
	
	tgts_in_range_cnt=0
	
	echo -ne "$station_details\n`date +"%x %X.%N %:z"`\n\n"
	echo 0 > $status_file
	
#############################################
### Цикл перебора всех существующих целей ###
###			 и их обработки               ###
#############################################

	for tgt_id in `ls $targets_dir 2>/dev/null | cut -d '.' -f 3 | sort -u`
	do
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
			$maths $maths_flag_sector $tgt_crds $station_crds $station_r $station_alpha $station_phi
			# Результат - через код возврата
			tgt_in_range=$?
			
			if [ "$tgt_in_range" -eq "0" ]
			then
				# Цель физически не входит в зону ответственности позиции
				:
			elif [ "$tgt_in_range" -eq "1" ]
			then
				# Цель физически в диапазоне, и РЛС видит её
				let 'tgts_in_range_cnt++'
				
				echo -en "\t$tgt_id:\t$tgt_crds"				
				
				# Смотрим, не была ли она обнаружена раньше
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
					# определить её скорость пока как бы невозможно
				else
					# Цель уже отслеживается
					echo -en "\t"
					# Для такой цели уже можно определить скорость
					tgt_vxvy=`$get_tgt_vxvy_by_id $tgt_id`
					tgt_v=`$get_tgt_v_by_vxvy $tgt_vxvy`
					tgt_type=`$get_tgt_type_by_v $tgt_v`
					tgt_type_rus=`$get_tgt_type_rus $tgt_type`
					
					printf "vx,vy: $tgt_vxvy\tv: $tgt_v\t%-16s" "$tgt_type_rus"
					
					# Занесём информацию о типе цели в соответствующий файл,
					# если не сделали этого ранее, и сообщим на КП об уточнении
					# типа цели
					tgt_is_tracked=`ls $tracked_tgts_detail_dir | grep -c $tgt_id`
					if [ "$tgt_is_tracked" = "0" ]
					then
						# Только что определили тип цели
						echo "$tgt_type" > "$tracked_tgts_detail_dir/$tgt_id"
						msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)\tТип: %s' 'Тип цели определён' $tgt_id $tgt_crds "$tgt_type_rus"`"
						logline "$msg"
						sendmsg "kp" "$msg"
					else
						# Уже знаем эту цель. Ничего не делаем
						:
					fi
					
					if [ "$tgt_type" = "icbm" ]
					then
						# Если обнаружили МБР, проверим, не направлена ли 
						# она в ЗО СПРО
						$maths $maths_flag_predict $tgt_crds $tgt_vxvy $spro_crds $spro_r
						tgt_heads_to_spro=$?
						if [ "$tgt_heads_to_spro" -eq "1" ]
						then
							# МБР направлена в ЗО СПРО
							echo -en "\tЦель направлена в сторону СПРО"
							# Предупреждение на СПРО и КП ВКО нужно выдать единожды,
							# поэтому проверим, была ли ранее уже замечена эта цель
							danger_tgt_detected=`grep -c $tgt_id $detected_danger_tgts_ids_file`
							if [ "$danger_tgt_detected" -eq "0" ]
							then
								# Не была замечена ранее. Заносим в журнал и выдаём предупреждение на КП
								msg="`printf '%-40s\tID:%6s\tКоординаты: (%8d;%8d)\tТип: ББ БР' 'Цель направлена в сторону СПРО' $tgt_id $tgt_crds`"
								logline "$msg"
								sendmsg "kp" "$msg"
								# Заносим информацию об опасной цели в файл
								echo "$tgt_id" >> $detected_danger_tgts_ids_file
							else
								# Была замечена ранее. Ничего не делаем
								:
							fi
						fi
					fi
					echo -en "\n"
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
	
	sleep 0.5

done
