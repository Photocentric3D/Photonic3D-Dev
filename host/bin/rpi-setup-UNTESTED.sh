#!/bin/bash

# variables (per pi)
newhost=4ktouch
#can be either 4ktouch, 4kscreen or LCHR

# DO FOR ALL
echo "Getting updates and installing utilities"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install fbi git rsync rpi-update matchbox-window-manager uzbl xinit nodm Xorg unclutter feh jq
sudo rpi-update

# redirect boot terminal output not to screen
echo "removing pi branding"
sudo mv /boot/cmdline.txt /boot/cmdline.old 
sudo sh -c 'echo -n "loglevel=3 logo.nologo " > /boot/cmdline.txt'
sudo sh -c 'cat /boot/cmdline.old >> /boot/cmdline.txt'
sudo sed -i "s/tty1/tty/g" /boot/cmdline.txt

echo "installing common files"
sudo rsync -av /opt/cwh/common /
sudo chmod a+x /etc/init.d/aasplashscreen
sudo insserv /etc/indit.d/aasplashscreen

Echo "disabling screen power down"
sudo sed -i "s/=false/=true/g" /etc/default/nodm
#this already happens once due to our rsync of an X11 config, but why not just make sure, eh?

Echo "Working on per printer settings..."
sudo sh -c 'echo \#Photocentric mods >> /boot/config.txt'

if [[${newhost} == "4ktouch"||${newhost}=="LCHR"]]
	then
		# Touchscreen pis only
		echo "Modifying config files for touchscreen"
		sudo sh -c 'echo disable_splash=1 >> /boot/config.txt'
		sudo sh -c 'echo lcd_rotate=2 >> /boot/config.txt'
		sudo sh -c 'echo avoid_warnings=1 >> /boot/config.txt'
		echo "installing kiosk browser"
		#wget http://steinerdatenbank.de/software/kweb-1.7.4.tar.gz
		#tar -xzf kweb-1.7.4.tar.gz
		#cd kweb-1.7.4
		#./debinstall
		#rm -rf kweb-1.7.4
		wget -qO - http://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -
		echo "deb http://dl.bintray.com/kusti8/chromium-rpi jessie main" | sudo tee -a /etc/apt/sources.list
		apt-get update && apt-get install -y kweb
		
fi

if [[${newhost} == "4ktouch"]]
	then
		#4K touchscreen only
		echo "Setting up kiosk-only mode"
		touch /home/pi/.xsession
		echo \#\!/bin/bash >> /home/pi/.xsession
		echo xset s off >> /home/pi/.xsession
		echo xset -dpms >> /home/pi/.xsession
		echo xset s noblank >> /home/pi/.xsession
		echo unclutter -jitter 1 -idle 0.2 -noevents -root \& feh --bg /etc/splash.png \& exec matchbox-window-manager -use_titlebar no \& >> /home/pi/.xsession
		echo while true\; do >> /home/pi/.xsession
		echo \#uzbl -u http://4kscreen.local:9091/printflow -c /home/pi/uzbl.conf \&\; >> /home/pi/.xsession
		echo kweb -KJ http://4kscreen.local:9091/printflow \&\; >> /home/pi/.xsession
		#echo exec matchbox-window-manager -use_titlebar no\; >> /home/pi/.xsession
		echo sleep 2s\; >> /home/pi/.xsession
		echo done >> /home/pi/.xsession
		sudo sed -i "s/=false/=true/g" /etc/default/nodm
		sudo sed -i "s/root/pi/g" /etc/default/nodm
		
		#keeping this as a fallback for kweb as sometimes kweb servers can be offline
		touch /home/pi/uzbl.conf
		echo set show_status=0 >> /home/pi/uzbl.conf
		echo set geometry=maximized >> /home/pi/uzbl.conf
		#enabling NTP listening 
		echo setting up network time client
		sudo sed -i "s/\#disable/disable/g" /etc/ntp.conf
		sudo sed -i "s/\#broadcastclient/broadcastclient/g" /etc/ntp.conf
		sudo /etc/init.d/ntp restart
fi

if [[${newhost} == "4kscreen"]]
	then
		echo "Installing 4k support"
		sudo sh -c 'echo hdmi_group=2 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_mode=87 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_cvt 3840 2160 24 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_width=3840 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_height=2160 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_pixel_freq_limit=400000000 >> /boot/config.txt'
		
		#TODO - add network time propogation to support 4ktouch. Currently built into WG images, but not setup by shell script yet
fi

if [[${newhost} == "LCHR"]]
	then
		echo setting up high resolution
fi


# Change hostname
hostn=$(cat /etc/hostname)
echo "Existing hostname is $hostn, changing to $newhost"
sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
sudo sed -i "s/$hostn/$newhost/g" /etc/hostname
echo "Your new hostname is $newhost, accessible from $newhost.local"

sudo apt-get clean
sudo reboot
