#!/bin/bash
# this file is for changes that need to happen to the pi outside of /opt/cwh
# each one is suggested to be of the structure
# COMMENT: VERSION this change was first needed from appeared at [in case of updates being applied spanning multiple previous releases]
# TEST to see if change has already been applied [Optional, heavily dependendent on if the change is destructive]
# CHANGE script to modify the installation

# Dev version 0.28?
sed -i "s/KJ/KEJ/g" /home/pi/.xsession

# Dev version 0.36
if [ ! -e /usr/bin/convert ]; then
	apt-get install --yes imagemagick
fi

# Dev version 0.38
if [ ! -e /etc/updatingBW.png ]; then
	sudo wget https://raw.githubusercontent.com/Photocentric3D/Photonic3D/master/host/common/etc/updatingBW.png
	sudo mv updatingBW.png /etc/
fi
# Dev version 0.38
if [ ! -e /etc/updating.png ]; then
	sudo wget https://raw.githubusercontent.com/Photocentric3D/Photonic3D/master/host/common/etc/updating.png
	sudo mv updating.png /etc/
fi

# Dev version ...
