#!/bin/sh
gcc -I /opt/vc/include -L /opt/vc/lib -O2 -o pdp -lbcm_host pdp.c
#gcc -I /opt/vc/include -L /opt/vc/lib -o dispmanx -lbcm_host dispmanx.c
#gcc -I /opt/vc/include -L /opt/vc/lib -O2 -o makeimage makeimage.c
