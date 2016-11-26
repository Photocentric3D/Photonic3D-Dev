package org.area515.resinprinter.network;

import java.util.ArrayList;
import java.util.List;

public class WirelessNetwork {
	private String ssid;
	private List<WirelessEncryption> supportedWirelessEncryption = new ArrayList<WirelessEncryption>();
	private String parentInterfaceName;
	private String password;
	private String signalStrength; 
	
	public WirelessNetwork() {}
	
	public String getSsid() {
		return ssid;
	}
	public void setSsid(String ssid) {
		this.ssid = ssid;
	}
	
	public List<WirelessEncryption> getSupportedWirelessEncryption() {
		return supportedWirelessEncryption;
	}
	public void setSupportedWirelessEncryption(List<WirelessEncryption> supportedWirelessEncryption) {
		this.supportedWirelessEncryption = supportedWirelessEncryption;
	}

	public String getParentInterfaceName() {
		return parentInterfaceName;
	}
	public void setParentInterfaceName(String parentInterfaceName) {
		this.parentInterfaceName = parentInterfaceName;
	}

	public String getPassword() {
		return password;
	}
	public void setPassword(String password) {
		this.password = password;
	}
		
	public String getSignalStrength(){
		return signalStrength;
	}
	
	public void setSignalStrength(String signalStrength){
		this.signalStrength = signalStrength;
	}
}
