#!/bin/bash

# Mapping ports - Listed here: https://knowledge.hds.com/Documents/IoT/Lumada/Install_Lumada/Lumada_System_Requirements
PORTS=( "lumadaCoreUIPort:443"
        "rabbitMQAMQPSecurePort:5671"
        "rabbitMQAMQPUnsecurePort:5672"
        "adminUIPort:8000"
        "rabbitMQMQTTSecurePort:8883"
        "rabbitMQMQTTUnsecurePort:1883"
				"marathonPort:8080"
				"chronosPort:8081"
      )
      
NAMES=()
DEFAULTS=()
USED=()
        
n=-1        
for port in "${PORTS[@]}" ; do

    ((n++))
    
    portName=${port%%:*}
    portValue=${port#*:}

    # Check if the port is already been used
    #opened=$(lsof -i :$portValue)
    opened=$(netstat -na | grep -i -E "^tcp.*[\.|:]$portValue\s+")

    if [ "$portName" == "debugPort" ]
    then

        # If the port is used, look for the next one free
        while ! [ -z "$opened" ]; do

            ((portValue++))
            #opened=$(lsof -i :$portValue)
            opened=$(netstat -na | grep -i -E "^tcp.*[\.|:]$portValue\s+")

        done

        read $portName <<<$portValue

    else

        NAMES[$n]=$portName
        DEFAULTS[$n]=$portValue

        # If the port is used, look for the next one free
        while ! [ -z "$opened" ]; do

            ((portValue++))
            #opened=$(lsof -i :$portValue)
            opened=$(netstat -na | grep -i -E "^tcp.*[\.|:]$portValue\s+")

        done

        USED[$n]=$portValue

    fi
    
done

exposePorts=""
for index in ${!NAMES[*]}
do
    exposePorts+=" -p ${USED[$index]}:${DEFAULTS[$index]}"
done

#echo $exposePorts
#echo $debugPort
