## Ubuntu Dockerfile


This repository contains a **Dockerfile** of [Ubuntu](http://www.ubuntu.com/) for NeuroImaging.

It sets up [NeuroDebian](http://neuro.debian.net) and installs:
- fsl-complete
- AFNI
- VTK
- ITK and SimpleITK (the code for this is commented for now)
- DCM2NIIX
- PETPVC
- ANTs
- SPM12 with MCR
- Python and the NiPy tools
- Neurita/boyle and pypes

### Base Docker Image

* [ubuntu:16.04](https://registry.hub.docker.com/u/library/ubuntu/)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Clone this repository and `cd` into it.

    ```bash
    git clone https://github.com/Neurita/neuro_docker.git

    cd neuro_docker
    ```

3. Build the docker image.

    ```bash
    docker build -t="dockerfile/neuro" .
    ```


### Usage

After a successful installation, you can run the docker container and run your analysis.

```bash
docker run -it dockerfile/neuro
```

#### Data sharing

If you want to share with the container a folder path with data, you can run the following command:

```bash
docker run -it -v <host_path>:<guest_path> dockerfile/neuro
```

For example, if you have some data in `/media/data/brains` and you would like it to be accessible in the container in `/data`. You should run:

```bash
docker run -it -v /media/data/brains:/data dockerfile/neuro
```

#### The Conda Python environment

This Dockerfile will setup a [Conda Python environment](https://conda.io/miniconda.html) with the Python dependencies for [Pypes](http://pypes.readthedocs.io/).

Once inside the container, to start using the Conda Python environment run:

```bash
source activate
```

#### Installing more Debian packages

The Dockerfile clears up the `apt` repository index after installing the needed dependencies.

If you want to install more packages, first you have to recreate this index. To do this, run:

```bash
apt-get update
```

#### Notes

Remember to add the `--rm` flag to the `docker run` command if you don't want to store a new container after exiting it. This will save you disk space.

Have a better understanding of the `docker run` command by running:

```bash
docker run --help
```
