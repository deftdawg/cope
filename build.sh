#!/usr/bin/env bash

errors=$(bash depends.sh)
error=$?
#echo $errors

if [ $error -eq 0 ];then
    perl Makefile.PL
    make
    exit 0
else
    echo missing packages: $errors
    echo try: sudo apt-get install $errors
    exit $error
fi
