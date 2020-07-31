# Origin-Containers
> ESCAPE Containers: XRootD based - EPEL/OSG stable versions & HEAD

- [Origin-XRootD-stable](#origin-xrootd-stable)

The procedure is similar to [XCache-Containers](containers/xcache/README.md#xcache-containers) with the following differences.

It is necessary to manually place files into `ORIGIN_ST` if MockStorage is meant to be used.

It is **not** necessary to place `xrdcert.pem` and `xrdkey.pem` in `/tmp/container_cert` directory.

The hostname of the container can **always** be randomly set.
However, it is necessary to update `/etc/xrootd/Authfile` to take into account the hostname of the host used (with the related ports).


If the host is an origin server itself, unused ports `XRD_MOCKSTORAGE_PORT` and `XRD_MOCKDATA_PORT` are mapped (`-p`) to `1094` and `1213` ports in the container.
The first accesses MockStorage, i.e. files physically present in `ORIGIN_ST`;
the second exploits MockData functionality, i.e. files are created on-the-fly as long as they are requested with format `file.root_1024_0`.

The image `containers/${REPO}:${TAG}` is used to run the container:
```
docker run -it -v /tmp/container_cert/hostcert.pem:/tmp/container_cert/hostcert.pem \
               -v /tmp/container_cert/hostkey.pem:/tmp/container_cert/hostkey.pem \
               -d \
               -h escape-wp2-puppet-mockdata-server.cern.ch \
               --name containers_${REPO}_${TAG} \
               -v ${ORIGIN_ST}:/data/xrd \
               -p ${XRD_MOCKDATA_PORT}:1213 -p ${XRD_MOCKSTORAGE_PORT}:1094 containers/${REPO}:${TAG}

```

## Origin-XRootD-stable
```
REPO=origin_xrootd_stable
IMAGE_ID=
TAG=4.12.3-0
XRD_MOCKSTORAGE_PORT=10949
XRD_MOCKDATA_PORT=12139
ORIGIN_ST="/data/xrd/container-$REPO"
```