#!/bin/bash

bap bin/strcpy_g -ldata_deps --data_deps-infile=in.txt --data_deps-idascript=script.py
#idaq64 -OIDAPython:`pwd`/script.py bin/strcpy_g
