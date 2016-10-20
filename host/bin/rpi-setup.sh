#!/bin/bash

# variables (per pi)
export newhost=LCHR
# can be either 4ktouch, 4kscreen, standalone or LCHR
export portno=9091
# currently set to 9091. Needs to be updated if the port config changes.
# Installers will also need to double check and update this if the port no changes between builds.
export newpassword=photocentric
# *** IMPORTANT NOTE *** declaring this as a variable in an open source project is totally insecure!
# Ideally the password should be changed offline, and this repo should never be updated to match that.
# but it's still better than sending out the hardware with the default pi user and password unchanged. Obviously.


# DO FOR ALL
echo "Getting updates and installing utilities"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install rpi-chromium-mods dos2unix curl librxtx-java fbi git rsync rpi-update matchbox-window-manager uzbl xinit nodm Xorg unclutter feh jq tint2 wmctrl

if [ -e photonic-repo ]; then
	sudo rm -rf photonic-repo
fi
sudo git clone https://github.com/Photocentric3D/Photonic3D.git photonic-repo
sudo rpi-update

if [[ "[ "$newhost" == "4kscreen" ]" || "[ "$newhost" == "LCHR" ]" || "[ "$newhost" == "standalone" ]" ]]
	then
		echo "update photonic"
		# would prefer to call this to update to a particular version,
		# but the auto-update in start.sh will flatten any changes we make in the next section
		# so doing this first.
		sudo chmod +x photonic-repo/host/bin/*.sh
		sudo dos2unix photonic-repo/host/bin/*.sh
		if [ -e "/opt/cwh/stop.sh" ]
			then
				# kill the old version of photonic using its stop.sh script
				sudo /opt/cwh/stop.sh
		fi
		# launch the Photocentric rather than area515 version of start.sh - ensures using Photocentric branch
		sudo photonic-repo/host/bin/start.sh
fi


# redirect boot terminal output not to screen
echo "removing pi branding"
# we can't remove everything as some is baked into the pi's firmware, but this gives a realistic amount.
if [ ! -e "/boot/cmdline.old" ]; then
	sudo mv /boot/cmdline.txt /boot/cmdline.old 
	sudo sh -c 'echo -n "loglevel=3 logo.nologo " > /boot/cmdline.txt'
	sudo sh -c 'cat /boot/cmdline.old >> /boot/cmdline.txt' 
	sudo sed -i "s/tty1/tty/g" /boot/cmdline.txt
else
	echo "already complete!"
fi

echo "installing common files"
sudo rsync -avr photonic-repo/host/common/ /
sudo rsync -avr photonic-repo/host/resourcesnew/printflow /opt/cwh/resourcesnew/ #keep printflow without the trailing / 
if [ -e /opt/cwh/photocentric/ ]; then
	sudo mkdir /opt/cwh/photocentric
fi
sudo rsync -avr photonic-repo/host/photocentric/printflow /opt/cwh/photocentric/
sudo cp photonic-repo/host/os/Linux/armv61/pdp /opt/cwh/os/Linux/armv61/pdp #copy display manager for screen + curing screen printers
sudo cp photonic-repo/host/resourcesnew/printflow/holdingpage.html /home/pi/holdingpage.html #copy holdingpage for fallback
#install splash screen
sudo chown root /etc/splash.png
sudo chmod 777 /etc/splash.png
sudo chmod a+x /etc/init.d/aasplashscreen
sudo insserv /etc/init.d/aasplashscreen

echo "disabling screen power down"
if [ -e "/etc/default/nodm" ]
	then
		sudo sed -i "s/=false/=true/g" /etc/default/nodm
		sudo sed -i "s/root/pi/g" /etc/default/nodm
	else
		echo "nodm doesn't exist"
fi
# this already happens once due to our rsync of an X11 config, but why not just make sure, eh?

echo "Working on per printer settings..."
sudo sh -c 'echo \#Photocentric mods >> /boot/config.txt'

if [[ "[ "$newhost" == "4ktouch" ]" || "[ "$newhost" == "LCHR" ]" || "[ "$newhost" == "standalone" ]" ]]; then
	# Touchscreen pis only
	echo "Modifying config files for touchscreen"
	if grep -Fxq "disable_splash" /boot/config.txt
	then
		echo "already done!"
	else
		sudo sh -c 'echo disable_splash=1 >> /boot/config.txt'
		sudo sh -c 'echo lcd_rotate=2 >> /boot/config.txt'
		sudo sh -c 'echo avoid_warnings=1 >> /boot/config.txt'
	fi
	echo "installing kiosk browser"
	# since this isn't on standard apt-get sources, i'm keeping this as an alternative way to source kweb
	###wget http://steinerdatenbank.de/software/kweb-1.7.4.tar.gz
	###tar -xzf kweb-1.7.4.tar.gz
	###cd kweb-1.7.4
	###./debinstall
	###rm -rf kweb-1.7.4
	if grep -Fxq "chromium-rpi" /etc/apt/sources.list
	then
		echo "already done!"
	else
		sudo wget -qO - http://bintray.com/user/downloadSubjectPublicKey?username=bintray | sudo apt-key add -
		sudo sh -c 'echo "deb http://dl.bintray.com/kusti8/chromium-rpi jessie main" | sudo tee -a /etc/apt/sources.list'
		sudo sh -c "yes Y | apt-get install -y kweb"
	fi
	
	touch /home/pi/.xsession
	echo "Setting up kiosk-only mode"
	if grep -Fxq "kweb" /home/pi/.xsession
	then
		echo "already done!"
	else
		
		echo \#\!/bin/bash > /home/pi/.xsession
		echo xset s off >> /home/pi/.xsession
		echo xset -dpms >> /home/pi/.xsession
		echo xset s noblank >> /home/pi/.xsession
	
	
		if [ $newhost == "4ktouch" ]; then
			export target=4kscreen
		else
			export target=$newhost
		fi


		echo unclutter -jitter 1 -idle 0.2 -noevents -root \& feh -NY --bg /etc/splash.png \& exec matchbox-window-manager -use_titlebar no \& >> /home/pi/.xsession
		echo while true\; do >> /home/pi/.xsession
	
		echo -e "\twhile true\; do" >> /home/pi/.xsession
		echo -e "\t\tif curl -fI http://$target.local:$portno/printflow/images/wifi-0.png" >> /home/pi/.xsession			
		echo -e"\t\t\tthen" >> /home/pi/.xsession
		echo -e "\t\t\t\tbreak" >> /home/pi/.xsession
		echo -e "\t\tfi" >> /home/pi/.xsession
		echo "\tdone" >> /home/pi/.xsession
	
		echo -e "\t\#uzbl -u /home/pi/holdingpage.html?target=http://$target.local:$portno/printflow -c /home/pi/uzbl.conf \&\;" >> /home/pi/.xsession
		echo -e "\tkweb -KJ http://$target.local:$portno/printflow\;" >> /home/pi/.xsession
		#echo exec matchbox-window-manager -use_titlebar no\; >> /home/pi/.xsession
		echo -e "\tsleep 2s\;" >> /home/pi/.xsession
		echo done >> /home/pi/.xsession
		fi
	
		if [ ! -e "/home/pi/uzbl.conf" ]; then
			#keeping this as a fallback for kweb as sometimes kweb servers can be offline
			touch /home/pi/uzbl.conf
			echo set show_status=0 >> /home/pi/uzbl.conf
			echo set geometry=maximized >> /home/pi/uzbl.conf
		fi
			
fi

if [ "$newhost" == "4ktouch" ]
	then
		#4K touchscreen only

		#enabling NTP listening 
		echo setting up network time client
		sudo sed -i "s/\#disable/disable/g" /etc/ntp.conf
		sudo sed -i "s/\#broadcastclient/broadcastclient/g" /etc/ntp.conf
		sudo /etc/init.d/ntp restart
fi

if [ "$newhost" == "4kscreen" ]
	then
		echo "Installing 4k support"
		if grep -Fxq "hdmi_pixel_freq_limit" /boot/config.txt
			then
				echo "already done!"
			else
				sudo sh -c 'echo hdmi_group=2 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_mode=87 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_cvt 3840 2160 24 >> /boot/config.txt'
				sudo sh -c 'echo max_framebuffer_width=3840 >> /boot/config.txt'
				sudo sh -c 'echo max_framebuffer_height=2160 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_pixel_freq_limit=400000000 >> /boot/config.txt'
		fi
		
		#TODO - add network time propogation to support 4ktouch. Currently built into WG images, but not setup by shell script yet
		echo "setting up Photocentric Pro profile"
		sudo wget https://raw.githubusercontent.com/Photocentric3D/Photonic3D/master/host/printers/Photocentric%20Pro.json -O printerprofile.json
		sudo curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @printerprofile.json 'http://localhost:$portno/services/printers/save'
		sudo sh -c 'echo var printerName = \"Photocentric Pro\"\; > /opt/cwh/resourcesnew/printflow/js/printerconfig.js'
fi

if [ "$newhost" == "LCHR" ]
	then
		echo "setting up high resolution screen"
		if grep -Fxq "hdmi_pixel_freq_limit" /boot/config.txt
			then
				echo "already done!"
			else
				sudo sh -c 'echo hdmi_group=2 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_mode=87 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_cvt 2048 1536 30 >> /boot/config.txt'
				sudo sh -c 'echo max_framebuffer_width=2048 >> /boot/config.txt'
				sudo sh -c 'echo max_framebuffer_height=1536 >> /boot/config.txt'
				sudo sh -c 'echo hdmi_pixel_freq_limit=400000000 >> /boot/config.txt'
		fi


		echo "installing Photocentric Liquid Crystal HR profile"
		sudo wget https://raw.githubusercontent.com/Photocentric3D/Photonic3D/master/host/printers/photocentric%20hr.json -O printerprofile.json
		sudo curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @printerprofile.json 'http://localhost:$portno/services/printers/save'
		sudo sh -c 'echo var printerName = \"LC HR\"\; > /opt/cwh/resourcesnew/printflow/js/printerconfig.js'
fi


if [ "$newhost" == "standalone" ]
	then
		echo "creating standalone image..."
		#TODO
		echo "installing Photocentric 10 profile"
		sudo wget https://raw.githubusercontent.com/Photocentric3D/Photonic3D/master/host/printers/photocentric%2010.json -O printerprofile.json
		sudo curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @printerprofile.json "http://localhost:$portno/services/printers/save"
		sudo sh -c 'echo var printerName = \"Photocentric 10\"\; > /opt/cwh/resourcesnew/printflow/js/printerconfig.js'
fi

# Change hostname
# left this 'til last for good reasons. Keep it last now.
export hostn=$(cat /etc/hostname)
echo "Existing hostname is $hostn, changing to $newhost"
sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
sudo sed -i "s/$hostn/$newhost/g" /etc/hostname
echo "Your new hostname is $newhost, accessible from $newhost.local"

echo "changing password"
sudo sh -c "echo 'pi:$newpassword' | chpasswd"
echo "password updated!"
#if you haven't already, re-read the big important note at the top!

sudo rm -rf photonic-repo
sudo rm printerprofile.json

sudo apt-get clean
sudo reboot
