#!/bin/bash

BASEDIR=$(dirname $0)
source "$BASEDIR/_utils.sh"
cd $BASEDIR

# Processes the main foundry software files to build the main images.

SOFTWARE_DIR=software
LICENSES_DIR=licenses


# Get list of files

SOFTWAREFILES=$( ls -1 $SOFTWARE_DIR/*Lumada* )

IFS=$'\n';
n=-1

echo

SOFTWAREFILESARRAY=()
OPTIONS=();

for softwareFile in $SOFTWAREFILES
do
	echo Software: $softwareFile
	SOFTWAREFILESARRAY=("${SOFTWAREFILESARRAY[@]}" $softwareFile)
	OPTIONS=("${OPTIONS[@]}" $(echo $softwareFile | cut -d / -f2) )
done;


promptUser "Softwares found on the $SOFTWARE_DIR dir:" $(( ${#OPTIONS[@]} - 1 )) "Choose the software to install" 
softwareChoiceIdx=$CHOICE
software=${OPTIONS[$CHOICE]}
softwareFile=${SOFTWAREFILESARRAY[$softwareChoiceIdx]}
DOCKERTAG=$(echo foundry-$software | sed -E -e ' s/.tgz//' | tr '[:upper:]' '[:lower:]')

# echo "Software chosen: $software ($softwareChoiceIdx); File: $softwareFile; Docker tag: $DOCKERTAG"

tmpDir=dockerfiles/tmp


# We'll use one of two things: If we have a project-specific Dockerfile, we'll 
# go for that one; if not, we'll use a default. 
# We'll also build a tmp dir for processing the stuff

if [ -d $tmpDir ]
then
	rm -rf $tmpDir
fi

mkdir -p $tmpDir

# Now - we need to check if we have the foundry-core docker image. Else, we need to build it

if  [[ ! $( docker images | grep foundry-core ) ]]; then

	echo Base imagee not found. Building foundry-core...
	docker build -t foundry-core -f dockerfiles/Dockerfile-FoundryCore dockerfiles

fi


# 1 - Unzip everything
# 2 - Call docker file

mkdir $tmpDir/lumada

# Because if the stupid file permissions, we have to unzip inside the container
cp $softwareFile $tmpDir/lumada

echo Creating docker image...
docker build -t $DOCKERTAG -f dockerfiles/Dockerfile-Lumada dockerfiles

if [ $? -ne 0 ] 
then
	echo
	echo An error occurred...
	exit 1
fi


rm -rf $tmpDir
echo Done

cd $BASEDIR
exit 0


