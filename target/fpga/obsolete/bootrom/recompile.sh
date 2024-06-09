# /bin/bash

make -C ../../sim/sw clean
make -C ../../sim/sw
make clean
make bootrom
make -C ../sw clean
make -C ../sw sw
