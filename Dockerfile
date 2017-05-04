FROM nvidia/cuda:13.5-cudnn5-devel-ubuntu14.04
MAINTAINER caffe-maint@googlegroups.com

RUN sed -i s/archive.ubuntu.com/mirrors.163.com/g /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        vim \
        wget \
        unzip \
        gfortran \
        curl \
        pkgconf \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*
RUN ln /dev/null /dev/raw1394
ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG=rc4

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    cp Makefile.config.example Makefile.config && \
    echo "USE_CUDNN := 1" >> Makefile.config && \
    make -j"$(nproc)"

RUN make pycaffe

WORKDIR /opt

# build and install opencv
RUN	apt-get update && apt-get install -y -q \
		libavformat-dev \
		libavcodec-dev \
		libavfilter-dev \
		libswscale-dev \
		libjpeg-dev \
		libpng-dev \
		libtiff-dev \
		libjasper-dev \
		zlib1g-dev \
		libopenexr-dev \
		libxine-dev \
		libeigen3-dev \
		libtbb-dev && \
    rm -rf /var/lib/apt/lists/*
ADD	build_opencv.sh	/build_opencv.sh
RUN	/bin/sh /build_opencv.sh
RUN	rm -rf /build_opencv.sh

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

WORKDIR /workspace 
                                                     