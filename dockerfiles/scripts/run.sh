#!/bin/bash


APPLICATION=$(basename /opt/*)

if [ ! -f /root/INIT_DONE ]
then

	echo Running the init scripts

	# Change the common-funcs script to point to the shared volume
	find /opt -iname common-funcs.sh -exec chmod +w {} \; -exec  perl -pi -e 's/-v "\$INSTALLDIR":"\$INTERNALHOMEDIR"/-v \$(hostname)-volume:\/opt/' {} \; -exec chmod -w {} \;

	# Change the APPLICATION_run command to point to the shared volume
	find /opt/*/bin -iname \*_run -exec perl -pi -e 's/-v \\"\$INSTALLDIR\\":\\"\$INTERNALHOMEDIR\\"/-v \$(hostname)-volume:\/opt/' {} \;
	
	cd /opt/$APPLICATION
	bin/${APPLICATION}_setup
	
	touch /root/INIT_DONE

fi


# Run it...

cd /opt/$APPLICATION
bin/${APPLICATION}_run

