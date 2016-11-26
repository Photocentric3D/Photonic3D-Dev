#!/bin/sh
build_dir=$(dirname "$0")
gcc -I /opt/vc/include -L /opt/vc/lib -O2 -o $build_dir/pdp -lbcm_host $build_dir/pdp.c
if [ -e "pdp" ]; then chmod +x pdp; fi
#gcc -I /opt/vc/include -L /opt/vc/lib -o dispmanx -lbcm_host dispmanx.c
#gcc -I /opt/vc/include -L /opt/vc/lib -O2 -o makeimage makeimage.c
