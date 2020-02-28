#!/bin/bash
set -e

# setup prometheus-cp
cd prometheus-cp
./setup.sh
cd ../

# setup prometheus-cc
cd prometheus-cc
./setup.sh
cd ../
