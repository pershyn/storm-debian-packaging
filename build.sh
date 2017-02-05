#!/bin/bash

# Build the binary debian packages for apache-storm
pushd apache-storm
dpkg-buildpackage -b -rfakeroot
popd

# Write down sample layouts for build packages
for pkg in $(ls storm*.deb)
do
	dpkg -c $pkg > ./sample-layout/$(cut -d '_' -f 1 <<< $pkg).sample-layout.txt
done

