#!/bin/bash

pushd apache-storm

dpkg-buildpackage -b -rfakeroot

popd
