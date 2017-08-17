#!/bin/bash


APPLICATION=$(basename /opt/*)

if [ ! -f /root/INIT_DONE ]
then

	echo Running the init scripts
	find /opt -iname common-funcs.sh -exec chmod +w {} \; -exec  perl -pi -e 's/-v "\$INSTALLDIR":"\$INTERNALHOMEDIR"/-v \$(hostname)-volume:\/opt/' {} \; -exec chmod -w {} \;
	
	cd /opt/$APPLICATION
	bin/${APPLICATION}_setup
	
	touch /root/INIT_DONE

fi


# 1. Extract the software file



if [ -z "$DEBUG" ]; then
  echo Starting Lumada in normal mode
  echo ./start-pentaho.sh;
else
  echo Starting Lumada in debug mode
  echo ./start-pentaho-debug.sh;
fi

