var printStatus = "";
            
function startpage(){
        //handles page setup and the common things across all pages:
        
        setInterval(function() {
                //time handling/updating
		document.getElementById("time").innerHTML = moment().format("HH:mm:ss[<br>]DD-MMM-YY");
                //wifi updating
                wifiupdate();
                //redirect to print dialogue on user initiating a print
                printredirect();
	}, 1000);
}

function wifiupdate(){
	wifiurl="";
	//TODO: JSON to query the server's wifi status and display it
	//in the meantime for testing purposes, choose a random number.
	wifi = Math.floor(Math.random() * 5)-1;
		
	switch (wifi){
		case 0: wifiurl="images/wifi-0.png";
			break;
		case 1: wifiurl="images/wifi-1.png";
			break;
		case 2: wifiurl="images/wifi-2.png";
			break;
		case 3: wifiurl="images/wifi-3.png";
			break;
		case -1: wifiurl="images/wifi-nc.png";
			break;
	}
	document.getElementById("wifi").src = wifiurl;
}
            
function printredirect(){
        if ((typeof printerName === 'undefined')||(String(window.location.href).indexOf("error.html") >= 0)) {
            //do nothing as there'll be a new call in 1 second, or we're on the error page and we don't want to redirect from that without the user dismissing the error.
        }
        else{
		//send the user to the printdialogue page if a print is in progress.
                $.getJSON("../services/printJobs/getByPrinterName/"+encodeURI(printerName)).done(function (data){
			if ((typeof data !== 'undefined')&&(data !== null)){
				console.log(data);
				printStatus= (data.status);
			}
			else{
				//not printing
			}
		});
             
		if (printStatus=="Failed"){
			if (String(window.location.href).indexOf("printdialogue") >= 0){
				window.location.href=("error.html?errorname=Print Failed&errordetails=The print has unexpectedly failed.\nPlease retry the print, and if the issue persists, contact Technical Support via <b>www.photocentric3d.com</b>");
			}
		}
		if (printStatus=="Cancelled"){
			if (String(window.location.href).indexOf("printdialogue") !== -1){
				window.location.href="printdialogue.html";
			}
		}
    }				
}

function urlParam (name){
	var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
	if ((results !== null)&&(results[1] !== null)){
        	return results[1];
    	}
	else{
		return null;
	}
}