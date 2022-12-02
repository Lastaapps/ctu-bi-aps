#!/bin/bash

./main vit_small.ppm
echo "24432 16307 15192 54597 9472"
md5sum output.ppm
echo "32554ccd9b09af5b660a17b05350959b"
stat output.ppm
