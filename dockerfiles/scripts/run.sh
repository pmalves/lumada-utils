#!/bin/bash


# 1. Extract the software file


# cd /opt/lumada && \
# 	tar -xvf ./*tgz -C . && \
# 	./*/bin/install && \
# 	echo DONE!

if [ -z "$DEBUG" ]; then
  echo Starting Lumada in normal mode
  echo ./start-pentaho.sh;
else
  echo Starting Lumada in debug mode
  echo ./start-pentaho-debug.sh;
fi

