## Ubuntu Dockerfile


This repository contains a **Dockerfile** of [Ubuntu](http://www.ubuntu.com/) for NeuroImaging.

It sets up [NeuroDebian](http://neuro.debian.net) and installs:
- fsl-complete
- VTK and ITK
- PETPVC
-

### Base Docker Image

* [ubuntu:16.04](https://registry.hub.docker.com/u/library/ubuntu/)


### Installation

1. Install [Docker](https://www.docker.com/).

2. Clone this repository and `cd` into it.

3. Build the docker image. `docker build -t="dockerfile/neuro"`

### Usage

    docker run -it --rm dockerfile/neuro
