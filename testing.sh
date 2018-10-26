#!/usr/bin/env sh

docker run -dit --name ubuntu ubuntu:bionic bash
docker cp apt-install.sh ubuntu:/apt-install.sh
docker exec -it ubuntu sh -c "bash /apt-install.sh"
#docker stop ubuntu && docker rm ubuntu
