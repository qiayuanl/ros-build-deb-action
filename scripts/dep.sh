#!/bin/bash
ros_distro=$1

echo "Install packaging tool..."
sudo apt update && sudo apt-get install -y \
    python3-bloom \
    fakeroot \
    dh-make \
    devscripts
pip install shyaml
pip3 uninstall empy
pip3 install empy==3.3.4
