#!/bin/bash

./main test-10x8/test.ppm
cat test-10x8/output.txt && echo ""
md5sum output.ppm
md5sum test-10x8/output.ppm
stat output.ppm
stat test-10x8/output.ppm
