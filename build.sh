#!/bin/bash

pushd storm-deb-packaging

dpkg-buildpackage -rfakeroot

popd
