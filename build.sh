#!/bin/bash

# Build the binary debian packages for apache-storm
pushd apache-storm
dpkg-buildpackage -b -rfakeroot
popd

# Write down sample layouts for build packages
for pkg in $(ls storm*.deb)
do
	echo
	echo "File layout for package $pkg:"
	echo
	dpkg -c $pkg 
done

