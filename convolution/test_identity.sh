#!/bin/bash

./main test-10x8/test.ppm && md5sum output.ppm && md5sum test-10x8/test.ppm && stat output.ppm && stat test-10x8/test.ppm
