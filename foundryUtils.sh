#!/bin/bash

###############################################################################
# 
# Foundry Utils
#
# The goal of the project is to make my life easier when it comes to managing
# foundry applications' lifecycle. 
#
# Author: Pedro Alves
# License: Whatever... Apache2 if I have to pick one
#
###############################################################################

VERSION=0.1

# Lists the clients and starts / delets
BASEDIR=$(dirname $0)
source "$BASEDIR/_utils.sh"
cd $BASEDIR


# We're going to do a few things here; 
# 1. Show the projects
#
# Each selection will have it's own option; On top of that we'll have the
# following:
# 1. Add new applications



DOCKER_CONTAINERS=()
DOCKER_STATUS=()
DOCKER_IDS=()
DOCKER_APPLICATIONS=()


# Get list of files

echo
echo "--------------------------------------------------------------"
echo "--------------------------------------------------------------"
echo "-----------------     Foundry  Utils     ---------------------"
echo "------                 Version: $VERSION                    -------"
echo "------ Author: Pedro Alves (pedro.alves@webdetails.pt) -------"
echo "--------------------------------------------------------------"
echo "--------------------------------------------------------------"


echo
echo Foundry Application Images
echo --------------------------
echo


# 1. Search for what we have
APPLICATIONS=$( docker images | egrep '^foundry' | grep -v 'foundry-core' | cut -d' ' -f 1 )

IFS=$'\n';
n=-1

for image in $APPLICATIONS
do
  ((n++))
  echo " [$n] $image"
  BUILD[$n]=$image
	TYPE[$n]="APPLICATION"
done;




# Not sure if we need this yet...

echo
echo Foundry containers:
echo -------------------
echo 


RUNNING_CONTAINERS=$( docker ps -a -f "name=foundry" --format "{{.ID}}XX{{.Names}}XX{{.Status}}XX{{.Image}}" | egrep -v 'data' )

for container in $RUNNING_CONTAINERS
do
  ((n++))
	IFS='XX' read -a ENTRY <<< "$container"

	if [[ ${ENTRY[4]} =~ "Up " ]]; then
		DOCKER_STATUS[$n]="Running"
	else
		DOCKER_STATUS[$n]="Stopped"
	fi

	DOCKER_CONTAINERS[$n]=${ENTRY[2]}
	DOCKER_IDS[$n]=${ENTRY[0]}
  	DOCKER_APPLICATIONS[$n]=${ENTRY[6]}
	TYPE[$n]="CONTAINER"
	echo " [$n] (${DOCKER_STATUS[$n]}): ${ENTRY[2]} "
done

echo
echo Foundry volumes:
echo ----------------
echo


VOLUMES=$( docker volume ls | grep foundry | awk '{print $2}' )

IFS=$'\n';

for image in $VOLUMES
do
  ((n++))
  echo " [$n] $image"
  BUILD[$n]=$image
	TYPE[$n]="VOLUME"
done;



echo
echo Foundry runtime services:
echo -------------------------
echo

# Runtime Services
RUNTIME_SERVICES=$( docker images | egrep '^com.hds|watchdog' | cut -d' ' -f 1 )

IFS=$'\n';
for image in $RUNTIME_SERVICES
do
  echo "     $image"
done;



echo
read -e -p "> Select an entry number, [A] to add new application, [W] to wipe out services: " choice

choice=$( tr '[:lower:]' '[:upper:]' <<< "$choice" )

if [ -z $choice ]
then
	echo You have to make a selection
	exit 1
fi

# Add a new image
if [ $choice == "A" ]; then
	source "$BASEDIR/installApplication.sh"
	exit 0;
fi

# Wipe services
if [ $choice == "W" ]; then
	source "$BASEDIR/wipeRuntimeServices.sh"
	exit 0;
fi


if ! [ "$choice" -eq "$choice" ] || [ "$choice" -lt 0 ] || [ "$choice" -gt "$n" ] 2>/dev/null
then
	echo Invalid choice: $choice
	exit 1;
else

	if [ ${TYPE[$choice]} == "APPLICATION" ]
	then

		# Action over the images
		build=${BUILD[$choice]}

		echo
		echo You selected the image $build
		echo

		read -e -p "> What do you want to do? (L)aunch a new container, (D)elete the image or (I)nspect before launch)? [L]: " operation
		operation=${operation:-L}

		operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

		if ! [ $operation == "L" ] && ! [ $operation == "D" ] && ! [ $operation == "I" ]
		then
			echo Invalid selection
			exit 1;
		fi

		# Are we deleting it?

		if [ $operation == "D" ]
		then
			docker rmi $build
			docker volume rm -f $build-volume
			echo Removed successfully
			exit 0
		fi


		# Are we launching it?

		CONTAINER_IP_OPT=""
		if [ ! -z ${FOUNDRY_BINDING_INTERFACE+x} ]
		then
			CONTAINER_IP_OPT="-e CONTAINER_IP=${FOUNDRY_BINDING_INTERFACE}"
		fi

		if [ $operation == "L" ]
		then


			source "$BASEDIR/setPorts.sh"

			# Allow to specify a network for docker
			
			DOCKER_NETWORK_OPT=""
			if [ ! -z ${FOUNDRY_DOCKER_NETWORK+x} ]
			then
				DOCKER_NETWORK_OPT="--net=${FOUNDRY_DOCKER_NETWORK}"
			fi

			eval "docker run -v $build-volume:/opt -e CONTAINER_ID=$build ${CONTAINER_IP_OPT} -v /var/run/docker.sock:/var/run/docker.sock $exposePorts $DOCKER_NETWORK_OPT --name $build --net=host $volumeList $build"

		fi

		# Are we inspecting it? it?

		if [ $operation == "I" ]
		then
			

			echo Inspecting $build. Hostname is $build.
			docker run -v $build-volume:/opt -e CONTAINER_ID=$build ${CONTAINER_IP_OPT} -v /var/run/docker.sock:/var/run/docker.sock --net=host  --entrypoint bash -i -t --rm $build
			exit 0

		fi

	elif [ ${TYPE[$choice]} == "VOLUME" ]
	then

		# Action over the images
		build=${BUILD[$choice]}

		echo
		echo You selected the volume $build
		echo

		read -e -p "> What do you want to do? (D)elete the volume or (R)eset it? [R]: " operation
		operation=${operation:-R}

		operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

		if ! [ $operation == "D" ] && ! [ $operation == "R" ] 
		then
			echo Invalid selection
			exit 1;
		fi

		# Are we deleting it?

		if [ $operation == "D" ]
		then
			docker volume rm -f $build
			echo Removed successfully
			exit 0
		fi

		# Are we resetting it?
		if [ $operation == "R" ]
		then
			docker volume rm -f $build
			docker volume create $build
			echo Successfully reset
			exit 0
		fi
	else

		# Action over the containers
		dockerId=${DOCKER_APPLICATIONS[$choice]}
        dockerImage=${DOCKER_CONTAINERS[$choice]}

		echo
		echo "You selected the container $dockerImage"
		echo


		echo 

		# Now, different options depending on the status

		if [[ ${DOCKER_STATUS[$choice]} == "Running" ]]
		then

			echo "The container is running; Possible operations:"
			echo
			echo " S: Stop it"
			echo " R: Restart it"
			echo " A: Attach to it"
			echo " L: See the Logs"
			echo " P: See exposed ports"

			if [[ $dockerImage =~ ^pdu ]]; then
				echo " E: Export the solution"
				echo " I: Import the solution"
			fi
			echo

			read -e -p "What do you want to do? [A]: " operation
			operation=${operation:-A}

			operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

			if ! [ $operation == "S" ] && ! [ $operation == "R" ]  && ! [ $operation == "A" ] && ! [ $operation == "E" ] && ! [ $operation == "I" ] && ! [ $operation == "L" ] && ! [ $operation == "P" ] 
			then
				echo Invalid selection
				exit 1;
			fi

			if [ $operation == "S" ]; then
				echo Stopping...
				docker stop -t 10 $dockerImage
				echo $dockerImage stopped successfully
				exit 0
			fi

			if [ $operation == "R" ]; then
				echo Restarting...
				docker restart $dockerImage
				echo $dockerImage restarted successfully
				exit 0
			fi

			if [ $operation == "A" ]; then
				docker exec -it $dockerImage bash
				echo Done
				exit 0
			fi

			if [ $operation == "L" ]; then
				docker logs --tail 500 -f $dockerImage
				echo Done
				exit 0
			fi

			if [ $operation == "P" ]; then
                echo "[Container] -> [Host]"
				docker port $dockerImage
				echo Done
				exit 0
			fi


		else

			# Stopped

			echo "The container is stopped; Possible operations:"
			echo " S: Start it"
			echo " D: Delete it"
			echo

			read -e -p "What do you want to do? [S]: " operation
			operation=${operation:-S}

			operation=$( tr '[:lower:]' '[:upper:]' <<< "$operation" )

			if ! [ $operation == "S" ]   && ! [ $operation == "D" ]
			then
				echo Invalid selection
				exit 1;
			fi

			if [ $operation == "S" ]; then
            
				echo Starting...
				docker start $dockerImage
				echo $dockerImage started successfully
				exit 0
			fi

			if [ $operation == "D" ]; then
				docker rm $dockerImage
				echo Done
				exit 0
			fi

		fi


	fi

	echo all good so far

fi


cd $BASEDIR

exit 0

