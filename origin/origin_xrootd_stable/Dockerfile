FROM centos:7

LABEL maintainer="Riccardo.Di.Maria@CERN.ch"

WORKDIR /root

RUN yum update -y
RUN yum install -y which wget curl hostname
RUN yum clean all -y

### yum repo
RUN curl -s -o /etc/pki/rpm-gpg/RPM-GPG-KEY-wlcg http://linuxsoft.cern.ch/wlcg/RPM-GPG-KEY-wlcg \
    curl -s -o /etc/yum.repos.d/wlcg-centos7.repo http://linuxsoft.cern.ch/wlcg/wlcg-centos7.repo \
    curl -s -o /etc/yum.repos.d/EGI-trustanchors.repo http://repository.egi.eu/sw/production/cas/1/current/repo-files/EGI-trustanchors.repo \
    curl -s -L -o /etc/yum.repos.d/xrootd-testing-slc7.repo http://www.xrootd.org/binaries/xrootd-testing-slc7.repo

RUN yum install -y https://repo.opensciencegrid.org/osg/3.5/osg-3.5-el7-release-latest.rpm

RUN yum install -y epel-release yum-plugin-ovl \ 
                   fetch-crl wn sysstat git vim gcc \
                   cmake make ca-policy-egi-core ca-policy-lcg \ 
                   voms-clients-cpp voms \
                   gcc-c++ voms-devel sudo \
    && yum clean all -y

### packages
RUN yum install -y xrootd \
                   xrootd-client  \
                   xrootd-devel xrootd-libs \ 
                   xrootd-server xrootd-server-devel \
                   xrdcl-http xrootd-voms

COPY rpms/* /root/
RUN yum install -y /root/mockdata-plugin-1.1.0-2.el7.cern.x86_64.rpm

RUN yum install -y jemalloc lsof iperf3

RUN yum install -y strace telnet gperftools screen
RUN yum install -y xrootd-lcmaps xrootd-scitokens xrootd-multiuser scitokens-cpp scitokens-cpp-devel

### vomses
RUN yum install -y wlcg-voms-atlas wlcg-voms-cms wlcg-voms-dteam
RUN mkdir -p /etc/vomses \
    && wget https://indigo-iam.github.io/escape-docs/voms-config/voms-escape.cloud.cnaf.infn.it.vomses -O /etc/vomses/voms-escape.cloud.cnaf.infn.it.vomses \
    && mkdir -p /etc/grid-security/vomsdir/escape \
    && wget https://indigo-iam.github.io/escape-docs/voms-config/voms-escape.cloud.cnaf.infn.it.lsc -O /etc/grid-security/vomsdir/escape/voms-escape.cloud.cnaf.infn.it.lsc

RUN yum install -y voms-clients voms-clients-java voms-api-java osg-ca-certs

### XRootD HEAD - ownership should be set in ENTRYPOINT if external volume is mounted with '-v' option from host
RUN mkdir -p /data/xrd
RUN chown -R xrootd:xrootd /data && chmod -R 0755 /data

COPY config/etc__xrootd__xrootd-mockdata_port1213.cfg.erb /etc/xrootd/xrootd-mockdata_port1213.cfg
COPY config/etc__xrootd__xrootd-mockstorage.cfg.erb /etc/xrootd/xrootd-mockstorage.cfg
COPY config/etc__xrootd__Authfile.erb /etc/xrootd/Authfile

EXPOSE 1094/tcp
EXPOSE 1213/tcp

### Debug
COPY files/etc__sysconfig__xrootd /etc/sysconfig/xrootd

COPY files/etc__systemd__system__xrootd@_service_d__xrootd@.conf.erb /etc/systemd/system/xrootd@.service.d/xrootd@.conf
RUN chmod 0444 /etc/systemd/system/xrootd@.service.d/xrootd@.conf

### HTTP and Tokens
COPY files/etc__xrootd__client_plugins_d__xrdcl-http-plugin.conf.erb /etc/xrootd/client.plugins.d/xrdcl-http-plugin.conf
COPY files/etc__xrootd__scitokens.cfg.erb /etc/xrootd/scitokens.cfg
COPY files/etc__xrootd__robots.txt.erb /etc/xrootd/robots.txt

### Entrypoint
# xrootd user is created during installation
# here we will fix its GID and UID so files created by one container will be modifiable by the next.
RUN groupmod -o -g 10940 xrootd
RUN usermod -o -u 10940 -g 10940 -s /bin/sh xrootd

RUN mkdir -p /var/run/xrootd && chown -R xrootd:xrootd /var/run/xrootd
RUN mkdir -p /var/log/xrootd && chown -R xrootd:xrootd /var/log/xrootd
RUN chown -R xrootd:xrootd /etc/xrootd
RUN mkdir -p /xrd && chown -R xrootd:xrootd /xrd
COPY scripts/container_start.sh /xrd/
RUN chmod -R +x /xrd/

# build  
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt
WORKDIR /xrd
ENTRYPOINT [ "/xrd/container_start.sh" ]
