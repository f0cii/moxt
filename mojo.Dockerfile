# Reference:
# https://github.com/modularml/mojo/blob/main/examples/docker/Dockerfile.mojosdk

# Use the base image based on Ubuntu 22.04
FROM ubuntu:22.04

# Set the default timezone argument
ARG DEFAULT_TZ=Asia/Shanghai
ENV DEFAULT_TZ=$DEFAULT_TZ

# Update package list and install basic utilities
RUN apt-get update \
   && DEBIAN_FRONTEND=noninteractive TZ=$DEFAULT_TZ apt-get install -y \
   tzdata \
   vim \
   nano \
   sudo \
   curl \
   wget \
   git && \
   rm -rf /var/lib/apt/lists/*

# Download the latest version of minicoda py3.11 for linux x86/x64.
RUN curl -fsSL https://repo.anaconda.com/miniconda/$( wget -O - https://repo.anaconda.com/miniconda/ 2>/dev/null | grep -o 'Miniconda3-py311_[^"]*-Linux-x86_64.sh' | head -n 1) > /tmp/miniconda.sh \
       && chmod +x /tmp/miniconda.sh \
       && /tmp/miniconda.sh -b -p /opt/conda

ENV PATH=/opt/conda/bin:$PATH
RUN conda init

RUN pip install \
        jupyterlab \
        ipykernel \
        matplotlib \
        ipywidgets

# A random default token
ARG AUTH_KEY=5ca1ab1e
ENV AUTH_KEY=$AUTH_KEY

RUN curl https://get.modular.com | sh - && \
    modular auth $AUTH_KEY 
RUN modular install mojo

ARG MODULAR_HOME="/root/.modular"
ENV MODULAR_HOME=$MODULAR_HOME
ENV PATH="$PATH:$MODULAR_HOME/pkg/packages.modular.com_mojo/bin"

# Change permissions to allow for Apptainer/Singularity containers
RUN chmod -R a+rwX /root

RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
# CMD ["jupyter", "lab", "--ip='*'", "--NotebookApp.token=''", "--NotebookApp.password=''","--allow-root"]

# Set the container startup command
CMD ["/bin/bash"]
