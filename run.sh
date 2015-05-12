#!/bin/bash

#bap bin/strcpy_g -ldata_deps --data_deps-infile=in.txt --data_deps-idascript=script.py -ltoida --emit-ida-script=two.py
bap /vagrant/coreutils_O1_cat -ldata_deps --data_deps-infile=in2.txt --data_deps-idascript=script.py -ltoida --emit-ida-script=two.py
#idaq64 -OIDAPython:`pwd`/script.py bin/strcpy_g
