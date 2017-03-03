package org.area515.resinprinter.display.dispmanx;

import org.area515.resinprinter.display.InappropriateDeviceException;

public class RaspberryPiForceTVScreen extends DispManXDevice {
	public RaspberryPiForceTVScreen() throws InappropriateDeviceException {
		super("Photocentric Custom Display", SCREEN.DISPMANX_ID_FORCE_TV);
	}
}
