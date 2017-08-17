docker rmi -f $( docker images | grep com.hds | awk '{print $3}' | uniq )
