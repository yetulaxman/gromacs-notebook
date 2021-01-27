# docker build -t gromacs/tutorial -f gromacs-notebook.dockerfile .
#
# Note the availability of the DOCKER_CORES build-arg when multiple CPUs are
# available to docker on the build host (though changing the value will invalidate
# cached build layers).
# E.g. docker build -t gromacs/tutorial -f gromacs-notebook.dockerfile --build-arg DOCKER_CORES=4 .
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
from base as gromacs2021

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

ENV HOME /home/tutorial
RUN groupadd -r tutorial && useradd -m -d $HOME -s /bin/bash -g tutorial tutorial

# Switch from `root` to non-root user for the rest of the build and for default container execution.
USER tutorial

WORKDIR $HOME

ENV VENV $HOME/venv
RUN python3 -m venv $VENV
RUN . $VENV/bin/activate && \
    pip install --no-cache-dir --upgrade pip setuptools

COPY --from=gromacs2021 /usr/local/gromacs /usr/local/gromacs

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
RUN . $VENV/bin/activate && \
    . /usr/local/gromacs/bin/GMXRC && \
    pip install --no-cache-dir mpi4py scikit-build && \
    pip install --no-cache-dir --pre gmxapi


# Set up and build the user environment.
from userbase as sample_restraint

COPY --from=gromacs2021 --chown=tutorial:tutorial /gromacs-2021-rc1/python_packaging/sample_restraint $HOME/sample_restraint

RUN . $VENV/bin/activate && \
    . /usr/local/gromacs/bin/GMXRC && \
    (cd $HOME/sample_restraint && \
     mkdir build && \
     cd build && \
     cmake .. \
             -DDOWNLOAD_GOOGLETEST=ON \
             -DGMXAPI_EXTENSION_DOWNLOAD_PYBIND=ON && \
     make -j4 && \
     make test && \
     make install \
    )

from userbase as user

COPY --from=sample_restraint --chown=tutorial:tutorial $VENV $VENV

# From https://gitlab.com/gromacs/gromacs/-/blob/master/python_packaging/docker/notebook.dockerfile

# The tutorials repository is not public. Since we are building a Singularity
# SIF from this Docker image, we will not include additional content,
# and we need to separately arrange for users to
#     git clone https://gitlab.com/gromacs/tutorials.git

ADD notebook /docker_entry_points/

# For the workshop, we will use Singularity, so Docker entry points are irrelevant.
#CMD ["notebook"]
