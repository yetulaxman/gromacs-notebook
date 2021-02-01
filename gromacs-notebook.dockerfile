# docker build -t gromacs/tutorial -f gromacs2021.dockerfile ..
#
# Note the availability of the DOCKER_CORES build-arg when multiple CPUs are
# available to docker on the build host (though changing the value will invalidate
# cached build layers).
# E.g. docker build -t gromacs/tutorial -f gromacs2021.dockerfile --build-arg DOCKER_CORES=4 ..
#
# If running this container with Docker (instead of just using as the basis for a Singularity container),
# the /docker_entry_points/notebook entry point script can be used to launch a Jupyter notebook server.
#     docker run --rm -ti -p 8888:8888 gromacs/tutorial /docker_entry_points/notebook
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

RUN wget ftp://ftp.gromacs.org/pub/gromacs/gromacs-2021.tar.gz && \
    tar xvf gromacs-2021.tar.gz

ARG DOCKER_CORES=1

ARG TYPE=Release

RUN cd gromacs-2021 && \
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

ENV TUTORIAL /home/tutorial
RUN groupadd -r tutorial && useradd -m -d $TUTORIAL -s /bin/bash -g tutorial tutorial

# Switch from `root` to non-root user for the rest of the build and for default container execution.
USER tutorial

WORKDIR $TUTORIAL

ENV VENV $TUTORIAL/venv
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
    pip install --no-cache-dir gmxapi

# Enable auto-completion for interfaces like Jupyter notebooks.
RUN . $VENV/bin/activate && \
    pip install --no-cache-dir "jedi!=0.18.0"

# Set up and build the user environment.
from userbase as sample_restraint

COPY --from=gromacs2021 --chown=tutorial:tutorial /gromacs-2021/python_packaging/sample_restraint $TUTORIAL/sample_restraint

RUN . $VENV/bin/activate && \
    . /usr/local/gromacs/bin/GMXRC && \
    (cd $TUTORIAL/sample_restraint && \
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

ADD docker/notebook /docker_entry_points/

CMD ["/docker_entry_points/notebook"]
