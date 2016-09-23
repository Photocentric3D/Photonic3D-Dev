#!/bin/bash

# variables (per pi)
export newhost=LCHR
# can be either 4ktouch, 4kscreen or LCHR

# DO FOR ALL
echo "Getting updates and installing utilities"
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install fbi git rsync rpi-update matchbox-window-manager uzbl xinit nodm Xorg unclutter feh jq tint2
git clone https://github.com/Photocentric3D/Photonic3D.git photonic-repo
sudo rpi-update

if [[ "[ "$newhost" == "4kscreen" ]" || "[ "$newhost" == "LCHR" ]" ]]
	then
		echo "update photonic"
# would prefer to call this to update to a particular version,
# but the auto-update in start.sh will flatten updates made in the next section
# so doing this first.
		sudo /opt/cwh/stop.sh
		sudo /opt/cwh/start.sh
fi


# redirect boot terminal output not to screen
echo "removing pi branding"
sudo mv /boot/cmdline.txt /boot/cmdline.old 
sudo sh -c 'echo -n "loglevel=3 logo.nologo " > /boot/cmdline.txt'
sudo sh -c 'cat /boot/cmdline.old >> /boot/cmdline.txt'
sudo sed -i "s/tty1/tty/g" /boot/cmdline.txt

echo "installing common files"
sudo rsync -avr photonic-repo/host/common/ /
sudo rsync -avr photonic-repo/host/resourcesnew/printflow /opt/cwh/resourcesnew/ #keep printflow without the 
sudo cp photonic-repo/host/os/Linux/armv61/pdp /opt/cwh/os/Linux/armv61/pdp
cp /etc/splash.png ~/.splash.png
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
#this already happens once due to our rsync of an X11 config, but why not just make sure, eh?

echo "Working on per printer settings..."
sudo sh -c 'echo \#Photocentric mods >> /boot/config.txt'

if [[ "[ "$newhost" == "4ktouch" ]" || "[ "$newhost" == "LCHR" ]" ]]
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
		sudo sh -c 'echo "deb http://dl.bintray.com/kusti8/chromium-rpi jessie main" | sudo tee -a /etc/apt/sources.list'
		sudo apt-get update && sudo apt-get install -y youtube-dl
		#HACK: installing youtube-dl just because it causes kweb installation script to ask a question that must be replied to on keyboard otherwise
		sudo apt-get install -y kweb
		
		echo "Setting up kiosk-only mode"
		touch /home/pi/.xsession
		echo \#\!/bin/bash >> /home/pi/.xsession
		echo xset s off >> /home/pi/.xsession
		echo xset -dpms >> /home/pi/.xsession
		echo xset s noblank >> /home/pi/.xsession
		echo unclutter -jitter 1 -idle 0.2 -noevents -root \& feh --bg /home/pi/.splash.png \& exec matchbox-window-manager -use_titlebar no \& >> /home/pi/.xsession
		echo while true\; do >> /home/pi/.xsession
		
		if [ $newhost == "4ktouch" ]; 
			then
				target=4kscreen
			else
				target=$newhost
		fi
		
		echo \#uzbl -u http://$target.local:9091/printflow -c /home/pi/uzbl.conf \&\; >> /home/pi/.xsession
		echo kweb -KJ http://$target.local:9091/printflow\; >> /home/pi/.xsession
		#echo exec matchbox-window-manager -use_titlebar no\; >> /home/pi/.xsession
		echo sleep 2s\; >> /home/pi/.xsession
		echo done >> /home/pi/.xsession
		
		#keeping this as a fallback for kweb as sometimes kweb servers can be offline
		touch /home/pi/uzbl.conf
		echo set show_status=0 >> /home/pi/uzbl.conf
		echo set geometry=maximized >> /home/pi/uzbl.conf
		
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
		sudo sh -c 'echo hdmi_group=2 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_mode=87 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_cvt 3840 2160 24 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_width=3840 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_height=2160 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_pixel_freq_limit=400000000 >> /boot/config.txt'
		
		#TODO - add network time propogation to support 4ktouch. Currently built into WG images, but not setup by shell script yet
		echo "setting up printer profile"
		curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "configuration": {
    "name": "Photocentric 10",
    "machineConfig": {
      "name": "Photocentric 10",
      "FileVersion": 0,
      "PlatformXSize": 450,
      "PlatformYSize": 280,
      "PlatformZSize": 300,
      "MaxXFeedRate": 0,
      "MaxYFeedRate": 0,
      "MaxZFeedRate": 0,
      "XRenderSize": 3840,
      "YRenderSize": 2160,
      "MotorsDriverConfig": {
        "DriverType": "Photocentric",
        "ComPortSettings": {
          "PortName": "/dev/ttyACM0",
          "Speed": 115200,
          "Databits": 8,
          "Parity": "None",
          "Stopbits": "One",
          "Handshake": "None"
        }
      },
      "MonitorDriverConfig": {
        "DLP_X_Res": 3840,
        "DLP_Y_Res": 2160,
        "MonitorID": "DISPLAY1",
        "OSMonitorID": ":0.0",
        "DisplayCommEnabled": false,
        "ComPortSettings": {
          "Handshake": "None"
        },
        "MonitorTop": 12,
        "MonitorLeft": 11,
        "MonitorRight": 11,
        "MonitorBottom": 12,
        "UseMask": false
      },
      "PauseOnPrinterResponseRegEx": ".*door.*open.*"
    },
    "slicingProfile": {
      "gCodeHeader": "G91;\nM17;",
      "gCodeFooter": "M18",
      "gCodePreslice": null,
      "gCodeLift": "G1 Z${ZLiftDist} F${ZLiftRate};\nG1 Z-${(ZLiftDist - LayerThickness)} F180;\nM17;\n;<delay> 1500;",
      "gCodeShutter": null,
      "name": "Hard daylight red 0.1",
      "zliftDistanceGCode": null,
      "zliftSpeedGCode": null,
      "selectedInkConfigIndex": 0,
      "DotsPermmX": 6.133261494252874,
      "DotsPermmY": 6.130268199233716,
      "XResolution": 3840,
      "YResolution": 2160,
      "BlankTime": 0,
      "PlatformTemp": 0,
      "ExportSVG": 0,
      "Export": false,
      "ExportPNG": false,
      "Direction": "Bottom_Up",
      "LiftDistance": 5,
      "SlideTiltValue": 0,
      "AntiAliasing": true,
      "UseMainLiftGCode": false,
      "AntiAliasingValue": 10,
      "LiftFeedRate": 50,
      "LiftRetractRate": 0,
      "FlipX": false,
      "FlipY": true,
      "ZLiftDistanceCalculator": "var minLift = 4.5;\nvar value = 8.0;\nif ($CURSLICE > $NumFirstLayers) {\nvalue = minLift  +  0.0015*Math.pow($buildAreaMM,1);\n}\nvalue",
      "ZLiftSpeedCalculator": "var value = 50.0;\nif ($CURSLICE > $NumFirstLayers) {\nvalue = 100.0 - 0.02 * Math.pow($buildAreaMM,1);\n}\nvalue",
      "ExposureTimeCalculator": "var value = $FirstLayerTime;\nif ($CURSLICE > $NumFirstLayers) {\n\tvalue = $LayerTime\n}\nvalue",
      "SelectedInk": "Default",
      "MinTestExposure": 0,
      "TestExposureStep": 0,
      "InkConfig": [
        {
          "PercentageOfPrintMaterialConsideredEmpty": 10,
          "Name": "Default",
          "SliceHeight": 0.05,
          "LayerTime": 26000,
          "FirstLayerTime": 140000,
          "NumberofBottomLayers": 4,
          "ResinPriceL": 65
        }
      ]
    },
    "MachineConfigurationName": "Photocentric 10",
    "SlicingProfileName": "Hard daylight red 0.1",
    "AutoStart": true,
    "Calibrated": false
  },
  "started": true,
  "shutterOpen": false,
  "displayDeviceID": ":0.0",
  "currentSlicePauseTime": 0,
  "status": "Ready",
  "printInProgress": false,
  "printPaused": false,
  "cachedBulbHours": null
}' 'http://localhost:9091/services/printers/save'
fi

if [ "$newhost" == "LCHR" ]
	then
		echo "setting up high resolution screen"
		sudo sh -c 'echo hdmi_group=2 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_mode=87 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_cvt 2048 1536 30 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_width=2048 >> /boot/config.txt'
		sudo sh -c 'echo max_framebuffer_height=1536 >> /boot/config.txt'
		sudo sh -c 'echo hdmi_pixel_freq_limit=400000000 >> /boot/config.txt'
		echo "installing LCHR profile"
		curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "configuration": {
    "name": "Photocentric 10",
    "machineConfig": {
      "name": "Photocentric 10",
      "FileVersion": 0,
      "PlatformXSize": 160,
      "PlatformYSize": 120,
      "PlatformZSize": 200,
      "MaxXFeedRate": 0,
      "MaxYFeedRate": 0,
      "MaxZFeedRate": 0,
      "XRenderSize": 2048,
      "YRenderSize": 1536,
      "MotorsDriverConfig": {
        "DriverType": "Photocentric",
        "ComPortSettings": {
          "PortName": "/dev/ttyACM0",
          "Speed": 115200,
          "Databits": 8,
          "Parity": "None",
          "Stopbits": "One",
          "Handshake": "None"
        }
      },
      "MonitorDriverConfig": {
        "DLP_X_Res": 2048,
        "DLP_Y_Res": 1536,
        "MonitorID": "DISPLAY1",
        "OSMonitorID": ":0.0",
        "DisplayCommEnabled": false,
        "ComPortSettings": {
          "Handshake": "None"
        },
        "MonitorTop": 12,
        "MonitorLeft": 11,
        "MonitorRight": 11,
        "MonitorBottom": 12,
        "UseMask": false
      },
      "PauseOnPrinterResponseRegEx": ".*door.*open.*"
    },
    "slicingProfile": {
      "gCodeHeader": "G91;\nM17;",
      "gCodeFooter": "M18",
      "gCodePreslice": null,
      "gCodeLift": "G1 Z${ZLiftDist} F${ZLiftRate};\nG1 Z-${(ZLiftDist - LayerThickness)} F180;\nM17;\n;<delay> 1500;",
      "gCodeShutter": null,
      "name": "Hard daylight red 0.1",
      "zliftDistanceGCode": null,
      "zliftSpeedGCode": null,
      "selectedInkConfigIndex": 0,
      "DotsPermmX": 6.1,
      "DotsPermmY": 6.1,
      "XResolution": 2048,
      "YResolution": 1536,
      "BlankTime": 0,
      "PlatformTemp": 0,
      "ExportSVG": 0,
      "Export": false,
      "ExportPNG": false,
      "Direction": "Bottom_Up",
      "LiftDistance": 5,
      "SlideTiltValue": 0,
      "AntiAliasing": true,
      "UseMainLiftGCode": false,
      "AntiAliasingValue": 10,
      "LiftFeedRate": 50,
      "LiftRetractRate": 0,
      "FlipX": false,
      "FlipY": true,
      "ZLiftDistanceCalculator": "var minLift = 4.5;\nvar value = 8.0;\nif ($CURSLICE > $NumFirstLayers) {\nvalue = minLift  +  0.0015*Math.pow($buildAreaMM,1);\n}\nvalue",
      "ZLiftSpeedCalculator": "var value = 50.0;\nif ($CURSLICE > $NumFirstLayers) {\nvalue = 100.0 - 0.02 * Math.pow($buildAreaMM,1);\n}\nvalue",
      "ExposureTimeCalculator": "var value = $FirstLayerTime;\nif ($CURSLICE > $NumFirstLayers) {\n\tvalue = $LayerTime\n}\nvalue",
      "SelectedInk": "Default",
      "MinTestExposure": 0,
      "TestExposureStep": 0,
      "InkConfig": [
        {
          "PercentageOfPrintMaterialConsideredEmpty": 10,
          "Name": "Default",
          "SliceHeight": 0.025,
          "LayerTime": 20000,
          "FirstLayerTime": 140000,
          "NumberofBottomLayers": 4,
          "ResinPriceL": 65
        }
      ]
    },
    "MachineConfigurationName": "Photocentric 10",
    "SlicingProfileName": "Hard daylight red 0.1",
    "AutoStart": true,
    "Calibrated": false
  },
  "started": true,
  "shutterOpen": false,
  "displayDeviceID": ":0.0",
  "currentSlicePauseTime": 0,
  "status": "Ready",
  "printInProgress": false,
  "printPaused": false,
  "cachedBulbHours": null
}
' 'http://localhost:9091/services/printers/save'
fi


# Change hostname
# left this 'til last for good reasons. Keep it last now.
hostn=$(cat /etc/hostname)
echo "Existing hostname is $hostn, changing to $newhost"
sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
sudo sed -i "s/$hostn/$newhost/g" /etc/hostname
echo "Your new hostname is $newhost, accessible from $newhost.local"

rm -rf photonic-repo

sudo apt-get clean
sudo reboot
