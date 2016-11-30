package org.area515.resinprinter.network;

import java.util.List;

public interface NetworkManager {
	public List<NetInterface> getNetworkInterfaces();
	public void connectToWirelessNetwork(WirelessNetwork net);
	public String getCurrentSSID();
	public String getHostname();
	public List<String> getIPs();
	public List<String> getMACs();
}
