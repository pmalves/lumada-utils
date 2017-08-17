
if [ -z "$DEBUG" ]; then
  echo Starting Lumada in normal mode
  echo ./start-pentaho.sh;
else
  echo Starting Lumada in debug mode
  echo ./start-pentaho-debug.sh;
fi

