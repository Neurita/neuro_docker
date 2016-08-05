
FROM ubuntu:16.04
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

ENV PETPVC_VERSION master
ENV ITK_VERSION v4.10.0
ENV VTK_VERSION v7.0.0
ENV SIMPLEITK_VERSION v0.10.0


# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu ssh curl git htop man unzip vim wget

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

# Python
RUN apt-get install -y python3-dev python3-pip python3-virtualenv

# Build tools
RUN \
  apt-get install -y cmake

# neurodebian
RUN wget -O- http://neuro.debian.net/lists/xenial.de-md.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    apt-get update

# SimpleITK
RUN \
    mkdir simpleitk && \
    cd simpleitk && \
    git clone --recursive http://itk.org/SimpleITK.git -b $SIMPLEITK_VERSION && \
    mkdir build && \
    cd build && \
    cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 -DWRAP_JAVA=OFF -DWRAP_CSHARP=OFF -DWRAP_RUBY=OFF ../SimpleITK/SuperBuild && \  
    make -j 2 && \
    cd ../..

RUN echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$pwd/simpleitk/build/lib" >> /root/.bashrc

# VTK
RUN \
    mkdir vtk && \
    cd vtk && \
    git clone https://gitlab.kitware.com/vtk/vtk.git -b $VTK_VERSION && \
    mkdir build && \
    cd build && \




    cd ../..


# FSL
#RUN \
#    apt-get install fsl-complete && \
#    source /etc/fsl/5.0/fsl.sh

# ENV FSLPARALLEL=condor
#
#
# # ITK
# RUN \
#     git clone http://itk.org/ITK.git -b $ITK_VERSION
#
#
# # PETPVC
# RUN \
#     mkdir petpvc
#
#     git clone https://github.com/UCL/PETPVC.git
#     cd PETPVC
#     mkdir bu
