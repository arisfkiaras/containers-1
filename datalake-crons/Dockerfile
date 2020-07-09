from rucio/rucio-daemons

RUN yum clean all && \
    rm -rf /var/cache/yum

RUN yum install -y git cronie

RUN mkdir /scripts

WORKDIR /scripts

RUN git clone https://github.com/ESCAPE-WP2/Utilities-and-Operations-Scripts.git

COPY ./scripts/* /scripts
COPY ./install_crons.sh /install_crons.sh

ENTRYPOINT ["/bin/bash"]
