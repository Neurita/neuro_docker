
FROM ubuntu:16.04
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu ssh curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get install linux-generic

# Add files.
ADD root/.bashrc /root/.bashrc
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts

EXPOSE 22

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]

# neurodebian
wget -O- http://neuro.debian.net/lists/xenial.de-md.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:800xA5D32F012649A5A9

apt-get update

apt-get install fsl-complete

RUN source /etc/fsl/5.0/fsl.sh
ENV FSLPARALLEL=condor
