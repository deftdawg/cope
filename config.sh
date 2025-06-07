#!/usr/bin/env bash

mkdir -p ~/.bash
echo "export PATH=$(perl cope_path.pl):\$PATH" > ~/.bash/cope

