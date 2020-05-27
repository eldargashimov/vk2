#!/bin/bash

# Запуск всех станций в фоновом режиме;
# главный монитор КП ВКО запускается в терминальном режиме

terminal="gnome-terminal --execute"

echo -e "\nЗапуск системы - фоновый режим"

## Запуск главного монитора КП ВКО
printf "* %25s ... " "Главный монитор КП ВКО"
# Проверим, не запущен ли процесс:
is_running=`pgrep kp_vko.sh -cx`
if [ "$is_running" -eq "0" ]
then
	# Перемещаемся в директорию КП ВКО, иначе
	# относительные пути не сработают
	cd "`pwd`/kp_vko"
	# Запускаем
	$terminal "`pwd`/kp_vko.sh" > /dev/null
	echo "ОК"
	cd ..
else
	echo "уже запущен"
fi

## Запуск монитора состояния систем ВКО КП ВКО
printf "* %25s ... " "Монитор состояния СВКО"
# Проверим, не запущен ли процесс:
is_running=`pgrep kp_vko_state_ch -c`
if [ "$is_running" -eq "0" ]
then
	# Перемещаемся в директорию КП ВКО, иначе
	# относительные пути не сработают
	cd kp_vko
	# Запускаем
	./kp_vko_state_checker.sh > /dev/null 2>/dev/null &
	echo "ОК"
	cd ..
else
	echo "уже запущен"
fi

## Запуск РЛС 1, 2, 3
for i in 1 2 3
do
	printf "* %25s ... " "РЛС$i"
	# Проверим, не запущен ли процесс:
	is_running=`pgrep rls$i -c`
	if [ "$is_running" -eq "0" ]
	then
		# Перемещаемся в директорию РЛС, иначе
		# относительные пути не сработают
		cd rls$i
		# Запускаем
		./rls$i.sh >/dev/null 2>/dev/null &
		echo "ОК"
		cd ..
	else
		echo "уже запущена"
	fi
done


## Запуск ЗРДН 1, 2, 3
for i in 1 2 3
do
	printf "* %25s ... " "ЗРДН$i"
	# Проверим, не запущен ли процесс:
	is_running=`pgrep zrdn$i -c`
	if [ "$is_running" -eq "0" ]
	then
		# Перемещаемся в директорию ЗРДН, иначе
		# относительные пути не сработают
		cd zrdn$i
		# Запускаем
		./zrdn$i.sh > /dev/null 2>/dev/null &
		echo "ОК"
		cd ..
	else
		echo "уже запущен"
	fi
done

## Запуск СПРО
printf "* %25s ... " "СПРО"
# Проверим, не запущен ли процесс:
is_running=`pgrep spro -c`
if [ "$is_running" -eq "0" ]
then
	# Перемещаемся в директорию СПРО, иначе
	# относительные пути не сработают
	cd spro
	# Запускаем
	./spro.sh > /dev/null 2>/dev/null &
	echo "ОК"

	cd ..
else
	echo "уже запущена"
fi
