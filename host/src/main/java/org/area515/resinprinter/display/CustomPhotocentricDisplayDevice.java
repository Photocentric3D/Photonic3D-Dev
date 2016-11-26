package org.area515.resinprinter.display;

import java.io.IOException;
import java.io.FileOutputStream;
import java.io.File;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import java.awt.GraphicsConfiguration;
import java.awt.GraphicsDevice;
import java.awt.DisplayMode;
import java.awt.Window;
import java.awt.Rectangle;
import java.awt.HeadlessException;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.awt.image.Raster;
import java.awt.image.SinglePixelPackedSampleModel;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

//public class CustomPhotocentricDisplayDevice extends CustomNamedDisplayDevice {
public class CustomPhotocentricDisplayDevice extends GraphicsDevice {	
	private static final Logger logger = LogManager.getLogger();
	private String displayName;
	private int width;
	private int height;
	private int bitDepth;
	private int refreshRate;
	private int sliceNumber;

	private CustomDisplayFrame refreshFrame;
    private Process photocentricDisplayServerProcess;


	public CustomPhotocentricDisplayDevice(String displayName) {
		this.displayName = displayName;
		bitDepth = 32;
		refreshRate = 60;
		width = 2048;
		height = 1536;

		logger.debug("CustomPhotocentricDisplayDevice initialising...\n");
		try {
			ProcessBuilder pb = new ProcessBuilder("/opt/cwh/os/Linux/armv61/pdp", "5");
			pb.redirectErrorStream(true);

			photocentricDisplayServerProcess = pb.start(); 
			BufferedReader br = new BufferedReader(new InputStreamReader(photocentricDisplayServerProcess.getInputStream()));

			String line = br.readLine();
			photocentricDisplayServerProcess.waitFor();
            logger.debug("PDP Init: processraw={}\n", line);
			String[] dims = line.split(",");
			width = Integer.parseInt( dims[0].trim() );
			height = Integer.parseInt( dims[1].trim() );
            logger.debug("PDP Init: w={} h={}\n", width, height);
			photocentricDisplayServerProcess.destroy();
        } catch ( IOException e ) {
            logger.error("Failed to spawn Photocentric display server process [IO]\n");
        } catch ( InterruptedException e) {
			logger.error("Failed to spawn Photocentric display server process [Interrupted]\n");
        }
	}

	@Override
	public void setFullScreenWindow(Window w) {
		refreshFrame = (CustomDisplayFrame)w;
		refreshFrame.setGraphicsDevice(this);	// @ is there a nicer way of doing this ???
	}

	@Override
	public DisplayMode getDisplayMode() {
		return new DisplayMode( width, height, bitDepth, refreshRate );
	}

	public Rectangle getBounds() {
		return new Rectangle( width, height );
	}


    public void outputImage( BufferedImage img ) {
	    if (photocentricDisplayServerProcess != null) {
	        photocentricDisplayServerProcess.destroy();
	    }
 
        String filename = "/opt/cwh/os/Linux/armv61/cure.ppm";
//        filename = "/tmp/TEST/cure"+sliceNumber+".ppm";      // .raw  
//    	filename = "/opt/cwh/os/Linux/armv61/cure.ppm"+sliceNumber+".ppm";      // .ppm

        byte[] destPixels = new byte[img.getWidth() * img.getHeight() * 3];
        int i = 0;

        for (int y=0; y<img.getHeight(); y++) {
            for (int x=0; x<img.getWidth(); x++) {
        		int rgb = img.getRGB(x, y);
                destPixels[i++] = (byte)((rgb >> 16) & 0xFF);
                destPixels[i++] = (byte)((rgb >> 8) & 0xFF);
                destPixels[i++] = (byte)((rgb >> 0) & 0xFF);
            }
        }

        try {
            File file = new File(filename);
            FileOutputStream fos = new FileOutputStream(file);

            if (!file.exists()) {
                file.createNewFile();
            }

           	String header = "P6\n" + img.getWidth()+" "+img.getHeight() + "\n" + 255 + "\n";
           	fos.write( header.getBytes() );  // write a PPM header

            fos.write( destPixels );
            fos.flush();
            fos.close();
        } catch (IOException e) {
            System.out.print("failed to save pdp image " + filename + "\n");
            e.printStackTrace();
        }

        try {
            photocentricDisplayServerProcess = Runtime.getRuntime().exec("/opt/cwh/os/Linux/armv61/pdp 5 300 " + filename);
        } catch ( IOException e ) {
            logger.debug("Failed to spawn Photocentric display server process\n");
        }

      	sliceNumber++;
    }
 

	// these are just copied from CustomNamedDisplayDevice
	// for some reason my Java-fu is failing me today and 
	// inheriting from CustomNamedDisplayDevice fails to 
	// compile complaining that the c'tor doesn't have enough
	// arguments...
	
	@Override
	public int getType() {
		return TYPE_IMAGE_BUFFER;
	}
	
	@Override
	public String getIDstring() {
		return displayName;
	}

	@Override
	public GraphicsConfiguration[] getConfigurations() {
		return null;
	}

	@Override
	public GraphicsConfiguration getDefaultConfiguration() {
		return null;
	}

	public String toString() {
		return displayName;
	}
	
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result
				+ ((displayName == null) ? 0 : displayName.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		CustomPhotocentricDisplayDevice other = (CustomPhotocentricDisplayDevice) obj;
		if (displayName == null) {
			if (other.displayName != null)
				return false;
		} else if (!displayName.equals(other.displayName))
			return false;
		return true;
	}
}
