FROM debian:wheezy
MAINTAINER Michael Pershyn michael.pershyn@gmail.com

LABEL Description="This image is used to build storm *.deb package"

RUN mkdir /mnt/workdir
VOLUME /mnt/workdir
WORKDIR /mnt/workdir

RUN apt-get update && apt-get install -y \
    git \
    g++ \
    uuid-dev \
    make \
    wget \
    libtool \
    openjdk-6-jdk \
    pkg-config \
    autoconf \
    automake \
    unzip \
    dpkg-dev \
    fakeroot \
    debhelper
