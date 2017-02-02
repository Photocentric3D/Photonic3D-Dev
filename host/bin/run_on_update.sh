#Updating resin profiles on every update

#Getting vars
source /opt/cwh/repoconfig.sh
echo "no update available"
#Downloading printer profile
#echo "Updating Photocentric Liquid Crystal HR profile"
#wget https://raw.githubusercontent.com/${DEFAULT_REPO}/master/host/printers/photocentric%20hr.json -O printerprofile.json

#Deleting old printer
#echo "Deleting old printer"
#curl -X GET --header 'Accept: application/json' 'http://localhost:9091/services/printers/delete/LC%20HR'

#Adding new printer profile and save printer
#echo "Updating printer profile"
#curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d @printerprofile.json "http://localhost:9091/services/printers/save"
