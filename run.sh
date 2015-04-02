make

bap-objdump bin/strcpy_g --use-ida -l ddep

dot -Tpng ddep.dot > ddep.png
