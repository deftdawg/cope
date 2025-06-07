#!/usr/bin/env bash

bash build.sh
if [ ! $? -eq 0 ];then
    sudo apt-get install $(bash depends.sh)
fi
bash build.sh
if [ $? -eq 0 ];then
    bash install.sh
    bash config.sh
fi

#libextutils-makemaker-perl \
#libio-handle-perl \
#libterm-ansicolor-perl\

