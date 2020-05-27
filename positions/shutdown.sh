#!/bin/bash

echo

if [ "$1" = "--stations" ]
then
	echo "SIGINT удалённым станциям..."
	# Посылаем SIGINT станциям: РЛС, ЗРДН и СПРО
	pkill -INT "rls" -e && echo "РЛС  ... остановлены"
	sleep 0.5
	pkill -INT "zrdn" -e && echo "ЗРДН ... остановлены"
	sleep 0.5
	pkill -INT "spro" -e && echo "СПРО ... остановлена"
	
	# Если эти процессы были запущены в фоновом режиме,
	# их нужно ещё добить
#	pkill "rls" -e && echo "РЛС  ... остановлены принудительно"
#	pkill "zrdn" -e && echo "ЗРДН ... остановлены принудительно"
#	pkill "spro" -e && echo "СПРО ... остановлена принудительно"
	pkill "rls"
	pkill "zrdn"
	pkill "spro"
	
elif [ "$1" = "--kp" ]
then
	echo "SIGINT КП ВКО..."
	# Посылаем SIGINT на модули КП ВКО
	pkill -INT "kp_vko_state_ch" -e && echo "Монитор состояния СВКО ... остановлен"
	# Если этот процесс был запущен в фоновом режиме, нужно его добить
#	pkill "kp_vko_state_ch" -e && echo "Монитор состояния СВКО ... остановлен принудительно"
	pkill "kp_vko_state_ch"
	sleep 0.5
	pkill -INT "kp_vko.sh" -e && echo "КП ВКО  ... остановлен"

elif [ "$1" = "--all" ]
then
	echo "SIGINT всем позициям..."
	# Посылаем SIGINT абсолютно всем модулям СВКО
	pkill -INT "rls" -e && echo "РЛС  ... остановлены"
	sleep 0.1
	pkill -INT "zrdn" -e && echo "ЗРДН ... остановлены"
	sleep 0.1
	pkill -INT "spro" -e && echo "СПРО ... остановлена"
	# Если эти процессы были запущены в фоновом режиме,
	# их нужно ещё добить
	pkill "rls" -e && echo "РЛС  ... остановлены принудительно"
	pkill "zrdn" -e && echo "ЗРДН ... остановлены принудительно"
	pkill "spro" -e && echo "СПРО ... остановлена принудительно"
	
	pkill -INT "kp_vko_state_ch" -e && echo "Монитор состояния СВКО ... остановлен"
	# Если этот процесс был запущен в фоновом режиме, нужно его добить
#	pkill "kp_vko_state_ch" -e && echo "Монитор состояния СВКО ... остановлен принудительно"
	pkill "kp_vko_state_ch"
	pkill -INT "kp_vko.sh" -e && echo "КП ВКО  ... остановлен"
elif [ "$1" = "--halt" ]
then
	echo "Принудительная остановка всех позиций..."
	# На всякий случай - принудительно завершаем все процессы СВКО
	pkill "rls" -e && echo "РЛС  ... остановлены принудительно"
	pkill "zrdn" -e && echo "ЗРДН ... остановлены принудительно"
	pkill "spro" -e && echo "СПРО ... остановлена принудительно"
	pkill "kp_vko" -e && echo "КП ВКО  ... остановлен принудительно"
else
	:
fi
