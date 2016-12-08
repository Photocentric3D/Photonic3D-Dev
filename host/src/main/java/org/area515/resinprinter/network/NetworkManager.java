package org.area515.resinprinter.network;

import java.util.List;
import java.util.Map;

public interface NetworkManager {
	public List<NetInterface> getNetworkInterfaces();
	public void connectToWirelessNetwork(WirelessNetwork net);
	public String getCurrentSSID();
	public String getHostname();
	public Map getIPs();
	public Map getMACs();
	public void setHostname(String hostname);
}
