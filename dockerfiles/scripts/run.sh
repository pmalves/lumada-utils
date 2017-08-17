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


# Run it...

cd /opt/$APPLICATION
bin/${APPLICATION}_run

