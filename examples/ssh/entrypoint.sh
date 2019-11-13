#!/bin/bash
set -e
 
printf "\n\033[0;44m---> Starting the SSH server.\033[0m\n"
 
sudo service ssh start
sudo service ssh status
 
exec "$@"
