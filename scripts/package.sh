#!/bin/bash
ros_distro=$1
ros_workspace=$2
hastimestamp=$3
tmp_space="/tmp/catkin_binary_deb"

source /opt/ros/$ros_distro/setup.bash
source $ros_workspace/devel/setup.bash

run_directory=`pwd`

time_stamp=`date +%Y%m%d.%H%M%S`

mkdir $tmp_space
cp -r ./ $tmp_space
package_list=`find $tmp_space -name package.xml | sed 's/package.xml//g'`
package_names=$(echo "$package_list" | awk -F '/' '{print $NF}')

echo "Add unreleased packages to rosdep"
rosdep_file="$run_directory/local.yaml"
for PKG in $(catkin_topological_order --only-names $ros_workspace|| colcon list --topological-order --names-only $ros_workspace); do
  printf "%s:\n  %s:\n  - %s\n" "$PKG" "ubuntu" "ros-$ros_distro-$(printf '%s' "$PKG" | tr '_' '-')" >> "$rosdep_file"
  echo "$PKG added" 
done
sudo bash -c 'echo "yaml file://$rosdep_file $ros_distro" >> /etc/ros/rosdep/sources.list.d/1-local.list'
echo $rosdep_file
cat $rosdep_file

# Start packaging
CM_PREFIX_PATH=`sed 's/:/;/g' <<< $CMAKE_PREFIX_PATH`
for package_source in $package_list
do
  echo "Trying to package $package_source..."
  cd $package_source
  bloom-generate rosdebian --os-name ubuntu --ros-distro $ros_distro
  package_version=`dpkg-parsechangelog | grep 'Version:' | sed 's/Version: //g'`
  if test $hastimestamp = "true"; then
    debchange -v $package_version.$time_stamp -p -D -u -m 'Append timestamp when binarydeb was built.'
  fi
  sed -e "s|-DCMAKE_PREFIX_PATH=.*|-DCMAKE_PREFIX_PATH=\""$CM_PREFIX_PATH"\"|g" -i debian/rules
  fakeroot debian/rules binary
  cd $run_directory
done
echo 'Package has been done.'
find $tmp_space/.. -name '*.deb' -o -name '*.ddeb'|xargs -I {} cp {} $run_directory/
