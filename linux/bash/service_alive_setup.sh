#!/bin/bash

# ROOT need

# Input Linux service name
echo -n "Input service name: "
read servicename

# verificamos que no existe el servicio en el cron
exists=$(sudo crontab -l | grep -c $servicename)

if [ $existe != 0 ]
then
        echo "Service is already monitored."
else
        # checking interval
        until [[ ($minrev > 0) && ($minrev < 61) ]]; do
                echo -n "Check interval minutes? (1/60): "
                read minrev
        done
        # save log?
        alog="a"
        until [ $alog == "y" ] || [ $alog == "Y" ] || [ $alog == "n" ] || [ $alog == "N" ]; do
                echo -n "Do you want a monthly log? (Y/N): "
                read alog
        done

        # copy script
        dst=~/service_alive.sh
        sudo cp service_alive.sh $dst
        sudo chmod 775 $dst

        #asign crob task
        if [ $alog == "s" ] || [ $alog == "S" ]
        then
           (sudo crontab -l ; echo "*/$minrev * * * * $dst $servicename /log") | sudo crontab -
        else
           (sudo crontab -l ; echo "*/$minrev * * * * $dst $servicename") | sudo crontab -
        fi
fi

