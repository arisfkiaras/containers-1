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
RUN yum install -y rpm-build cmake3 readline-devel \
                   fuse-devel libxml2-devel ncurses-devel \
                   libcurl-devel libuuid-devel libmacaroons-devel \
                   json-c-devel python2-devel python3-devel \
                   selinux-policy-devel doxygen systemd-devel \
                   davix davix-devel \
    && yum clean all -y

RUN yum install -y krb5-devel openssl-devel graphviz

RUN yum install -y python36 pip3
RUN pip3 install requests

RUN yum install -y jemalloc lsof iperf3

RUN yum install -y strace telnet gperftools
RUN yum install -y scitokens-cpp scitokens-cpp-devel

### vomses
RUN yum install -y wlcg-voms-atlas wlcg-voms-cms wlcg-voms-dteam
RUN mkdir -p /etc/vomses \
    && wget https://indigo-iam.github.io/escape-docs/voms-config/voms-escape.cloud.cnaf.infn.it.vomses -O /etc/vomses/voms-escape.cloud.cnaf.infn.it.vomses \
    && mkdir -p /etc/grid-security/vomsdir/escape \
    && wget https://indigo-iam.github.io/escape-docs/voms-config/voms-escape.cloud.cnaf.infn.it.lsc -O /etc/grid-security/vomsdir/escape/voms-escape.cloud.cnaf.infn.it.lsc

RUN yum install -y voms-clients voms-clients-java voms-api-java osg-ca-certs

### XRootD HEAD
COPY --chown=root:root files/xrootd.spec .

RUN git clone https://github.com/xrootd/xrootd.git \
    && cd /root/xrootd \
    && git submodule init && git submodule update -- src/XrdClHttp \
    && cd /root/xrootd/packaging \
    && ./makesrpm.sh && cp xrootd-*rpm /tmp \
    && mkdir -p /tmp/x /root/rpmbuild /root/rpmbuild/SPECS/ /root/rpmbuild/SOURCES/ \
    && cd /tmp/x \
    && rpm2cpio /tmp/xroot*rpm | cpio -dimv \
    && cp /root/xrootd.spec /root/rpmbuild/SPECS/ && cp xrootd.tar.gz /root/rpmbuild/SOURCES/ \
    && rm -rf /tmp/xrootd-*rpm /tmp/x \
    && cd /root/rpmbuild/SPECS \
    && rpmbuild -ba --define "_with_xrdclhttp 1" xrootd.spec \
    && rpm -Uvh --nodeps /root/rpmbuild/RPMS/x86_64/* /root/rpmbuild/RPMS/noarch/* \
    && cd /root && rm -rf build xrootd rpmbuild \
    && yum --enablerepo=osg-upcoming-development install -y xrootd-lcmaps xrootd-scitokens xrootd-multiuser

RUN mkdir -p /data/xrd
RUN chown -R xrootd:xrootd /data && chmod 0755 /data
RUN chown -R xrootd:xrootd /data/xrd && chmod 0755 /data/xrd

COPY --chown=xrootd:xrootd config/etc__xrootd__xrootd-xcache_XRootD_HEAD.cfg.erb /etc/xrootd/xrootd-xcache.cfg
COPY --chown=xrootd:xrootd config/etc__xrootd__Authfile.erb /etc/xrootd/Authfile
RUN chown -R xrootd:xrootd /etc/xrootd/

EXPOSE 1094/tcp
EXPOSE 1213/tcp

### Monit
COPY --chown=root:root monit/* /root/

### Debug
COPY --chown=root:root files/etc__sysconfig__xrootd /etc/sysconfig/xrootd

COPY --chown=root:root files/etc__systemd__system__xrootd@_service_d__xrootd@.conf.erb /etc/systemd/system/xrootd@.service.d/xrootd@.conf
RUN chmod 0444 /etc/systemd/system/xrootd@.service.d/xrootd@.conf

### Auth
RUN mkdir -p /etc/grid-security/xrd/
RUN chown -R xrootd:xrootd /etc/grid-security/xrd/

### HTTP and Tokens
COPY --chown=xrootd:xrootd files/etc__xrootd__client_plugins_d__xrdcl-http-plugin.conf.erb /etc/xrootd/client.plugins.d/xrdcl-http-plugin.conf
COPY --chown=xrootd:xrootd files/etc__xrootd__scitokens.cfg.erb /etc/xrootd/scitokens.cfg
COPY --chown=xrootd:xrootd files/etc__xrootd__robots.txt.erb /etc/xrootd/robots.txt

### Entrypoint
RUN mkdir -p /xrd /var/run/xrootd && chown -R xrootd:xrootd /xrd /var/run/xrootd
COPY scripts/container_start.sh /xrd/
RUN chmod -R +x /xrd/
WORKDIR /xrd
ENTRYPOINT [ "/xrd/container_start.sh" ]
