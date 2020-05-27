#!/bin/bash
declare -a TargetsId
MaxKolTargets=29      #+1
Probability=8         #вероятность поражения 10-90%
RangeX=13000000       #метры
RangeY=9000000        #метры

#скорость М/с min, разница между масимумом и минимумом
SpeedBm=(8000 2000)   #8000-10000 
SpeedPl=(50 199)      #50 249
SpeedCm=(250 750)     #250-1000

TtlBmMax=300          #Максимальное время жизни
TtlPlMax=200
TtlCmMax=200
Sleeptime=1           #задержка 
TempDirectory=/tmp/GenTargets
DirectoryTargets="$TempDirectory/Targets"
DestroyDirectory="$TempDirectory/Destroy"
LogFile=$TempDirectory/GenTargets.log
date >$LogFile
mkdir $TempDirectory >/dev/null 2>/dev/null;  mkdir $DirectoryTargets >/dev/null 2>/dev/null; mkdir $DestroyDirectory >/dev/null 2>/dev/null
cd "$DirectoryTargets/"
rm -rf $DestroyDirectory/* 2>/dev/null
rm -rf $DirectoryTargets/* 2>/dev/null
let NoTarget=$MaxKolTargets+1
while : 
do
  let NoTarget-=1 
  if [ $NoTarget -lt 0 ]
    then 
      NoTarget=$MaxKolTargets
      sleep $Sleeptime
      find -mmin +1 -delete 2>/dev/null 
      #map 
      if [ "$1" == "map" ] 
       then
         for i in `seq   0 $MaxKolTargets`
           do
            mapt=${TargetsId[0+10*$i]:0:2}
            case ${TargetsId[6+10*$i]} in
              "Бал.блок" )
                maps[$((TargetsId[7+10*$i]+$i+TargetsId[8+10*$i]*30))]="$mapt^"
              ;;
              "Самолет" )
                maps[$((TargetsId[7+10*$i]+$i+TargetsId[8+10*$i]*30))]="$mapt>"
              ;;
              "К.ракета" )
                maps[$((TargetsId[7+10*$i]+$i+TargetsId[8+10*$i]*30))]="$mapt-"
            esac
           done
          clear
        for i in `seq  18 -1 0`
          do
            for j in `seq 0 26`
              do
                echo -n "${maps[$(($j+$i*30))]}"  
                maps[$(($j+$i*30))]="..."
              done
            echo          
          done
      fi
  fi
    #/map

  if [[ "${#TargetsId[0+10*$NoTarget]}" -lt 1 ]] #Генерация цели
    then 
      tip_target=$((RANDOM%3)) #0-br 1-plan 2-cmiss
      destX=$(($RANDOM%2*2-1))
      destY=$(($RANDOM%2*2-1))
      case $tip_target in
       0 )
          ((SpeedX=($RANDOM%(${SpeedBm[1]})+${SpeedBm[0]})*$destX))
          ((SpeedY=($RANDOM%(${SpeedBm[1]})+${SpeedBm[0]})*$destY))
          ttl=$((RANDOM%TtlBmMax+10))
          Ykoord=`echo | awk  " { srand($RANDOM); print int(rand()*$RangeY) }" ` 
          Xkoord=`echo | awk  " { srand($RANDOM); print int(rand()*$RangeX) }" `
          tip_target="Бал.блок"
        ;;
       1 )
          ((SpeedX=($RANDOM%(${SpeedPl[1]})+${SpeedPl[0]})*$destX))
          ((SpeedY=($RANDOM%(${SpeedPl[1]})+${SpeedPl[0]})*$destY))
          ttl=$((RANDOM%TtlPlMax+10))
          Ykoord=`echo | awk  " { srand($RANDOM); print int(rand()*($RangeY-3000000)+1000000) }" `
          Xkoord=`echo | awk  " { srand($RANDOM); print int(rand()*($RangeX-3000000)+2000000) }" `
          tip_target="Самолет"
        ;;
       2 )
          ((SpeedX=($RANDOM%(${SpeedCm[1]})+${SpeedCm[0]})*$destX))
          ((SpeedY=($RANDOM%(${SpeedCm[1]})+${SpeedCm[0]})*$destY))
          ttl=$((RANDOM%TtlCmMax+10))
          Ykoord=`echo | awk  " { srand($RANDOM); print int(rand()*($RangeY-3000000)+1000000) }" `
          Xkoord=`echo | awk  " { srand($RANDOM); print int(rand()*($RangeX-3000000)+1000000) }" `
          tip_target="К.ракета"
      esac
      
      BASE_STR=`mcookie` ;NameTarget=${BASE_STR:11:6};
      echo -e "$tip_target \t$NameTarget\t$NoTarget\t\t Koord $Xkoord\t$Ykoord\t\tSpeed $SpeedX\t$SpeedY\tTtl$ttl" 
      echo -e "$tip_target \t$NameTarget\t$NoTarget\t\t Koord $Xkoord\t$Ykoord\t\tSpeed $SpeedX\t $SpeedY \tTtl $ttl" >>$LogFile
      TargetsId[0+10*$NoTarget]=$NameTarget
      TargetsId[1+10*$NoTarget]=$Xkoord
      TargetsId[2+10*$NoTarget]=$Ykoord 
      TargetsId[3+10*$NoTarget]=$SpeedX
      TargetsId[4+10*$NoTarget]=$SpeedY
      TargetsId[5+10*$NoTarget]=$ttl
      TargetsId[6+10*$NoTarget]=$tip_target
      TargetsId[7+10*$NoTarget]=$NoTarget
      TargetsId[8+10*$NoTarget]=$((Xkoord/500000))
      TargetsId[9+10*$NoTarget]=$((Ykoord/500000))
    else  #Обновление цели
      if [ -e "$DestroyDirectory/${TargetsId[0+10*$NoTarget]}"  ]  #Уничтожение цели по запросу
        then 
          rm "$DestroyDirectory/${TargetsId[0+10*$NoTarget]}"
          if [  $((RANDOM%$Probability)) -ge 1 ]
            then 
              echo  -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} уничт." "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}"
              echo  -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} уничт." "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}">>$LogFile
              rm $DirectoryTargets/Target.id.${TargetsId[0+10*$NoTarget]}.*
              TargetsId[0+10*$NoTarget]=""
              continue
            else
              echo  -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} промах" "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}"
              echo  -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} промах" "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}">>$LogFile
          fi
      fi  
    (( TargetsId[1+10*$NoTarget]+=${TargetsId[3+10*$NoTarget]} )) #Координаты + скорость
    (( TargetsId[2+10*$NoTarget]+=${TargetsId[4+10*$NoTarget]} ))
    (( TargetsId[5+10*$NoTarget]+=-1 ))	#уменьшение времени жизни
    echo ${TargetsId[1+10*$NoTarget]} ${TargetsId[2+10*$NoTarget]} >"$DirectoryTargets/Target.id.${TargetsId[0+10*$NoTarget]}.`mcookie | sed -e '2p'`" 2>/dev/null 

    if [ ${TargetsId[5+10*$NoTarget]} -le 0 ]  #Время жизни цели истекло
      then 
        echo -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} мертва" "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}"
        echo -e "${TargetsId[6+10*$NoTarget]} \t${TargetsId[0+10*$NoTarget]} мертва" "\t\t Koord ${TargetsId[1+10*$NoTarget]}\t${TargetsId[2+10*$NoTarget]}">>$LogFile
        rm $DirectoryTargets/Target.id.${TargetsId[0+10*$NoTarget]}.*
        TargetsId[0+10*$NoTarget]=""
     fi
   fi
done

