
FROM debian:jessie
#FROM ubuntu:16.04
MAINTAINER Alexandre Savio <alexsavio@gmail.com>

RUN ln -snf /bin/bash /bin/sh

ENV PETPVC_VERSION master
ENV ITK_VERSION v4.10.0
ENV VTK_VERSION v6.3.0
ENV SIMPLEITK_VERSION v0.10.0
ENV ANTS_VERSION v2.1.0
ENV N_CPUS 2

#ENV NEURODEBIAN_URL http://neuro.debian.net/lists/xenial.de-md.full
ENV NEURODEBIAN_URL http://neuro.debian.net/lists/jessie.de-m.full
ENV LIBXP_URL http://mirrors.kernel.org/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb
ENV AFNI_URL https://afni.nimh.nih.gov/pub/dist/bin/linux_fedora_21_64/@update.afni.binaries

ENV VTK_GIT https://gitlab.kitware.com/vtk/vtk.git
ENV ITK_GIT http://itk.org/ITK.git
ENV SIMPLEITK_GIT http://itk.org/SimpleITK.git
ENV PETPVC_GIT https://github.com/UCL/PETPVC.git
ENV CAMINO_GIT git://git.code.sf.net/p/camino/code
ENV ANTS_GIT https://github.com/stnava/ANTs.git
ENV PYENV_NAME pytre

## Configure default locale

#RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
#    locale-gen en_US.utf8 && \
#    /usr/sbin/update-locale LANG=en_US.UTF-8

# Set environment
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

ENV HOME /work
ENV SOFT $HOME/soft
ENV BASHRC $HOME/.bashrc

# Create a non-priviledge user that will run the services
ENV BASICUSER basicuser
ENV BASICUSER_UID 1000

RUN useradd -m -d /work -s /bin/bash -N -u $BASICUSER_UID $BASICUSER && \
    chown $BASICUSER /work
USER $BASICUSER
WORKDIR $HOME

# Add files.
ADD root/.bashrc $BASHRC
ADD root/.gitconfig $HOME/.gitconfig
ADD root/.scripts $HOME/.scripts
ADD root/.nipype $HOME/.nipype
ADD patches $HOME/patches
ADD root/pypes_requirements.txt $HOME/pypes_requirements.txt

# define a variable for the path where the software is installed
RUN \
    mkdir $SOFT && \
    echo "export SOFT=$HOME/soft" >> $BASHRC


# neurodebian and Install.
RUN \
    wget -O- $NEURODEBIAN_URL | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y build-essential && \
    apt-get install -y software-properties-common && \
    apt-get install -y \
byobu \
ssh \
curl \
git \
htop \
unzip \
vim \
wget \
xvfb \
bzip2 \
unzip \
apt-utils \
fusefat \
graphviz \
cmake \
gcc-4.9 \
g++-4.9 \
gfortran-4.9 \
tcsh \
xfonts-base \
python-qt4 \
libxm4 \
libuil4 \
libmrm4 \
libmotif-common \
libmotif-dev \
motif-clients \
gsl-bin \
netpbm \
gnome-tweak-tool \
libjpeg62 \
libxml2-dev \
libxslt1-dev \
mricron \
dicomnifti \
fsl-core \
fsl-atlases \
fsl-5.0-eddy-nonfree \
python3-dev \
python3-pip \
python3-virtualenv \
python3-tk && \
    ln -s /usr/lib/x86_64-linux-gnu/libgsl.so /usr/lib/libgsl.so.0
    apt-get -y build-dep vtk6 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5   40 --slave /usr/bin/g++ g++ /usr/bin/g++-5 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.9 && \
    rm -rf /var/lib/apt/lists/*

#-------------------------------------------------------------------------------
# VTK (http://www.vtk.org)
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
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
# ITK
#-------------------------------------------------------------------------------
# RUN \
#     cd $SOFT && \
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
#     echo "addlibpath $SOFT/simpleitk/build/lib" >> $BASHRC


#-------------------------------------------------------------------------------
# AFNI
# https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_linux_ubuntu.html#install-steps-linux-ubuntu
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    wget -c $LIBXP_URL && \
    dpkg -i `basename $LIBXP_URL` && \
    apt-get install -f  && \
    curl -O $AFNI_URL && \
    ["chsh", "-s", "/usr/bin/tcsh"] && \
    ["tcsh", "@update.afni.binaries", "-package", "linux_openmp_64", "-do_extras"] && \
    ["chsh", "-s", "/bin/bash"] && \
    cp $HOME/abin/AFNI.afnirc $HOME/.afnirc && \
    echo "addpath $HOME/abin" >> $BASHRC


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
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DUSE_VTK=ON \
          -DUSE_SYSTEM_VTK=ON \
          -DVTK_DIR=$SOFT/vtk/build \
          ../ANTs && \
    make -j $N_CPUS && \
    echo "export ANTSPATH=${SOFT}/ants/build/bin" >> $BASHRC && \
    echo 'addpath $ANTSPATH' >> $BASHRC

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
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DITK_DIR=$SOFT/ants/build/ITKv4-build \
          ../PETPVC && \
    make -j $N_CPUS && \
    echo "addpath ${SOFT}/petpvc/build/src" >> $BASHRC

#-------------------------------------------------------------------------------
# Camino (http://camino.cs.ucl.ac.uk/)
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
# FSL (http://fsl.fmrib.ox.ac.uk)
#-------------------------------------------------------------------------------
RUN \
    cd $SOFT && \
    git clone $CAMINO_GIT camino && \
    echo "addpath ${SOFT}/camino/bin" >> $BASHRC && \
    echo "source /etc/fsl/5.0/fsl.sh" >> $BASHRC && \
    echo "export FSLPARALLEL=condor"  >> $BASHRC

#-------------------------------------------------------------------------------
# MATLAB and toolboxes
#-------------------------------------------------------------------------------
ENV MCR_DIR $SOFT/mcr

RUN \
    cd $SOFT && \
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
    echo "export MCR_DIR=$SOFT/mcr/v85" >> $BASHRC && \
    echo "addpath $MCR_DIR/bin"         >> $BASHRC && \
    cd $SOFT && \
    curl -sSL http://www.fil.ion.ucl.ac.uk/spm/download/restricted/utopia/dev/spm12_r6472_Linux_R2015a.zip \
         -o spm12.zip && \
    unzip spm12.zip && \
    rm -rf spm12.zip && \
    echo "export SPM_DIR=$SOFT/spm12"                               >> $BASHRC && \
    echo "export SPMMCRCMD='$SPM_DIR/run_spm12.sh $MCR_DIR script'" >> $BASHRC && \
    echo "export FORCE_SPMMCR=1"                                    >> $BASHRC

ENV MCR_DIR $SOFT/mcr/v85
ENV SPM_DIR $SOFT/spm12
ENV SPMMCRCMD "$SPM_DIR/run_spm12.sh $MCR_DIR script"
ENV FORCE_SPMMCR 1

#-------------------------------------------------------------------------------
# Python environment with virtualenvwrapper
#-------------------------------------------------------------------------------
RUN \
    pip3 install -U pip setuptools virtualenvwrapper && \
    export VIRTUALENVWRAPPER_PYTHON=`which python3` && \
    export WORKON_HOME=$HOME/pyenvs && \
    source /usr/local/bin/virtualenvwrapper.sh && \
    mkvirtualenv -p /usr/bin/python3 $PYENV_NAME && \
    source $WORKON_HOME/$PYENV_NAME/bin/activate && \
    pip install cython && \
    pip install numpy scipy && \
    pip install -r $HOME/pypes_requirements.txt && \
    echo "export VIRTUALENVWRAPPER_PYTHON=`which python3`" >> $BASHRC && \
    echo "export WORKON_HOME=$HOME/pyenvs"                 >> $BASHRC && \
    echo "source /usr/local/bin/virtualenvwrapper.sh"      >> $BASHRC && \
    echo "workon $PYENV_NAME"                              >> $BASHRC

#-------------------------------------------------------------------------------
# source .bashrc
#-------------------------------------------------------------------------------
RUN source $BASHRC && \
    ldconfig

CMD ["/bin/bash"]
