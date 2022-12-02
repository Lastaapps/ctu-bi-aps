#!/bin/bash

./main vit_small.ppm
md5sum output.ppm
md5sum vit_small.ppm
stat output.ppm
stat vit_small.ppm
