docker rmi -f $( docker images | grep com.hds | awk -e '{print $3}' | uniq )
