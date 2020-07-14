# containers
> ESCAPE Containers: XRootD based - EPEL/OSG stable versions & HEAD

## XCache-Containers

- [XRootD-HEAD](#xrootd-head)
- [XRootD-HEAD-standalone](#xrootd-head-standalone)
- [XRootD-stable](#xrootd-stable)
- [XRootD-stable-standalone](#xrootd-stable-standalone)

After having exported the `ENV` variables of the chosen configuration, the image is built:
```
docker build ${REPO}
```
`TAG` refers to the XRootD version being installed, but it is not used during image building.

`IMAGE_ID` can be set to tag the image itself:
```
docker tag ${IMAGE_ID} containers/${REPO}:${TAG}
```

The image is saved to be exported to the desired host:
```
docker save -o ${REPO}_${TAG} containers/${REPO}:${TAG}
```
The image is loaded on the host:
```
docker load --input ${REPO}_${TAG}
```

If the container uses the external volume `/data/xrd` of the host, it is necessary to create a sub-directory that is used only by the container itself:
```
mkdir -p ${CACHE_ST}
```
This path is mounted during run-time through `-v` option at default location on the container: `/data/xrd`.
This method deals with host-container ownerships.

It is necessary to place `hostcert.pem` and `hostkey.pem` in `/tmp/container_cert` directory that the user created locally on the host.
These will be used by XCache to AuthN the client.

It is necessary to place `xrdcert.pem` and `xrdkey.pem` in `/tmp/container_cert` directory that the user created locally on the host.
These will be used by XCache to be AuthN by the origin server.
For CERN specific case, the attribute `Role=xcache` of the ESCAPE robot certificate defines XCache as superuser.

The hostname of the container can be randomly set (`-h`) **only if standalone** images are used.
Otherwise, XCache configuration file uses `escape-wp2-puppet-xcache-${CACHE_LEVEL}.cern.ch` pattern to properly construct the cluster.


If the host is XCache itself, unused ports `CMSD_CONTAINER_PORT` and `XRD_CONTAINER_PORT` are mapped (`-p`) to `cmsd` and `xrd` default ports in the container.

The image `containers/${REPO}:${TAG}` is used to run the container:
```
docker run -it -v /tmp/container_cert/hostcert.pem:/tmp/container_cert/hostcert.pem \
               -v /tmp/container_cert/hostkey.pem:/tmp/container_cert/hostkey.pem \
               -v /tmp/container_cert/xrdcert.pem:/tmp/container_cert/xrdcert.pem \
               -v /tmp/container_cert/xrdkey.pem:/tmp/container_cert/xrdkey.pem \
               -d \
               -h escape-wp2-puppet-xcache-${CACHE_LEVEL}.cern.ch \
               --name containers_${REPO}_${TAG} \
               -v ${CACHE_ST}:/data/xrd \
               -p ${CMSD_CONTAINER_PORT}:1213 -p ${XRD_CONTAINER_PORT}:1094 containers/${REPO}:${TAG}
```

The container, named `containers_${REPO}_${TAG}`, is accessible:
```
docker exec -it containers_${REPO}_${TAG} /bin/bash
```



### XRootD-HEAD
```
REPO=xcache_xrootd_head
IMAGE_ID=
TAG=5.0.0-0
CACHE_LEVEL=level0-10
XRD_CONTAINER_PORT=10940
CMSD_CONTAINER_PORT=12130
CACHE_ST="/data/xrd/container-$REPO"
```

### XRootD-HEAD-standalone
```
REPO=xcache_xrootd_head_standalone
IMAGE_ID=
TAG=5.0.0-0
CACHE_LEVEL=0
XRD_CONTAINER_PORT=10941
CMSD_CONTAINER_PORT=12131
CACHE_ST="/data/xrd/container-$REPO"
```

### XRootD-stable
```
REPO=xcache_xrootd_stable
IMAGE_ID=
TAG=4.12.3-0
CACHE_LEVEL=level1-10
XRD_CONTAINER_PORT=10942
CMSD_CONTAINER_PORT=12132
CACHE_ST="/data/xrd/container-$REPO"
```

### XRootD-stable-standalone
```
REPO=xcache_xrootd_stable_standalone
IMAGE_ID=
TAG=4.12.3-0
CACHE_LEVEL=1
XRD_CONTAINER_PORT=10943
CMSD_CONTAINER_PORT=12133
CACHE_ST="/data/xrd/container-$REPO"
```

## Origin-Containers

- [Origin-XRootD-stable](#origin-xrootd-stable)

The procedure is similar to [XCache-Containers](#xcache-containers) with the following differences.

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

### Origin-XRootD-stable
```
REPO=origin_xrootd_stable
IMAGE_ID=
TAG=4.12.3-0
XRD_MOCKSTORAGE_PORT=10949
XRD_MOCKDATA_PORT=12139
ORIGIN_ST="/data/xrd/container-$REPO"
```