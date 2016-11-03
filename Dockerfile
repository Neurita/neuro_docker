
#FROM debian:jessie
FROM ubuntu:16.04
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

RUN ln -snf /bin/bash /bin/sh

ARG DEBIAN_FRONTEND=noninteractive

ENV PETPVC_VERSION master
ENV PETPVC_GIT https://github.com/UCL/PETPVC.git

ENV ITK_VERSION v4.10.0
ENV ITK_GIT http://itk.org/ITK.git

ENV VTK_VERSION v6.3.0
ENV VTK_GIT https://gitlab.kitware.com/vtk/vtk.git

ENV SIMPLEITK_VERSION v0.10.0
ENV SIMPLEITK_GIT http://itk.org/SimpleITK.git

ENV ANTS_VERSION v2.1.0
ENV ANTS_GIT https://github.com/stnava/ANTs.git

ENV DCM2NIIX_VERSION 20160606
ENV DCM2NIIX_GIT https://github.com/neurolabusc/dcm2niix.git

ENV NEURODEBIAN_URL http://neuro.debian.net/lists/xenial.de-md.full
#ENV NEURODEBIAN_URL http://neuro.debian.net/lists/jessie.de-m.full
ENV LIBXP_URL http://mirrors.kernel.org/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb
ENV AFNI_URL https://afni.nimh.nih.gov/pub/dist/bin/linux_fedora_21_64/@update.afni.binaries
ENV CAMINO_GIT git://git.code.sf.net/p/camino/code
ENV SPM12_URL http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_r6906_Linux_R2016b.zip

ENV PYENV_NAME pytre
ENV N_CPUS 2
## Configure default locale

# Debian
#RUN apt-get update && \
#    apt-get -y install apt-utils locales && \
#    dpkg-reconfigure locales && \
#    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
#    locale-gen

# Ubuntu
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.utf8 && \
    /usr/sbin/update-locale LANG=en_US.UTF-8

# Set environment
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TERM xterm

ENV HOME /work
ENV SOFT $HOME/soft
ENV BASHRC $HOME/.bashrc

# Create a non-priviledge user that will run the services
ENV BASICUSER basicuser
ENV BASICUSER_UID 1000

RUN useradd -m -d $HOME -s /bin/bash -N -u $BASICUSER_UID $BASICUSER && \
    mkdir $SOFT && \
    mkdir $HOME/.scripts && \
    mkdir $HOME/.nipype
USER $BASICUSER
WORKDIR $HOME

# Add files.
COPY root/.* $HOME/
COPY root/* $HOME/
COPY root/.scripts/* $HOME/.scripts/
COPY root/.nipype/* $HOME/.nipype/

# neurodebian and Install.
USER root
RUN \
    chown -R $BASICUSER $HOME && \
    echo "export SOFT=\$HOME/soft" >> $BASHRC && \
    echo "source /etc/fsl/5.0/fsl.sh" >> $BASHRC && \
    echo "export FSLPARALLEL=condor"  >> $BASHRC && \
    apt-get update && \
    apt-get install -y wget bzip2 unzip htop curl git && \
    wget -O- $NEURODEBIAN_URL | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y \
cmake \
gcc-4.9 \
g++-4.9 \
gfortran-4.9 \
tcsh \
libjpeg62 \
libxml2-dev \
libxslt1-dev \
dicomnifti \
dcm2niix \
#fsl-atlases \
fsl-5.0-eddy-nonfree \
fsl-5.0-core \
&& ln -s /usr/lib/x86_64-linux-gnu/libgsl.so /usr/lib/libgsl.so.0 && \
apt-get -y build-dep vtk6 && \
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5   40 --slave /usr/bin/g++ g++ /usr/bin/g++-5 && \
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 && \
rm -rf /var/lib/apt/lists/*

#-------------------------------------------------------------------------------
# DCM2NIIX
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir dcm2niix && \
    cd dcm2niix && \
    git clone $DCM2NIIX_GIT -b $DCM2NIIX_VERSION DCM2NIIX && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          ../DCM2NIIX && \
    make -j $N_CPUS && \
    make install && \
    cd ../.. && \
    rm -rf dcm2niix

#-------------------------------------------------------------------------------
# VTK (http://www.vtk.org)
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir vtk && \
    cd vtk && \
    git clone $VTK_GIT -b $VTK_VERSION VTK && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DPYTHON_EXECUTABLE=/usr/bin/python2.7 \
          -DPYTHON_INCLUDE_DIR=/usr/include/python2.7 \
          -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python2.7m \
          -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython2.7m.so.1 \
          ../VTK && \
    make -j $N_CPUS && \
    make install

#-------------------------------------------------------------------------------
# AFNI
# https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_linux_ubuntu.html#install-steps-linux-ubuntu
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    wget -c $LIBXP_URL && \
    dpkg -i `basename $LIBXP_URL` && \
    apt-get install -f  && \
    curl -O $AFNI_URL && \
    chsh -s /usr/bin/tcsh && \
    tcsh @update.afni.binaries -package linux_openmp_64 -do_extras && \
    chsh -s /bin/bash && \
    cp $HOME/abin/AFNI.afnirc $HOME/.afnirc && \
    echo "addpath \$HOME/abin" >> $BASHRC && \
    chown -R $BASICUSER $HOME/abin


#-------------------------------------------------------------------------------
## Here start the libraries that won't be installed in /usr/local
USER $BASICUSER

#-------------------------------------------------------------------------------
# ITK
#-------------------------------------------------------------------------------
# WORKDIR $SOFT
# RUN \
#     mkdir itk && \
#     cd itk && \
#     git clone $ITK_GIT -b $ITK_VERSION && \
#     mkdir build && \
#     cd build && \
    # cmake -DCMAKE_BUILD_TYPE=Release \
    #       -DPYTHON_EXECUTABLE=/usr/bin/python2.7 \
    #       -DPYTHON_INCLUDE_DIR=/usr/include/python2.7 \
    #       -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python2.7m \
    #       -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython2.7m.so.1 \
#           ../ITK && \
#     make -j $N_CPUS && \
#     make install && \
#   echo "addpath \$SOFT/itk/build/bin" >> $BASHRC

# RUN ldconfig


#-------------------------------------------------------------------------------
# SimpleITK
#-------------------------------------------------------------------------------
# WORKDIR $SOFT
# RUN \
#     mkdir simpleitk && \
#     cd simpleitk && \
#     git clone --recursive $SIMPLEITK_GIT -b $SIMPLEITK_VERSION && \
#     mkdir build && \
#     cd build && \
#     cmake  -DCMAKE_BUILD_TYPE=Release \
#            -DPYTHON_EXECUTABLE=/usr/bin/python3 \
#            -DPYTHON_INCLUDE_DIR=/usr/include/python3.5 \
#            -DPYTHON_INCLUDE_DIR=/usr/include/x86_64-linux-gnu/python3.5m \
#            -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.5m.so.1 \
#            -DWRAP_JAVA=OFF \
#            -DWRAP_CSHARP=OFF \
#            -DWRAP_RUBY=OFF \
#            ../SimpleITK/SuperBuild && \
#     make -j $N_CPUS && \
#     echo "addlibpath \$SOFT/simpleitk/build/lib" >> $BASHRC


#-------------------------------------------------------------------------------
# ANTS (https://github.com/stnava/ANTs)
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir ants && \
    cd ants && \
    git clone $ANTS_GIT -b $ANTS_VERSION ANTs && \
    cd ANTs && \
    git apply $HOME/ANTs_0001-fix-ifstream-error.patch && \
    cd .. && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DUSE_VTK=ON \
          -DUSE_SYSTEM_VTK=ON \
          -DVTK_DIR=$SOFT/vtk/build \
          ../ANTs && \
    make -j $N_CPUS && \
    echo "export ANTSPATH=\${SOFT}/ants/build/bin" >> $BASHRC && \
    echo 'addpath \$ANTSPATH' >> $BASHRC

#-------------------------------------------------------------------------------
# PETPVC (https://github.com/UCL/PETPVC)
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    mkdir petpvc && \
    cd petpvc && \
    git clone $PETPVC_GIT -b $PETPVC_VERSION && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DITK_DIR=$SOFT/ants/build/ITKv4-build \
          ../PETPVC && \
    make -j $N_CPUS && \
    echo "addpath \${SOFT}/petpvc/build/src" >> $BASHRC

#-------------------------------------------------------------------------------
# Camino (http://camino.cs.ucl.ac.uk/)
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# FSL (http://fsl.fmrib.ox.ac.uk)
#-------------------------------------------------------------------------------
WORKDIR $SOFT
RUN \
    git clone $CAMINO_GIT camino && \
    echo "addpath \${SOFT}/camino/bin" >> $BASHRC

#-------------------------------------------------------------------------------
# MATLAB and toolboxes
#-------------------------------------------------------------------------------
ENV MCR_DIR $SOFT/mcr

WORKDIR $SOFT
RUN \
    echo "destinationFolder=$MCR_DIR" > mcr_options.txt && \
    echo "agreeToLicense=yes" >> mcr_options.txt && \
    echo "outputFile=/tmp/matlabinstall_log" >> mcr_options.txt && \
    echo "mode=silent" >> mcr_options.txt && \
    mkdir -p matlab_installer && \
    curl -sSL http://www.mathworks.com/supportfiles/downloads/R2015a/deployment_files/R2015a/installers/glnxa64/MCR_R2015a_glnxa64_installer.zip \
         -o matlab_installer/installer.zip && \
    unzip matlab_installer/installer.zip -d matlab_installer/ && \
    matlab_installer/install -inputFile mcr_options.txt && \
    rm -rf matlab_installer mcr_options.txt && \
    echo "export MCR_DIR=\$SOFT/mcr/v85" >> $BASHRC && \
    echo "addpath \$MCR_DIR/bin"         >> $BASHRC && \
    cd $SOFT && \
    curl -sSL $SPM12_URL -o spm12.zip && \
    unzip spm12.zip && \
    rm -rf spm12.zip && \
    echo "export SPM_DIR=\$SOFT/spm12"                                 >> $BASHRC && \
    echo "export SPMMCRCMD='\$SPM_DIR/run_spm12.sh \$MCR_DIR script'" >> $BASHRC && \
    echo "export FORCE_SPMMCR=1"                                      >> $BASHRC

ENV MCR_DIR $SOFT/mcr/v85
ENV SPM_DIR $SOFT/spm12
ENV SPMMCRCMD "$SPM_DIR/run_spm12.sh $MCR_DIR script"
ENV FORCE_SPMMCR 1

#-------------------------------------------------------------------------------
# Python environment with virtualenvwrapper
#-------------------------------------------------------------------------------
# Install Python 3 from miniconda

ENV PATH="$HOME/miniconda/bin:$PATH"

WORKDIR $SOFT
RUN \
  wget -O miniconda.sh \
     https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
  bash miniconda.sh -b -p $HOME/miniconda && \
  rm miniconda.sh && \
  echo "addpath \$HOME/miniconda/bin" >> $BASHRC && \
  conda update -y python conda && \
  conda config --add channels conda-forge && \
  conda install -y --no-deps \
matplotlib \
cycler \
freetype \
libpng \
pyparsing \
pytz \
python-dateutil \
six \
pip \
setuptools \
numpy \
scipy \
pandas \
scipy \
scikit-learn \
scikit-image \
statsmodels \
networkx \
pillow \
openblas \
&& conda clean -tipsy

# Install the other requirements
RUN pip install -r $HOME/requirements.txt && \
    rm -rf ~/.cache/pip/ && \
    source $BASHRC

#-------------------------------------------------------------------------------
# source .bashrc
#-------------------------------------------------------------------------------
USER root
RUN ldconfig

CMD ["/bin/bash"]
