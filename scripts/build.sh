#!/bin/bash
ros_distro=$1
ros_workspace='/tmp/catkin_build'

source /opt/ros/$ros_distro/setup.bash

mkdir -p $ros_workspace/src/
cp -r ./ $ros_workspace/src/

echo 'Installing dependence..'
rosdep update > /dev/null
rosdep install --from-paths $ros_workspace/src --ignore-packages-from-source --rosdistro $ros_distro -y -r > /dev/null
catkin_make -C $ros_workspace
rosdep update > /dev/null
echo "::set-output name=catkin-ws-directory::$(echo $ros_workspace)"
