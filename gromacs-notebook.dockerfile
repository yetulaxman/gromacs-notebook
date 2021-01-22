# docker build -t gromacs/tutorial -f gromacs-notebook.dockerfile .
#
# From https://gitlab.com/gromacs/gromacs/-/blob/master/python_packaging/docker/gromacs-dependencies.dockerfile

FROM ubuntu:groovy as base

# Basic packages
RUN apt-get update && \
    apt-get -yq --no-install-suggests --no-install-recommends install software-properties-common build-essential && \
    apt-get -yq --no-install-suggests --no-install-recommends install \
        cmake \
        git \
        libblas-dev \
        libfftw3-dev \
        liblapack-dev \
        libxml2-dev \
        make \
        vim \
        wget \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# System Python.
RUN apt-get update && \
    apt-get -yq --no-install-suggests --no-install-recommends install \
        python3 \
        python3-dev \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

# OpenMPI layer
RUN apt-get update && \
    apt-get -yq --no-install-suggests --no-install-recommends install \
         libopenmpi-dev && \
    rm -rf /var/lib/apt/lists/*

# GROMACS 2021
# Adapted from https://gitlab.com/gromacs/gromacs/-/blob/master/python_packaging/docker/gromacs.dockerfile
from base as gromacs

RUN wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-2021-rc1.tar.gz && \
    tar xvf gromacs-2021-rc1.tar.gz

ARG DOCKER_CORES=1

ARG TYPE=Release

RUN cd gromacs-2021-rc1 && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr/local/gromacs \
        -DGMX_THREAD_MPI=ON \
        -DCMAKE_BUILD_TYPE=$TYPE && \
    make -j$DOCKER_CORES && \
    make -j$DOCKER_CORES install

# Switch to the user environment
from base as userbase

RUN groupadd -r tutorial && useradd -m -s /bin/bash -g tutorial tutorial

# Switch from `root` to non-root user for the rest of the build and for default container execution.
USER tutorial

WORKDIR /home/tutorial

ENV VENV /home/tutorial/venv
RUN python3 -m venv $VENV
RUN . $VENV/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools

COPY --from=gromacs /usr/local/gromacs /usr/local/gromacs

# Miniconda3
# Locally cache the miniconda download.
from userbase as conda

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Consider checking the checksum.
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Set up and build the user environment.
from userbase as user

##
# Do we want the Conda stuff?
##
#COPY --from=conda --chown=tutorial:tutorial /home/tutorial/miniconda /home/tutorial/miniconda
#
#ENV CONDA /home/tutorial/miniconda/bin/conda
#
#RUN $CONDA update conda -y
#
#RUN . /home/tutorial/miniconda/bin/activate && $CONDA init bash
#
## Follow procedure from https://github.com/ENCCS/gromacs-workshop-installation
## Maybe avoid graphical parts unless we plan to tunnel X or VNC
##RUN $CONDA create --name gromacs-tutorials -c conda-forge -c bioconda nglview
#RUN $CONDA create --name gromacs-tutorials -c conda-forge -c bioconda gromacs=2020.4 matplotlib notebook numpy requests pandas seaborn
#
#RUN bash -c "$CONDA activate gromacs-tutorials && \
#    $CONDA install -c conda-forge compilers && \
#    $CONDA install -c conda-forge openmpi && \
#    $CONDA install -c conda-forge cmake && \
#    $CONDA install -c conda-forge ocl-icd-system && \
#    $CONDA install scikit-build "


RUN . $VENV/bin/activate && \
    pip install --no-cache-dir jupyter && \
    pip install \
        matplotlib \
        nglview \
        pandas \
        requests \
        seaborn

# gmxapi
# Adapted from https://gitlab.com/gromacs/gromacs/-/blob/master/python_packaging/docker/ci.dockerfile
# TODO: If we aren't building from the GROMACS repository, then we should bump the version on pypi and use that.
#RUN . $VENV/bin/activate && \
#    . /usr/local/gromacs/bin/GMXRC && \
#    pip install --no-cache-dir mpi4py scikit-build && \
#    pip install gmxapi

# TODO: Test sample_restraint plugin code.
#RUN . $VENV/bin/activate && \
#    . /usr/local/gromacs/bin/GMXRC && \
#    (cd $HOME/sample_restraint && \
#     mkdir build && \
#     cd build && \
#     cmake .. \
#             -DDOWNLOAD_GOOGLETEST=ON \
#             -DGMXAPI_EXTENSION_DOWNLOAD_PYBIND=ON && \
#     make -j4 && \
#     make test && \
#     make install \
#    )

# From https://gitlab.com/gromacs/gromacs/-/blob/master/python_packaging/docker/notebook.dockerfile

#FROM user

# The tutorials repository is not public. We can build this docker image from the tutorials repository or choose another way to get the files.
#RUN git clone https://gitlab.com/gromacs/tutorials.git


ADD notebook /docker_entry_points/

# For the workshop, we will use Singularity, so Docker entry points are irrelevant.
#CMD ["notebook"]
