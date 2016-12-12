(function() {
	var cwhApp = angular.module('cwhApp');
	cwhApp.controller("SettingsController", ['$scope', '$http', '$location', '$routeParams', '$interval', '$uibModal', 'cwhWebSocket', 'cacheControl', function ($scope, $http, $location, $routeParams, $interval, $uibModal, cwhWebSocket, cacheControl) {
		controller = this;
		var timeoutValue = 500;
		var maxUnmatchedPings = 3;//Maximum number of pings before we assume that we lost our connection
		var unmatchedPing = -1;    //Number of pings left until we lose our connection
		$scope.showAdvanced = false;
		var thankYouMessage = " Thank you for unplugging the network cable. This configuration process could take a few minutes to complete. You can close your browser now and use the Photonic3D Client to find your printer.";
		this.loadingNetworksMessage = "--- Loading wifi networks from server ---"
		
		var PRINTERS_DIRECTORY = "printers";
		var BRANCH = "master";
		var REPO = $scope.repo;
		
		this.loadingFontsMessage = "--- Loading fonts from server ---"
		this.loadingProfilesMessage = "--- Loading slicing profiles from server ---"
		this.loadingMachineConfigMessage = "--- Loading machine configurations from server ---"
		this.autodirect = $location.search().autodirect;
		
		this.toggleAdvanced = function toggleAdvanced(){
			$scope.showAdvanced = !$scope.showAdvanced;
			console.log("Advanced is now"+$scope.showAdvanced);
		}
		
		this.getAdvanced = function getAdvanced(){
			return showAdvanced;
		}
		
		function refreshSelectedPrinter(printerList) {
        	var foundPrinter = false;
        	if (printerList.length == 1 &&  controller.autodirect != 'disabled') {
        		controller.currentPrinter = printerList[0];
        		foundPrinter = true;
        	} else {
        		var printersStarted = 0;
        		var currPrinter = null;
	        	for (var i = 0; i < printerList.length; i++) {
				// had to change as for ___ of ____ isn't supported in IE11 :(
	        		if (printersStarted > 1) {
	        			break;
	        		}
	        		if (printerList[i].started) {
	        			printersStarted += 1;
	        			currPrinter = printerList[i];
	        		}
	        		if (controller.currentPrinter != null && printerList[i].configuration.name === controller.currentPrinter.configuration.name) {
	        			controller.currentPrinter = printerList[i];
	        			foundPrinter = true;
	        		}
	        	}
	        	if (printersStarted == 1 && controller.autodirect != 'disabled') {
	        		controller.currentPrinter = currPrinter;
	        		foundPrinter = true;
	        	}
        	}
        	if (!foundPrinter) {
        		controller.currentPrinter = null;
        	}
        }
		
		function refreshPrinters() {
	        $http.get('/services/printers/list').success(function(data) {
	        	$scope.printers = data;
	        	refreshSelectedPrinter(data);
	        });
	    }
		
		function executeActionAndRefreshPrinters(command, message, service, targetPrinter, postTargetPrinter) {
			if (targetPrinter === null) {
    			$scope.$emit("MachineResponse", {machineResponse: {command:command, message:message, successFunction:null, afterErrorFunction:null}});
		        return;
			}
			var printerName = encodeURIComponent(targetPrinter.configuration.name);
			if (postTargetPrinter) {
			   $http.post(service, targetPrinter).then(
	       			function(response) {
	        			$scope.$emit("MachineResponse", {machineResponse: {command:"Settings Saved!"+newHostname, message:"Your new settings have been saved. Please start the printer to make use of these new settings!.", response:true}, successFunction:null, afterErrorFunction:null});
	       			}, 
	       			function(response) {
 	        			$scope.$emit("HTTPError", {status:response.status, statusText:response.data});
	       		}).then(function() {
	       			    $('#start-btn').attr('class', 'fa fa-play');
	        			$('#stop-btn').attr('class', 'fa fa-stop');
	       		});
		    } else {
		       $http.get(service + printerName).then(
		       		function(response) {
		        		$scope.$emit("MachineResponse", {machineResponse: response.data, successFunction:refreshPrinters, afterErrorFunction:null});
		       		}, 
		       		function(response) {
	 	        		$scope.$emit("HTTPError", {status:response.status, statusText:response.data});
		       		}).then(function() {
		       			    $('#start-btn').attr('class', 'fa fa-play');
		        			$('#stop-btn').attr('class', 'fa fa-stop');
		       		});
			}
		}
		
		$scope.editCurrentPrinter = function editCurrentPrinter(editTitle) {
			controller.editTitle = editTitle;
			controller.editPrinter = JSON.parse(JSON.stringify(controller.currentPrinter));
			openSavePrinterDialog(editTitle, false);
		}

		$scope.savePrinter = function savePrinter(printer, renameProfiles) {
			if (renameProfiles) {
				controller.editPrinter.configuration.MachineConfigurationName = controller.editPrinter.configuration.name;
				controller.editPrinter.configuration.SlicingProfileName = controller.editPrinter.configuration.name;
			}
			executeActionAndRefreshPrinters("Save Printer", "No printer selected to save.", '/services/printers/save', printer, true);
	        controller.editPrinter = null;
	        controller.openType = null;
			cacheControl.clearPreviewExternalState();
		}
		
		function openSavePrinterDialog(editTitle, isNewPrinter) {
			var editPrinterModal = $uibModal.open({
		        animation: true,
		        templateUrl: 'editPrinter.html',
		        controller: 'EditPrinterController',
		        size: "lg",
		        resolve: {
		        	title: function () {return editTitle;},
		        	editPrinter: function () {return controller.editPrinter;}
		        }
			});
		    editPrinterModal.result.then(function (savedPrinter) {$scope.savePrinter(savedPrinter, isNewPrinter)});
		}
		
		//TODO: When we get an upload complete message, we need to refresh file list...
		$scope.showFontUpload = function showFontUpload() {
			var fileChosenModal = $uibModal.open({
		        animation: true,
		        templateUrl: 'upload.html',
		        controller: 'UploadFileController',
		        size: "lg",
		        resolve: {
		        	title: function () {return "Upload True Type Font";},
		        	supportedFileTypes: function () {return ".ttf";},
		        	getRestfulFileUploadURL: function () {return function (filename) {return '/services/machine/uploadFont';}},
		        	getRestfulURLUploadURL: function () {return null;}
		        }
			});
			
			//fileChosenModal.result.then(function (savedPrinter) {$scope.savePrinter(savedPrinter, newPrinter)});
		}
		
		$scope.installCommunityPrinter = function installCommunityPrinter(printer) {
	        $http.get(printer.url).success(
	        		function (data) {
	        			controller.editPrinter = JSON.parse(window.atob(data.content));
	        			$scope.savePrinter(controller.editPrinter, false);
	        		}).error(
    				function (data, status, headers, config, statusText) {
 	        			$scope.$emit("HTTPError", {status:status, statusText:data});
	        		})
	        return;
	    }
		
		this.createNewPrinter = function createNewPrinter(editTitle) {
			if (controller.currentPrinter === null) {
		        $http.post('/services/printers/createTemplatePrinter').success(
		        		function (data) {
		        			controller.editPrinter = data;
		        			openSavePrinterDialog(editTitle, true);
		        		}).error(
	    				function (data, status, headers, config, statusText) {
	 	        			$scope.$emit("HTTPError", {status:status, statusText:data});
		        		})
		        return;
			}
			
			controller.editPrinter = JSON.parse(JSON.stringify(controller.currentPrinter));
			controller.editPrinter.configuration.name = controller.editPrinter.configuration.name + " (Copy)";
			//These must be set before we save a printer, otherwise the xml files aren't saved properly
			controller.editPrinter.configuration.MachineConfigurationName = controller.editPrinter.configuration.name;
			controller.editPrinter.configuration.SlicingProfileName = controller.editPrinter.configuration.name;
			openSavePrinterDialog(editTitle, true);
		}

		this.startCurrentPrinter = function startCurrentPrinter() {
			$('#start-btn').attr('class', 'fa fa-refresh fa-spin');
			executeActionAndRefreshPrinters("Start Printer", "No printer selected to start.", '/services/printers/start/', controller.currentPrinter, false);
		}
		
		this.stopCurrentPrinter = function stopCurrentPrinter() {
			$('#stop-btn').attr('class', 'fa fa-refresh fa-spin');			
			executeActionAndRefreshPrinters("Stop Printer", "No printer selected to Stop.", '/services/printers/stop/', controller.currentPrinter, false);
		}
		
		this.deleteCurrentPrinter = function deleteCurrentPrinter() {
			executeActionAndRefreshPrinters("Delete Printer", "No printer selected to Delete.", '/services/printers/delete/', controller.currentPrinter, false);
	        controller.currentPrinter = null;
		}
		
		this.changeHostname = function changeHostname(newHostname) {
			$http.get("/services/machine/setNetworkHostname/"+newHostname).success(
	        		function (data) {
	        			$scope.$emit("MachineResponse", {machineResponse: {command:"Hostname changed to: "+newHostname, message:"Your new hostname ("+newHostname+") will take effect the next time the printer is powered on.", response:true}, successFunction:null, afterErrorFunction:null});
	        		}).error(
    				function (data, status, headers, config, statusText) {
 	        			$scope.$emit("HTTPError", {status:status, statusText:data});
	        		})
	        return;
		}
		
		this.changeCurrentPrinter = function changeCurrentPrinter(newPrinter) {
			controller.currentPrinter = newPrinter;
		}
		
        this.gotoPrinterControls = function gotoPrinterControls() {
        	$location.path('/printerControlsPage').search({printerName: controller.currentPrinter.configuration.name})
        };
        
		this.testScript = function testScript(scriptName, returnType, script) {
			var printerNameEn = encodeURIComponent(controller.currentPrinter.configuration.name);
			var scriptNameEn = encodeURIComponent(scriptName);
			var returnTypeEn = encodeURIComponent(returnType);
			
			$http.post('/services/printers/testScript/' + printerNameEn + "/" + scriptNameEn + "/" + returnTypeEn, script).success(function (data) {
				controller.graph = data.result;
				if (data.error) {
	     			$scope.$emit("MachineResponse", {machineResponse: {command:scriptName, message:data.errorDescription}, successFunction:null, afterErrorFunction:null});
	     		} else if (returnType.indexOf("[") > -1){
					$('#graphScript').modal();
				} else {
	     			$scope.$emit("MachineResponse", {machineResponse: {command:scriptName, message:"Successful execution. Script returned:" + JSON.stringify(data.result), response:true}, successFunction:null, afterErrorFunction:null});
				}
			}).error(function (data, status, headers, config, statusText) {
     			$scope.$emit("HTTPError", {status:status, statusText:data});
    		})
		}
		
		this.testTemplate = function testTemplate(scriptName, script) {
			var printerNameEn = encodeURIComponent(controller.currentPrinter.configuration.name);
			var scriptNameEn = encodeURIComponent(scriptName);
			
			$http.post('/services/printers/testTemplate/' + printerNameEn + "/" + scriptNameEn, script).success(function (data) {
				if (data.error) {
	     			$scope.$emit("MachineResponse", {machineResponse: {command:scriptName, message:data.errorDescription}, successFunction:null, afterErrorFunction:null});
				} else {
	     			$scope.$emit("MachineResponse", {machineResponse: {command:scriptName, message:"Successful execution. Template returned:" + data.result, response:true}, successFunction:null, afterErrorFunction:null});
				}
			}).error(function (data, status, headers, config, statusText) {
     			$scope.$emit("HTTPError", {status:status, statusText:data});
    		})
		}
		
		this.testRemainingPrintMaterial = function testRemainingPrintMaterial(printer) {
			var printerNameEn = encodeURIComponent(printer.configuration.name);
			
			$http.get('/services/printers/remainingPrintMaterial/' + printerNameEn).success(function (data) {
				//if (data.error) {
	     			$scope.$emit("MachineResponse", {machineResponse: data, successFunction:null, afterErrorFunction:null});
				/*} else {
	     			$scope.$emit("MachineResponse", {machineResponse: {command:scriptName, message:"Successful execution. Template returned:" + data.result, response:true}, successFunction:null, afterErrorFunction:null});
				}*/
			}).error(function (data, status, headers, config, statusText) {
     			$scope.$emit("HTTPError", {status:status, statusText:data});
    		})
		}
		
		$http.get('/services/machine/supportedFontNames').success(
				function (data) {
					controller.fontNames = data;
					controller.loadingFontsMessage = "Select a font...";
				});
		
		$http.get('/services/machine/slicingProfiles/list').success(
				function (data) {
					controller.slicingProfiles = data;
					controller.loadingProfilesMessage = "Select a slicing profile...";
				});
		
		$http.get('/services/machine/machineConfigurations/list').success(
				function (data) {
					controller.machineConfigurations = data;
					controller.loadingMachineConfigMessage = "Select a machine configuration...";
				});
		//https://raw.githubusercontent.com/WesGilster/Creation-Workshop-Host/master/host/printers/mUVe%201.json
		$http.get("https://api.github.com/repos/" + $scope.repo + "/contents/host/" + PRINTERS_DIRECTORY + "?ref=" + BRANCH).success(
			function (data) {
				$scope.communityPrinters = data;
			}
		);
		
		controller.inkDetectors = [{name:"Visual Ink Detector", className:"org.area515.resinprinter.inkdetection.visual.VisualPrintMaterialDetector"}];
		refreshPrinters();
		
		function attachToHost() {
			controller.hostSocket = cwhWebSocket.connect("services/hostNotification", $scope).onJsonContent(function(hostEvent) {
				controller.restartMessage = " " + hostEvent.message;	
				if (hostEvent.notificationEvent == "Ping") {
					var unmatchedPingCheck = function() {
						controller.hostSocket.sendMessage(hostEvent);
						
						if (unmatchedPing === 0) {
							controller.restartMessage = thankYouMessage;
							unmatchedPing = -1;//Start over from scratch if we get another ping!!!
						} else {
							unmatchedPing--;
							$interval(unmatchedPingCheck, timeoutValue, 1);
						}
					}
					
					if (unmatchedPing === -1) {
						$interval(unmatchedPingCheck, timeoutValue, 1);
					}
					
					unmatchedPing = maxUnmatchedPings;
				}
			}).onClose(function() {
				controller.restartMessage = thankYouMessage;
			});
			if (controller.hostSocket === null) {
				$scope.$emit("MachineResponse",  {machineResponse: {command:"Browser Too Old", message:"You will need to use a modern browser to run this application."}});
			}
		}
		
		this.connectToWireless = function connectToWireless() {
			controller.shutdownInProgress = true;
			$http.put("services/machine/wirelessConnect", controller.selectedNetworkInterface).then(
		    		function (data) {
		    			controller.restartMessage = " Waiting for host to start monitoring process.";
		    			$('#editModal').modal();
		    			
		    			$http.post("services/machine/startNetworkRestartProcess/600000/" + timeoutValue + "/" + maxUnmatchedPings).then(
		    		    		function (data) {
		    		    			controller.restartMessage = " Network monitoring has been setup.";
		    		    		},
		    		    		function (error) {
		    		    			controller.restartMessage = " Print host was unable to start network monitoring process. Click cancel."
		    		    		}
		    		    )
		    		},
		    		function (error) {
 	        			$scope.$emit("HTTPError", {status:error.status, statusText:error.data});
 	        			controller.shutdownInProgress = false;
		    		}
		    )
		};
		
		//TODO: this needs to be attached to more than just the cancel button so that we can kill the web socket.
		this.cancelRestartProcess = function cancelRestartProcess() {
			$http.post("services/machine/cancelNetworkRestartProcess").then(
		    		function (data) {
		    			controller.shutdownInProgress = false;
		    		},
		    		function (error) {
		    			controller.shutdownInProgress = false;
 	        			$scope.$emit("HTTPError", {status:error.status, statusText:error.data});
		    		}
		    )
		}
		this.saveEmailSettings = function saveEmailSettings() {
			if (!Array.isArray(controller.emailSettings.notificationEmailAddresses)) {
				controller.emailSettings.notificationEmailAddresses = [controller.emailSettings.notificationEmailAddresses];
			}
			if (!Array.isArray(controller.emailSettings.serviceEmailAddresses)) {
				controller.emailSettings.serviceEmailAddresses = [controller.emailSettings.serviceEmailAddresses];
			}
			$http.put("services/settings/emailSettings", controller.emailSettings).then(
		    		function (data) {
		    			alert("Email settings saved.");
		    		},
		    		function (error) {
 	        			$scope.$emit("HTTPError", {status:error.status, statusText:error.data});
		    		}
		    )
		};
		
		$http.get("services/settings/emailSettings").success(
	    		function (data) {
	    			controller.emailSettings = data;
	    		})
		
		$http.get('/services/machine/getNetworkHostConfiguration').success(
				function(data) {
					controller.hostConfig = data;
				})
	    		
		$http.get("services/machine/wirelessNetworks/list").success(
	    		function (data) {
	    			controller.networkInterfaces = data;
	    			controller.loadingNetworksMessage = "Select a wifi network";
	    		})
	
		attachToHost();
	}])
})();
