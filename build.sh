#!/bin/bash

pushd buildroot

dpkg-buildpackage -rfakeroot

popd
