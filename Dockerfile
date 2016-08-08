
FROM ubuntu:16.04
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

ENV PETPVC_VERSION master
ENV ITK_VERSION v4.10.0
ENV VTK_VERSION v7.0.0
ENV SIMPLEITK_VERSION v0.10.0
ENV ANTS_VERSION v2.1.0
ENV N_CPUS 2

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
ENV SOFT $HOME
ENV BASHRC $HOME/.bashrc

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


#-------------------------------------------------------------------------------
# VTK (http://www.vtk.org)
#-------------------------------------------------------------------------------
RUN apt-get -y build-dep vtk6

RUN \
    mkdir vtk && \
    cd vtk && \
    git clone https://gitlab.kitware.com/vtk/vtk.git -b $VTK_VERSION VTK && \
    mkdir build && \
    cd build && \
    cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 \
          -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 \
          -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m \
          -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 \
          ../VTK && \
    make -j $N_CPUS && \
    make install && \
    cd ../..

RUN ldconfig


#-------------------------------------------------------------------------------
# ITK
#-------------------------------------------------------------------------------
# RUN \
#     mkdir itk && \
#     cd itk && \
#     git clone http://itk.org/ITK.git -b $ITK_VERSION && \
#     mkdir build && \
#     cd build && \
#     cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#           -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 \
#           -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m \
#           -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 \
#           ../ITK && \
#     make -j $N_CPUS && \
#     make install && \
#     cd ../..

# RUN \
#   echo "addlibpath $pwd/itk/build/lib" >> $BASHRC && \
#   echo "addapath $pwd/itk/build/bin" >> $BASHRC

# RUN ldconfig


#-------------------------------------------------------------------------------
# SimpleITK
#-------------------------------------------------------------------------------
# RUN \
#     mkdir simpleitk && \
#     cd simpleitk && \
#     git clone --recursive http://itk.org/SimpleITK.git -b $SIMPLEITK_VERSION && \
#     mkdir build && \
#     cd build && \
#     cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 -DWRAP_JAVA=OFF -DWRAP_CSHARP=OFF -DWRAP_RUBY=OFF ../SimpleITK/SuperBuild && \
#     make -j $N_CPUS && \
#     cd ../..
#
# RUN echo "addlibpath $pwd/simpleitk/build/lib" >> $BASHRC


#-------------------------------------------------------------------------------
# AFNI
# https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_linux_ubuntu.html#install-steps-linux-ubuntu
#-------------------------------------------------------------------------------
RUN \
    apt-get install -y tcsh xfonts-base python-qt4  && \
    apt-get install -y libxm4 libuil4 libmrm4 libmotif-common libmotif-dev motif-clients && \
    apt-get install -y gsl-bin netpbm gnome-tweak-tool libjpeg62 && \
    apt-get update && \
    ln -s /usr/lib/x86_64-linux-gnu/libgsl.so /usr/lib/libgsl.so.0 && \
    wget -c http://mirrors.kernel.org/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb && \
    dpkg -i libxp6_1.0.2-2_amd64.deb && \
    apt-get install -f

RUN \
    curl -O https://afni.nimh.nih.gov/pub/dist/bin/linux_fedora_21_64/@update.afni.binaries && \
    chsh -s /usr/bin/tcsh && \
    tcsh @update.afni.binaries -package linux_openmp_64 -do_extras && \
    chsh -s /bin/bash;

RUN \
    cp $HOME/abin/AFNI.afnirc $HOME/.afnirc && \
    $HOME/abin/suma -updated_env

RUN \
    echo "addapath $HOME/abin" >> $BASHRC


#-------------------------------------------------------------------------------
# ANTS (https://github.com/stnava/ANTs)
#-------------------------------------------------------------------------------
RUN \
    mkdir ants && \
    cd ants && \
    git clone https://github.com/stnava/ANTs.git -b $ANTS_VERSION  && \
    mkdir build && \
    cd build && \
    cmake -DUSE_VTK=ON -DUSE_SYSTEM_VTK=ON -DVTK_DIR=$HOME/vtk/build && \
    make -j $N_CPUS && \
    make install && \
    cd ../..

RUN \
    echo "export ANTSPATH=${HOME}/ants/build/bin" >> $BASHRC && \
    echo "addapath $ANTSPATH" >> $BASHRC

RUN ldconfig

#-------------------------------------------------------------------------------
# PETPVC (https://github.com/UCL/PETPVC)
#-------------------------------------------------------------------------------
RUN \
    mkdir petpvc && \
    cd petpvc && \
    git clone https://github.com/UCL/PETPVC.git -b $PETPVC_VERSION && \
    mkdir build && \
    cd build && \
    cmake -DITK_DIR=$HOME/ants/build/ITKv4-build && \
    make -j $N_CPUS && \
    cd ../..; \

RUN echo "addapath $HOME/petpvc/build/src" >> $BASHRC


RUN ldconfig

#-------------------------------------------------------------------------------
# Camino (http://camino.cs.ucl.ac.uk/)
#-------------------------------------------------------------------------------
RUN \
    git clone git://git.code.sf.net/p/camino/code camino

RUN \
    echo "export MANPATH=$HOME/camino/man:$MANPATH" >> $BASHRC && \
    echo "addapath $HOME/camino/bin" >> $BASHRC

#-------------------------------------------------------------------------------
# FSL (http://fsl.fmrib.ox.ac.uk)
#-------------------------------------------------------------------------------
RUN \
    apt-get install -y fsl-complete && \
    echo "source /etc/fsl/5.0/fsl.sh" >> $BASHRC && \
    echo "export FSLPARALLEL=condor" >> $BASHRC

#-------------------------------------------------------------------------------
# Python environment with virtualenvwrapper
#-------------------------------------------------------------------------------
RUN \
    pip instal virtualenvwrapper && \
    source /usr/local/bin/virtualenvwrapper.sh && \
    mkvirtualenv -p /usr/bin/python3 pytre && \
    pip install -r root/pypes_requirements.txt

ENV WORKON_HOME $HOME/pyenvs

RUN \
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> $BASHRC && \
    echo "export WORKON_HOME=$HOME/pyenvs" >> $BASHRC && \
    echo "workon pytre" >> $BASHRC

#-------------------------------------------------------------------------------
# source .bashrc
RUN source $BASHRC
