#!/bin/bash

server=$(hostname)
mail=unknown@unknown.com

# service name var #
servicename=${1}

# log var #
log=/var/log/cron_"$servicename"_$(date +"%d_%m_%Y").log

# service status var #
cstat=$(sudo -u root service $servicename= status | grep -c "Active: active")

# service status check #
if [ $cstat == "0" ]
then
   sudo -u root service $servicename start
   echo "Service $servicename stopped and was started" | mail -s "Server: $servidor - Service error: $servicename" $mail
   msg=" - Serviced was started"
fi

# log creation - with /log parameter #
if [ -z ${2} ]
then
   stat="no parameter"
else
    if [ $2 == "/log" ]
    then
        # cout status line to log
        sudo -u root echo $(date +"%H:%M:%S")"$msg" >> $log

        # log deletion date vars #
        meslog=$(($(date +"%m")-1))
        daylog=$(date +"%d")
        yearlog=$(date +"%Y")

        # year awareness #
        if [ $(date +"%m") == "01" ]
        then
           yearlog=$(($yearlog -1))
           meslog=12
        fi
        # Filename to delete #
        logsupr=/var/log/cron_"$servicename"_"$daylog"_"$meslog"_"$yearlog".log        
        # Delete #
        sudo rm $logsupr
    fi
fi
