
FROM ubuntu:16.04
RUN ln -snf /bin/bash /bin/sh
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

ENV PETPVC_VERSION master
ENV ITK_VERSION v4.10.0
ENV VTK_VERSION v6.3.0
ENV SIMPLEITK_VERSION v0.10.0
ENV ANTS_VERSION v2.1.0
ENV N_CPUS 2

ENV NEURODEBIAN_URL http://neuro.debian.net/lists/xenial.de-md.full
ENV LIBXP_URL http://mirrors.kernel.org/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb
ENV AFNI_URL https://afni.nimh.nih.gov/pub/dist/bin/linux_fedora_21_64/@update.afni.binaries

ENV VTK_GIT https://gitlab.kitware.com/vtk/vtk.git
ENV ITK_GIT http://itk.org/ITK.git
ENV SIMPLEITK_GIT http://itk.org/SimpleITK.git
ENV PETPVC_GIT https://github.com/UCL/PETPVC.git
ENV CAMINO_GIT git://git.code.sf.net/p/camino/code
ENV ANTS_GIT https://github.com/stnava/ANTs.git
ENV PYENV_NAME pytre

# Install.
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu \
                     ssh \
                     curl \
                     git \
                     htop \
                     man \
                     unzip \
                     vim \
                     wget \
                     xvfb \
                     bzip2 \
                     unzip \
                     apt-utils \
                     fusefat \
                     graphviz

EXPOSE 22

# Set environment variables.
ENV HOME /root
ENV SOFT /root/soft
ENV BASHRC /root/.bashrc

# Add files.
ADD root/.bashrc $BASHRC
ADD root/.gitconfig /root/.gitconfig
ADD root/.scripts /root/.scripts
ADD root/.nipype /root/.nipype
ADD patches /root/patches

# Define working directory.
WORKDIR /root

# Python
RUN apt-get install -y python3-dev python3-pip python3-virtualenv

# Build tools
RUN \
  apt-get install -y cmake gcc-4.9 g++-4.9 gfortran-4.9

RUN \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5   40 --slave /usr/bin/g++ g++ /usr/bin/g++-5 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9

# neurodebian
RUN wget -O- $NEURODEBIAN_URL | tee /etc/apt/sources.list.d/neurodebian.sources.list

RUN \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    apt-get update

# define a variable for the path where the software is installed
RUN \
    mkdir $SOFT && \
    echo "export SOFT=$HOME/soft" >> $BASHRC

#-------------------------------------------------------------------------------
# VTK (http://www.vtk.org)
#-------------------------------------------------------------------------------
RUN apt-get -y build-dep vtk6

RUN \
    cd $SOFT && \
    mkdir vtk && \
    cd vtk && \
    git clone $VTK_GIT -b $VTK_VERSION VTK && \
    mkdir build && \
    cd build && \
    cmake -DPYTHON_EXECUTABLE=/usr/bin/python2.7 \
          -DPYTHON_INCLUDE_DIR=/usr/include/python2.7 \
          -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python2.7m \
          -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython2.7m.so.1 \
          ../VTK && \
    make -j $N_CPUS && \
    make install

RUN ldconfig


#-------------------------------------------------------------------------------
# ITK
#-------------------------------------------------------------------------------
# RUN \
#     cd $SOFT && \
#     mkdir itk && \
#     cd itk && \
#     git clone $ITK_GIT -b $ITK_VERSION && \
#     mkdir build && \
#     cd build && \
    # cmake -DPYTHON_EXECUTABLE=/usr/bin/python2.7 \
    #       -DPYTHON_INCLUDE_DIR=/usr/include/python2.7 \
    #       -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python2.7m \
    #       -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython2.7m.so.1 \
#           ../ITK && \
#     make -j $N_CPUS && \
#     make install

# RUN \
#   echo "addlibpath $SOFT/itk/build/lib" >> $BASHRC && \
#   echo "addpath $SOFT/itk/build/bin" >> $BASHRC

# RUN ldconfig


#-------------------------------------------------------------------------------
# SimpleITK
#-------------------------------------------------------------------------------
# RUN \
#     cd $SOFT && \
#     mkdir simpleitk && \
#     cd simpleitk && \
#     git clone --recursive $SIMPLEITK_GIT -b $SIMPLEITK_VERSION && \
#     mkdir build && \
#     cd build && \
#     cmake \
#            -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#            -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 \
#            -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m \
#            -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 \
#            -DWRAP_JAVA=OFF \
#            -DWRAP_CSHARP=OFF \
#            -DWRAP_RUBY=OFF \
#            ../SimpleITK/SuperBuild && \
#     make -j $N_CPUS
#
# RUN echo "addlibpath $SOFT/simpleitk/build/lib" >> $BASHRC


#-------------------------------------------------------------------------------
# AFNI
# https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_linux_ubuntu.html#install-steps-linux-ubuntu
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    apt-get install -y tcsh xfonts-base python-qt4  && \
    apt-get install -y libxm4 libuil4 libmrm4 libmotif-common libmotif-dev motif-clients && \
    apt-get install -y gsl-bin netpbm gnome-tweak-tool libjpeg62 && \
    apt-get update && \
    ln -s /usr/lib/x86_64-linux-gnu/libgsl.so /usr/lib/libgsl.so.0 && \
    wget -c $LIBXP_URL && \
    dpkg -i `basename $LIBXP_URL` && \
    apt-get install -f

RUN curl -O $AFNI_URL

RUN ["chsh", "-s", "/usr/bin/tcsh"]
RUN ["tcsh", "@update.afni.binaries", "-package", "linux_openmp_64", "-do_extras"]
RUN ["chsh", "-s", "/bin/bash"]

RUN \
    cp $HOME/abin/AFNI.afnirc $HOME/.afnirc && \
    echo "addpath $SOFT/abin" >> $BASHRC


#-------------------------------------------------------------------------------
# ANTS (https://github.com/stnava/ANTs)
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    mkdir ants && \
    cd ants && \
    git clone $ANTS_GIT -b $ANTS_VERSION ANTs && \
    cd ANTs && \
    git apply /root/patches/ANTs/0001-fix-ifstream-error.patch && \
    cd .. && \
    mkdir build && \
    cd build && \
    cmake -DUSE_VTK=ON \
          -DUSE_SYSTEM_VTK=ON \
          -DVTK_DIR=$SOFT/vtk/build \
          ../ANTs && \
    make -j $N_CPUS

RUN \
    echo "export ANTSPATH=${SOFT}/ants/build/bin" >> $BASHRC && \
    echo "addpath $ANTSPATH" >> $BASHRC

RUN ldconfig

#-------------------------------------------------------------------------------
# PETPVC (https://github.com/UCL/PETPVC)
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    mkdir petpvc && \
    cd petpvc && \
    git clone $PETPVC_GIT -b $PETPVC_VERSION && \
    mkdir build && \
    cd build && \
    cmake -DITK_DIR=$SOFT/ants/build/ITKv4-build \
          ../PETPVC && \
    make -j $N_CPUS

RUN echo "addpath ${SOFT}/petpvc/build/src" >> $BASHRC


RUN ldconfig

#-------------------------------------------------------------------------------
# Camino (http://camino.cs.ucl.ac.uk/)
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    git clone $CAMINO_GIT camino

RUN \
    echo "export MANPATH=${SOFT}/camino/man:$MANPATH" >> $BASHRC && \
    echo "addpath ${SOFT}/camino/bin" >> $BASHRC

#-------------------------------------------------------------------------------
# FSL (http://fsl.fmrib.ox.ac.uk)
#-------------------------------------------------------------------------------
RUN \
    apt-get install -y fsl-complete && \
    echo "source /etc/fsl/5.0/fsl.sh" >> $BASHRC && \
    echo "export FSLPARALLEL=condor" >> $BASHRC

#-------------------------------------------------------------------------------
# MATLAB and toolboxes
#-------------------------------------------------------------------------------
RUN echo "destinationFolder=/opt/mcr" > mcr_options.txt && \
    echo "agreeToLicense=yes" >> mcr_options.txt && \
    echo "outputFile=/tmp/matlabinstall_log" >> mcr_options.txt && \
    echo "mode=silent" >> mcr_options.txt && \
    mkdir -p matlab_installer && \
    curl -sSL http://www.mathworks.com/supportfiles/downloads/R2015a/deployment_files/R2015a/installers/glnxa64/MCR_R2015a_glnxa64_installer.zip \
         -o matlab_installer/installer.zip && \
    unzip matlab_installer/installer.zip -d matlab_installer/ && \
    matlab_installer/install -inputFile mcr_options.txt && \
    rm -rf matlab_installer mcr_options.txt

ENV SPMMCRCMD "$SPM_DIR/run_spm12.sh /opt/mcr/v85/ script"
ENV FORCE_SPMMCR 1

RUN \
    echo "export SPMMCRCMD='$SPM_DIR/run_spm12.sh /opt/mcr/v85/ script'" >> $BASHRC && \
    echo "export FORCE_SPMMCR=1" >> $BASHRC && \
    echo "addlibpath /opt/mcr/v85/runtime/glnxa64" >> $BASHRC && \
    echo "addlibpath /opt/mcr/v85/bin/glnxa64" >> $BASHRC && \
    echo "addlibpath /opt/mcr/v85/sys/os/glnxa64" >> $BASHRC

# Install SPM
RUN curl -sSL http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_r6472_Linux_R2015a.zip -o spm12.zip && \
    unzip spm12.zip && \
    rm -rf spm12.zip

#-------------------------------------------------------------------------------
# Python environment with virtualenvwrapper
#-------------------------------------------------------------------------------
RUN \
    pip3 install -U pip setuptools virtualenvwrapper && \
    export VIRTUALENVWRAPPER_PYTHON=`which python3` && \ 
    source /usr/local/bin/virtualenvwrapper.sh && \
    mkvirtualenv --no-site-packages -p /usr/bin/python3 $PYENV_NAME

ENV WORKON_HOME $HOME/pyenvs

RUN \
    echo "VIRTUALENVWRAPPER_PYTHON=`which python3`" >> $BASHRC && \
    echo "source /usr/local/bin/virtualenvwrapper.sh" >> $BASHRC && \
    echo "export WORKON_HOME=$HOME/pyenvs" >> $BASHRC && \
    echo "workon $PYENV_NAME" >> $BASHRC

RUN \
    workon $PYENV_NAME && \
    pip install -r root/pypes_requirements.txt

#-------------------------------------------------------------------------------
# CLEANUP
#-------------------------------------------------------------------------------
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#-------------------------------------------------------------------------------
# source .bashrc
#-------------------------------------------------------------------------------
RUN source $BASHRC

CMD ["/bin/bash"]
