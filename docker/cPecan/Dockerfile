FROM ubuntu:14.04
MAINTAINER Trevor Pesout, tpesout@ucsc.edu

ENV SONLIB_COMMIT=265d6c510cff90412d88e5ab9945818cfdff6e41
ENV CPECAN_COMMIT=9c1523479d1cce29f073608dcd8855c48a1f77ce

# update and install dependencies
RUN apt-get update && \
    apt-get -y install time git make gcc bzip2 lzma-dev zlib1g-dev libcurl4-openssl-dev libcrypto++-dev \
        libpthread-stubs0-dev g++ wget libbz2-dev liblzma-dev autoconf unzip php5-mcrypt python-pip python-dev && \
    apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    pip install numpy pysam

# get sonLib
WORKDIR /opt
RUN wget https://github.com/benedictpaten/sonLib/archive/$SONLIB_COMMIT.zip && \
    unzip $SONLIB_COMMIT.zip && \
    cd /opt/sonLib-$SONLIB_COMMIT && \
    make && \
    cd /opt && \
    mv /opt/sonLib-$SONLIB_COMMIT /opt/sonLib && \
    rm -rf /opt/*$SONLIB_COMMIT*

# get cPecan
WORKDIR /opt
RUN git clone --recursive https://github.com/benedictpaten/cPecan.git && \
    cd /opt/cPecan && \
    git fetch && \
    git checkout $CPECAN_COMMIT && \
    rm -rf /opt/cPecan/.git && \
    cd /opt/cPecan && \
    make

# setup entrypoint
COPY wrapper.sh /opt/
ENTRYPOINT ["sh", "/opt/wrapper.sh"]
