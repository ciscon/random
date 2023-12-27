#!/bin/bash

QUAKEDIR="$HOME/games/quake.testing"
ORIGVT=$(fgconsole)


docker build --pull -t asdf . && \
	docker run --rm --name debian-stable-test --net=host --privileged -v /run/udev/data:/run/udev/data -v $QUAKEDIR:/home/quakeuser/quake  asdf
sudo chvt $ORIGVT
