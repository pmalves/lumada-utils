#!/bin/bash


APPLICATION=$(basename /opt/*)

if [ ! -f /root/INIT_DONE ]
then

	echo Running the init scripts

	# Change the common-funcs.sh and other run scripts to point to the shared volume and use bridge mode

	find /opt \( -iname common-funcs.sh -o -iname '*run' \) -exec chmod +w {} \; -exec perl -pi -e "s/-v \\\\?\"\\\$INSTALLDIR\\\\?\"?:\\\\?\"\\\$INTERNALHOMEDIR\\\\?\"/-v $CONTAINER_ID-volume:\/opt/;" {} \; -exec chmod -w {} \;

	
	cd /opt/$APPLICATION
	bin/${APPLICATION}_setup
	
	touch /root/INIT_DONE

fi


# Run it...

cd /opt/$APPLICATION
bin/${APPLICATION}_run
