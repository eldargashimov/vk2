#!/bin/bash

#############################
### Главный модуль КП ВКО ###
#############################

## Принимает данные от всех станций и ведёт журнал работы
## запускает монитор состояния системы

# Функция для записи строки в лог-файл с 
# одновременным её форматированным выводом
function logline()
{
	if [ "$#" -eq "1" ]
	then
		# Формат Штамп_Времени + сообщение
		echo -e "[`date +"%x %X"`] $1" | tee -a $log_file
	elif [ "$#" -eq "2" ]
	then
		# Формат Штамп_Времени + ID_станции + сообщение
		
#		echo -e "[`date +"%x %X"`] `printf "%10s>" $1`\t$2" >> $log_file
		echo -e "[`date +"%x %X"`] `printf "%10s>" $1`\t$2" | tee -a $log_file
		
	fi
}

messages_dir="messages"
read_messages_dir="$messages_dir/read"

log_file="var/kp_vko.log"

trap 'clear; logline "КП_ВКО" "Конец работы\n"; exit' SIGINT

/dev/null > $log_file 2>/dev/null
# Очищаем все старые сообщения
rm -rf $messages_dir/*
# Создаём директории для сообщений (если их не было)
mkdir -p $messages_dir
mkdir -p $read_messages_dir

clear

logline "КП_ВКО" "Начало работы"

while true
do
	# Выбираем самое старое сообщение и обрабатываем его
	msg_fname=`ls $messages_dir -tr | grep mesg | head -n 1`
	# Проверяем, есть ли новые сообщения
	if [ ! -z $msg_fname ]
	then
		# Название передающей станции
		sender_id=`basename $msg_fname | cut -d '.' -f 2`
		# На всякий случай - заменяем пробелы на _
		sender_id=${sender_id/ /_}
		# Получим русское наименование
		case $sender_id in
			RLS*)
				sender_id_rus=${sender_id/"RLS"/"РЛС"}
				;;
			ZRDN*)
				sender_id_rus=${sender_id/"ZRDN"/"ЗРДН"}
				;;
			SPRO)
				sender_id_rus=${sender_id/"SPRO"/"СПРО"}
				;;
			KP_VKO_STATE_CHECKER)
				sender_id_rus="КОНТР"
				;;
			*)
				sender_id_rus=$sender_id
		esac
		
		# Содержание сообщения
		msg_contents=`cat $messages_dir/$msg_fname`

		logline "$sender_id_rus" "$msg_contents"
		
		# Закончили работать с сообщением -  считаем прочитанным
		mv $messages_dir/$msg_fname $read_messages_dir/$msg_fname
	else
		# Новых сообщений нет
		:
	fi
	
done
