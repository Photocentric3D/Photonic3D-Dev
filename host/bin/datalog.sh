#!/bin/bash

#args: $1 - memory warning
# $2 - temperature warning
# $3 - memory error
# $4 - temperature error

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

filename=pilog-$(date "+%y-%m-%d").log
touch /opt/cwh/$filename

defaultsleeptime=15s
#parameterising so that the script can log more regularly if warnings are triggered
changes=0
sleeptime=$defaultsleeptime
while true; do
	process=$(ps -A | grep java |awk '{$2=$2};1'|cut -d " " -f1)
	mem=$(cat /proc/$process/status|grep VmSize)
	max=$(cat /proc/$process/status|grep VmPeak)

	timestamp=$(date "+%d/%m/%y %H:%M:%S")

	cpuTemp0=$(cat /sys/class/thermal/thermal_zone0/temp)
	cpuTemp1=$(($cpuTemp0/1000))
	cpuTemp2=$(($cpuTemp0/100))
	cpuTempM=$(($cpuTemp2 % $cpuTemp1))

	gpuTemp0=$(/opt/vc/bin/vcgencmd measure_temp)
	gpuTemp0=${gpuTemp0//\'/º}
	gpuTemp0=${gpuTemp0//temp=/}
	timestamp=$(date "+%d/%m/%y %H:%M:%S")
	echo "["$timestamp"] Curr mem: "$mem", Max Mem: "$max". CPU Temp: "$cpuTemp1"."$cpuTempM"ºC GPU Temp: "$gpuTemp0 >> /opt/cwh/$filename
	
	#do error checking

#	if [ ! -z "$1" ]; then
#		#changes=$changes + 1
#	fi

#	if [ ! -z "$2" ]; then
#		#changes=$changes + 1
#	fi

	if [ ! -z "$3" ]; then
		if [ $(bc <<< "$3 <= $cpuTemp1.$cpuTempM") -eq 1 ]; then
			warnstring="WARNING! CPU Temperature is too high! ($cpuTemp1.$cpuTempM)"
			let changes=changes+1
		fi
	fi

	if [ ! -z "$4" ]; then
		if [ $(bc <<< "$4 <= $cpuTemp1.$cpuTempM") -eq 1 ]; then
			warnstring="ERROR! CPU Temperature is too high ($cpuTemp1.$cpuTempM)"
			let changes=changes+1
		fi
	fi

	if [ "$changes" -gt "0" ]; then
		echo "["$timestamp"] "$warnstring
		sleeptime=1s
	else
		sleeptime=$defaultsleeptime
	fi
	changes=0
	sleep $sleeptime
done
